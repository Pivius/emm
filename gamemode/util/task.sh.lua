TaskService = TaskService or Class.New()

function TaskService:Init()
	self.completions = {}
	self.running = {}
	self:Hook("Move", "Jump", function(ply, move)
		if move:KeyPressed(IN_JUMP) then
			return true
		end
	end)
end

function TaskService:Hook(hook, identifier, func)
	self.hook = hook
	self.identifier = "Task_" .. identifier
	self.func = function(...)
		local var_args = {...}
		local ply = var_args[1]

		if not IsEntity(ply) then
			self:Stop()
		else
			if not self:HasCompleted(ply) and self:IsRunningTask(ply) and func(...) then
					self:Complete(ply)
			end
		end
	end
end

function TaskService:Start()
	hook.Add(self.hook, self.identifier, self.func)
end

function TaskService:Stop()
	hook.Remove(self.hook, self.identifier)
end

function TaskService:AddPlayer(ply)
	self.running[ply] = true
end

function TaskService:Complete(ply)
	self.completions[ply] = true
	self.running[ply] = false
	hook.Call("Task_Complete", nil, ply, self.identifier)
end

function TaskService:IsRunningTask(ply)
	return self.running[ply]
end

function TaskService:HasCompleted(ply)
	return self.completions[ply]
end


task = TaskService.New()

task:Start()