TutorialService = TutorialService or {}


-- # Properties

function TutorialService.InitPlayerProperties(ply)
	ply.running_tutorial = false
end
hook.Add(
	SERVER and "InitPlayerProperties" or "InitLocalPlayerProperties",
	"TutorialService.InitPlayerProperties",
	TutorialService.InitPlayerProperties
)


-- # Utils

function TutorialService.GetAngle(ply)
	local pos = ply:GetPos()
	local angle = ply:EyeAngles()
	local distance = 100
	local trace_east = util.TraceLine{
		start = pos,
		endpos = pos + Vector(distance),
		mask = MASK_PLAYERSOLID_BRUSHONLY,
		filter = ply
	}
	local trace_west = util.TraceLine{
		start = pos,
		endpos = pos - Vector(distance),
		mask = MASK_PLAYERSOLID_BRUSHONLY,
		filter = ply
	}
	local trace_north = util.TraceLine{
		start = pos,
		endpos = pos + Vector(0, distance),
		mask = MASK_PLAYERSOLID_BRUSHONLY,
		filter = ply
	}
	local trace_south = util.TraceLine{
		start = pos,
		endpos = pos - Vector(0, distance),
		mask = MASK_PLAYERSOLID_BRUSHONLY,
		filter = ply
	}

	return math.min(WalljumpService.GetAngle(angle:Right(), trace_east.HitNormal) + WalljumpService.GetAngle(angle:Right(), trace_west.HitNormal) + WalljumpService.GetAngle(angle:Right(), trace_north.HitNormal) + WalljumpService.GetAngle(angle:Right(), trace_south.HitNormal), 90)
end


-- # Enums

TUTORIAL_WALLJUMP = 1
TUTORIAL_CORNERJUMP = 2
TUTORIAL_WALLSLIDE = 3
TUTORIAL_XWJ_ANGLE = 4
TUTORIAL_VWJ = 5
TUTORIAL_XWJ = 6


-- # Tasks

TutorialService.notification = {
	[TUTORIAL_WALLJUMP] = "Stand next to a wall, hold spacebar and press any key pointing the opposite direction of the wall",
	[TUTORIAL_CORNERJUMP] = "Hold W+A+D and press Spacebar while looking into a corner",
	[TUTORIAL_WALLSLIDE] = "Right Click on your mouse to wall slide",
	[TUTORIAL_XWJ_ANGLE] = ("Look at a wall at a 45-58 degree angle"),
	[TUTORIAL_VWJ] = "Press and hold D+SPACE and rapidly press W+A.",
	[TUTORIAL_VWJ + 0.5] = "Press and hold A+SPACE and rapidly press W+D.",
	[TUTORIAL_XWJ] = "Press and hold W+D+SPACE and rapidly press A.",
	[TUTORIAL_XWJ + 0.5] = "Press and hold W+A+SPACE and rapidly press D.",
}

TutorialService.tasks = TutorialService.tasks or {
	TaskService.New(),
	TaskService.New(),
	TaskService.New(),
	TaskService.New(),
	TaskService.New(),
	TaskService.New(),
}

TutorialService.tasks[TUTORIAL_WALLJUMP]:Hook("Walljump", "Tutorial.Walljump", function(ply, task)
	if IsFirstTimePredicted() then
		TutorialService.tasks[TUTORIAL_CORNERJUMP]:AddPlayer {
			player = ply, 
			count = 0, 
			max_count = 10, 
			type = "Cornerjump", 
			tutorial = TutorialService.notification[TUTORIAL_CORNERJUMP]
		}
		ply.running_tutorial = TUTORIAL_CORNERJUMP
		return true
	end
end)

TutorialService.tasks[TUTORIAL_CORNERJUMP]:Hook("Activity.Cornerjump", "Tutorial.Cornerjump", function(ply, task, data)
	if IsFirstTimePredicted() then
		data.count = data.count + 1

		if data.count >= data.max_count then
			TutorialService.tasks[TUTORIAL_WALLSLIDE]:AddPlayer {
				player = ply, 
				type = "Wallslide",
				tutorial = TutorialService.notification[TUTORIAL_WALLSLIDE]
			}
			ply.running_tutorial = TUTORIAL_WALLSLIDE
			return true
		end
	end
end)

TutorialService.tasks[TUTORIAL_WALLSLIDE]:Hook("Wallslide", "Tutorial.Wallslide", function(ply, task, data)
	if IsFirstTimePredicted() then
		TutorialService.tasks[TUTORIAL_XWJ_ANGLE]:AddPlayer {
			player = ply, 
			count =  0, 
			max_count = 100, 
			angles = 0,
			type = "Finding the angle",
			tutorial = TutorialService.notification[TUTORIAL_XWJ_ANGLE]
		}
		ply.running_tutorial = TUTORIAL_XWJ_ANGLE
		return true
	end
end)

TutorialService.tasks[TUTORIAL_XWJ_ANGLE]:Hook("Move", "Tutorial.XWJAngle", function(ply, task, data)
	if IsFirstTimePredicted() then
		data.angle = math.Round(TutorialService.GetAngle(ply))

		if ply.walljump_max_angle > data.angle and data.angle > 45 then
			data.count = data.count + 1

			if data.count >= data.max_count then
				local right = ply:EyeAngles():Forward():GetNormalized()
				local trace_left = WalljumpService.Trace(ply, -Vector(right.y, -right.x, 0))

				TutorialService.tasks[TUTORIAL_VWJ]:AddPlayer {
					player = ply, 
					count = 0, 
					max_count = 10, 
					type = "Vertical Walljump",
					tutorial = (trace_left.HitWorld and TutorialService.notification[TUTORIAL_VWJ]) or TutorialService.notification[TUTORIAL_VWJ + 0.5]
				}
				ply.running_tutorial = TUTORIAL_VWJ
				return true
			end
		end
	end
end)

TutorialService.tasks[TUTORIAL_VWJ]:Hook("Activity.VWJ", "Tutorial.VWJ", function(ply, task, data)
	if IsFirstTimePredicted() then
		data.count = data.count + 1

		if data.count >= data.max_count then
			local right = ply:EyeAngles():Forward():GetNormalized()
			local trace_left = WalljumpService.Trace(ply, -Vector(right.y, -right.x, 0))

			TutorialService.tasks[TUTORIAL_XWJ]:AddPlayer {
				player = ply, 
				count =  0, 
				max_count = 10, 
				type = "Extreme Walljump",
				tutorial = (trace_left.HitWorld and TutorialService.notification[TUTORIAL_XWJ]) or TutorialService.notification[TUTORIAL_XWJ + 0.5]
			}
			ply.running_tutorial = TUTORIAL_XWJ
			return true
		end
	end
end)

TutorialService.tasks[TUTORIAL_XWJ]:Hook("Activity.XWJ", "Tutorial.XWJ", function(ply, task, data)
	if IsFirstTimePredicted() then
		data.count = data.count + 1

		if data.count >= data.max_count then
			ply.running_tutorial = false
			return true
		end
	end
end)


function TutorialService.DetermineKeys(ply, move)
	if ply.running_tutorial == TUTORIAL_VWJ or ply.running_tutorial == TUTORIAL_XWJ then
		local angle = math.Round(TutorialService.GetAngle(ply))
		local right = ply:EyeAngles():Forward():GetNormalized()
		local trace_left, trace_right

		right = Vector(right.y, -right.x, 0)
		trace_left = WalljumpService.Trace(ply, -right)
		trace_right = WalljumpService.Trace(ply, right)

		if not (trace_left.HitWorld or trace_right.HitWorld) or (45 > angle or angle > 58) then
			TutorialService.tasks[ply.running_tutorial]:GetPlayerData(ply).tutorial = TutorialService.notification[TUTORIAL_XWJ_ANGLE]
			TutorialService.tasks[ply.running_tutorial]:GetPlayerData(ply).angle = angle
		else
			TutorialService.tasks[ply.running_tutorial]:GetPlayerData(ply).tutorial = (trace_left.HitWorld and TutorialService.notification[ply.running_tutorial]) or TutorialService.notification[ply.running_tutorial + 0.5]
			TutorialService.tasks[ply.running_tutorial]:GetPlayerData(ply).angle = nil
		end
	end
end
hook.Add("Move", "TutorialService.DetermineKeys", TutorialService.DetermineKeys)

-- # Command

function TutorialService.Command(ply)
	if not ply.running_tutorial then
		ply.running_tutorial = TUTORIAL_WALLJUMP
		TutorialService.tasks[TUTORIAL_WALLJUMP]:AddPlayer {
			player = ply, 
			type = "Walljump", 
			tutorial = TutorialService.notification[TUTORIAL_WALLJUMP]
		}
	else
		ply.running_tutorial = false
	end
end
CommandService.AddCommand({name = "tutorial", callback = TutorialService.Command})