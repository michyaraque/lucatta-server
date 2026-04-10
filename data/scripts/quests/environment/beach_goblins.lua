local config = {
    monsterName = "goblin",
    chestItemId = 2000,
    chestActionId = 60002,
    chestPos = Position(16, 265, 7),
    spawnArea = {
        from = Position(11, 260, 7),
        to = Position(22, 269, 7)
    },
    rewards = {143, 144, 22, 85, 326},
    globalStorage = 60001,
    neededKills = 3
}

local function isInArea(position)
    return position:isInRange(config.spawnArea.from, config.spawnArea.to)
end

local function isTrackedMonster(creature)
    return creature and creature:isMonster() and creature:getName():lower() == config.monsterName
end

local function findChest()
    local tile = Tile(config.chestPos)
    if not tile then
        return nil
    end

    local items = tile:getItems()
    for _, tileItem in ipairs(items) do
        if tileItem:getId() == config.chestItemId and tileItem:getActionId() == config.chestActionId then
            return tileItem
        end
    end

    return nil
end

local function registerTrackedMonster(creature)
    if isTrackedMonster(creature) and isInArea(creature:getPosition()) then
        creature:registerEvent("GoblinAreaDeath")
    end
end

local function registerExistingMonsters()
    local center = Position(
        math.floor((config.spawnArea.from.x + config.spawnArea.to.x) / 2),
        math.floor((config.spawnArea.from.y + config.spawnArea.to.y) / 2),
        config.spawnArea.from.z
    )

    local spectators = Game.getSpectators(
        center,
        false,
        false,
        center.x - config.spawnArea.from.x,
        config.spawnArea.to.x - center.x,
        center.y - config.spawnArea.from.y,
        config.spawnArea.to.y - center.y
    )

    for _, spectator in ipairs(spectators) do
        registerTrackedMonster(spectator)
    end
end

local goblinDeath = CreatureEvent("GoblinAreaDeath")

function goblinDeath.onDeath(creature, corpse, killer, mostDamageKiller, lastHitUnjustified, mostDamageUnjustified)
    if not isTrackedMonster(creature) then
        return true
    end

    local pos = creature:getPosition()
    if not isInArea(pos) then
        return true
    end

    local currentKills = math.max(0, Game.getStorageValue(config.globalStorage)) + 1

    if currentKills < config.neededKills then
        Game.setStorageValue(config.globalStorage, currentKills)
        return true
    end

    Game.setStorageValue(config.globalStorage, 0)
    if findChest() then
        return true
    end

    local chest = Game.createItem(config.chestItemId, 1, config.chestPos)
    if not chest then
        return true
    end

    chest:setActionId(config.chestActionId)
    config.chestPos:sendMagicEffect(CONST_ME_MAGIC_RED)

    local spectators = Game.getSpectators(config.chestPos, false, true, 7, 7, 5, 5)
    for _, spectator in ipairs(spectators) do
        spectator:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The goblins have been defeated! A treasure chest has appeared.")
    end

    return true
end

goblinDeath:register()

local spawnEvent = Event()

function spawnEvent.onSpawn(creature, position, startup, artificial)
    registerTrackedMonster(creature)
    return true
end

spawnEvent:register(-1)

local goblinChest = Action()

function goblinChest.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local randomReward = config.rewards[math.random(#config.rewards)]
    local itemType = ItemType(randomReward)

    if player:addItem(randomReward, 1) then
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You found a " .. itemType:getName() .. " inside the chest.")
        player:getPosition():sendMagicEffect(CONST_ME_GIFT_WRAPS)
        item:remove()
    else
        player:sendCancelMessage("You do not have enough capacity.")
    end
    return true
end

goblinChest:aid(config.chestActionId)
goblinChest:register()

registerExistingMonsters()
