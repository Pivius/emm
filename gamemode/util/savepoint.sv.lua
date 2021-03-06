SavepointService = SavepointService or {}


-- # Properties

function SavepointService.InitPlayerProperties(ply)
	ply.can_savepoint = false
end
hook.Add(
	SERVER and "InitPlayerProperties" or "InitLocalPlayerProperties",
	"SavepointService.InitPlayerProperties",
	SavepointService.InitPlayerProperties
)


-- # Saving/loading

function SavepointService.CreateSavepoint(ply)
	local savepoint = {}
	savepoint.position = ply:GetPos()
	savepoint.velocity = ply:GetVelocity()
	savepoint.angle = ply:EyeAngles()

	return savepoint
end

function SavepointService.LoadSavepoint(ply, savepoint)
	ply:SetPos(savepoint.position)
	ply:SetVelocity(-ply:GetVelocity() + savepoint.velocity)
	ply:SetEyeAngles(savepoint.angle)
end

function SavepointService.RequestSavepoint(ply, cmd, args)
	if ply.can_savepoint then
		ply:ChatPrint("Savepoint created!")
		ply.savepoint = SavepointService.CreateSavepoint(ply)
	end
end
concommand.Add("emm_savepoint", SavepointService.RequestSavepoint)

function SavepointService.RequestLoadSavepoint(ply, cmd, args)
	if ply.can_savepoint and ply.savepoint then
		ply:ChatPrint("Savepoint loaded!")
		SavepointService.LoadSavepoint(ply, ply.savepoint)
	end
end
concommand.Add("emm_load_savepoint", SavepointService.RequestLoadSavepoint)