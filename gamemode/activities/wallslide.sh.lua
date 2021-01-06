ActivityService.NewActivity{
	key = "wallslide",
	name = "Wallslide",
	count = 0,
	time = 0,
}

ActivityService.NewActivity{
	key = "lag_slide",
	name = "LSD",
    count = 0
}


-- # Hooks

hook.Add("Wallslide", "Activity.Wallslide", function(ply, move, trace)
	if ply.last_wallslide_time == CurTime() then
		ActivityService.AddData(ply, "wallslide", {count = 1})
	end

	ActivityService.AddData(ply, "wallslide", {time = FrameTime()})

	if ply.old_velocity < move:GetVelocity() then
		ActivityService.AddData(ply, "lag_slide", {count = 1})
	end
end)