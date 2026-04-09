local event = CreatureEvent("WorldTimeAndLight")

function event.onLogin(player)
	local worldTime = Game.getWorldTime()
	player:sendWorldTime(worldTime)

	local worldLightLevel, worldLightColor = Game.getWorldLight()
	player:sendWorldLight(worldLightColor, worldLightLevel)
	return true
end

event:register()
