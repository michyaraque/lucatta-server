

local mType = Game.createMonsterType("Spectre")
local monster = {}

monster.name = "Spectre"
monster.experience = 58
monster.outfit = {
  lookType = 50,
}
monster.health = 500
monster.maxHealth = 500
monster.race = "undead"
monster.speed = 310
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
  {id = 35, chance = 25000, maxCount = 1},
  {id = 65, chance = 15000, maxCount = 1},
  {id = 38, chance = 5000, maxCount = 1},
  {id = 75, chance = 20000, maxCount = 1},
  {id = 81, chance = 4000, maxCount = 1},
  {id = 86, chance = 3000, maxCount = 1},
  {id = 112, chance = 2000, maxCount = 1},
  {id = 146, chance = 5000, maxCount = 1},
  {id = 92, chance = 12000, maxCount = 19},
}
monster.attacks = {
	{ name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = -30 },
	{ name = "combat", interval = 2000, chance = 20, type = COMBAT_PHYSICALDAMAGE, minDamage = 0, maxDamage = -55, range = 7, shootEffect = CONST_ANI_SUDDENDEATH, effect = CONST_ME_MORTAREA, target = false },
	{ name = "combat", interval = 2000, chance = 10, type = COMBAT_DEATHDAMAGE, minDamage = -20, maxDamage = -720, length = 8, spread = 0, effect = CONST_ME_MORTAREA, target = false },
	{ name = "combat", interval = 2000, chance = 15, type = COMBAT_PHYSICALDAMAGE, minDamage = 0, maxDamage = -30, length = 7, spread = 0, effect = CONST_ME_EXPLOSIONAREA, target = false },
	{ name = "combat", interval = 2000, chance = 10, type = COMBAT_DEATHDAMAGE, minDamage = -15, maxDamage = -35, radius = 4, effect = CONST_ME_MORTAREA, target = false },
}

monster.defenses = {
	defense = 35,
	armor = 30,
	mitigation = 0.64,
	{ name = "combat", interval = 2000, chance = 15, type = COMBAT_HEALING, minDamage = 130, maxDamage = 205, target = false },
	{ name = "speed", interval = 2000, chance = 15, speed = 450, effect = CONST_ME_MAGIC_RED, target = false, duration = 5000 },
}

mType:register(monster)
