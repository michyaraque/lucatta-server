JEWEL_SKULL_CONFIG = {
    -- dropChance: 1 en X (ej: 100 = 1/100 = 1% de probabilidad)
    SKULLS = {
        [1] = {
            id = 1000,
            name = "Common",
            minMonsterLevel = 1,
            maxMonsterLevel = 10,
            dropChance = 100,        -- 1/100 = 1%
            minAttributes = 1,
            maxAttributes = 1,
            valueMultiplier = 0.25
        },
        [2] = {
            id = 1001,
            name = "Uncommon",
            minMonsterLevel = 25,
            dropChance = 125,        -- 1/125 = 0.8%
            minAttributes = 1,
            maxAttributes = 2,
            valueMultiplier = 0.5
        },
        [3] = {
            id = 1002,
            name = "Rare",
            minMonsterLevel = 50,
            dropChance = 200,        -- 1/200 = 0.5%
            minAttributes = 1,
            maxAttributes = 3,
            valueMultiplier = 0.75
        },
        [4] = {
            id = 1003,
            name = "Epic",
            minMonsterLevel = 70,
            dropChance = 400,        -- 1/400 = 0.25%
            minAttributes = 2,
            maxAttributes = 4,
            valueMultiplier = 1
        },
        [5] = {
            id = 1004,
            name = "Legendary",
            minMonsterLevel = 100,
            dropChance = 100,       -- 1/1000 = 0.1%
            minAttributes = 2,
            maxAttributes = 5,
            valueMultiplier = 1.25,
            execute = function(player)
                Discord.sendDropMessage(string.format("**%s** found a lv.5 Jewel Skull %s", player:getName(), Discord.Emojis.SkullLegendary))
            end
        }
    },
    RARITY_BY_ID = {},
    SKULL_EXTRACTOR_ID = 1683
}

for rarity, skull in pairs(JEWEL_SKULL_CONFIG.SKULLS) do
    JEWEL_SKULL_CONFIG.RARITY_BY_ID[skull.id] = rarity
end

JEWEL_SKULL_ENCHANTMENTS = nil

function initJewelSkullEnchantments()
    if JEWEL_SKULL_ENCHANTMENTS then return end
    if not US_ENCHANTMENTS then return end

    JEWEL_SKULL_ENCHANTMENTS = {}
    for i = 1, #US_ENCHANTMENTS do
        local enchant = US_ENCHANTMENTS[i]
        if enchant and enchant.itemType then
            if bit.band(enchant.itemType, US_ITEM_TYPES.ALL) ~= 0 or
               bit.band(enchant.itemType, US_ITEM_TYPES.WEAPON_MELEE) ~= 0 or
               bit.band(enchant.itemType, US_ITEM_TYPES.WEAPON_DISTANCE) ~= 0 or
               bit.band(enchant.itemType, US_ITEM_TYPES.WEAPON_WAND) ~= 0 or
               bit.band(enchant.itemType, US_ITEM_TYPES.SHIELD) ~= 0 or
               bit.band(enchant.itemType, US_ITEM_TYPES.HELMET) ~= 0 or
               bit.band(enchant.itemType, US_ITEM_TYPES.ARMOR) ~= 0 or
               bit.band(enchant.itemType, US_ITEM_TYPES.LEGS) ~= 0 or
               bit.band(enchant.itemType, US_ITEM_TYPES.BOOTS) ~= 0 or
               bit.band(enchant.itemType, US_ITEM_TYPES.NECKLACE) ~= 0 or
               bit.band(enchant.itemType, US_ITEM_TYPES.RING) ~= 0 then
                table.insert(JEWEL_SKULL_ENCHANTMENTS, i)
            end
        end
    end
    print(">> Jewel Skull Enchantments initialized with " .. #JEWEL_SKULL_ENCHANTMENTS .. " enchantments")
end

print(">> Loaded Jewel Skull Config")
