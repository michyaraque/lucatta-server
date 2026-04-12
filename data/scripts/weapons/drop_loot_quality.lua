DROP_LOOT_QUALITY_CONFIG = {
    ENABLED = true,
    UNIQUE_CHANCE = 1,
    SUPERIOR_CHANCE = 10,
	SUPER_UNIQUE_CHANCE = 1000,
}

local function rollDropPercent(chance)
    return chance and chance > 0 and math.random(100) <= chance
end

local function rollDropInverseChance(chance)
    return chance and chance > 0 and math.random(chance) == 1
end

local function raiseItemRarity(item, minimumRarity)
    if not item or not item.setRarity then
        return
    end

    local currentRarity = item:getRarityId()
    local nextRarity = math.min(LEGENDARY, math.max(currentRarity + 1, minimumRarity or currentRarity))
    item:setRarity(nextRarity)
end

local function addBonusGoldToCorpse(corpse, killer)
    if not corpse or not killer then
        return
    end

    for slot = CONST_SLOT_HEAD, CONST_SLOT_PET do
        local equippedItem = killer:getSlotItem(slot)
        if equippedItem then
            local values = equippedItem:getAllEquippedBonuses()
            if values then
                for _, value in pairs(values) do
                    local attr = US_ENCHANTMENTS[value[1]]
                    if attr and attr.name == "Additonal Gold" then
                        local crystalCoins = 0
                        local platinumCoins = 0
                        local goldCoins = 0
                        local bonusGold = 0

                        for index = 0, corpse:getSize() do
                            local lootItem = corpse:getItem(index)
                            if lootItem then
                                if lootItem.itemid == 92 then
                                    bonusGold = bonusGold + lootItem:getCount()
                                end
                            end
                        end

                        bonusGold = math.floor(bonusGold * value[2] / 100)

                        while bonusGold >= 10000 do
                            bonusGold = bonusGold - 10000
                            crystalCoins = crystalCoins + 1
                        end

                        while bonusGold >= 100 do
                            bonusGold = bonusGold - 100
                            platinumCoins = platinumCoins + 1
                        end

                        goldCoins = bonusGold

                        if crystalCoins > 0 then
                            corpse:addItemEx(Game.createItem(2160, crystalCoins))
                        end

                        if platinumCoins > 0 then
                            corpse:addItemEx(Game.createItem(2152, platinumCoins))
                        end

                        if goldCoins > 0 then
                            corpse:addItemEx(Game.createItem(92, goldCoins))
                        end
                    end
                end
            end
        end
    end
end

local function getEligibleUniqueIds(item)
    local uniqueIds = {}
    if not item or not item.getItemType then
        return uniqueIds
    end

    local usItemType = item:getItemType()
    local itemLevel = item:getItemLevel()

    for uniqueId = 1, #US_UNIQUES do
        local uniqueData = US_UNIQUES[uniqueId]
        if uniqueData.minLevel <= itemLevel and bit.band(usItemType, uniqueData.itemType) ~= 0 then
            uniqueIds[#uniqueIds + 1] = uniqueId
        end
    end

    return uniqueIds
end

local function rollUniqueId(item)
    local eligibleUniqueIds = getEligibleUniqueIds(item)
    if #eligibleUniqueIds == 0 then
        return nil
    end

    for _ = 1, 25 do
        local uniqueId = eligibleUniqueIds[math.random(#eligibleUniqueIds)]
        local uniqueData = US_UNIQUES[uniqueId]
        if not uniqueData.chance or math.random(100) <= uniqueData.chance then
            return uniqueId
        end
    end

    return eligibleUniqueIds[math.random(#eligibleUniqueIds)]
end

local function processUpgradableDrop(item, killer, corpsePosition, itemLevelBase)
    local itemType = item:getType()

    if not itemType:isUpgradable() then
        return
    end

    if not US_CONFIG.ALWAYS_IDENTIFIED and math.random(US_CONFIG.UNIDENTIFIED_DROP_CHANCE) == 1 then
        item:unidentify()
        return
    end

    item:rollRarity()

    local itemLevel = math.random(math.max(1, itemLevelBase - 2), itemLevelBase + 2)
    item:setItemLevel(math.min(US_CONFIG.MAX_ITEM_LEVEL, itemLevel), true)
    item:generateRandomSockets()

    local appliedSuperUnique = false
    if rollDropInverseChance(DROP_LOOT_QUALITY_CONFIG.SUPER_UNIQUE_CHANCE) then
        appliedSuperUnique = item:applyRandomUniqueName(corpsePosition)
    end
    local appliedUnique = false

    if not appliedSuperUnique and rollDropPercent(DROP_LOOT_QUALITY_CONFIG.UNIQUE_CHANCE) then
        local uniqueId = rollUniqueId(item)
        if uniqueId then
            item:setUnique(uniqueId)
            raiseItemRarity(item, RARE)
            appliedUnique = true
        end
    end

    if not appliedSuperUnique and not appliedUnique and US_CONFIG.ALWAYS_IDENTIFIED and item:getMaxSockets() > 0 then
        item:rollAttribute(killer, itemType, itemType:getWeaponType(), true)
    end

    if rollDropPercent(DROP_LOOT_QUALITY_CONFIG.SUPERIOR_CHANCE) then
        item:setSuperior(true)
        raiseItemRarity(item, COMMON)
    end
end

function applyDropLootQuality(monsterType, corpse, killer)
    if not DROP_LOOT_QUALITY_CONFIG.ENABLED or not monsterType or not corpse or not corpse:isContainer() then
        return
    end

    addBonusGoldToCorpse(corpse, killer)

    local itemLevelBase = monsterType:calculateItemLevel()
    for index = 0, corpse:getCapacity() do
        local item = corpse:getItem(index)
        if item then
            local itemType = item:getType()
            if itemType then
                if itemType:canHaveItemLevel() then
                    item:setItemLevel(math.min(US_CONFIG.MAX_ITEM_LEVEL, math.random(math.max(1, itemLevelBase - 5), itemLevelBase)), true)
                end

                if itemType:isUpgradable() then
                    processUpgradableDrop(item, killer, corpse:getPosition(), itemLevelBase)
                end
            end
        end
    end
end

print(">> Loaded Drop Loot Quality")
