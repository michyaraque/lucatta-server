

local mType = Game.createMonsterType("Undead Goblin")
local monster = {}

monster.name = "Undead Goblin"
monster.experience = 600
monster.outfit = {
  lookType = 15,
}
monster.health = 600
monster.maxHealth = 600
monster.race = "blood"
monster.speed = 210
monster.runHealth = 0
monster.flags = {
  attackable = true,
  hostile = true,
  targetDistance = 1,
}
monster.loot = {
  {id = 110, chance = 50000, maxCount = 1},
  {id = 77, chance = 5000, maxCount = 1},
  {id = 331, chance = 5000, maxCount = 1},
  {id = 91, chance = 5000, maxCount = 1},
  {id = 76, chance = 4000, maxCount = 1},
  {id = 113, chance = 1000, maxCount = 1},
  {id = 148, chance = 3000, maxCount = 1},
  {id = 92, chance = 82000, maxCount = 24},
}
monster.attacks = {
  {
    name = "melee",
    interval = 2000,
    minDamage = -90,
    maxDamage = -15
  },
}
monster.defenses = {
  defense = 17,
  armor = 6,
}

mType:register(monster)
