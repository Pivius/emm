TaskService = TaskService or {}
TaskService.tasks = TaskService.tasks or {}


-- # Properties

function TaskService.InitPlayerProperties(ply)
	ply.tasks = table.Copy(TaskService.tasks)
end
hook.Add(
	SERVER and "InitPlayerProperties" or "InitLocalPlayerProperties",
	"TaskService.InitPlayerProperties",
	TaskService.InitPlayerProperties
)

function TaskService.Reload()
	for _, ply in pairs(player.GetAll()) do
		ply.tasks = table.Copy(TaskService.tasks)
	end
end
hook.Add("OnReloaded", "TaskService.Reload", TaskService.Reload)


-- # Utils

function TaskService.NewTask(task)
	assert(task.key and task.name and task.hook, task.func, (task.key and "Missing task key") or (task.name and "Missing task key") or (task.hook and "Missing task hook") or (task.func and "Missing task function"))

	local new_task = (task.inherit and table.Copy(TaskService.tasks[task.inherit])) or task
	local key = task.key
	local func = task.func

	new_task.completed = false
	new_task.running = false
	new_task.func = function(...)
		local var_args = {...}
		local ply = var_args[1]
		table.insert(var_args, 2, ply.tasks[key])

		if not IsEntity(ply) then
			TaskService.End(ply, key)
		else
			if not TaskService.HasCompleted(ply, key) and TaskService.IsRunningTask(ply, key) then
				if func(unpack(var_args)) then
					TaskService.Complete(ply, key)
				end
			end
		end
	end

	if not TaskService.tasks[key] then
		for _, ply in pairs(player.GetAll()) do
			ply.tasks[key] = new_task
		end
	end

	TaskService.tasks[key] = new_task
	TaskService.Start(key)
end

function TaskService.SetPlayerTask(ply, task, tbl)
	for k, v in pairs(tbl) do
		if ply.tasks[task][k] then
			if istable(ply.tasks[task][k]) then
				table.insert(ply.tasks[task][k], v)
			else
				ply.tasks[task][k] = v
			end
		end
	end
end

function TaskService.Complete(ply, task)
	if ply.tasks[task].running then
		ply.tasks[task].completed = true
		hook.Call("TaskService.Complete", GAMEMODE, ply, ply.tasks[task])
	end
end

function TaskService.Start(task)
	local task = TaskService.tasks[task]
	
	hook.Add(task.hook, "TaskService."..task.key, task.func)
end

function TaskService.Stop(task)
	local task = TaskService.tasks[task]

	hook.Remove(task.hook, "TaskService."..task.key)
end

function TaskService.IsRunningTask(ply, task)
	return not Falsy(ply.tasks[task].running)
end

function TaskService.HasCompleted(ply, task)
	return ply.tasks[task].completed
end

function TaskService.Reset(ply, task)
	if istable(task) then
		for k, v in pairs(task) do
			ply.tasks[v] = table.Copy(TaskService.tasks[v])
		end
	else
		ply.tasks[task] = TaskService.tasks[task]
	end
end
