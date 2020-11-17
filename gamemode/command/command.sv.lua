function CommandService.CreateConCommand(cmd)
	concommand.Add("net_emm_".. cmd.name, function(sender, _, args)
		cmd:Execute(sender, unpack(args))
	end)
end