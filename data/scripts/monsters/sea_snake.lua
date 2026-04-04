

local mType = Game.createMonsterType("Sea Snake")
local monster = {}

monster.name = "Sea Snake"
monster.experience = 1750
monster.outfit = {
  lookType = 47,
}
monster.health = 1545
monster.maxHealth = 1545
monster.speed = 180
monster.runHealth = 15
monster.flags = {
  attackable = true,
  hostile = true,
  targetDistance = 1,
}
monster.loot = {
  {id = 110, chance = 60000, maxCount = 1},
  {id = 91, chance = 3000, maxCount = 1},
  {id = 141, chance = 3000, maxCount = 1},
  {id = 76, chance = 4000, maxCount = 1},
  {id = 82, chance = 3000, maxCount = 1},
  {id = 113, chance = 2000, maxCount = 1},
  {id = 149, chance = 2000, maxCount = 1},
  {id = 150, chance = 2000, maxCount = 1},
  {id = 333, chance = 2000, maxCount = 1},
  {id = 92, chance = 60000, maxCount = 100},
}
monster.attacks = {
  {
    name = "melee",
    interval = 2000,
    minDamage = -110,
    maxDamage = -10
  },
  {
    name = "combat",
    type = COMBAT_ICEDAMAGE,
    chance = 22,
    interval = 2600,
    target = true,
    range = 4,
    minDamage = -179,
    maxDamage = -109,
    effect = 4,
    condition = {
      type = CONDITION_FREEZING,
      duration = 4000
    },
    duration = 4000,
    speed = -100
  },
}
monster.defenses = {
  defense = 37,
  armor = 26,
}
monster.elements = {
  {
    type = COMBAT_ICEDAMAGE,
    percent = 100
  },
}

mType:register(monster)
