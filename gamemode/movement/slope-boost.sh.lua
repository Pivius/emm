SlopeService = SlopeService or {}


-- # Properties

function SlopeService.InitPlayerProperties(ply)
	ply.slope_onground = false
	ply.last_vel = Vector(0,0,0)
end
hook.Add(
	SERVER and "InitPlayerProperties" or "InitLocalPlayerProperties",
	"SlopeService.InitPlayerProperties",
	SlopeService.InitPlayerProperties
)


-- # Slope Boost

function SlopeService.AddSpeed(trace, ply, move)
	local vel = move:GetVelocity()
	local origin = move:GetOrigin()
	
	if 
		1 > trace.HitNormal.z and 
		ply:OnGround() and 
		not ply.slope_onground and
		0 >= vel.z 
	then
		local last_vel = ply.last_vel
		local adjust

		last_vel.z = last_vel.z - (ply.gravity * FrameTime() * 0.5)
		change = trace.HitNormal * last_vel:Dot(trace.HitNormal)
		vel = last_vel - change
		adjust = vel:Dot(trace.HitNormal)

		if adjust < 0 then
			vel = vel - (trace.HitNormal * adjust)
		end

		vel.z = 0
		last_vel.z = 0

		if vel:LengthSqr() > last_vel:LengthSqr() then
			move:SetVelocity(vel)
		end
		
		ply.slope_onground = true
	end
end

function SlopeService.SetupSlope(ply, move, cmd)
	if ply:OnGround() then
		ply.slope_onground = true
	else
		ply.slope_onground = false
	end

	ply.last_vel = move:GetVelocity()
end
hook.Add("SetupMove", "SlopeService.SetupSlope", SlopeService.SetupSlope)