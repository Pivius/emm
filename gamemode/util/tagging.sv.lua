TaggingService.taggable_groups = TaggingService.taggable_groups or {}

function TaggingService.InitPlayerProperties(ply)
	ply.taggable = true
	ply.taggable_radius = 80
	ply.taggable_cooldown = 1
	ply.last_tag_time = 0
end
hook.Add("InitPlayerProperties", "TaggingService.InitPlayerProperties", TaggingService.InitPlayerProperties)

function TaggingService.InitPlayerClassProperties(ply_class)
	ply_class.can_tag = {}
end
hook.Add("InitPlayerClassProperties", "TaggingService.InitPlayerClassProperties", TaggingService.InitPlayerClassProperties)

function TaggingService.Tag(lobby, taggable, tagger)
	taggable.last_tag_time = CurTime()
	tagger.last_tag_time = CurTime()

	MinigameService.CallNetHook(taggable.lobby, "Tag", taggable, tagger)

	if taggable.player_class then
		if taggable.player_class.swap_on_tag then
			MinigameService.SwapPlayerClass(taggable, tagger, taggable.player_class.kill_on_tag, taggable.player_class.kill_tagger_on_tag)
		elseif taggable.player_class.recruit_on_tag then
			tagger:SetPlayerClass(taggable.player_class)
		else
			if taggable.player_class.player_class_on_tag then
				taggable:SetPlayerClass(lobby.player_classes[taggable.player_class.player_class_on_tag])
			end

			if taggable.player_class.give_player_class_on_tag then
				tagger:SetPlayerClass(lobby.player_classes[taggable.player_class.give_player_class_on_tag])
			end
		end
	end
end

function TaggingService.Think()
	for i = 1, #TaggingService.taggable_groups do
		for _i = 1, #TaggingService.taggable_groups[i] do
			local taggable = TaggingService.taggable_groups[i][_i]

			if IsValid(taggable) then
				local ents = ents.FindInSphere(GhostService.Entity(taggable):GetPos() + taggable:OBBCenter(), taggable.taggable_radius)

				if
					taggable.taggable and
					GhostService.Alive(taggable) and
					CurTime() > (taggable.last_tag_time + taggable.taggable_cooldown)
				then
					for __i = 1, #ents do
						local ent = ents[__i]

						if
							taggable ~= ent and
							ent:IsPlayer() and
							GhostService.Alive(ent) and
							MinigameService.IsSharingLobby(taggable, ent) and
							ent.player_class and
							taggable.player_class.can_tag[ent.player_class.key] and
							CurTime() > ((ent.last_tag_time or 0) + (ent.taggable_cooldown or 1))
						then
							TaggingService.Tag(taggable.lobby, taggable, ent)
						end
					end
				end
			end
		end
	end
end
hook.Add("Think", "TaggingService.Think", TaggingService.Think)

hook.Add("TriggerStartTouch", "TaggingService.Tag", function (a, b)
	TaggingService.Tag(a.lobby, a.owner_tag and a:GetOwner() or a, b)
end)

function TaggingService.InitLobby(lobby)
	for k, player_class in pairs(lobby.player_classes) do
		if player_class.can_tag then
			table.insert(TaggingService.taggable_groups, lobby[k])
		end
	end
end
hook.Add("LobbyCreate", "TaggingService.InitLobby", TaggingService.InitLobby)

function TaggingService.FinishLobby(lobby)
	for k, player_class in pairs(lobby.player_classes) do
		if player_class.can_tag then
			table.RemoveByValue(TaggingService.taggable_groups, lobby[k])
		end
	end
end
hook.Add("LobbyFinish", "TaggingService.FinishLobby", TaggingService.FinishLobby)