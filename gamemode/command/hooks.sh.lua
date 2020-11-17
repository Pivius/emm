function CommandService.ChatCommand(ply, text)
	if CommandService.Symbols[COMMAND_PREFIX]:find(text:sub(1, 1)) then
		local args = text:sub(2):Split(" ")
		local cmd = CommandService.FindCommand(table.remove(args, 1))

		if cmd then
			cmd:Execute(ply, unpack(args))
			return true
		end
	end
end
hook.Add(
	"OnChat",
	"CommandService.ChatCommand",
	CommandService.ChatCommand
)

hook.Add("OnCommand", "CommandService.OnCommand", function(ply, cmd, args)
end)