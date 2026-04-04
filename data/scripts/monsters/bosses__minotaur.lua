

-- Source monster callbacks still need a dedicated Lua port.
local mType = Game.createMonsterType("Minotaur")
local monster = {}

monster.name = "Minotaur"
monster.experience = 10223
monster.outfit = {
  lookType = 25,
}
monster.health = 17769
monster.maxHealth = 17769
monster.race = "blood"
monster.speed = 82
monster.runHealth = 0
monster.flags = {
  attackable = true,
  hostile = true,
  targetDistance = 1,
  boss = true,
}
monster.loot = {
  {id = 132, chance = 12000, maxCount = 1},
  {id = 142, chance = 5000, maxCount = 1},
  {id = 133, chance = 10000, maxCount = 1},
  {id = 134, chance = 10000, maxCount = 1},
  {id = 200, chance = 47000, maxCount = 1},
}
monster.attacks = {
  {
    name = "melee",
    interval = 2000,
    minDamage = -39,
    maxDamage = 0
  },
}
monster.defenses = {
  defense = 32,
  armor = 32,
}
monster.elements = {
  {
    type = COMBAT_ENERGYDAMAGE,
    percent = 80
  },
  {
    type = COMBAT_FIREDAMAGE,
    percent = 100
  },
  {
    type = COMBAT_ENERGYDAMAGE,
    percent = 100
  },
}

mType:register(monster)
