

local mType = Game.createMonsterType("Spider")
local monster = {}

monster.name = "Spider"
monster.experience = 2934
monster.outfit = {
  lookType = 51,
}
monster.health = 2085
monster.maxHealth = 2085
monster.race = "venom"
monster.speed = 127
monster.runHealth = 25
monster.flags = {
  attackable = true,
  hostile = true,
  targetDistance = 1,
}
monster.loot = {
  {id = 110, chance = 20000, maxCount = 1},
  {id = 200, chance = 3000, maxCount = 1},
  {id = 209, chance = 2000, maxCount = 1},
  {id = 212, chance = 2000, maxCount = 1},
  {id = 111, chance = 10000, maxCount = 1},
  {id = 338, chance = 2000, maxCount = 1},
  {id = 156, chance = 2000, maxCount = 1},
  {id = 228, chance = 2000, maxCount = 1},
  {id = 197, chance = 2000, maxCount = 1},
  {id = 92, chance = 12000, maxCount = 10},
}
monster.attacks = {
  {
    name = "melee",
    interval = 2000,
    minDamage = -320,
    maxDamage = 0
  },
}
monster.defenses = {
  defense = 29,
  armor = 29,
}
monster.elements = {
  {
    type = COMBAT_EARTHDAMAGE,
    percent = 100
  },
}

mType:register(monster)
