-- Talkaction to change the world time (affects day/night cycle and light)
-- Usage: /worldtime [time_in_minutes | HH:MM]
-- Example: /worldtime 480 (8:00 AM - full daylight)
-- Example: /worldtime 12:00 (noon)
-- Example: /worldtime 0:00 (midnight)
--
-- Time Reference (in minutes):
-- 0 = 00:00 (midnight)
-- 360 = 06:00 (sunrise starts)
-- 480 = 08:00 (full day)
-- 1080 = 18:00 (sunset starts)
-- 1200 = 20:00 (full night)

local talk = TalkAction("/worldtime", "/wt")

function talk.onSay(player, words, param)
	if not player:getGroup():getAccess() then
		player:sendTextMessage(MESSAGE_STATUS_SMALL, "You cannot execute this command.")
		return false
	end

	if param == "" then
		-- Show current world time
		local currentTime = getWorldTime()
		local hours = math.floor(currentTime / 60)
		local minutes = currentTime % 60
		local level, color = getWorldLight()

		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, string.format("Current world time: %02d:%02d (%d minutes)", hours, minutes, currentTime))
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, string.format("Current light level: %d, color: %d", level, color))
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Usage: /worldtime [minutes] or /worldtime HH:MM")
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Examples: /worldtime 480 (8AM) | /worldtime 12:00 (noon) | /worldtime 0:00 (midnight)")
		return false
	end

	local newTime

	-- Check if format is HH:MM
	local hours, minutes = param:match("^(%d+):(%d+)$")
	if hours and minutes then
		hours = tonumber(hours)
		minutes = tonumber(minutes)
		if hours >= 0 and hours <= 23 and minutes >= 0 and minutes <= 59 then
			newTime = (hours * 60) + minutes
		else
			player:sendTextMessage(MESSAGE_STATUS_SMALL, "Invalid time format. Hours: 0-23, Minutes: 0-59")
			return false
		end
	else
		-- Try to parse as minutes
		newTime = tonumber(param)
		if not newTime then
			player:sendTextMessage(MESSAGE_STATUS_SMALL, "Invalid time. Use minutes (0-1439) or HH:MM format")
			return false
		end
	end

	-- Clamp to valid range
	newTime = math.max(0, math.min(1439, newTime))

	-- Set the world time (this automatically updates light)
	Game.setWorldTime(newTime)

	local displayHours = math.floor(newTime / 60)
	local displayMinutes = newTime % 60
	local level, color = Game.getWorldLight()

	local timeOfDay = "unknown"
	if newTime >= 0 and newTime < 360 then
		timeOfDay = "night"
	elseif newTime >= 360 and newTime < 480 then
		timeOfDay = "sunrise"
	elseif newTime >= 480 and newTime < 1080 then
		timeOfDay = "day"
	elseif newTime >= 1080 and newTime < 1200 then
		timeOfDay = "sunset"
	else
		timeOfDay = "night"
	end

	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, string.format("World time set to: %02d:%02d (%s)", displayHours, displayMinutes, timeOfDay))
	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, string.format("Light updated to: Level = %d, Color = %d", level, color))
	print(string.format("[WorldTime] %s changed world time to %02d:%02d (%d min, %s)",
		player:getName(), displayHours, displayMinutes, newTime, timeOfDay))

	return false
end

talk:separator(" ")
talk:register()
