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

function ActivityService.Reload()
	for _, ply in pairs(player.GetAll()) do
		ply.activities = table.Copy(ActivityService.activities)
	end
end
hook.Add("OnReloaded", "ActivityService.Reload", ActivityService.Reload)

-- # Utils

function ActivityService.NewActivity(activity)
	assert(activity.key, "Missing activity key")
	assert(activity.key, "Missing activity name")

	local new_activity = {}

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

function ActivityService.SetData(ply, activity, data)
	assert(istable(data), "3rd argument is not a table!")

	for k, v in pairs(data) do
		if ply.activities[activity][k] then
			ply.activities[activity][k] = v
		end
	end

	hook.Call("Activity."..ply.activities[activity].name, GAMEMODE, ply, activity)
end

function ActivityService.AddData(ply, activity, data)
	assert(istable(data), "3rd argument is not a table!")

	for k, v in pairs(data) do
		if ply.activities[activity][k] then
			if istable(ply.activities[activity][k]) then
				table.insert(ply.activities[activity][k], v)
			else
				ply.activities[activity][k] = v
			end
		end
	end

	hook.Call("Activity."..ply.activities[activity].name, GAMEMODE, ply, activity)
end

function ActivityService.ResetActivity(ply, activity)
	ply.activities[activity] = ActivityService.activities[activity]
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

	hook.Run "LoadActivities"
end
hook.Add("Initialize", "ActivityService.LoadActivities", ActivityService.LoadActivities)
hook.Add("OnReloaded", "ActivityService.ReloadActivities", ActivityService.LoadActivities)