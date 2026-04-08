local mType = Game.createMonsterType("Rat")
local monster = {}

monster.name = "Rat"
monster.experience = 1000
monster.outfit = {
  lookType = 29,
}
monster.corpse = 37
monster.health = 23
monster.maxHealth = 23
monster.race = "blood"
monster.speed = 150
monster.runHealth = 5
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
  {id = 35, chance = 40000, maxCount = 1},
  {id = 38, chance = 5000, maxCount = 1},
  {id = 74, chance = 20000, maxCount = 1},
  {id = 80, chance = 5000, maxCount = 1},
  {id = 92, chance = 100000, maxCount = 5},
  {id = 61, chance = 100000, maxCount = 1},
  {id = 128, chance = 100000, maxCount = 1},
}
monster.attacks = {
  {
    name = "combat",
    type = COMBAT_PHYSICALDAMAGE,
    chance = 100,
    interval = 2000,
    target = true,
    range = 1,
    minDamage = -3,
    maxDamage = -1,
    effect = 8
  },
}
monster.defenses = {
  defense = 1,
  armor = 1,
}

mType:register(monster)
