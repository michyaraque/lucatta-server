

local mType = Game.createMonsterType("Crab")
local monster = {}

monster.name = "Crab"
monster.experience = 4
monster.outfit = {
  lookType = 7,
}
monster.health = 73
monster.maxHealth = 73
monster.race = "blood"
monster.speed = 183
monster.runHealth = 0
monster.changeTarget = {
  interval = 4000,
  chance = 10,
}
monster.flags = {
  attackable = true,
  hostile = true,
  targetDistance = 1,
}
monster.loot = {
  {id = 35, chance = 20000, maxCount = 1},
  {id = 63, chance = 10000, maxCount = 1},
  {id = 143, chance = 5000, maxCount = 1},
  {id = 22, chance = 10000, maxCount = 1},
  {id = 38, chance = 5000, maxCount = 1},
  {id = 74, chance = 20000, maxCount = 1},
  {id = 80, chance = 5000, maxCount = 1},
  {id = 85, chance = 10000, maxCount = 1},
  {id = 92, chance = 15000, maxCount = 1},
}
monster.attacks = {
  {
    name = "melee",
    interval = 2000,
    minDamage = -6,
    maxDamage = 0
  },
}
monster.defenses = {
  defense = 2,
  armor = 2,
}

mType:register(monster)
