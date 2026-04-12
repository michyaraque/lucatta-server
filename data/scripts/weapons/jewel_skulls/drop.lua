function tryDropJewelSkull(monsterType, corpse, player)
    if not player or not corpse or not corpse:isContainer() then return end

    local monsterLevel = monsterType:calculateItemLevel()
    local eligibleSkulls = {}

    for rarity = 5, 1, -1 do
        local skull = JEWEL_SKULL_CONFIG.SKULLS[rarity]
        local meetsMinLevel = not skull.minMonsterLevel or monsterLevel >= skull.minMonsterLevel
        local meetsMaxLevel = not skull.maxMonsterLevel or monsterLevel <= skull.maxMonsterLevel

        if meetsMinLevel and meetsMaxLevel then
            table.insert(eligibleSkulls, rarity)
        end
    end

    if #eligibleSkulls == 0 then return end

    for _, rarity in ipairs(eligibleSkulls) do
        local skull = JEWEL_SKULL_CONFIG.SKULLS[rarity]

        if math.random(skull.dropChance) == 1 then
            local skullItem = corpse:addItem(skull.id, 1)
            if skullItem then
                skullItem:generateJewelSkullAttributes(monsterLevel)

                if skull.execute then
                    skull.execute(player)
                end

                local pos = corpse:getPosition()
                local specs = Game.getSpectators(pos, false, true, 9, 9, 8, 8)
                for i = 1, #specs do
                    local player = specs[i]
                    player:say(skull.name .. " Jewel Skull!", TALKTYPE_MONSTER_SAY, false, player, pos)
                end
            end
            return
        end
    end
end

print(">> Loaded Jewel Skull Drop System")
