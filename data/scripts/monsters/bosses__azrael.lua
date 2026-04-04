

-- Source monster callbacks still need a dedicated Lua port.
local mType = Game.createMonsterType("Azrael")
local monster = {}

monster.name = "Azrael"
monster.experience = 87596
monster.outfit = {
  lookType = 8,
}
monster.health = 39646
monster.maxHealth = 39646
monster.race = "undead"
monster.speed = 73
monster.runHealth = 0
monster.flags = {
  attackable = true,
  hostile = true,
  targetDistance = 1,
  boss = true,
}
monster.loot = {
  {id = 324, chance = 20000, maxCount = 1},
  {id = 200, chance = 38000, maxCount = 1},
  {id = 206, chance = 20000, maxCount = 1},
  {id = 158, chance = 5000, maxCount = 1},
  {id = 401, chance = 5000, maxCount = 1},
  {id = 341, chance = 5000, maxCount = 1},
  {id = 242, chance = 5000, maxCount = 1},
  {id = 202, chance = 5000, maxCount = 1},
  {id = 196, chance = 5000, maxCount = 1},
  {id = 214, chance = 2000, maxCount = 1},
  {id = 398, chance = 1000, maxCount = 1},
}
monster.attacks = {
  {
    name = "melee",
    interval = 2000,
    minDamage = -3951,
    maxDamage = -637
  },
}
monster.defenses = {
  defense = 306,
  armor = 44,
}
monster.elements = {
  {
    type = COMBAT_ENERGYDAMAGE,
    percent = 100
  },
  {
    type = COMBAT_FIREDAMAGE,
    percent = 100
  },
  {
    type = COMBAT_ENERGYDAMAGE,
    percent = 100
  },
  {
    type = COMBAT_ICEDAMAGE,
    percent = 100
  },
  {
    type = COMBAT_EARTHDAMAGE,
    percent = 100
  },
}

mType:register(monster)
