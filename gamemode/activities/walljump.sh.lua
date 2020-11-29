ActivityService.NewActivity{
	key = "xwalljump",
	name = "XWJ",
	count = 0
}

ActivityService.NewActivity{
	key = "hwalljump",
	name = "HWJ",
	count = 0
}

ActivityService.NewActivity{
	key = "vwalljump",
	name = "VWJ",
	count = 0,
}

ActivityService.NewActivity{
	key = "walljump_angle",
	name = "WallJump Angle",
	xwalljump_sum = 0,
	xwalljump_samples = 0,
	hwalljump_sum = 0,
	hwalljump_samples = 0
}

ActivityService.NewActivity{
	key = "queue_walljump",
	name = "QueueWJ",
	queue = {},
	last_walljump = 0
}

local function GetButtons(buttons)
	return bit.band(buttons, bit.bor(IN_FORWARD, IN_BACK)), bit.band(buttons, bit.bor(IN_MOVELEFT, IN_MOVERIGHT))
end

local function XWallJump(ply, move, angle, dir)
	local fwd_buttons, side_buttons = GetButtons(move:GetButtons()) 
	local fwd_old_buttons = GetButtons(move:GetOldButtons()) 
	local last_walljump = ply.activities.queue_walljump.last_walljump

	if ((fwd_buttons > 0 and side_buttons > 0) or (fwd_old_buttons > 0 and side_buttons > 0)) and last_walljump ~= CurTime() then
		ActivityService.AddStats(ply, "queue_walljump", {queue = {walljump = "xwalljump", dir = dir, angle = angle, time = CurTime()}})
		ActivityService.SetStats(ply, "queue_walljump", {last_walljump = CurTime()})
	end
	
end
hook.Add("WallJump", "XWallJump", XWallJump)

local function HWallJump(ply, move, angle, dir)
	local fwd_buttons, side_buttons = GetButtons(move:GetButtons()) 
	local fwd_old_buttons = GetButtons(move:GetOldButtons()) 
	local last_walljump = ply.activities.queue_walljump.last_walljump

	if ((fwd_buttons == 0 and side_buttons > 0) and fwd_old_buttons == 0) and last_walljump ~= CurTime() then
		ActivityService.AddStats(ply, "queue_walljump", {queue = {walljump = "hwalljump", dir = dir, angle = angle, time = CurTime()}})
		ActivityService.SetStats(ply, "queue_walljump", {last_walljump = CurTime()})
	end
	
end
hook.Add("WallJump", "HWallJump", HWallJump)

local function QueueWallJump(ply, move, cmd)
	local queue = ply.activities.queue_walljump.queue

	if #queue > 0 and IsFirstTimePredicted() then 
		if queue[1].time + 0.2 > CurTime() then
			local fwd_buttons, side_buttons = GetButtons(move:GetButtons())
			local walljump_dir = queue[1].dir:Dot(move:GetAngles():Right())

			if queue[1].walljump == "hwalljump" and fwd_buttons > 0 then
				ply.activities.queue_walljump.queue[1].walljump = "xwalljump"
			elseif 
				queue[1].walljump == "xwalljump" and 
				fwd_buttons == 0 and 
				side_buttons ~= 1536 and 
				((walljump_dir > 0 and 
				move:KeyDown(IN_MOVELEFT)) or 
				0 > walljump_dir and 
				move:KeyDown(IN_MOVERIGHT)) 
			then
				table.remove(ply.activities.queue_walljump.queue, 1)
				ActivityService.SetStats(ply, "vwalljump", {count = ply.activities.vwalljump.count + 1})
			end
		else
			ActivityService.SetStats(ply, queue[1].walljump, {count = ply.activities[queue[1].walljump].count + 1})
			ActivityService.SetStats(ply, "walljump_angle", {[queue[1].walljump.."_sum"] = ply.activities.walljump_angle[queue[1].walljump.."_sum"] + queue[1].angle})
			ActivityService.SetStats(ply, "walljump_angle", {[queue[1].walljump.."_samples"] = ply.activities.walljump_angle[queue[1].walljump.."_samples"] + 1})
			table.remove(ply.activities.queue_walljump.queue, 1)
		end
	end
end
hook.Add("SetupMove", "QueueWallJump", QueueWallJump)