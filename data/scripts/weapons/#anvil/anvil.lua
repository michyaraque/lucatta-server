anvil_network = {}
anvil_network.OPCODE = 69
anvil_network.ITEM_UPGRADE_CRYSTAL = 2149
anvil_network.SOCKET_STONE_ID = 7759

anvil_network.ACTION = {
    OPEN = 1,
    CLOSE = 2,
    RESULT = 3,
    UPGRADE = 4,
    SOCKET = 5,
    SOCKET_RESULT = 6,
    SOCKET_STONE = 7,
    SOCKET_STONE_RESULT = 8
}

local clientIdMap = {}

function anvil_network.clientIdToServerId(clientId)
    if clientIdMap[clientId] then
        return clientIdMap[clientId]
    end
    
    -- Iterate and find
    for serverId = 100, 35000 do
        local itemType = ItemType(serverId)
        if itemType and itemType:getClientId() == clientId then
            clientIdMap[clientId] = serverId
            return serverId
        end
    end
    return 0
end

local handler = PacketHandler(anvil_network.OPCODE)

function handler.onReceive(player, msg)
    local action = msg:getByte()
    
    if action == anvil_network.ACTION.UPGRADE then
        anvil_network.handleUpgrade(player, msg)
    elseif action == anvil_network.ACTION.SOCKET then
        anvil_network.handleSocket(player, msg)
    elseif action == anvil_network.ACTION.SOCKET_STONE then
        anvil_network.handleSocketStone(player, msg)
    end
end

-- Configuration
anvil_network.LUCKY_SLOT_BONUS = 15 -- Extra % chance if player matches lucky slot

-- Get item from position (handles inventory, containers, and ground)
function anvil_network.getItemFromPosition(player, x, y, z, stackpos, expectedItemId)
    local pos = Position(x, y, z)

    -- Check if it's an inventory/container position (x = 0xFFFF)
    if x == 0xFFFF then
        -- y = container id or slot, z = slot index
        local containerId = y - 64 -- Container IDs start at 64
        if containerId >= 0 then
            -- It's in a container
            local container = player:getContainerById(containerId)
            if container then
                local item = container:getItem(z)
                if item and item:getId() == expectedItemId then
                    return item
                end
            end
        else
            -- It's an equipment slot
            local item = player:getSlotItem(y)
            if item and item:getId() == expectedItemId then
                return item
            end
        end
    else
        -- Ground position
        local tile = Tile(pos)
        if tile then
            local thing = tile:getThing(stackpos)
            if thing and thing:isItem() and thing:getId() == expectedItemId then
                return thing
            end
        end
    end

    return nil
end

-- Handle upgrade request
function anvil_network.handleUpgrade(player, msg)
    -- Read weapon position and ID
    local weaponPosX = msg:getU16()
    local weaponPosY = msg:getU16()
    local weaponPosZ = msg:getByte()
    local weaponStackPos = msg:getByte()
    local weaponClientId = msg:getU16()
    local itemCount = msg:getByte()

    if not weaponClientId or weaponClientId == 0 then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "Invalid weapon.")
        return
    end

    local weaponServerId = anvil_network.clientIdToServerId(weaponClientId)

    if weaponServerId == 0 then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "Unknown weapon type.")
        return
    end

    -- Get the weapon - try position-based first, then fallback
    local weapon = nil
    if weaponPosX ~= 0xFFFF or weaponPosY ~= 0 or weaponPosZ ~= 0 then
        weapon = anvil_network.getItemFromPosition(player, weaponPosX, weaponPosY, weaponPosZ, weaponStackPos, weaponServerId)
    end

    -- Fallback to search by item ID
    if not weapon then
        weapon = player:getItemById(weaponServerId, true)
    end

    if not weapon then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "You do not have this weapon.")
        return
    end

    -- Calculate Crystal Client ID
    local crystalServerId = anvil_network.ITEM_UPGRADE_CRYSTAL
    local crystalClientId = ItemType(crystalServerId):getClientId()

    local upgradeItems = {}
    local playerSlots = {} -- Track which slots (1-9) the player used

    for i = 1, itemCount do
        local slotIndex = msg:getByte() -- Slot index (1-9)
        local itemPosX = msg:getU16()
        local itemPosY = msg:getU16()
        local itemPosZ = msg:getByte()
        local count = msg:getByte()

        -- Track player slot
        if slotIndex >= 1 and slotIndex <= 9 then
            table.insert(playerSlots, slotIndex)
        end

        -- We still need to verify the player has the crystals
        table.insert(upgradeItems, {count = count, slot = slotIndex})
    end

    local crystalCount = 0
    for _, item in ipairs(upgradeItems) do
        crystalCount = crystalCount + item.count
    end

    if crystalCount == 0 then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "You need upgrade crystals.")
        return
    end

    if player:getItemCount(crystalServerId) < crystalCount then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "Not enough upgrade crystals.")
        return
    end

    local weaponItemType = ItemType(weapon.itemid)

    if not weaponItemType:isUpgradable() then
        player:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
        return
    end

    if weapon:isUnidentified() then
        player:sendTextMessage(MESSAGE_STATUS_WARNING, "Sorry, this item is unidentified and can't be modified!")
        player:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
        return
    end

    if weapon:isMirrored() then
        player:sendTextMessage(MESSAGE_STATUS_WARNING, "Sorry, this item is mirrored and can't be modified!")
        player:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
        return
    end

    local upgrade = weapon:getUpgradeLevel()
    if upgrade >= US_CONFIG.MAX_UPGRADE_LEVEL then
        player:sendTextMessage(MESSAGE_STATUS_WARNING, "Maximum upgrade level reached!")
        player:sendAnvilResult(false, weaponClientId, upgrade, 0, false)
        return
    end

    -- Generate lucky slot (1-9)
    local luckySlot = math.random(1, 9)

    -- Check if player matched the lucky slot
    local matched = false
    for _, slot in ipairs(playerSlots) do
        if slot == luckySlot then
            matched = true
            break
        end
    end

    player:removeItem(crystalServerId, crystalCount)

    upgrade = upgrade + 1

    -- Calculate success chance with potential bonus
    local bonusChance = matched and anvil_network.LUCKY_SLOT_BONUS or 0

    if upgrade >= US_CONFIG.UPGRADE_LEVEL_DESTROY then
        local destroyChance = US_CONFIG.UPGRADE_DESTROY_CHANCE[upgrade] + bonusChance
        if math.random(100) > destroyChance then
            if player:getItemCount(US_CONFIG.ITEM_UPGRADE_CATALYST) > 0 then
                player:removeItem(US_CONFIG.ITEM_UPGRADE_CATALYST, 1)
               -- player:getPosition():sendMagicEffect(CONST_ME_GROUNDSHAKER)
                player:sendAnvilResult(false, weaponClientId, weapon:getUpgradeLevel(), luckySlot, matched)
                return
            end
            weapon:remove(1)
            -- player:getPosition():sendMagicEffect(CONST_ME_GROUNDSHAKER)
            player:sendAnvilResult(false, 0, 0, luckySlot, matched)
            return
        end
    else
        local successChance = US_CONFIG.UPGRADE_SUCCESS_CHANCE[upgrade] + bonusChance
        if math.random(100) > successChance then
            weapon:reduceUpgradeLevel()
            -- player:getPosition():sendMagicEffect(CONST_ME_GROUNDSHAKER)
            player:sendAnvilResult(false, weaponClientId, weapon:getUpgradeLevel(), luckySlot, matched)
            return
        end
    end

    weapon:setUpgradeLevel(upgrade)

    -- player:getPosition():sendMagicEffect(CONST_ME_GIFT_WRAPS)
    -- player:getPosition():sendMagicEffect(CONST_ME_FIREWORK_YELLOW)

    if weapon:getItemLevel() == 0 then
        weapon:setItemLevel(1, true)
    end

    player:sendAnvilResult(true, weaponClientId, upgrade, luckySlot, matched)
end

function anvil_network.handleSocket(player, msg)
    local weaponPosX = msg:getU16()
    local weaponPosY = msg:getU16()
    local weaponPosZ = msg:getByte()
    local weaponStackPos = msg:getByte()
    local weaponClientId = msg:getU16()
    local itemCount = msg:getByte()

    if not weaponClientId or weaponClientId == 0 then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "Invalid item.")
        return
    end

    local weaponServerId = anvil_network.clientIdToServerId(weaponClientId)
    if weaponServerId == 0 then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "Unknown item type.")
        return
    end

    local weapon = nil
    if weaponPosX ~= 0xFFFF or weaponPosY ~= 0 or weaponPosZ ~= 0 then
        weapon = anvil_network.getItemFromPosition(player, weaponPosX, weaponPosY, weaponPosZ, weaponStackPos, weaponServerId)
    end
    if not weapon then
        weapon = player:getItemById(weaponServerId, true)
    end

    if not weapon then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "You do not have this item.")
        return
    end

    local weaponItemType = ItemType(weapon.itemid)
    if not weaponItemType:isUpgradable() then
        player:sendTextMessage(MESSAGE_STATUS_WARNING, "This item cannot have sockets.")
        player:sendAnvilSocketResult(false, weaponClientId, 0, "Not sockettable")
        return
    end

    if weapon:isUnidentified() then
        player:sendTextMessage(MESSAGE_STATUS_WARNING, "Identify the item first.")
        player:sendAnvilSocketResult(false, weaponClientId, 0, "Unidentified")
        return
    end

    local maxSockets = weapon:getMaxSockets()
    if maxSockets == 0 then
        player:sendTextMessage(MESSAGE_STATUS_WARNING, "This item has no socket slots.")
        player:sendAnvilSocketResult(false, weaponClientId, 0, "No sockets")
        return
    end

    local emptySocket = weapon:getFirstEmptySocket()
    if not emptySocket then
        player:sendTextMessage(MESSAGE_STATUS_WARNING, "All socket slots are filled.")
        player:sendAnvilSocketResult(false, weaponClientId, 0, "Full")
        return
    end

    local skullItem = nil
    local skullClientId = 0
    local skullSlotIndex = 0

    for i = 1, itemCount do
        local slotIndex = msg:getByte()
        local itemPosX = msg:getU16()
        local itemPosY = msg:getU16()
        local itemPosZ = msg:getByte()
        local count = msg:getByte()
        local slotClientId = msg:getU16()

        if slotClientId and slotClientId > 0 then
            local slotServerId = anvil_network.clientIdToServerId(slotClientId)
            if slotServerId > 0 and JEWEL_SKULL_CONFIG and JEWEL_SKULL_CONFIG.RARITY_BY_ID[slotServerId] then
                local foundSkull = player:getItemById(slotServerId, true)
                if foundSkull and foundSkull:isJewelSkull() then
                    skullItem = foundSkull
                    skullClientId = slotClientId
                    skullSlotIndex = slotIndex
                    break
                end
            end
        end
    end

    if not skullItem then
        player:sendTextMessage(MESSAGE_STATUS_WARNING, "Place a Jewel Skull in one of the slots.")
        player:sendAnvilSocketResult(false, weaponClientId, 0, "No skull")
        return
    end

    local bonuses = skullItem:getJewelSkullBonuses()
    if not bonuses or #bonuses == 0 then
        player:sendTextMessage(MESSAGE_STATUS_WARNING, "This skull has no attributes.")
        player:sendAnvilSocketResult(false, weaponClientId, 0, "Empty skull")
        return
    end

    if weapon:insertJewelSkull(skullItem, emptySocket) then
        local skullConfig = skullItem:getJewelSkullConfig()
        local skullName = skullConfig and skullConfig.name or "Jewel"
        skullItem:remove(1)
        player:getPosition():sendMagicEffect(CONST_ME_GIFT_WRAPS)
        player:sendTextMessage(MESSAGE_INFO_DESCR, skullName .. " Skull socketed into slot " .. emptySocket .. "!")
        player:sendAnvilSocketResult(true, weaponClientId, emptySocket, skullName)
    else
        player:sendTextMessage(MESSAGE_STATUS_WARNING, "Failed to socket Jewel Skull.")
        player:sendAnvilSocketResult(false, weaponClientId, 0, "Failed")
    end
end

function Player:sendAnvilSocketResult(success, itemClientId, socketIndex, message)
    local msg = NetworkMessage()
    msg:addByte(anvil_network.OPCODE)
    msg:addByte(anvil_network.ACTION.SOCKET_RESULT)
    msg:addByte(success and 1 or 0)
    msg:addU16(itemClientId)
    msg:addByte(socketIndex)
    msg:addString(message or "")
    msg:sendToPlayer(self)
end

function anvil_network.handleSocketStone(player, msg)
    local weaponPosX = msg:getU16()
    local weaponPosY = msg:getU16()
    local weaponPosZ = msg:getByte()
    local weaponStackPos = msg:getByte()
    local weaponClientId = msg:getU16()
    local stoneCount = msg:getByte()
    
    if not weaponClientId or weaponClientId == 0 then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "Invalid item.")
        return
    end
    
    local weaponServerId = anvil_network.clientIdToServerId(weaponClientId)
    if weaponServerId == 0 then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "Unknown item type.")
        return
    end
    
    local weapon = nil
    if weaponPosX ~= 0xFFFF or weaponPosY ~= 0 or weaponPosZ ~= 0 then
        weapon = anvil_network.getItemFromPosition(player, weaponPosX, weaponPosY, weaponPosZ, weaponStackPos, weaponServerId)
    end
    if not weapon then
        weapon = player:getItemById(weaponServerId, true)
    end
    
    if not weapon then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "You do not have this item.")
        return
    end
    
    local weaponItemType = ItemType(weapon.itemid)
    if not weaponItemType:isUpgradable() then
        player:sendTextMessage(MESSAGE_STATUS_WARNING, "This item cannot have sockets.")
        player:sendSocketStoneResult(false, weaponClientId, 0, "Not upgradable", nil)
        return
    end
    
    if weapon:isUnidentified() then
        player:sendTextMessage(MESSAGE_STATUS_WARNING, "Identify the item first.")
        player:sendSocketStoneResult(false, weaponClientId, 0, "Unidentified", nil)
        return
    end
    
    -- Check player has socket stone
    local stoneServerId = anvil_network.SOCKET_STONE_ID
    if player:getItemCount(stoneServerId) < 1 then
        player:sendTextMessage(MESSAGE_STATUS_WARNING, "You need a Socket Stone.")
        player:sendSocketStoneResult(false, weaponClientId, 0, "No stone", nil)
        return
    end
    
    local currentSockets = weapon:getMaxSockets()
    local hasFilledSockets = false
    
    -- Only check for socketed jewel skulls, NOT native bonuses (Slot{i})
    for i = 1, currentSockets do
        if weapon:getSocketedSkull(i) then
            hasFilledSockets = true
            break
        end
    end
    
    -- Determine max sockets for re-roll based on unique status
    local maxRerollSockets = weapon:isUnique() and 4 or 3
    
    if currentSockets == 0 then
        -- CASE 1: No sockets - create random sockets
        weapon:generateRandomSockets()
        local newSockets = weapon:getMaxSockets()
        player:removeItem(stoneServerId, 1)
        player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
        player:sendTextMessage(MESSAGE_INFO_DESCR, "Created " .. newSockets .. " socket slots!")
        player:sendSocketStoneResult(true, weaponClientId, newSockets, "Sockets created", nil)
        
    elseif not hasFilledSockets then
        -- CASE 2: Has sockets but all are empty - re-roll
        local usItemType = weapon:getItemType()
        local baseMax = US_MAX_SOCKET_PER_ITEM_TYPE[usItemType] or 3
        local newSockets = math.random(1, math.min(baseMax, maxRerollSockets))
        weapon:setMaxSockets(newSockets)
        player:removeItem(stoneServerId, 1)
        player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
        player:sendTextMessage(MESSAGE_INFO_DESCR, "Re-rolled to " .. newSockets .. " socket slots!")
        player:sendSocketStoneResult(true, weaponClientId, newSockets, "Sockets re-rolled", nil)
        
    else
        -- CASE 3: Has filled sockets - extract last item with 50% burn chance
        local extractedSlot = 0
        local extractedItem = nil
        local burned = false
        
        for i = currentSockets, 1, -1 do
            local skullId = weapon:getSocketedSkull(i)
            if skullId then
                extractedSlot = i
                if math.random(100) <= 50 then
                    -- Success - extract the skull
                    extractedItem = weapon:extractJewelSkull(i)
                    if extractedItem then
                        if player:addItemEx(extractedItem) ~= RETURNVALUE_NOERROR then
                            extractedItem:moveTo(player:getPosition())
                        end
                    end
                else
                    -- Burned - remove without returning
                    local prefix = "SocketedSkullAttr" .. i .. "_"
                    for j = 1, 5 do
                        weapon:removeCustomAttribute(prefix .. j)
                    end
                    weapon:removeCustomAttribute("SocketedSkull" .. i)
                    burned = true
                end
                break
            end
            -- NOTE: Native bonuses (Slot{i}) are permanent and should NEVER be removed by socket operations
        end
        
        player:removeItem(stoneServerId, 1)
        
        if burned then
            player:getPosition():sendMagicEffect(CONST_ME_FIREAREA)
            player:sendTextMessage(MESSAGE_STATUS_WARNING, "The socketed item was burned during extraction!")
            player:sendSocketStoneResult(true, weaponClientId, extractedSlot, "Burned", nil)
        else
            player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
            player:sendTextMessage(MESSAGE_INFO_DESCR, "Successfully extracted item from socket " .. extractedSlot .. "!")
            local extractedClientId = extractedItem and ItemType(extractedItem:getId()):getClientId() or 0
            player:sendSocketStoneResult(true, weaponClientId, extractedSlot, "Extracted", extractedClientId)
        end
    end
end

function Player:sendSocketStoneResult(success, itemClientId, sockets, action, extractedClientId)
    local msg = NetworkMessage()
    msg:addByte(anvil_network.OPCODE)
    msg:addByte(anvil_network.ACTION.SOCKET_STONE_RESULT)
    msg:addByte(success and 1 or 0)
    msg:addU16(itemClientId)
    msg:addByte(sockets)
    msg:addString(action or "")
    msg:addU16(extractedClientId or 0)
    msg:sendToPlayer(self)
end

handler:register()
