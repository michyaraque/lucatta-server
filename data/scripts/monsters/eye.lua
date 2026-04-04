

local mType = Game.createMonsterType("Eye")
local monster = {}

monster.name = "Eye"
monster.experience = 43
monster.outfit = {
  lookType = 12,
}
monster.health = 251
monster.maxHealth = 251
monster.race = "blood"
monster.speed = 122
monster.runHealth = 0
monster.changeTarget = {
  interval = 4000,
  chance = 8,
}
monster.flags = {
  attackable = true,
  hostile = true,
  targetDistance = 1,
}
monster.loot = {
  {id = 35, chance = 25000, maxCount = 1},
  {id = 329, chance = 8000, maxCount = 1},
  {id = 25, chance = 8000, maxCount = 1},
  {id = 38, chance = 5000, maxCount = 1},
  {id = 75, chance = 20000, maxCount = 1},
  {id = 86, chance = 3000, maxCount = 1},
  {id = 112, chance = 2000, maxCount = 1},
  {id = 146, chance = 5000, maxCount = 1},
  {id = 92, chance = 12000, maxCount = 30},
}
monster.attacks = {
  {
    name = "melee",
    interval = 2000,
    minDamage = -14,
    maxDamage = 0
  },
}
monster.defenses = {
  defense = 4,
  armor = 4,
}

mType:register(monster)
