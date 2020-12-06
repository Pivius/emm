TaskService = TaskService or Class.New()


-- Utils

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

		table.insert(var_args, 2, self)

		if not IsEntity(ply) then
			self:Stop()
		else
			if not self:HasCompleted(ply) and self:IsRunningTask(ply) and func(unpack(var_args)) then
				self:Complete(ply)
			end
		end
	end
	
	self:Start()
end

function TaskService:Start()
	hook.Add(self.hook, self.identifier, self.func)
end

function TaskService:Stop()
	hook.Remove(self.hook, self.identifier)
end

function TaskService:AddPlayer(data)
	self.running[data.player] = data
end

function TaskService:RemovePlayer(ply)
	self.running[ply] = false
end

function TaskService:Complete(ply)
	self.completions[ply] = self.running[ply]
	self.running[ply] = false
	hook.Call("Task_Complete", GAMEMODE, ply, self.identifier)
end

function TaskService:Clear()
	self.completions = {}
	self.running = {}
end

function TaskService:IsRunningTask(ply)
	return self.running[ply]
end

function TaskService:HasCompleted(ply)
	return self.completions[ply] ~= false
end