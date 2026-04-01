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

-- Sin truncamiento para precisión completa en las transiciones
local lightChange = {
	sunrise = (lightConfig.day - lightConfig.night) / (worldConfig.dayTime - worldConfig.sunrise),
	sunset = (lightConfig.day - lightConfig.night) / (worldConfig.nightTime - worldConfig.sunset)
}

do
	-- load default values
	local defaultColor = 215
	local defaultLevel = lightConfig.day
	Game.setWorldLight(defaultColor, defaultLevel)
end

local function calculateWorldLightLevel()
	local worldTime = Game.getWorldTime()
	local level

	if worldTime >= worldConfig.sunrise and worldTime < worldConfig.dayTime then
		-- Amanecer: interpolación gradual de noche → día
		level = lightConfig.night + (worldTime - worldConfig.sunrise) * lightChange.sunrise
	elseif worldTime >= worldConfig.dayTime and worldTime < worldConfig.sunset then
		-- Día completo
		level = lightConfig.day
	elseif worldTime >= worldConfig.sunset and worldTime < worldConfig.nightTime then
		-- Atardecer: interpolación gradual de día → noche
		level = lightConfig.day - (worldTime - worldConfig.sunset) * lightChange.sunset
	else
		-- Noche completa (después de nightTime o antes de sunrise)
		level = lightConfig.night
	end

	-- Clamping y redondeo para evitar valores fuera de rango
	return math.max(lightConfig.night, math.min(lightConfig.day, math.floor(level + 0.5)))
end

function event.onTime(interval)
	local worldLightLevel, worldLightColor = Game.getWorldLight()
	local level = calculateWorldLightLevel()
	Game.setWorldLight(worldLightColor, level)
	return true
end

event:interval(5000) -- 5 segundos - balance entre suavidad y rendimiento
event:register()
