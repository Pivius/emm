MINIGAME.name = "Cloud"
MINIGAME.color = COLOR_ROYAL
MINIGAME.default_player_class = "Tagger"

MINIGAME.random_player_classes = {
	class_key = "Cloud",
	rejected_class_key = "Tagger"
}

hook.Add("CreateMinigameHookSchemas", "Cloud", function ()
	MinigameNetService.CreateHookSchema("SetCloud", {"entity"})
end)

if SERVER then
	MINIGAME:AddHook("StartStateStarting", "ClearEntities", MinigameService.ClearEntities)
else
	MINIGAME:AddHookNotification("SetCloud", function (self, involves_local_ply, cloud)
		if involves_local_ply then
			NotificationService.PushText "you set cloud"
		else
			NotificationService.PushAvatarText(cloud, "set cloud")
		end
	end)
end

MINIGAME:AddPlayerClass({
	name = "Cloud",
	color = COLOR_CLOUD,
	tag_victim = true,
	swap_on_tag = true
}, {
	cloud_set = false,
	swap_closest_on_death = true
})

MINIGAME:AddPlayerClass {
	name = "Tagger"
}

if SERVER then
	function MINIGAME:SetCloud(ply)
		ply.cloud_trigger = TriggerService.CreateTrigger(self, {
			owner = ply,
			position = ply:GetPos(),
			width = 512,
			can_tag = {Tagger = true},
			indicator_name = "cloud",
			indicator_icon = "emm2/minigames/cloud.png"
		})

		self.cloud_trigger = ply.cloud_trigger

		local dynamic_ply_class = ply.dynamic_player_class
		dynamic_ply_class.cloud_set = true
		dynamic_ply_class.swap_closest_on_death = false

		MinigameService.CallNetHookWithoutMethod(self, "SetCloud", ply)
	end

	function MINIGAME:Tag(taggable, tagger)
		taggable.cloud_trigger:Remove()
	end

	function MINIGAME.player_classes.Cloud:SetupMove(move)
		if IsFirstTimePredicted() and not self.cloud_set and self:Alive() and move:KeyPressed(IN_ATTACK) then
			self.lobby:SetCloud(self)
		end
	end
end