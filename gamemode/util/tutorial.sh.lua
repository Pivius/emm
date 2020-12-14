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


-- # Enums

TUTORIAL_WALLJUMP = 1
TUTORIAL_CORNERJUMP = 2
TUTORIAL_VWJ = 5
TUTORIAL_WALLSLIDE = 3
TUTORIAL_XWJ_ANGLE = 4
TUTORIAL_XWJ = 4


-- # Utils

local function DebugChatMessage(msg)
	if CLIENT then
		chat.AddText( Color( 255, 255, 255 ), msg)
	end
end


-- # Tasks

TutorialService.tasks = {
	TaskService.New(),
	TaskService.New(),
	TaskService.New(),
	TaskService.New(),
	TaskService.New(),
	TaskService.New(),
}

TutorialService.tasks[TUTORIAL_WALLJUMP]:Hook("Walljump", "Tutorial.Walljump", function(ply, task)
	if IsFirstTimePredicted() then
		TutorialService.tasks[TUTORIAL_CORNERJUMP]:AddPlayer {player = ply, count = 0}
		DebugChatMessage "Perform 10x cornerjumps"
		return true
	end
end)

TutorialService.tasks[TUTORIAL_CORNERJUMP]:Hook("Activity.Cornerjump", "Tutorial.Cornerjump", function(ply, task, data)
	if IsFirstTimePredicted() then
		data.count = data.count + 1

		if data.count >= 10 then
			TutorialService.tasks[TUTORIAL_VWJ]:AddPlayer {player = ply, count = 0}
			DebugChatMessage "Perform 10x vertical walljumps"
			return true
		end
	end
end)

TutorialService.tasks[TUTORIAL_VWJ]:Hook("Activity.VWJ", "Tutorial.VWJ", function(ply, task, data)
	if IsFirstTimePredicted() then
		data.count = data.count + 1

		if data.count >= 10 then
			TutorialService.tasks[TUTORIAL_WALLSLIDE]:AddPlayer {player = ply}
			DebugChatMessage "Perform a wallslide"
			return true
		end
	end
end)

TutorialService.tasks[TUTORIAL_WALLSLIDE]:Hook("Wallslide", "Tutorial.Wallslide", function(ply, task, data)
	if IsFirstTimePredicted() then
		TutorialService.tasks[TUTORIAL_XWJ]:AddPlayer {player = ply, count =  0}
		DebugChatMessage "Perform 20x extreme walljumps"
		return true
	end
end)

TutorialService.tasks[TUTORIAL_XWJ]:Hook("Activity.XWJ", "Tutorial.XWJ", function(ply, task, data)
	if IsFirstTimePredicted() then
		data.count = data.count + 1

		if data.count >= 20 then
			DebugChatMessage "Course finished, you're a pro player now"
			return true
		end
	end
end)


-- # Command

function TutorialService.Command(ply)
	if not ply.running_tutorial then
		DebugChatMessage "Tutorial started"
		DebugChatMessage "Perform a walljump"
		ply.running_tutorial = TUTORIAL_WALLJUMP
		TutorialService.tasks[TUTORIAL_WALLJUMP]:AddPlayer {player = ply}
	else
		ply.running_tutorial = false
	end
end
CommandService.AddCommand({name = "tutorial", callback = TutorialService.Command})