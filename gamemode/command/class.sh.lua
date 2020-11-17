Command = Command or Class.New()

function Command:Init()
	self.name = ""
	self.cmds = {}
	self.args = {}
	self.flags = {}
	self.func = function(target, target) end
end

function Command:Remove(flag)
	self.flags[flag] = false
end

function Command:AddFlag(flag)
	self.flags[flag] = true
end

function Command:GetFlag(flag)
	return self.flags[flag]
end

function Command:SetCommand(...)
	self.cmds = table.concat({...}, " "):lower():Split(" ")
	self.name = self.cmds[1]

	for _, cmd in ipairs(CommandService.Commands) do
		if cmd.name:sub(1, 1) ~= self.name:sub(1, 1) then
			continue
		end

		return
	end

	table.insert(self.cmds, self.name:sub(1, 1))
end

function Command:SetFunction(...)
	local func

	self.args = {...}
	func = table.remove(self.args)
	self.func = function(...)
		local args = self.args
		local command_args = {...}
		local sender = table.remove(command_args, 1)
		
		if #command_args > 0 then
			for i = 1, #args do
				if isnumber(args[i]) and isnumber(command_args[i - 1]) then
					if isnumber(args[i + 1]) then
						command_args[i - 1] = math.min(command_args[i - 1], args[i + 1])
						table.remove(command_args, i + 1)
					end

					command_args[i - 1] = math.max(command_args[i - 1], args[i])
					table.remove(command_args, i)
					continue
				end

				if command_args[i] then
					command_args[i] = CommandService.object_types[args[i]](command_args[i])
				end
			end

			func(sender, unpack(command_args))
		else
			func(sender)
		end
	end 
end

function Command:Execute(sender, ...)
	sender = (sender != NULL and sender or "server")
	hook.Call("OnCommand", nil, sender, self, {...})
	self.func(sender, ...)
end