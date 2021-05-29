ActivityService = ActivityService or {}
ActivityService.activities = ActivityService.activities or {}


-- # Properties

function ActivityService.InitPlayerProperties(ply)
	ply.activities = table.Copy(ActivityService.activities)
	ply.activities_bit = 0
	ply.activities_time = 0
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

function ActivityService.NewActivity(activity, override_on_reload)
	if (ActivityService.activities[activity.key] and override_on_reload) or not ActivityService.activities[activity.key] then
		assert(activity.key, "Missing activity key")
		assert(activity.name, "Missing activity name")

		local new_activity = (activity.inherit and table.Copy(ActivityService.activities[activity.inherit])) or {}
		local key = activity.key

		new_activity.bit = (not ActivityService.activities[activity.key] and 2 ^ table.Count(ActivityService.activities)) or ActivityService.activities[activity.key].bit

		for k, v in pairs(activity) do
			if k ~= "key" then
				new_activity[k] = v
			end
		end

		if not ActivityService.activities[key] then
			for _, ply in pairs(player.GetAll()) do
				ply.activities[key] = new_activity
			end
		end

		ActivityService.activities[key] = new_activity
	end
end

function ActivityService.SetData(ply, activity, data)
	assert(istable(data), "3rd argument is not a table!")

	for k, v in pairs(data) do
		if ply.activities[activity][k] then
			ply.activities[activity][k] = v
		end
	end
end

function ActivityService.AddData(ply, activity, data)
	assert(istable(data), "3rd argument is not a table!")

	for k, v in pairs(data) do
		if ply.activities[activity][k] then
			if istable(ply.activities[activity][k]) then
				table.insert(ply.activities[activity][k], v)
			else
				ply.activities[activity][k] = ply.activities[activity][k] + v
			end
		end
	end
end

function ActivityService.Run(ply, activity)
	hook.Call("Activity."..ply.activities[activity].name, GAMEMODE, ply, activity)
	ply.activities_bit = ply.activities_bit + ply.activities[activity].bit
end

function ActivityService.IsTriggered(ply, activity)
	return bit.band(ply.activities_bit, ActivityService.GetBit(activity)) ~= 0
end

function ActivityService.RemoveData(ply, activity, data)
	assert(istable(data), "3rd argument is not a table!")

	for k, v in pairs(data) do
		if ply.activities[activity][k] then
			if istable(ply.activities[activity][k]) then
				table.remove(ply.activities[activity][k], v)
			else
				ply.activities[activity][k] = nil
			end
		end
	end
end

function ActivityService.ResetActivity(ply, activity)
	ply.activities[activity] = ActivityService.activities[activity]
end

function ActivityService.GetBit(activity)
	return ActivityService.activities[activity].bit
end

-- # Hooks

function ActivityService.Trigger(ply)
	ply.activities_bit = 0
end
hook.Add("StartCommand", "ActivityService.Trigger", ActivityService.Trigger)


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