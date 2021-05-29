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
	if move:KeyPressed(IN_ATTACK2) and IsFirstTimePredicted() then
		ActivityService.AddData(ply, "wallslide", {count = 1})
		ActivityService.Run(ply, "wallslide")
	end
end)