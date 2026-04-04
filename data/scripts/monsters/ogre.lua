

local mType = Game.createMonsterType("Ogre")
local monster = {}

monster.name = "Ogre"
monster.experience = 32
monster.outfit = {
  lookType = 28,
}
monster.health = 270
monster.maxHealth = 270
monster.race = "blood"
monster.speed = 180
monster.runHealth = 0
monster.flags = {
  attackable = true,
  hostile = true,
  targetDistance = 1,
}
monster.loot = {
  {id = 35, chance = 25000, maxCount = 1},
  {id = 328, chance = 10000, maxCount = 1},
  {id = 24, chance = 10000, maxCount = 1},
  {id = 38, chance = 5000, maxCount = 1},
  {id = 75, chance = 20000, maxCount = 1},
  {id = 80, chance = 5000, maxCount = 1},
  {id = 81, chance = 2000, maxCount = 1},
  {id = 145, chance = 5000, maxCount = 1},
  {id = 92, chance = 15000, maxCount = 24},
}
monster.attacks = {
  {
    name = "melee",
    interval = 2000,
    minDamage = -30,
    maxDamage = 0
  },
}
monster.defenses = {
  defense = 3,
  armor = 3,
}

mType:register(monster)
