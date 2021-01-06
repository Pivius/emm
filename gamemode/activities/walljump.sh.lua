-- # Walljump types

ActivityService.NewActivity{
	key = "xwalljump",
	name = "XWJ",
	count = 0,
	angle = {},
	interval = {},
	velocity = {}
}

ActivityService.NewActivity{
	key = "hwalljump",
	name = "HWJ",
	inherit = "xwalljump",
}

ActivityService.NewActivity{
	key = "vwalljump",
	name = "VWJ",
	inherit = "xwalljump",
}

ActivityService.NewActivity{
	key = "cornerjump",
	name = "Cornerjump",
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


-- # Enums

MAX_INTERVAL_SAMPLES = 50
MAX_ANGLE_SAMPLES = 50


-- # Utils

local function GetButtons(buttons)
	return bit.band(buttons, bit.bor(IN_FORWARD, IN_BACK)), bit.band(buttons, bit.bor(IN_MOVELEFT, IN_MOVERIGHT))
end

local function CanWallJump(ply, dir)
	local trace = WalljumpService.Trace(ply, dir)

	return trace.Hit and (ply.can_walljump_sky or not trace.HitSky) and (58 > WalljumpService.GetAngle(dir, trace.HitNormal))
end


-- # Hooks

hook.Add("Walljump", "Activity.Walljump", function(ply, move, angle, dir)
	local fwd_buttons, side_buttons = GetButtons(move:GetButtons()) 
	local fwd_old_buttons = GetButtons(move:GetOldButtons()) 
	local cur_time = CurTime()
	local walljump_type = nil

	if ply.activities.queue_walljump.last_walljump ~= cur_time then
		if ((fwd_buttons > 0 and side_buttons > 0) or (fwd_old_buttons > 0 and side_buttons > 0)) then
			local fwd = move:GetAngles():Forward()
			fwd.z = 0
			fwd:Normalize()

			if WalljumpService.Trace(ply, -dir).HitWorld then
				if WalljumpService.Trace(ply, fwd).HitWorld or WalljumpService.Trace(ply, -fwd).HitWorld then
					ActivityService.AddData(ply, "cornerjump", {count = 1})
					ActivityService.Run(ply, "cornerjump")
				else
					walljump_type = "xwalljump"
				end
			else
				walljump_type = "xwalljump"
			end
		elseif ((fwd_buttons == 0 and side_buttons > 0) and fwd_old_buttons == 0) then
			walljump_type = "hwalljump"
		end
	end

	if walljump_type then
		ActivityService.AddData(ply, "queue_walljump", {
			queue = {
				walljump = walljump_type, 
				dir = dir, 
				angle = angle, 
				time = cur_time, 
				interval = math.Round(cur_time - ply.activities.queue_walljump.last_walljump, 4)
			}
		})
		ActivityService.SetData(ply, "queue_walljump", {last_walljump = cur_time})
		ActivityService.Run(ply, "queue_walljump")
	end
	
end)


hook.Add("SetupMove", "Activity.WalljumpQueue", function(ply, move, cmd)
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
				ply.activities.queue_walljump.queue[1].walljump = "vwalljump"
			end
		else
			ActivityService.AddData(ply, walljump_type, {count = 1, angle = queue[1].angle})

			if #ply.activities[walljump_type].angle > MAX_ANGLE_SAMPLES then
				ActivityService.RemoveData(ply, walljump_type, {angle = 1})
			end

			if 0.85 > queue[1].interval then
				ActivityService.AddData(ply, walljump_type, {interval = queue[1].interval})

				if #ply.activities[walljump_type].interval > MAX_INTERVAL_SAMPLES then
					ActivityService.RemoveData(ply, walljump_type, {interval = 1})
				end
			end

			ActivityService.Run(ply, walljump_type)
			table.remove(ply.activities.queue_walljump.queue, 1)
		end
	end
end)

hook.Add("SetupMove", "Activity.Wallcheck", function(ply, move, cmd) 
	if 
		ply.activities.queue_walljump.last_walljump + 1.5 >= CurTime() and 
		IsFirstTimePredicted() and 
		ply.old_velocity:Length2DSqr() * 0.2 > move:GetVelocity():Length2DSqr() and
		ply.old_velocity:Length2DSqr() >= 250000
	then
		ActivityService.AddData(ply, "wallcheck", {count = 1})
		ActivityService.Run(ply, "wallcheck")
	end
end)
