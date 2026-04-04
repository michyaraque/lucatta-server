

local mType = Game.createMonsterType("Poison Rat")
local monster = {}

monster.name = "Poison Rat"
monster.experience = 161
monster.outfit = {
  lookType = 31,
}
monster.health = 924
monster.maxHealth = 924
monster.race = "venom"
monster.speed = 209
monster.runHealth = 0
monster.flags = {
  attackable = true,
  hostile = true,
  targetDistance = 1,
}
monster.loot = {
  {id = 289, chance = 5000, maxCount = 1},
  {id = 110, chance = 25000, maxCount = 1},
  {id = 111, chance = 25000, maxCount = 1},
  {id = 200, chance = 2000, maxCount = 1},
  {id = 212, chance = 2000, maxCount = 1},
  {id = 209, chance = 2000, maxCount = 1},
  {id = 335, chance = 2000, maxCount = 1},
  {id = 152, chance = 2000, maxCount = 1},
  {id = 128, chance = 2000, maxCount = 1},
  {id = 201, chance = 2000, maxCount = 1},
  {id = 199, chance = 2000, maxCount = 1},
  {id = 92, chance = 10000, maxCount = 100},
}
monster.attacks = {
  {
    name = "melee",
    interval = 2000,
    minDamage = -92,
    maxDamage = 0
  },
}
monster.defenses = {
  defense = 19,
  armor = 19,
}
monster.elements = {
  {
    type = COMBAT_EARTHDAMAGE,
    percent = 100
  },
}

mType:register(monster)
