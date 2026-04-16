

local mType = Game.createMonsterType("Death Knight")
local monster = {}

monster.name = "Death Knight"
monster.experience = 71
monster.outfit = {
  lookType = 10,
}
monster.health = 354
monster.maxHealth = 354
monster.race = "blood"
monster.speed = 210
monster.runHealth = 0
monster.flags = {
  attackable = true,
  hostile = true,
  targetDistance = 1,
}
monster.loot = {
  {id = 36, chance = 40000, maxCount = 1},
  {id = 81, chance = 5000, maxCount = 1},
  {id = 86, chance = 5000, maxCount = 1},
  {id = 112, chance = 2000, maxCount = 1},
  {id = 75, chance = 20000, maxCount = 1},
  {id = 146, chance = 5000, maxCount = 1},
  {id = 92, chance = 12000, maxCount = 22},
}
monster.attacks = {
  { name = "melee", interval = 2000, chance = 100, minDamage = -49, maxDamage = -16 },
  { name = "combat", interval = 5000, chance = 20, type = COMBAT_PHYSICALDAMAGE,
    minDamage = -30, maxDamage = -70, length = 3, spread = 3,
    effect = CONST_ME_HITAREA, target = false },
}
monster.defenses = {
  defense = 4,
  armor = 4,
}

mType:register(monster)
