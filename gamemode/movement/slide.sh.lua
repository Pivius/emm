SlideService = SlideService or {}


-- # Properties

function SlideService.InitPlayerProperties(ply)
	ply.can_slide = false
	ply.slide_minimum = 0.71
	ply.slide_hover_height = 2
	ply.slide_onground = false
	ply.sliding = false
	ply.surfing = false
end
hook.Add(
	SERVER and "InitPlayerProperties" or "InitLocalPlayerProperties",
	"SlideService.InitPlayerProperties",
	SlideService.InitPlayerProperties
)


-- # Util

function SlideService.Clip(vel, plane)
	return vel - (plane * vel:Dot(plane))
end

function SlideService.GetGroundTrace(pos, end_pos, ply)
	return util.TraceHull {
		start = pos,
		endpos = end_pos,
		mins = ply:OBBMins(),
		maxs = ply:OBBMaxs(),
		mask = MASK_PLAYERSOLID_BRUSHONLY
	}
end

function SlideService.Trace(ply, vel, origin)
	local pred_vel = vel * FrameTime()
	local hover_height = ply.slide_hover_height
	local slide_trace

	if not ply.sliding and not ply.surfing then
		if 0 > vel.z and not ply:OnGround() then
			slide_trace = SlideService.GetGroundTrace(origin, origin + Vector(0, 0, -hover_height + math.min(pred_vel.z, 0)), ply)
			
			if not slide_trace.HitWorld then
				slide_trace = SlideService.GetGroundTrace(origin, origin + Vector(pred_vel.x, pred_vel.y, -hover_height + math.min(pred_vel.z, 0)), ply)
			end
		else
			if ply:OnGround() then
				slide_trace = SlideService.GetGroundTrace(origin + Vector(0,0,1), origin + Vector(0, 0, -hover_height), ply)
			else
				slide_trace = SlideService.GetGroundTrace(origin, origin + Vector(pred_vel.x, pred_vel.y, -hover_height), ply)
			end
		end
	else
		slide_trace = SlideService.GetGroundTrace(origin, origin + Vector(0, 0, -hover_height + math.min(pred_vel.z, 0)), ply)
		
		if not slide_trace.HitWorld then
			slide_trace = SlideService.GetGroundTrace(origin, origin + Vector(pred_vel.x, pred_vel.y, -hover_height + math.min(pred_vel.z, 0) - 0.1), ply)
		end
	end

	if slide_trace.HitNormal:LengthSqr() ~= 0 then
		return slide_trace
	end

	return false
end

function SlideService.ShouldSlide(ply, normal, vel, slide_vel_z)
	if (0 > Vector(normal.x, normal.y):Dot(Vector(vel.x, vel.y):GetNormalized()) and
		1 > normal.z and
		normal.z > ply.slide_minimum and
		vel:Dot(vel) > 900 and
		((not ply.sliding and slide_vel_z > 150) or ply.sliding)) or
		(normal.z > 0.1 and ply.slide_minimum >= normal.z)
	then
		return true
	end

	return false
end


-- # Sliding

function SlideService.SlideStrafe(move, cmd, normal)
	local forward, right = move:GetMoveAngles():Forward(), move:GetMoveAngles():Right()
	local wish_vel, wish_speed, wish_dir

	forward.z, right.z = 0
	forward:Normalize()
	right:Normalize()
	
	wish_vel = (forward * cmd:GetForwardMove()) + (right * cmd:GetSideMove())
	wish_vel.z = 0
	
	wish_speed = wish_vel
	wish_speed:Normalize()
	wish_speed = wish_speed:Length()
	wish_speed = wish_speed * move:GetMaxSpeed()
	
	if wish_speed > move:GetMaxSpeed() then
		wish_vel = wish_vel * (move:GetMaxSpeed()/wish_speed)
	end
	
	wish_dir = wish_vel

	if normal:Dot(wish_dir) > 0 and move:GetVelocity():Dot(normal) > 0 then
		return true
	end

	return false
end

function SlideService.Slide(ply, move, trace, slide_vel)
	if not ((ply.sliding or ply.surfing) and 0 > (slide_vel.z - move:GetVelocity().z)) then
		if SlideService.ShouldSlide(ply, trace.HitNormal, slide_vel, slide_vel.z) then
			if trace.HitNormal.z > 0.1 and ply.slide_minimum >= trace.HitNormal.z then
				ply.surfing = true
				ply.sliding = false
			else
				ply.surfing = false
				ply.sliding = true
			end

			if (move:GetVelocity().z >= 0 and ply.sliding) or ply.surfing then
				local origin = move:GetOrigin()
				local second_trace

				slide_vel = slide_vel + ply:GetBaseVelocity()
				origin.z = trace.HitPos.z + ply.slide_hover_height
				ply:SetGroundEntity(NULL)
				move:SetVelocity(slide_vel)

				second_trace = SlideService.Trace(ply, slide_vel, origin)

				if second_trace then
					if not second_trace.StartSolid then
						move:SetOrigin(origin)
					end
				end
			end
		end
	else
		ply.sliding = false
		ply.surfing = false
	end
end

function SlideService.RampSlide_DamageFix(ply)
	local vel = ply:GetVelocity()
	local pos = ply:GetPos()
	local pred_vel = vel * FrameTime()
	local slide_trace = SlideService.GetGroundTrace(pos, pos + Vector(pred_vel.x, pred_vel.y, -ply.slide_hover_height + math.min(pred_vel.z, 0)), ply)
	local slide_vel = SlideService.Clip(vel, slide_trace.HitNormal)

	if SlideService.ShouldSlide(ply, slide_trace.HitNormal, vel, slide_vel.z) and (ply.surfing or ply.sliding) then
		pos = slide_trace.HitPos
		pos.z = slide_trace.HitPos.z + ply.slide_hover_height
		ply.slide_onground = {[1] = slide_vel, [2] = pos}
		ply:SetGroundEntity(NULL)
	end
end
hook.Add("OnPlayerHitGround", "SlideService.RampSlide_DamageFix", SlideService.RampSlide_DamageFix)

function SlideService.SetupSlide(ply, move, cmd)
	local vel = move:GetVelocity()
	local origin = move:GetOrigin()
	local slide_trace = SlideService.Trace(ply, vel, origin)
	local slide_vel = Vector(0, 0, 0)
	local should_slide = false
	local fix

	if slide_trace then
		fix = SlideService.SlideStrafe(move, cmd, slide_trace.HitNormal)
		slide_vel = SlideService.Clip(vel, slide_trace.HitNormal)
		should_slide = SlideService.ShouldSlide(ply, slide_trace.HitNormal, vel, slide_vel.z)
		
		if (1 > slide_trace.HitNormal.z and not slide_trace.StartSolid and should_slide) then
			SlideService.Slide(ply, move, slide_trace, slide_vel)

			if fix then
				move:SetVelocity(vel)
				move:SetOrigin(origin)
			end
		end
		
		if 1 > slide_trace.HitNormal.z and not slide_trace.StartSolid then
			SlopeService.AddSpeed( slide_trace, ply, move )
		end
	end

	if ply.slide_onground then
		move:SetVelocity(ply.slide_onground[1])
		move:SetOrigin(ply.slide_onground[2])
		ply.slide_onground = false
	end
	
	if not should_slide then
		ply.sliding = false
		ply.surfing = false
	end
end
hook.Add("SetupMove", "SlideService.SetupSlide", SlideService.SetupSlide)