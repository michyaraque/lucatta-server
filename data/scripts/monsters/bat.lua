

local mType = Game.createMonsterType("Bat")
local monster = {}

monster.name = "Bat"
monster.experience = 9
monster.outfit = {
  lookType = 1,
}
monster.health = 83
monster.maxHealth = 83
monster.race = "blood"
monster.speed = 180
monster.runHealth = 0
monster.changeTarget = {
  interval = 4000,
  chance = 20,
}
monster.flags = {
  attackable = true,
  hostile = true,
  targetDistance = 1,
}
monster.loot = {
  {id = 35, chance = 25000, maxCount = 1},
  {id = 63, chance = 15000, maxCount = 1},
  {id = 38, chance = 5000, maxCount = 1},
  {id = 74, chance = 20000, maxCount = 1},
  {id = 80, chance = 5000, maxCount = 1},
  {id = 85, chance = 5000, maxCount = 1},
  {id = 143, chance = 10000, maxCount = 1},
  {id = 92, chance = 15000, maxCount = 15},
}
monster.attacks = {
  {
    name = "melee",
    interval = 2000,
    minDamage = -5,
    maxDamage = 0
  },
  {
    name = "combat",
    type = COMBAT_LIFEDRAIN,
    chance = 20,
    interval = 2000,
    target = true,
    range = 1,
    minDamage = -3,
    maxDamage = -2,
    effect = 8
  },
}
monster.defenses = {
  defense = 2,
  armor = 2,
  {
    name = "combat",
    type = COMBAT_HEALING,
    chance = 15,
    interval = 2000,
    target = false,
    range = 0,
    minDamage = 3,
    maxDamage = 6,
    effect = 8
  },
}

mType:register(monster)
