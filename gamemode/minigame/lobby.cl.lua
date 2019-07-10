function MinigameService.CreateLobby(props)
	local lobby = MinigameLobby.New(props)
	MinigameService.lobbies[lobby.id] = lobby

	return lobby
end

function MinigameService.FinishLobby(lobby)
	MinigameService.lobbies[lobby.id] = nil
	lobby:Finish()
end

function MinigameService.LobbyText(lobby)
	local host = lobby.host

	return (IsLocalPlayer(host) and "your" or host:GetName().."'s").." "..lobby.prototype.name.." lobby"
end

function MinigameService.PushLobbyMetaText(lobby)
	NotificationService.PushMetaText(MinigameService.LobbyText(lobby), "Lobby", 1)
end

function MinigameService.InitHUDElements()
	local lobby = LocalPlayer().lobby

	if lobby then
		MinigameService.PushLobbyMetaText(lobby)
	end
end
hook.Add("InitHUDElements", "MinigameService.InitHUDElements", MinigameService.InitHUDElements)

function MinigameLobby:Init(props)
	self.id = props.id
	self.prototype = props.prototype
	self.state = props.state
	self.last_state_start = props.last_state_start
	self.host = props.host
	self.players = props.players or {}
	self.ents = props.ents or {}

	for _, ply in pairs(self.players) do
		ply.lobby = self
	end

	for k, _ in pairs(self.prototype.player_classes) do
		self[k] = self[k] or {}
	end

	self:InitSettings()

	hook.Run("LobbyInit", self)

	if self:IsLocal() then
		hook.Run("LocalLobbyInit", self)

		if IsLocalPlayer(self.host) then
			MinigameService.PushLobbyMetaText(self)
		end
	end
end

function MinigameLobby:Finish()
	hook.Run("LobbyFinish", self)

	for _, ent in pairs(self.ents) do
		ent:Finish()
	end
	
	if self:IsLocal() then
		hook.Run("LocalLobbyFinish", self)
	end

	for _, ply in pairs(self.players) do
		self:RemovePlayer(ply, false)
	end

	table.Empty(self)
end

function MinigameLobby:GetSanitized()
	local sanitized_lobby = {}
	sanitized_lobby.id = self.id
	sanitized_lobby.prototype = self.prototype.id
	sanitized_lobby.host = self.host:EntIndex()
	sanitized_lobby.players = {}

	for k, ply in pairs(self.players) do
		sanitized_lobby.players[k] = ply:EntIndex()
	end

	return sanitized_lobby
end

function MinigameLobby:IsLocal()
	return self == LocalPlayer().lobby
end

function MinigameLobby:SetHost(ply)
	self.host = ply
	hook.Run("LobbyHostChange", self, ply)

	if self:IsLocal() then
		hook.Run("LocalLobbyHostChange", self, ply)
		MinigameService.PushLobbyMetaText(self)
	end
end

function MinigameLobby:AddPlayer(ply)
	ply.lobby = self
	table.insert(self.players, ply)

	hook.Run("LobbyPlayerJoin", self, ply)

	if self:IsLocal() then
		hook.Run("LocalLobbyPlayerJoin", self, ply)

		if IsLocalPlayer(ply) then
			MinigameService.PushLobbyMetaText(self)
		end
	end

	MinigameService.CallHook(self, "PlayerJoin", ply)
end

function MinigameLobby:RemovePlayer(ply)
	if IsValid(ply) then
		hook.Run("LobbyPlayerLeave", self, ply)

		if self:IsLocal() then
			hook.Run("LocalLobbyPlayerLeave", self, ply)

			if IsLocalPlayer(ply) then
				NotificationService.FinishSticky "Lobby"
			end
		end

		MinigameService.CallHook(self, "PlayerLeave", ply)

		ply.lobby = nil
		table.RemoveByValue(self.players, ply)
	end
end

hook.Add("PlayerDisconnected", "MinigameService.RemoveDisconnectedPlayer", function (ply)
	if IsValid(ply) and ply.lobby then
		ply.lobby:RemovePlayer(ply)
	else
		for _, lobby in pairs(MinigameService.lobbies) do
			local invalid_plys = {}

			for _, ply in pairs(lobby.players) do
				if not IsValid(ply) then
					table.insert(invalid_plys, ply)
				end
			end

			for _, ply in pairs(invalid_plys) do
				table.RemoveByValue(lobby.players, ply)
			end
		end
	end
end)