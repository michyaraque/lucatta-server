local event = GlobalEvent("WorldLight")

local lightConfig = {
	day = 250,
	night = 40
}

local worldConfig = {
	sunrise = 360, -- 6:00 AM - empieza a amanecer
	dayTime = 480, -- 8:00 AM - sol completamente arriba
	sunset = 1080, -- 6:00 PM - empieza a atardecer
	nightTime = 1200 -- 8:00 PM - noche completa
}

local lightChange = {
	sunrise = (lightConfig.day - lightConfig.night) / (worldConfig.dayTime - worldConfig.sunrise),
	sunset = (lightConfig.day - lightConfig.night) / (worldConfig.nightTime - worldConfig.sunset)
}

do
	local defaultColor = 215
	local defaultLevel = lightConfig.day
	Game.setWorldLight(defaultColor, defaultLevel)
end

local function calculateWorldLightLevel()
	local worldTime = Game.getWorldTime()
	local level

	if worldTime >= worldConfig.sunrise and worldTime < worldConfig.dayTime then
		level = lightConfig.night + (worldTime - worldConfig.sunrise) * lightChange.sunrise
	elseif worldTime >= worldConfig.dayTime and worldTime < worldConfig.sunset then
		level = lightConfig.day
	elseif worldTime >= worldConfig.sunset and worldTime < worldConfig.nightTime then
		level = lightConfig.day - (worldTime - worldConfig.sunset) * lightChange.sunset
	else
		level = lightConfig.night
	end

	return math.max(lightConfig.night, math.min(lightConfig.day, math.floor(level + 0.5)))
end

function event.onTime(interval)
	local worldLightLevel, worldLightColor = Game.getWorldLight()
	local level = calculateWorldLightLevel()
	Game.setWorldLight(worldLightColor, level)
	return true
end

event:interval(5000)
event:register()
