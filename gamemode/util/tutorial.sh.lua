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
	local fwd = angle:Forward():GetNormalized()
	local right = Vector(fwd.y, -fwd.x, 0)
	local distance = 75
	
	local trace_right = util.TraceLine{
		start = pos,
		endpos = pos + right * distance,
		mask = MASK_PLAYERSOLID_BRUSHONLY,
		filter = ply
	}
	local trace_left = util.TraceLine{
		start = pos,
		endpos = pos - right * distance,
		mask = MASK_PLAYERSOLID_BRUSHONLY,
		filter = ply
	}

	return math.min(WalljumpService.GetAngle(angle:Right(), trace_right.HitNormal) + WalljumpService.GetAngle(angle:Right(), trace_left.HitNormal) , 90), trace_right.HitWorld, trace_left.HitWorld
end

function TutorialService.DetermineKeys(ply)
	local angle, trace_right, trace_left = TutorialService.GetAngle(ply)

	angle = math.Round(angle)

	if not (trace_left or trace_right) or (45 > angle or angle > 58) then
		return angle
	elseif trace_left then
		return "left"
	elseif trace_right then
		return "right"
	end

	return false
end


-- # Enums

TUTORIAL_WALLJUMP = 1
TUTORIAL_CORNERJUMP = 2
TUTORIAL_WALLSLIDE = 3
TUTORIAL_ANGLE = 4
TUTORIAL_VWJ = 5
TUTORIAL_XWJ = 6


-- # Tasks

TutorialService.notification = {
	[TUTORIAL_WALLJUMP] = "Stand next to a wall, hold spacebar and press any key pointing the opposite direction of the wall",
	[TUTORIAL_CORNERJUMP] = "Hold W+A+D and press Spacebar while looking into a corner",
	[TUTORIAL_WALLSLIDE] = "Right Click on your mouse to wall slide",
	[TUTORIAL_ANGLE] = ("Look at a wall at a 45-58 degree angle"),
	[TUTORIAL_VWJ] = "Press and hold D+SPACE and rapidly press W+A.",
	[TUTORIAL_VWJ + 0.5] = "Press and hold A+SPACE and rapidly press W+D.",
	[TUTORIAL_XWJ] = "Press and hold W+D+SPACE and rapidly press A.",
	[TUTORIAL_XWJ + 0.5] = "Press and hold W+A+SPACE and rapidly press D.",
}

TaskService.NewTask({
	key = "tutorial_walljump",
	name = "WalJump Tutorial",
	description = TutorialService.notification[TUTORIAL_WALLJUMP],
	hook = "Walljump",
	func = function(ply, task)
		if IsFirstTimePredicted() then
			ply.running_tutorial = "tutorial_cornerjump"
			ply.tasks["tutorial_cornerjump"].running = true
			return true
		end
	end
})

TaskService.NewTask({
	key = "tutorial_cornerjump",
	name = "CornerJump Tutorial",
	description = TutorialService.notification[TUTORIAL_CORNERJUMP],
	hook = "Activity.Cornerjump",
	count = 0,
	max_count = 10,
	func = function(ply, task)
		if IsFirstTimePredicted() then
			task.count = task.count + 1

			if task.count >= task.max_count then
				ply.running_tutorial = "tutorial_wallslide"
				ply.tasks["tutorial_wallslide"].running = true
				return true
			end
		end
	end
})

TaskService.NewTask({
	key = "tutorial_wallslide",
	name = "Wallslide Tutorial",
	description = TutorialService.notification[TUTORIAL_WALLSLIDE],
	hook = "Wallslide",
	time = 0,
	max_time = 3,
	func = function(ply, task)
		if IsFirstTimePredicted() then
			task.time = task.time + FrameTime()

			if task.time >= task.max_time then
				ply.running_tutorial = "tutorial_vwj"
				ply.tasks["tutorial_vwj"].running = true
				return true
			end
		end
	end
})

TaskService.NewTask({
	key = "tutorial_vwj",
	name = "VWJ Tutorial",
	description = TutorialService.notification[TUTORIAL_ANGLE],
	hook = "Move", --"Activity.VWJ",
	count = 0,
	max_count = 10,
	angle = 0,
	func = function(ply, task)
		local trace = TutorialService.DetermineKeys(ply)

		if isnumber(trace) then
			task.description = TutorialService.notification[TUTORIAL_ANGLE]
			task.angle = trace
		elseif trace == "left" then
			task.description = TutorialService.notification[TUTORIAL_VWJ]
			task.angle = nil
		elseif trace == "right" then
			task.description = TutorialService.notification[TUTORIAL_VWJ + 0.5]
			task.angle = nil
		end

		if IsFirstTimePredicted() and ActivityService.IsTriggered(ply, "vwalljump") then
			task.count = task.count + 1

			if task.count >= task.max_count then
				ply.running_tutorial = "tutorial_xwj"
				ply.tasks["tutorial_xwj"].running = true
				return true
			end
		end
	end
})

TaskService.NewTask({
	key = "tutorial_xwj",
	name = "XWJ Tutorial",
	description = TutorialService.notification[TUTORIAL_ANGLE],
	hook = "Move", --"Activity.VWJ",
	count = 0,
	max_count = 10,
	angle = 0,
	func = function(ply, task)
		local trace = TutorialService.DetermineKeys(ply)

		if isnumber(trace) then
			task.description = TutorialService.notification[TUTORIAL_ANGLE]
			task.angle = trace
		elseif trace == "left" then
			task.description = TutorialService.notification[TUTORIAL_XWJ]
			task.angle = nil
		elseif trace == "right" then
			task.description = TutorialService.notification[TUTORIAL_XWJ + 0.5]
			task.angle = nil
		end

		if IsFirstTimePredicted() and ActivityService.IsTriggered(ply, "xwalljump") then
			task.count = task.count + 1

			if task.count >= task.max_count then
				ply.running_tutorial = false
				return true
			end
		end
	end
})


-- # Command

function TutorialService.Command(ply)
	if not ply.running_tutorial then
		ply.running_tutorial = "tutorial_vwj"
		TaskService.Reset(ply, {"tutorial_walljump", "tutorial_cornerjump", "tutorial_wallslide", "tutorial_vwj", "tutorial_xwj"})
		ply.tasks["tutorial_vwj"].running = true
	else
		TaskService.Reset(ply, {"tutorial_walljump", "tutorial_cornerjump", "tutorial_wallslide", "tutorial_vwj", "tutorial_xwj"})
		ply.running_tutorial = false
	end
end
CommandService.AddCommand({name = "tutorial", callback = TutorialService.Command})