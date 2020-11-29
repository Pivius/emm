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

function ActivityService.NewActivity(activity)
	local new_activity = {}

	assert(activity.key, "Missing activity key")

	for k, v in pairs(activity) do
		if k ~= "key" then
			new_activity[k] = v
		end
	end

	if not ActivityService.activities[activity.key] then
		for _, ply in pairs(player.GetAll()) do
			ply.activities[activity.key] = new_activity
		end
	end

	ActivityService.activities[activity.key] = new_activity
end

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


-- # Init

local ACTIVITY_DIRECTORY = "activities/"
local activity_files, activity_dirs = file.Find(gamemode_lua_directory..ACTIVITY_DIRECTORY.."*", "LUA")

function ActivityService.LoadActivities()
	for _, activity in pairs(activity_files) do
		EMM.Include(ACTIVITY_DIRECTORY..activity)
	end

	for _, activity in pairs(activity_dirs) do
		EMM.Include(ACTIVITY_DIRECTORY..activity.."/init")
	end

	hook.Run "LoadActivityPrototypes"
end
hook.Add("Initialize", "ActivityService.LoadActivities", ActivityService.LoadActivities)
hook.Add("OnReloaded", "ActivityService.ReloadActivities", ActivityService.LoadActivities)