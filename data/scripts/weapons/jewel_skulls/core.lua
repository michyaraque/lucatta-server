function Item.isJewelSkull(self)
    return JEWEL_SKULL_CONFIG.RARITY_BY_ID[self:getId()] ~= nil
end

function Item.getJewelSkullRarity(self)
    return JEWEL_SKULL_CONFIG.RARITY_BY_ID[self:getId()]
end

function Item.getJewelSkullConfig(self)
    local rarity = self:getJewelSkullRarity()
    if rarity then
        return JEWEL_SKULL_CONFIG.SKULLS[rarity]
    end
    return nil
end

function Item.generateJewelSkullAttributes(self, monsterLevel)
    initJewelSkullEnchantments()
    
    local config = self:getJewelSkullConfig()
    if not config then return false end
    
    -- Define specific item types to categorize the skull
    local possibleTypes = {
        US_ITEM_TYPES.WEAPON_MELEE,
        US_ITEM_TYPES.WEAPON_DISTANCE,
        US_ITEM_TYPES.WEAPON_WAND,
        US_ITEM_TYPES.SHIELD,
        US_ITEM_TYPES.HELMET,
        US_ITEM_TYPES.ARMOR,
        US_ITEM_TYPES.LEGS,
        US_ITEM_TYPES.BOOTS,
        US_ITEM_TYPES.RING,
        US_ITEM_TYPES.NECKLACE
    }
    
    -- Select a random item type for this skull to prevent contradictory attributes
    local targetItemType = possibleTypes[math.random(#possibleTypes)]

    -- Filter enchantments that match the selected item type
    local compatibleEnchantments = {}
    if US_ENCHANTMENTS then
        for i = 1, #US_ENCHANTMENTS do
            local enchant = US_ENCHANTMENTS[i]
            if enchant and enchant.itemType then
                if bit.band(enchant.itemType, targetItemType) ~= 0 then
                    table.insert(compatibleEnchantments, i)
                end
            end
        end
    end
    
    if #compatibleEnchantments == 0 then
        print("[Warning] No compatible enchantments found for skull type: " .. targetItemType)
        return false
    end
    
    local numAttributes = math.random(config.minAttributes, config.maxAttributes)
    local usedEnchants = {}
    
    for slot = 1, numAttributes do
        local attempts = 0
        local maxAttempts = 100
        local enchantIndex = nil
        
        while attempts < maxAttempts do
            local randomIndex = math.random(1, #compatibleEnchantments)
            enchantIndex = compatibleEnchantments[randomIndex]
            
            if not usedEnchants[enchantIndex] then
                local enchant = US_ENCHANTMENTS[enchantIndex]
                if enchant then
                    local minLevel = enchant.minLevel or 0
                    if monsterLevel >= minLevel then
                        if not enchant.chance or math.random(100) <= enchant.chance then
                            usedEnchants[enchantIndex] = true
                            break
                        end
                    end
                end
            end
            attempts = attempts + 1
        end
        
        if enchantIndex and usedEnchants[enchantIndex] then
            local enchant = US_ENCHANTMENTS[enchantIndex]
            local baseValue = 1
            if enchant.VALUES_PER_LEVEL then
                baseValue = math.random(1, math.ceil(monsterLevel * enchant.VALUES_PER_LEVEL))
            end
            local finalValue = math.ceil(baseValue * config.valueMultiplier)
            finalValue = math.max(1, finalValue)
            self:setCustomAttribute("JewelSlot" .. slot, enchantIndex .. "|" .. finalValue)
        end
    end
    
    self:setCustomAttribute("jewel_monster_level", monsterLevel)
    return true
end

function Item.getJewelSkullBonuses(self)
    if not self:isJewelSkull() then return nil end
    
    local bonuses = {}
    for i = 1, 5 do
        local attr = self:getCustomAttribute("JewelSlot" .. i)
        if attr then
            local data = {}
            for part in attr:gmatch("([^|]+)") do
                data[#data + 1] = tonumber(part)
            end
            if #data == 2 then
                bonuses[#bonuses + 1] = {
                    slot = i,
                    enchantId = data[1],
                    value = data[2]
                }
            end
        end
    end
    return #bonuses > 0 and bonuses or nil
end

function Item.getJewelSkullBonusCount(self)
    local bonuses = self:getJewelSkullBonuses()
    return bonuses and #bonuses or 0
end

function Item.getSocketedSkull(self, socketIndex)
    return self:getCustomAttribute("SocketedSkull" .. socketIndex)
end

function Item.getSocketedSkullBonuses(self, socketIndex)
    local prefix = "SocketedSkullAttr" .. socketIndex .. "_"
    local bonuses = {}
    for i = 1, 5 do
        local attr = self:getCustomAttribute(prefix .. i)
        if attr then
            local data = {}
            for part in attr:gmatch("([^|]+)") do
                data[#data + 1] = tonumber(part)
            end
            if #data == 2 then
                bonuses[#bonuses + 1] = {
                    enchantId = data[1],
                    value = data[2]
                }
            end
        end
    end
    return #bonuses > 0 and bonuses or nil
end

function Item.getAllSocketedBonuses(self)
    local allBonuses = {}
    for i = 1, self:getMaxSockets() do
        local skullId = self:getSocketedSkull(i)
        if skullId then
            local bonuses = self:getSocketedSkullBonuses(i)
            if bonuses then
                for _, bonus in ipairs(bonuses) do
                    allBonuses[#allBonuses + 1] = bonus
                end
            end
        end
    end
    return #allBonuses > 0 and allBonuses or nil
end

function Item.getFirstEmptySocket(self)
    for i = 1, self:getMaxSockets() do
        if not self:getSocketedSkull(i) then
            return i
        end
    end
    return nil
end

function Item.insertJewelSkull(self, skull, socketIndex)
    if not skull:isJewelSkull() then return false end
    
    local bonuses = skull:getJewelSkullBonuses()
    if not bonuses then return false end
    
    self:setCustomAttribute("SocketedSkull" .. socketIndex, skull:getId())
    
    local prefix = "SocketedSkullAttr" .. socketIndex .. "_"
    for _, bonus in ipairs(bonuses) do
        self:setCustomAttribute(prefix .. bonus.slot, bonus.enchantId .. "|" .. bonus.value)
    end
    
    return true
end

function Item.extractJewelSkull(self, socketIndex)
    local skullId = self:getSocketedSkull(socketIndex)
    if not skullId then return nil end
    
    local skull = Game.createItem(skullId, 1)
    if not skull then return nil end
    
    local prefix = "SocketedSkullAttr" .. socketIndex .. "_"
    for i = 1, 5 do
        local attr = self:getCustomAttribute(prefix .. i)
        if attr then
            skull:setCustomAttribute("JewelSlot" .. i, attr)
            self:removeCustomAttribute(prefix .. i)
        end
    end
    
    self:removeCustomAttribute("SocketedSkull" .. socketIndex)
    return skull
end

print(">> Loaded Jewel Skull Core Functions")
