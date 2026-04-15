local dropEvent = Event()
local pickupEvent = MoveEvent()
local movedEvent = Event()

local LOOT_BAG_ITEM_ID = 37
local LOOT_BAG_ACTION_ID = 47001
local LOOT_BAG_DURATION_MS = 60 * 1000
local LOOT_BAG_EFFECT_ID = 146
local LOOT_BAG_EFFECT_INTERVAL_MS = 1250
local LOOT_BAG_TOKEN_KEY = "loot_bag_token"
local LOOT_BAG_HIGHLIGHT_KEY = "loot_bag_highlight"
local LOOT_BAG_EFFECT_STARTED_KEY = "loot_bag_effect_started"
local LOOT_BAG_INTERNAL_KEY = "loot_bag_internal"
local LOOT_PICKUP_OPCODE = 151

local lootBagTokenCounter = 0

if not Item.setTimedDecay then
	function Item.setTimedDecay(self, durationMs, decayTo)
		if not self or durationMs <= 0 then
			return false
		end

		self:setAttribute(ITEM_ATTRIBUTE_DECAYTO, decayTo or 0)
		self:setAttribute(ITEM_ATTRIBUTE_DURATION, durationMs)
		self:decay()
		return true
	end
end

local function clonePosition(position)
	return Position(position.x, position.y, position.z)
end

local function nextLootBagToken()
	lootBagTokenCounter = lootBagTokenCounter + 1
	return ("loot_bag_%d"):format(lootBagTokenCounter)
end

local function getTileItems(position)
	local tile = Tile(position)
	return tile and tile:getItems() or {}
end

local function findLootBag(position, token)
	for _, tileItem in ipairs(getTileItems(position)) do
		if tileItem:isContainer() and tileItem:getActionId() == LOOT_BAG_ACTION_ID then
			if not token or tileItem:getCustomAttribute(LOOT_BAG_TOKEN_KEY) == token then
				return tileItem
			end
		end
	end
	return nil
end

local HIGHLIGHT_MAX_DEPTH = 8

local function itemQualifiesForHighlight(item, depth)
	if not item then
		return false
	end

	depth = depth or 0
	if depth > HIGHLIGHT_MAX_DEPTH then
		return false
	end

	if item.hasItemUniqueName and item:hasItemUniqueName() then
		return true
	end

	if item.getUnique and item:getUnique() then
		return true
	end

	if item.isSuperior and item:isSuperior() then
		return true
	end

	if item.getRarityId and item:getRarityId() >= EPIC then
		return true
	end

	if not item:isContainer() then
		return false
	end

	for index = 0, item:getSize() - 1 do
		if itemQualifiesForHighlight(item:getItem(index), depth + 1) then
			return true
		end
	end

	return false
end

local function scheduleLootBagEffect(position, token)
	addEvent(function()
		local bag = findLootBag(position, token)
		if not bag then
			return
		end

		if tonumber(bag:getCustomAttribute(LOOT_BAG_HIGHLIGHT_KEY)) ~= 1 then
			return
		end

		position:sendMagicEffect(LOOT_BAG_EFFECT_ID)
		scheduleLootBagEffect(clonePosition(position), token)
	end, LOOT_BAG_EFFECT_INTERVAL_MS)
end

local function refreshLootBagHighlight(bag)
	if not bag or not bag:isContainer() or bag:getActionId() ~= LOOT_BAG_ACTION_ID then
		return false
	end

	local shouldHighlight = itemQualifiesForHighlight(bag)
	bag:setCustomAttribute(LOOT_BAG_HIGHLIGHT_KEY, shouldHighlight and 1 or 0)

	if not shouldHighlight then
		return false
	end

	local token = bag:getCustomAttribute(LOOT_BAG_TOKEN_KEY)
	if not token then
		token = nextLootBagToken()
		bag:setCustomAttribute(LOOT_BAG_TOKEN_KEY, token)
	end

	if tonumber(bag:getCustomAttribute(LOOT_BAG_EFFECT_STARTED_KEY)) ~= 1 then
		bag:setCustomAttribute(LOOT_BAG_EFFECT_STARTED_KEY, 1)
		scheduleLootBagEffect(clonePosition(bag:getPosition()), token)
	end

	return true
end

local function canCollectLootBag(player, bag)
	local ownerId = bag:getCorpseOwner()
	if ownerId == 0 or ownerId == player:getId() then
		return true
	end

	local party = player:getParty()
	if not party then
		return false
	end

	local owner = Player(ownerId)
	if not owner then
		return false
	end

	return party:getLeader():getId() == ownerId or owner:getParty() == party
end

local COLLECT_FLAGS = FLAG_IGNORENOTMOVEABLE

local function sendLootPickupPacket(player, position, aggregated)
	if not player or not aggregated or next(aggregated) == nil then
		return
	end

	local items = {}
	for _, bucket in pairs(aggregated) do
		items[#items + 1] = {
			id = bucket.id,
			count = bucket.count,
			rarity = bucket.rarity or 0,
			quality = bucket.quality or 0,
		}
	end

	local payload = json.encode({
		pos = { x = position.x, y = position.y, z = position.z },
		items = items,
	})

	player:sendExtendedOpcode(LOOT_PICKUP_OPCODE, payload)
end

local function collectLootBag(player, bag)
	local backpack = player:getSlotItem(CONST_SLOT_BACKPACK)
	if not backpack or not backpack:isContainer() then
		return RETURNVALUE_NOTENOUGHROOM
	end

	if backpack:getEmptySlots(true) == 0 then
		return RETURNVALUE_NOTENOUGHROOM
	end

	local lastError = RETURNVALUE_NOERROR
	local movedAny = false
	local pickupPosition = clonePosition(bag:getPosition())
	local aggregated = {}

	local function collectItem(lootItem)
		if not lootItem then
			return
		end

		if lootItem:isContainer() and tonumber(lootItem:getCustomAttribute(LOOT_BAG_INTERNAL_KEY)) == 1 then
			for nestedIndex = lootItem:getSize() - 1, 0, -1 do
				collectItem(lootItem:getItem(nestedIndex))
			end

			if lootItem:getSize() == 0 then
				lootItem:remove()
			end
			return
		end

		if backpack:getEmptySlots(true) == 0 then
			lastError = RETURNVALUE_NOTENOUGHROOM
			return
		end

		local itemId = lootItem:getId()
		local itemCount = lootItem:getCount() or 1
		local rarity = (lootItem.getRarityId and lootItem:getRarityId()) or 0
		local quality = 0
		if lootItem.hasItemUniqueName and lootItem:hasItemUniqueName() then
			quality = 3
		elseif lootItem.getUnique and lootItem:getUnique() then
			quality = 2
		elseif lootItem.isSuperior and lootItem:isSuperior() then
			quality = 1
		end

		local moved = lootItem:moveTo(backpack, COLLECT_FLAGS)
		if moved then
			movedAny = true
			local key = itemId .. ":" .. rarity .. ":" .. quality
			local bucket = aggregated[key]
			if bucket then
				bucket.count = bucket.count + itemCount
			else
				aggregated[key] = { id = itemId, count = itemCount, rarity = rarity, quality = quality }
			end
		else
			lastError = RETURNVALUE_NOTENOUGHROOM
		end
	end

	for index = bag:getSize() - 1, 0, -1 do
		collectItem(bag:getItem(index))
	end

	if movedAny then
		sendLootPickupPacket(player, pickupPosition, aggregated)
	end

	if bag:getSize() == 0 then
		bag:remove()
		return movedAny and RETURNVALUE_NOERROR or lastError
	end

	refreshLootBagHighlight(bag)
	return movedAny and RETURNVALUE_NOERROR or lastError
end

local function moveLootToBag(sourceContainer, targetBag)
	local activeBag = targetBag

	for index = sourceContainer:getSize() - 1, 0, -1 do
		local lootItem = sourceContainer:getItem(index)
		if lootItem then
			while activeBag:getSize() >= activeBag:getCapacity() do
				local nestedBag = Game.createItem(LOOT_BAG_ITEM_ID, 1)
				if not nestedBag or not nestedBag:isContainer() then
					return false
				end
				nestedBag:setCustomAttribute(LOOT_BAG_INTERNAL_KEY, 1)

				if activeBag:addItemEx(nestedBag) ~= RETURNVALUE_NOERROR then
					nestedBag:remove()
					return false
				end

				activeBag = nestedBag
			end

			if activeBag:addItemEx(lootItem) ~= RETURNVALUE_NOERROR then
				return false
			end
		end
	end

	return true
end

local function normalizeLootBag(corpse)
	if not corpse or not corpse:isContainer() then
		return nil
	end

	if corpse:getId() == LOOT_BAG_ITEM_ID then
		return corpse
	end

	local bag = Game.createItem(LOOT_BAG_ITEM_ID, 1, corpse:getPosition())
	if not bag or not bag:isContainer() then
		return corpse
	end

	bag:setAttribute(ITEM_ATTRIBUTE_CORPSEOWNER, corpse:getCorpseOwner())
	if not moveLootToBag(corpse, bag) then
		bag:remove()
		return corpse
	end

	corpse:remove()
	return bag
end

local function prepareLootBag(corpse)
	local bag = normalizeLootBag(corpse)
	if not bag or not bag:isContainer() then
		return nil
	end

	if bag:getSize() == 0 then
		bag:remove()
		return nil
	end

	bag:setActionId(LOOT_BAG_ACTION_ID)
	bag:setTimedDecay(LOOT_BAG_DURATION_MS)
	refreshLootBagHighlight(bag)
	return bag
end

dropEvent.onDropLoot = function(self, corpse)
	if not corpse or configManager.getNumber(configKeys.RATE_LOOT) == 0 then
		if corpse then
			corpse:remove()
		end
		return
	end

	local player = Player(corpse:getCorpseOwner())
	local mType = self:getType()
	local doCreateLoot = false

	if not player or player:getStamina() > 840 or not configManager.getBoolean(configKeys.STAMINA_SYSTEM) then
		doCreateLoot = true
	end

	if doCreateLoot then
		local monsterLoot = mType:getLoot()
		for i = 1, #monsterLoot do
			local item = corpse:createLootItem(monsterLoot[i])
			if not item then
				print("[Warning] DropLoot: Could not add loot item to corpse.")
			end
		end
	end

	if doCreateLoot and applyDropLootQuality then
		applyDropLootQuality(mType, corpse, player)
	end

	if tryDropJewelSkull then
		tryDropJewelSkull(mType, corpse, player)
	end

	local lootBag = prepareLootBag(corpse)
	local lootDescription = lootBag and lootBag:getContentDescription() or "nothing"

	if player then
		local text
		if not doCreateLoot and lootDescription == "nothing" then
			text = ("Loot of %s: nothing (due to low stamina)."):format(mType:getNameDescription())
		else
			text = ("Loot of %s: %s."):format(mType:getNameDescription(), lootDescription)
		end

		local party = player:getParty()
		if party then
			party:broadcastPartyLoot(text)
		else
			player:sendTextMessage(MESSAGE_LOOT, text)
		end
	end
end

function pickupEvent.onStepIn(creature, item, position, fromPosition)
	if not creature or not creature:isPlayer() then
		return true
	end

	if not item or not item:isContainer() or item:getActionId() ~= LOOT_BAG_ACTION_ID then
		return true
	end

	local player = Player(creature:getId())
	if not player then
		return true
	end

	if not canCollectLootBag(player, item) then
		player:sendCancelMessage("This loot belongs to another player.")
		return true
	end

	local result = collectLootBag(player, item)
	if result ~= RETURNVALUE_NOERROR then
		player:sendTextMessage(MESSAGE_STATUS_SMALL, Game.getReturnMessage(result))
	end

	return true
end

pickupEvent:type("stepin")
pickupEvent:aid(LOOT_BAG_ACTION_ID)

movedEvent.onItemMoved = function(player, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	if fromPosition.x == CONTAINER_POSITION then
		return
	end

	local bag = findLootBag(fromPosition)
	if bag then
		refreshLootBagHighlight(bag)
	end
end

dropEvent:register()
pickupEvent:register()
movedEvent:register()
