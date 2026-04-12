

local mType = Game.createMonsterType("Skeleton")
local monster = {}

monster.name = "Skeleton"
monster.experience = 17
monster.outfit = {
  lookType = 33,
}
monster.health = 138
monster.maxHealth = 138
monster.race = "undead"
monster.speed = 157
monster.runHealth = 0
monster.changeTarget = {
  interval = 5000,
  chance = 0,
}
monster.flags = {
  attackable = true,
  hostile = true,
  targetDistance = 1,
}
monster.loot = {
  {id = 35, chance = 10000, maxCount = 1},
  {id = 23, chance = 8000, maxCount = 1},
  {id = 327, chance = 8000, maxCount = 1},
  {id = 63, chance = 12000, maxCount = 1},
  {id = 38, chance = 5000, maxCount = 1},
  {id = 75, chance = 20000, maxCount = 1},
  {id = 80, chance = 5000, maxCount = 1},
  {id = 144, chance = 5000, maxCount = 1},
  {id = 92, chance = 45000, maxCount = 18},
}
monster.attacks = {
  {
    name = "melee",
    interval = 1300,
    minDamage = -11,
    maxDamage = 0
  },
}
monster.defenses = {
  defense = 2,
  armor = 2,
}

mType:register(monster)
