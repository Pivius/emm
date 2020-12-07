TaskService = TaskService or Class.New()


-- # Utils

function TaskService:Init()
	self.players = {}
	self:Hook("Move", "Jump", function(ply, move)
		if move:KeyPressed(IN_JUMP) then
			return true
		end
	end)
end

function TaskService:Hook(hook, identifier, func)
	self.hook = hook
	self.identifier = "TaskService." .. identifier
	self.func = function(...)
		local var_args = {...}
		local ply = var_args[1]

		table.insert(var_args, 2, self)
		table.insert(var_args, 3, self.players[ply])

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
	data.completed = false
	self.players[data.player] = data
end

function TaskService:RemovePlayer(ply)
	self.players[ply] = false
end

function TaskService:Complete(ply)
	self.players[ply].completed = true
	hook.Call("Task_Complete", GAMEMODE, ply, self)
end

function TaskService:Clear()
	self.players = {}
end

function TaskService:IsRunningTask(ply)
	return not Falsy(self.players[ply])
end

function TaskService:HasCompleted(ply)
	return self.players[ply].completed
end