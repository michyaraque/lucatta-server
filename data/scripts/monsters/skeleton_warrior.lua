

local mType = Game.createMonsterType("Skeleton Warrior")
local monster = {}

monster.name = "Skeleton Warrior"
monster.experience = 70
monster.outfit = {
  lookType = 34,
}
monster.health = 216
monster.maxHealth = 216
monster.race = "undead"
monster.speed = 138
monster.runHealth = 0
monster.changeTarget = {
  interval = 4000,
  chance = 30,
}
monster.flags = {
  attackable = true,
  hostile = true,
  targetDistance = 1,
}
monster.loot = {
  {id = 35, chance = 25000, maxCount = 1},
  {id = 24, chance = 10000, maxCount = 1},
  {id = 64, chance = 10000, maxCount = 1},
  {id = 38, chance = 5000, maxCount = 1},
  {id = 75, chance = 20000, maxCount = 1},
  {id = 81, chance = 2000, maxCount = 1},
  {id = 145, chance = 5000, maxCount = 1},
  {id = 92, chance = 12000, maxCount = 1},
}
monster.attacks = {
  { name = "melee", interval = 2000, chance = 100, minDamage = -40, maxDamage = -10 },
  { name = "combat", interval = 3000, chance = 15, type = COMBAT_LIFEDRAIN, minDamage = -20, maxDamage = -50, range = 1, effect = CONST_ME_MAGIC_RED, target = false },
  { name = "combat", interval = 4000, chance = 20, type = COMBAT_PHYSICALDAMAGE, minDamage = -25, maxDamage = -60, range = 5, shootEffect = CONST_ANI_SUDDENDEATH, effect = CONST_ME_MORTAREA, target = false },
}
monster.defenses = {
  defense = 18,
  armor = 14,
}
monster.elements = {
  { type = COMBAT_PHYSICALDAMAGE, percent = 0 },
  { type = COMBAT_HOLYDAMAGE, percent = -15 },
  { type = COMBAT_DEATHDAMAGE, percent = 100 },
  { type = COMBAT_FIREDAMAGE, percent = -5 },
  { type = COMBAT_ENERGYDAMAGE, percent = -5 },
}
monster.immunities = {
  { type = "paralyze", condition = false },
  { type = "invisible", condition = true },
}

mType:register(monster)
