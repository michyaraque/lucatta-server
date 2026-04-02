QuestChain = {
	storage = {
		ratStage = 410001,
		ratKills = 410002,
		beachCrab = 410101,
		osseousOmens = 410111,
		skeletonKey = 410121,
		skeletonCrypt = 410131,
		skeletonKing = 410132,
		frozenFrontier = 410141,
		skeletonCommander = 410151,
		necromancerHeart = 410161,
		cowHorn = 410171,
		nft = 410181,
		dragonWing = 410191,
		crystal = 410201,
		grimoireChamber = 410211,
		grimoire = 410212,
		spiderQueen = 410221,
		butcher = 410231,
		temple = 410241,
		azrael = 410242,
	},
	item = {
		skeletonKey = 94,
		necromancerHeart = 124,
		cowHorn = 137,
		nft = 273,
		dragonWing = 274,
		crystal = 285,
	},
}

function QuestChain.hasReached(player, storageId, value)
	return player:getStorageValue(storageId) >= value
end

function QuestChain.ensureValue(player, storageId, value)
	if player:getStorageValue(storageId) >= value then
		return false
	end

	player:setStorageValue(storageId, value)
	return true
end

function QuestChain.advanceExact(player, storageId, fromValue, toValue)
	if player:getStorageValue(storageId) ~= fromValue then
		return false
	end

	player:setStorageValue(storageId, toValue)
	return true
end

function QuestChain.startQuest(player, storageId, startValue, extraStorageId, extraValue)
	local started = QuestChain.ensureValue(player, storageId, startValue)
	if extraStorageId then
		QuestChain.ensureValue(player, extraStorageId, extraValue or startValue)
	end
	return started
end

function QuestChain.finishItemStep(player, storageId, itemId, consumeItem)
	if player:getStorageValue(storageId) ~= 0 or player:getItemCount(itemId) < 1 then
		return false
	end

	if consumeItem and not player:removeItem(itemId, 1) then
		return false
	end

	player:setStorageValue(storageId, 1)
	return true
end
