local storageBase = 9000000
local actionId = 65535

local action = Action()

function action.onUse(player, chest, fromPos, target, toPos, isHotkey)
    local questId = chest:getUniqueId()
    if not chest:getType():isContainer() then
        error(string.format("[Error - QuestChest::%d] Item %d is not a container.", questId, chest:getId()))
    end

    if player:getStorageValue(storageBase + questId) ~= -1 then
        player:sendTextMessage(MESSAGE_INFO_DESCR, "It is empty.")
        return true
    end

    local items = chest:getItems()
    if #items == 0 then
        error(string.format("[Error - QuestChest::%d] No items found for quest %d", questId, questId))
    end

    player:setStorageValue(storageBase + questId, 1)
    player:sendTextMessage(MESSAGE_LOOT, string.format("You have found %s.", chest:getContentDescription()))
    for _, item in pairs(items) do
        player:addItemEx(item:clone(), true)
    end
    return true
end

action:aid(actionId)
action:register()
