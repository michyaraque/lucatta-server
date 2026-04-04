

local mType = Game.createMonsterType("Damned Snake")
local monster = {}

monster.name = "Damned Snake"
monster.experience = 2434
monster.outfit = {
  lookType = 49,
}
monster.health = 1361
monster.maxHealth = 1361
monster.race = "blood"
monster.speed = 72
monster.runHealth = 25
monster.flags = {
  attackable = true,
  hostile = true,
  targetDistance = 1,
}
monster.loot = {
  {id = 110, chance = 20000, maxCount = 1},
  {id = 200, chance = 3000, maxCount = 2},
  {id = 209, chance = 5000, maxCount = 1},
  {id = 212, chance = 5000, maxCount = 1},
  {id = 154, chance = 1000, maxCount = 1},
  {id = 336, chance = 1000, maxCount = 1},
  {id = 195, chance = 1000, maxCount = 1},
  {id = 338, chance = 1000, maxCount = 1},
  {id = 156, chance = 1000, maxCount = 1},
  {id = 228, chance = 1000, maxCount = 1},
  {id = 197, chance = 1000, maxCount = 1},
  {id = 92, chance = 10000, maxCount = 100},
}
monster.attacks = {
  {
    name = "melee",
    interval = 2000,
    minDamage = -31,
    maxDamage = 0
  },
}
monster.defenses = {
  defense = 24,
  armor = 24,
}
monster.elements = {
  {
    type = COMBAT_FIREDAMAGE,
    percent = 100
  },
}

mType:register(monster)
