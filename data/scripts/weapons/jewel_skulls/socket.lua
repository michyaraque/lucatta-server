local JewelSkullAction = Action()

function JewelSkullAction.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    if not target or not target:isItem() then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "Use this on an upgradable item.")
        return true
    end
    
    if not target:getType():isUpgradable() then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "This item cannot have sockets.")
        return true
    end
    
    if target:isUnidentified() then
        player:sendTextMessage(MESSAGE_STATUS_WARNING, "Identify the item first.")
        return true
    end
    
    if target:isMirrored() then
        player:sendTextMessage(MESSAGE_STATUS_WARNING, "Mirrored items cannot be modified.")
        return true
    end
    
    if toPosition.y <= CONST_SLOT_AMMO then
        player:sendTextMessage(MESSAGE_STATUS_WARNING, "Unequip the item first.")
        return true
    end
    
    local maxSockets = target:getMaxSockets()
    if maxSockets == 0 then
        player:sendTextMessage(MESSAGE_STATUS_WARNING, "This item has no socket slots.")
        return true
    end
    
    local emptySocket = target:getFirstEmptySocket()
    if not emptySocket then
        player:sendTextMessage(MESSAGE_STATUS_WARNING, "All socket slots are filled.")
        return true
    end
    
    local bonuses = item:getJewelSkullBonuses()
    if not bonuses or #bonuses == 0 then
        player:sendTextMessage(MESSAGE_STATUS_WARNING, "This skull has no attributes.")
        return true
    end
    
    if target:insertJewelSkull(item, emptySocket) then
        local skullConfig = item:getJewelSkullConfig()
        local skullName = skullConfig and skullConfig.name or "Unknown"
        player:sendTextMessage(MESSAGE_INFO_DESCR, skullName .. " Jewel Skull inserted into socket " .. emptySocket .. "!")
        player:getPosition():sendMagicEffect(CONST_ME_GIFT_WRAPS)
        item:remove(1)
    else
        player:sendTextMessage(MESSAGE_STATUS_WARNING, "Failed to insert Jewel Skull.")
    end
    
    return true
end

for _, skull in pairs(JEWEL_SKULL_CONFIG.SKULLS) do
    JewelSkullAction:id(skull.id)
end
JewelSkullAction:register()

local SkullExtractorAction = Action()

function SkullExtractorAction.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    if not target or not target:isItem() then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "Use this on an item with socketed skulls.")
        return true
    end
    
    if not target:getType():isUpgradable() then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "This item cannot have sockets.")
        return true
    end
    
    if toPosition.y <= CONST_SLOT_AMMO then
        player:sendTextMessage(MESSAGE_STATUS_WARNING, "Unequip the item first.")
        return true
    end
    
    local extractedAny = false
    for i = target:getMaxSockets(), 1, -1 do
        local skullId = target:getSocketedSkull(i)
        if skullId then
            local skull = target:extractJewelSkull(i)
            if skull then
                if player:addItemEx(skull) ~= RETURNVALUE_NOERROR then
                    skull:moveTo(player:getPosition())
                end
                extractedAny = true
                player:sendTextMessage(MESSAGE_INFO_DESCR, "Extracted Jewel Skull from socket " .. i .. "!")
                break
            end
        end
    end
    
    if extractedAny then
        player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
        item:remove(1)
    else
        player:sendTextMessage(MESSAGE_STATUS_WARNING, "No socketed Jewel Skulls found.")
    end
    
    return true
end

SkullExtractorAction:id(JEWEL_SKULL_CONFIG.SKULL_EXTRACTOR_ID)
SkullExtractorAction:register()

print(">> Loaded Jewel Skull Socket Actions")
