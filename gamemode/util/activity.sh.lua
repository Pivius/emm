ActivityService = ActivityService or {}
ActivityService.activities = ActivityService.activities or {}


-- # Properties

function ActivityService.InitPlayerProperties(ply)
	ply.activities = table.Copy(ActivityService.activities)
end
hook.Add(
	SERVER and "InitPlayerProperties" or "InitLocalPlayerProperties",
	"ActivityService.InitPlayerProperties",
	ActivityService.InitPlayerProperties
)


-- # Utils

function ActivityService.SetStats(ply, activity, stats)
	assert(istable(stats), "3rd argument is not a table!")

	for k, v in pairs(stats) do
		ply.activities[activity][k] = v
	end
end

function ActivityService.AddStats(ply, activity, stats)
	assert(istable(stats), "3rd argument is not a table!")

	for k, v in pairs(stats) do
		if istable(ply.activities[activity][k]) then
			table.insert(ply.activities[activity][k], v)
		end
	end
end

function ActivityService.RegisterActivity(activities)
	for key, activity in pairs(activities) do
		if ActivityService.activities[key] then
			activity.id = ActivityService.activities[key].id
			ActivityService.activities[key] = activity
		else
			activity.id = table.Count(ActivityService.activities) + 1
			ActivityService.activities[key] = activity

			for _, ply in pairs(player.GetAll()) do
				ply.activities[key] = activity
			end
		end
	end
end


-- # Init

local ACTIVITY_DIRECTORY = "activities/"
local activity_files, activity_dirs = file.Find(gamemode_lua_directory..ACTIVITY_DIRECTORY.."*", "LUA")
local activity_fenv_metatable = {__index = _G}

function ActivityService.LoadActivity(path)
	local activity_fenv = {}

	activity_fenv.ACTIVITY = ActivityService.activities
	setmetatable(activity_fenv, activity_fenv_metatable)

	setfenv(0, activity_fenv)
	EMM.Include(path)
	setfenv(0, _G)

	ActivityService.RegisterActivity(activity_fenv.ACTIVITY)
end

function ActivityService.LoadActivities()
	for _, activity in pairs(activity_files) do
		ActivityService.LoadActivity(ACTIVITY_DIRECTORY..activity)
	end

	for _, activity in pairs(activity_dirs) do
		ActivityService.LoadActivity(ACTIVITY_DIRECTORY..activity.."/init")
	end

	hook.Run "LoadActivityPrototypes"
end
hook.Add("Initialize", "ActivityService.LoadActivities", ActivityService.LoadActivities)
hook.Add("OnReloaded", "ActivityService.ReloadActivities", ActivityService.LoadActivities)

PrintTable(ActivityService.activities)