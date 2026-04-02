local function getKillersForQuest(monster)
	local killers = {}

	for _, killer in pairs(monster:getKillers(true)) do
		local party = killer:getParty()
		if party then
			for _, member in pairs({ party:getLeader(), unpack(party:getMembers()) }) do
				if party:isMemberSharingExp(member) then
					killers[member:getId()] = member
				end
			end
		else
			killers[killer:getId()] = killer
		end
	end

	return killers
end

local killTargets = {
	["Rat"] = {
		storageId = 410002,
		mode = "increment",
		from = 0,
		to = 20,
	},
	["Crab"] = {
		storageId = 410101,
		mode = "increment",
		from = 0,
		to = 12,
	},
	["Skeleton King"] = {
		storageId = 410132,
		mode = "set",
		from = 0,
		to = 1,
	},
	["Skeleton Commander"] = {
		storageId = 410151,
		mode = "set",
		from = 0,
		to = 1,
	},
	["Spider Queen"] = {
		storageId = 410221,
		mode = "set",
		from = 0,
		to = 1,
	},
	["Gorefiend the Butcher"] = {
		storageId = 410231,
		mode = "set",
		from = 0,
		to = 1,
	},
	["Azrael"] = {
		storageId = 410242,
		mode = "set",
		from = 0,
		to = 1,
	},
}

local function advanceKill(player, targetConfig)
	local value = player:getStorageValue(targetConfig.storageId)
	if value < targetConfig.from then
		return
	end

	if targetConfig.mode == "increment" then
		if value < targetConfig.to then
			player:setStorageValue(targetConfig.storageId, value + 1)
		end
		return
	end

	if value == targetConfig.from then
		player:setStorageValue(targetConfig.storageId, targetConfig.to)
	end
end

local killEvent = CreatureEvent("StoryCampaignKills")

function killEvent.onKill(player, target)
	local monster = target:getMonster()
	if not monster or monster:getMaster() then
		return true
	end

	local targetConfig = killTargets[monster:getName()]
	if not targetConfig then
		return true
	end

	for _, killer in pairs(getKillersForQuest(monster)) do
		advanceKill(killer, targetConfig)
	end

	return true
end

killEvent:register()

local loginEvent = CreatureEvent("StoryCampaignLogin")

function loginEvent.onLogin(player)
	player:registerEvent("StoryCampaignKills")
	return true
end

loginEvent:type("login")
loginEvent:register()
