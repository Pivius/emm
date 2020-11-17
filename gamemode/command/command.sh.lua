CommandService = CommandService or {}
CommandService.Commands = {}


-- # Object Types

CommandService.object_types = {
	bool = tobool,
	string = tostring,
	number = tonumber,
	table = function(tbl) return CommandService.ToType("table", "string.Explode(',', '" .. tbl .. "')") end,
	vector = function(vector) return CommandService.ToType("vector", "Vector(unpack(string.Explode(',', '" .. vector .. "')))") end,
	angle = function(ang) return CommandService.ToType("angle", "Angle(unpack(string.Explode(',', '" .. ang .. "')))") end,
	player = function(ply)
		return CommandService.FindTarget(ply)[1]
	end,

}


-- # Symbols

COMMAND_PREFIX = 1
COMMAND_SELF = 2
COMMAND_ALL = 3

CommandService.Symbols = {
	"!/",
	"^",
	"*"
}


-- # Utils

function CommandService.FindTarget(target)
	local tbl = {}

	for _, ply in pairs(player.GetAll()) do
		if string.lower(ply:Nick()):find(target:lower()) then
			table.insert(tbl, ply)
		end
	end
	
	if #tbl > 0 then
		return tbl
	else
		return nil
	end
end

function CommandService.FindCommand(str)
	local tbl = {}

	str = str:lower()

	for name, cmd in pairs(CommandService.Commands) do
		if name:find(str) then
			if table.HasValue(cmd.cmds, str) then
				return cmd
			end
		end
	end
	
	return nil
end

function CommandService.ExecuteCommand(cmd, sender, ...)
	cmd = CommandService.FindCommand(cmd)

	if cmd then
		cmd:Execute(sender, ...)
	end
end


function CommandService.AutoComplete(cmd, args)
	local auto_complete = {}
	local con_cmd = cmd .. " "

	cmd = CommandService.Commands[cmd:sub(5)]

	if istable(cmd) then
		args = args:sub(2):Split(" ")
		
		if cmd.args[#args] == "player" then
			for _, ply in pairs(player.GetAll()) do
				if string.lower(" " .. ply:Nick()):find(args[#args]:lower()) then
					table.insert(auto_complete, con_cmd .. ply:Nick())
				end
			end

			return auto_complete
		elseif cmd.args[#args] == "number" then
			auto_complete = {con_cmd .. args[#args]}

			if isnumber(cmd.args[#args + 1]) then
				auto_complete = {con_cmd .. "[".. cmd.args[#args + 1] .. "]"}

				if isnumber(cmd.args[#args + 2]) then
					auto_complete = {con_cmd .. "[".. cmd.args[#args + 1] .. " - " .. cmd.args[#args + 2] .. "]"}
				end
			end

			return auto_complete
		end
	end
end

function CommandService.ToType(type, arg)
	local type_pass, arg = CompileString("return is" .. type .. "(" .. arg .. "), " .. arg, "CommandService.TypeCheck")()

	if type_pass then
		return arg
	else
		return nil
	end
end

function CommandService.AddCommand(...)
	local args = {...}
	local cmd = Command.New()

	cmd:SetCommand(table.remove(args, 1))
	cmd:SetFunction(unpack(args))
	CommandService.CreateConCommand(cmd)
	CommandService.Commands[cmd.name] = cmd
end
