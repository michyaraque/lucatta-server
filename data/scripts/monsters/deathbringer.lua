

local mType = Game.createMonsterType("Death Bringer")
local monster = {}

monster.name = "Death Bringer"
monster.experience = 26793
monster.outfit = {
  lookType = 9,
}
monster.health = 12296
monster.maxHealth = 12296
monster.race = "blood"
monster.speed = 61
monster.runHealth = 0
monster.flags = {
  attackable = true,
  hostile = true,
  targetDistance = 1,
}
monster.loot = {
  {id = 200, chance = 380, maxCount = 1},
}
monster.attacks = {
  {
    name = "melee",
    interval = 2000,
    minDamage = -1834,
    maxDamage = -245
  },
}
monster.defenses = {
  defense = 43,
  armor = 43,
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
