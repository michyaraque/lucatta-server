local creative = TalkAction("/creative", "!creative")

local storagePreviousGroup = 910000
local playerGroupId = 1
local fallbackGroupId = 6

local function setPlayerGroupById(player, groupId)
	local group = Group(groupId)
	if not group then
		return false
	end

	player:setGroup(group)
	return true
end

local function enableCreative(player)
	local previousGroupId = player:getStorageValue(storagePreviousGroup)
	if previousGroupId <= playerGroupId then
		previousGroupId = fallbackGroupId
	end

	if not setPlayerGroupById(player, previousGroupId) then
		return false, "Could not restore the access group."
	end

	player:setStorageValue(storagePreviousGroup, -1)
	return true, "Creative mode enabled."
end

local function disableCreative(player)
	local currentGroupId = player:getGroup():getId()
	if currentGroupId ~= playerGroupId then
		player:setStorageValue(storagePreviousGroup, currentGroupId)
	end

	if not setPlayerGroupById(player, playerGroupId) then
		return false, "Could not switch to the player group."
	end

	if player:isInGhostMode() then
		player:setGhostMode(false, CONST_ME_NONE)
	end

	return true, "Creative mode disabled."
end

function creative.onSay(player, words, param)
	if player:getAccountType() < ACCOUNT_TYPE_GOD then
		return true
	end

	local action = param:trim():lower()
	if action == "" then
		action = player:getGroup():getAccess() and "off" or "on"
	end

	local ok, message
	if action == "off" or action == "disable" or action == "0" then
		ok, message = disableCreative(player)
	elseif action == "on" or action == "enable" or action == "1" then
		ok, message = enableCreative(player)
	else
		player:sendCancelMessage("Use /creative on or /creative off.")
		return false
	end

	if not ok then
		player:sendCancelMessage(message)
		return false
	end

	player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, message)
	return false
end

creative:separator(" ")
creative:accountType(ACCOUNT_TYPE_GOD)
creative:register()
