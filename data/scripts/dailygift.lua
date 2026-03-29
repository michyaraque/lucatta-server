local DailyGift = {
	OPCODE = 150,
	STORAGE_DAY = 419120,
	STORAGE_TIME_LEFT = 419122,
	DAYS_AFTER_PRIZE = 22,
	DAY_SECONDS = 24 * 60 * 60,

	-- Configuration matching client
	REWARDS = {
		[1] = { itemId = 7759, count = 1 },
		[2] = { itemId = 7618, count = 20 },
		[3] = { itemId = 7759, count = 5, needvip = true },
		[4] = { itemId = 14324, count = 2 },
	},

	AFTER_PRIZE = { itemId = 8150, count = 1 } -- Golden Dimensional Key
}

function DailyGift.getUnixTimestampLeft(lastClaimTime)
	-- Calculate time until next midnight
	local nextMidnight = (math.floor(os.time() / DailyGift.DAY_SECONDS) + 1) * DailyGift.DAY_SECONDS
	return nextMidnight - os.time()
end

function DailyGift.sendJSON(player, data)
	player:sendExtendedOpcode(DailyGift.OPCODE, json.encode(data))
end

-- Define Extended Opcode Event
local opcodeEvent = CreatureEvent("DailyGiftOpcode")

function opcodeEvent.onExtendedOpcode(player, opcode, buffer)
	if opcode ~= DailyGift.OPCODE then
		return
	end

	local status, data = pcall(json.decode, buffer)
	if not status or not data then
		return
	end

	local accountId = player:getAccountId()

	if data.action == "get_config" then
		local clientRewards = {}
		for i, reward in ipairs(DailyGift.REWARDS) do
			local it = ItemType(reward.itemId)
			local cid = it and it:getClientId() or reward.itemId
			clientRewards[i] = {
				name = it and reward.name or it:getName(),
				itemId = cid,
				count = reward.count,
				needvip = reward.needvip
			}
		end

		local afterPrizeIt = ItemType(DailyGift.AFTER_PRIZE.itemId)
		local afterPrizeCid = afterPrizeIt and afterPrizeIt:getClientId() or DailyGift.AFTER_PRIZE.itemId

		DailyGift.sendJSON(player, {
			action = "config",
			rewards = clientRewards,
			afterPrize = {
				itemId = afterPrizeCid,
				count = DailyGift.AFTER_PRIZE.count
			}
		})

	elseif data.action == "claim" then
		local dayIndex = tonumber(data.day)
		if dayIndex then
			local storedDay = player:getAccountStorageValue(DailyGift.STORAGE_DAY)
			local lastClaimTime = player:getAccountStorageValue(DailyGift.STORAGE_TIME_LEFT)

			-- Calculate logic explicitly to verify claim validity
			local currentDayId = math.floor(os.time() / DailyGift.DAY_SECONDS)
			local lastClaimDayId = math.floor(lastClaimTime / DailyGift.DAY_SECONDS)
			local dayDiff = currentDayId - lastClaimDayId

			-- Handle first time claim
			if lastClaimTime == -1 then dayDiff = 999 end

			if dayDiff < 1 then
				-- Already claimed today or invalid time
				return
			end

			-- Determine actual reward index based on streak
			local actualRewardDay = storedDay
			if dayDiff > 1 then
				-- Streak broken, reset to Day 1
				actualRewardDay = 1
			end

			local validClaim = false
			if actualRewardDay < DailyGift.DAYS_AFTER_PRIZE and DailyGift.REWARDS[actualRewardDay] then
				local reward = DailyGift.REWARDS[actualRewardDay]
				player:addItem(reward.itemId, reward.count)
				validClaim = true
			elseif actualRewardDay >= DailyGift.DAYS_AFTER_PRIZE then
				player:addItem(DailyGift.AFTER_PRIZE.itemId, DailyGift.AFTER_PRIZE.count)
				validClaim = true
			end

			if validClaim then
				-- Update storage on successful claim
				player:setAccountStorageValue(DailyGift.STORAGE_DAY, actualRewardDay + 1)
				player:setAccountStorageValue(DailyGift.STORAGE_TIME_LEFT, os.time())

				player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
				player:getPosition():sendMagicEffect(169)

				DailyGift.sendJSON(player, {
					action = "timer",
					timeLeft = DailyGift.getUnixTimestampLeft(os.time())
				})
			end
		end

	elseif data.action == "time_left" then
		DailyGift.sendJSON(player, {
			action = "timer",
			timeLeft = DailyGift.getUnixTimestampLeft(player:getAccountStorageValue(DailyGift.STORAGE_TIME_LEFT))
		})

	elseif data.action == "start_daily" then
		local lastClaimTime = player:getAccountStorageValue(DailyGift.STORAGE_TIME_LEFT)
		local nextRewardDay = player:getAccountStorageValue(DailyGift.STORAGE_DAY)

		local canClaim = 0
		local currentDayId = math.floor(os.time() / DailyGift.DAY_SECONDS)
		local lastClaimDayId = math.floor(lastClaimTime / DailyGift.DAY_SECONDS)
		local dayDiff = currentDayId - lastClaimDayId

		if lastClaimTime == -1 then dayDiff = 999 end

		if dayDiff >= 1 then
			canClaim = 1
			if dayDiff > 1 then
				-- Streak broken preview
				nextRewardDay = 1
			end
		end

		DailyGift.sendJSON(player, {
			action = "data",
			day = nextRewardDay,
			canClaim = canClaim,
			timeLeft = DailyGift.getUnixTimestampLeft(lastClaimTime)
		})
	end
end

opcodeEvent:type("extendedopcode")
opcodeEvent:register()

-- Define Login Event to register the opcode
local loginEvent = CreatureEvent("DailyGiftLogin")

function loginEvent.onLogin(player)
	player:registerEvent("DailyGiftOpcode")

	-- Initialize storage for first-time players
	if player:getAccountStorageValue(DailyGift.STORAGE_DAY) == -1 or player:getAccountStorageValue(DailyGift.STORAGE_DAY) == nil then
		player:setAccountStorageValue(DailyGift.STORAGE_DAY, 1)
		player:setAccountStorageValue(DailyGift.STORAGE_TIME_LEFT, -1)
	end

	-- Check if claim is available to auto-open
	local lastClaimTime = player:getAccountStorageValue(DailyGift.STORAGE_TIME_LEFT)
	if lastClaimTime == nil or lastClaimTime == -1 then
		-- First time player, show daily gift window
		DailyGift.sendJSON(player, { action = "start" })
		return true
	end

	local currentDayId = math.floor(os.time() / DailyGift.DAY_SECONDS)
	local lastClaimDayId = math.floor(lastClaimTime / DailyGift.DAY_SECONDS)
	local dayDiff = currentDayId - lastClaimDayId

	if dayDiff >= 1 then
		DailyGift.sendJSON(player, { action = "start" })
	end

	return true
end

loginEvent:type("login")
loginEvent:register()
