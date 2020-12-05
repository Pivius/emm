-- Walljump types

ActivityService.NewActivity{
	key = "xwalljump",
	name = "XWJ",
	count = 0,
	angle = {sum = 0, samples = 0},
	interval = {sum = 0, samples = 0}
}

ActivityService.NewActivity{
	key = "hwalljump",
	name = "HWJ",
	count = 0,
	angle = {sum = 0, samples = 0},
	interval = {sum = 0, samples = 0}
}

ActivityService.NewActivity{
	key = "vwalljump",
	name = "VWJ",
	count = 0,
}

ActivityService.NewActivity{
	key = "queue_walljump",
	name = "QueueWJ",
	queue = {},
	last_walljump = 0
}

ActivityService.NewActivity{
	key = "wallcheck",
	name = "Wallcheck",
	count = 0,
}

local function GetButtons(buttons)
	return bit.band(buttons, bit.bor(IN_FORWARD, IN_BACK)), bit.band(buttons, bit.bor(IN_MOVELEFT, IN_MOVERIGHT))
end

hook.Add("WallJump", "Activity.Walljump", function(ply, move, angle, dir)
	local fwd_buttons, side_buttons = GetButtons(move:GetButtons()) 
	local fwd_old_buttons = GetButtons(move:GetOldButtons()) 
	local cur_time = CurTime()
	local walljump_type = nil
	
	if ply.activities.queue_walljump.last_walljump ~= cur_time then
		if ((fwd_buttons > 0 and side_buttons > 0) or (fwd_old_buttons > 0 and side_buttons > 0))  then
			walljump_type = "xwalljump"
		elseif ((fwd_buttons == 0 and side_buttons > 0) and fwd_old_buttons == 0) then
			walljump_type = "hwalljump"
		end
	end

	if walljump_type then
		ActivityService.AddData(ply, "queue_walljump", {
			queue = {
				walljump = walljump_type, 
				dir = dir, angle = angle, 
				time = cur_time, 
				interval = math.Round(cur_time - ply.activities.queue_walljump.last_walljump, 4)
			}, 
			last_walljump = cur_time
		})
	end
	
end)

hook.Add("SetupMove", "Activity.WallJumpQueue", function(ply, move, cmd)
	local queue = ply.activities.queue_walljump.queue

	if #queue > 0 and IsFirstTimePredicted() then 
		local walljump_type = queue[1].walljump

		if queue[1].time + 0.2 > CurTime() then
			local fwd_buttons, side_buttons = GetButtons(move:GetButtons())
			local walljump_dir = queue[1].dir:Dot(move:GetAngles():Right())

			if walljump_type == "hwalljump" and fwd_buttons > 0 then
				ply.activities.queue_walljump.queue[1].walljump = "xwalljump"
			elseif 
				walljump_type == "xwalljump" and 
				fwd_buttons == 0 and 
				side_buttons ~= 1536 and 
				((walljump_dir > 0 and 
				move:KeyDown(IN_MOVELEFT)) or 
				0 > walljump_dir and 
				move:KeyDown(IN_MOVERIGHT)) 
			then
				table.remove(ply.activities.queue_walljump.queue, 1)
				ActivityService.SetData(ply, "vwalljump", {count = ply.activities.vwalljump.count + 1})
			end
		else
			ActivityService.SetData(ply, walljump_type, {
				count = ply.activities[walljump_type].count + 1,
				angle = {sum = ply.activities[walljump_type].angle.sum + queue[1].angle, samples = ply.activities[walljump_type].angle.samples + 1}
			})

			if 0.85 > queue[1].interval then
				ActivityService.SetData(ply, walljump_type, {
					interval = {sum = ply.activities[walljump_type].interval.sum + queue[1].interval, samples = ply.activities[walljump_type].interval.samples + 1}
				})
			end

			table.remove(ply.activities.queue_walljump.queue, 1)
		end
	end
end)

hook.Add("SetupMove", "Activity.Wallcheck", function(ply, move, cmd) 
	if ply.activities.queue_walljump.last_walljump + 1.5 >= CurTime() and IsFirstTimePredicted() then
		if ply.old_velocity:Length2DSqr() * 0.2 > move:GetVelocity():Length2DSqr() then
			ActivityService.SetData(ply, "wallcheck", {count = ply.activities.wallcheck.count + 1})
		end
	end
end)
