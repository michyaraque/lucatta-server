

local mType = Game.createMonsterType("Skeleton Commander")
local monster = {}

monster.name = "Skeleton Commander"
monster.experience = 2500
monster.outfit = {
  lookType = 42,
}
monster.health = 3000
monster.maxHealth = 3000
monster.race = "blood"
monster.speed = 200
monster.runHealth = 0
monster.changeTarget = {
  interval = 5000,
  chance = 0,
}
monster.flags = {
  attackable = true,
  hostile = true,
  targetDistance = 1,
  boss = true,
}
monster.loot = {
  {id = 76, chance = 6000, maxCount = 2},
  {id = 141, chance = 3000, maxCount = 1},
  {id = 332, chance = 3000, maxCount = 1},
  {id = 83, chance = 5000, maxCount = 1},
  {id = 82, chance = 4000, maxCount = 1},
  {id = 113, chance = 4000, maxCount = 1},
  {id = 149, chance = 4000, maxCount = 1},
}
monster.attacks = {
  {
    name = "melee",
    interval = 2000,
    minDamage = -130,
    maxDamage = -40
  },
}
monster.defenses = {
  defense = 13,
  armor = 13,
}

mType:register(monster)
