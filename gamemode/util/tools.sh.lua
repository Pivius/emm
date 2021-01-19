ToolService = ToolService or {}

ToolService.tools = {}


-- # Properties

function ToolService.InitPlayerProperties(ply)
	ply.can_pause = true
	ply.is_paused = false
	ply.pause_savepoint = {}
	ply.can_rewind = true
	ply.is_rewinding = false
	ply.rewind_tickrate = 0.25
	ply.rewind_ticks = 0
	ply.last_rewind = {}
	ply.rewind_data = {}
	ply.last_key_press = {
		pause = false,
		rewind = false,
		key = 0
	}
end
hook.Add(
	SERVER and "InitPlayerProperties" or "InitLocalPlayerProperties",
	"ToolService.InitPlayerProperties",
	ToolService.InitPlayerProperties
)


-- ¤ Enum

MAX_REWIND_SIZE = 528


-- # Utils
if CLIENT then
	last_key_press = TimeAssociatedMapService.CreateMap(1, function()
		return LocalPlayer().last_key_press
	end)

	function ToolService.PressedKey(ply, key)
		return key == last_key_press:Value().key
	end
else
	function ToolService.PressedKey(ply, key)
		return key == ply.last_key_press.key
	end
end


function ToolService.CanRewind(ply)
	return ply.can_rewind and not ply.is_paused and not ply.is_rewinding
end

function ToolService.Rewind(ply, move, cmd)
	if ply.can_rewind then
		if not ply.is_paused and not ply.is_rewinding then
			if IsFirstTimePredicted() then
				if ply.rewind_ticks ~= 0 then
					for i = #ply.rewind_data, #ply.rewind_data - ply.rewind_ticks + 1, -1 do
						table.remove(ply.rewind_data, i)
					end

					ply.rewind_ticks = 0
				end
				print(#ply.rewind_data)
				table.insert(ply.rewind_data, {
					position = move:GetOrigin(),
					velocity = move:GetVelocity(),
					angle = cmd:GetViewAngles(),
					health = ply:Health(),
					time = CurTime()
				})
				
				if #ply.rewind_data >= MAX_REWIND_SIZE then
					table.remove(ply.rewind_data, 1)
				end
			end
		elseif ply.is_rewinding then
			print(ply.rewind_ticks)
			local rewind_data = ply.rewind_data[#ply.rewind_data - ply.rewind_ticks] or ply.last_rewind

			move:SetOrigin(rewind_data.position)
			move:SetVelocity(rewind_data.velocity)
			ply:SetEyeAngles(rewind_data.angle)
			ply.pause_savepoint = rewind_data

			if #ply.rewind_data > 1 and IsFirstTimePredicted() then
				ply.rewind_ticks = ply.rewind_ticks + 1
				ply.last_rewind = rewind_data
				--table.remove(ply.rewind_data, #ply.rewind_data)
			end
		end
	end
end
hook.Add("SetupMove", "ToolService.Rewind", ToolService.Rewind)

function ToolService.Pause(ply, move, cmd)
	local last_key = ply.last_key_press

	if CLIENT then
		last_key =  last_key_press:Value()
	end

	if ply.can_pause then
		if (ply.is_paused and not ply.is_rewinding) then
			local savepoint = ply.pause_savepoint
			print(ply.pause_savepoint.position)
			move:SetOrigin(ply.pause_savepoint.position)
			move:SetVelocity(ply.pause_savepoint.velocity)
			ply:SetEyeAngles(ply.pause_savepoint.angle)
			ply:SetHealth(ply.pause_savepoint.health)
		end
	end
end
hook.Add("PlayerTick", "ToolService.Pause", ToolService.Pause)

function ToolService.Binds(ply, move, cmd)
	local last_key = ply.last_key_press

	if CLIENT then
		last_key =  last_key_press:Value()
	end
	
	local rewind_key = ToolService.PressedKey(ply, 79) and ply.can_rewind
	local pause_key = ToolService.PressedKey(ply, 83) and ply.can_pause
	print(ply.is_rewinding)
	
	if rewind_key then
		ply.is_rewinding = !last_key.rewind
	elseif pause_key then
		ply.pause_savepoint = last_key.savepoint
		ply.is_paused = !last_key.pause
	end
end
hook.Add("SetupMove", "ToolService.Binds", ToolService.Binds)

function ToolService.KeyDown(ply, key)
	local paused = ply.is_paused
	local rewind = ply.is_rewinding
	local savepoint = {
		position = ply:GetPos(),
		velocity = ply:GetVelocity(),
		angle = ply:EyeAngles(),
		health = ply:Health()
	}
	
	if not IsFirstTimePredicted() and paused ~= last_key_press:Value().pause then
		paused = !paused
		savepoint = last_key_press:Value().savepoint
	end

	if not IsFirstTimePredicted() and rewind ~= last_key_press:Value().rewind then
		rewind = !rewind
	end
	
	ply.last_key_press = {
		pause = paused,
		rewind = rewind,
		key = key,
		savepoint = savepoint
	}
end
hook.Add( "PlayerButtonUp", "ToolService.KeyDown", ToolService.KeyDown)
