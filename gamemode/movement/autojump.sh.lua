AutoJumpService = AutoJumpService or {}


-- # Properties

function AutoJumpService.InitPlayerProperties(ply)
	ply.can_autojump = false
	ply.force_autojump = false
	ply.unduck_jump = false
end
hook.Add(
	SERVER and "InitPlayerProperties" or "InitLocalPlayerProperties",
	"AutoJumpService.InitPlayerProperties",
	AutoJumpService.InitPlayerProperties
)


-- # Autojump

function AutoJumpService.AutoJump(ply, move)
	if 	
		ply.can_autojump and
		(move:KeyDown(IN_JUMP) or ply.force_autojump) and
		ply:IsOnGround()
	then
		move:SetOldButtons(bit.band(move:GetOldButtons(), bit.bnot(IN_JUMP)))
		move:SetButtons(bit.bor(move:GetButtons(), IN_JUMP))
	end
end
hook.Add("SetupMove", "AutoJumpService.AutoJump", AutoJumpService.AutoJump)


-- # Unduck jump

function AutoJumpService.DuckJump(ply, move)
	local mins, maxs = ply:GetHull()
	local duck_mins, duck_maxs = ply:GetHullDuck()
	local pos = move:GetOrigin()
	local trace_hull = util.TraceHull {
		start = pos,
		endpos = pos,
		mins = mins,
		maxs = maxs + Vector(0, 0, maxs.z/2),
		mask = MASK_PLAYERSOLID_BRUSHONLY
	}
	local should_jump = ((ply:KeyPressed(IN_JUMP) or ply:KeyReleased(IN_JUMP)) or (ply.can_autojump and ply:KeyDown(IN_JUMP)) or ply.force_autojump)

	if 
		ply:OnGround() and 
		not move:KeyDown(IN_DUCK) and 
		ply:Crouching() and 
		0 >= ply.old_velocity.z and
		should_jump
	then
		if not trace_hull.HitWorld then
			ply:RemoveFlags(FL_DUCKING)
			ply.unduck_jump = true
		else
			ply:SetGroundEntity(NULL)
			move:SetVelocity(move:GetVelocity() + Vector(0, 0, ply:GetJumpPower()))
		end
	end

	if not trace_hull.HitWorld and ply.unduck_jump and not ply:IsFlagSet(FL_DUCKING) then
		ply:AddFlags(FL_DUCKING)

		if ply:OnGround() then
			ply:SetGroundEntity(NULL)
			ply.unduck_jump = false
			pos.z = trace_hull.HitPos.z + (maxs.z - duck_maxs.z)
			move:SetOrigin(pos)
		end
	end
end
hook.Add("PlayerTick", "AutoJumpService.DuckJump", AutoJumpService.DuckJump)