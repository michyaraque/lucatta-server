local giveSkullTalk = TalkAction("/giveskull")

function giveSkullTalk.onSay(player, words, param)
    if not player:getGroup():getAccess() then
        return true
    end
    
    initJewelSkullEnchantments()
    
    local rarity = tonumber(param)
    if not rarity or rarity < 1 or rarity > 5 then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Usage: /giveskull [1-5] (1=Common, 2=Uncommon, 3=Rare, 4=Epic, 5=Legendary)")
        return false
    end
    
    local skullConfig = JEWEL_SKULL_CONFIG.SKULLS[rarity]
    if not skullConfig then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED, "Invalid rarity.")
        return false
    end
    
    local skull = player:addItem(skullConfig.id, 1)
    if skull then
        local monsterLevel = math.random(skullConfig.minMonsterLevel or 1, (skullConfig.minMonsterLevel or 1) + 20)
        skull:generateJewelSkullAttributes(monsterLevel)
        
        local bonuses = skull:getJewelSkullBonuses()
        local bonusCount = bonuses and #bonuses or 0
        
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Created " .. skullConfig.name .. " Jewel Skull with " .. bonusCount .. " bonuses (simulated monster level: " .. monsterLevel .. ")")
    else
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED, "Failed to create Jewel Skull.")
    end
    
    return false
end

giveSkullTalk:separator(" ")
giveSkullTalk:register()

local testSocketTalk = TalkAction("/testsocket")

function testSocketTalk.onSay(player, words, param)
    if not player:getGroup():getAccess() then
        return true
    end

    
	if player:getAccountType() < ACCOUNT_TYPE_GOD then
		return false
	end

	local split = param:splitTrimmed(",")

	local itemType = ItemType(split[1])
	if itemType:getId() == 0 then
		itemType = ItemType(tonumber(split[1]))
		if not tonumber(split[1]) or itemType:getId() == 0 then
			player:sendCancelMessage("There is no item with that id or name.")
			return false
		end
	end

    local rarity = tonumber(split[2])
	if rarity then
        rarity = rarity
    else
        rarity = 3
    end
    
    local slots = tonumber(param) or 3
    slots = math.max(1, math.min(5, slots))
    
    local testItem = player:addItem(itemType:getId(), 1)
    if testItem then
        testItem:setRarity(rarity)
        testItem:setMaxSockets(slots)
        testItem:setItemLevel(100, true)
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Created test Magic Sword with " .. slots .. " socket slots.")
    else
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED, "Failed to create test item.")
    end
    
    return false
end

testSocketTalk:separator(" ")
testSocketTalk:register()

print(">> Loaded Jewel Skull Talkactions")
