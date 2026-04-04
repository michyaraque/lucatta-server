

local mType = Game.createMonsterType("Vampire Bat")
local monster = {}

monster.name = "Vampire Bat"
monster.experience = 400
monster.outfit = {
  lookType = 2,
}
monster.health = 450
monster.maxHealth = 450
monster.speed = 200
monster.runHealth = 0
monster.flags = {
  attackable = true,
  hostile = true,
  targetDistance = 1,
}
monster.loot = {
  {id = 110, chance = 5000, maxCount = 1},
  {id = 77, chance = 5000, maxCount = 1},
  {id = 331, chance = 5000, maxCount = 1},
  {id = 91, chance = 3000, maxCount = 1},
  {id = 76, chance = 4000, maxCount = 1},
  {id = 148, chance = 3000, maxCount = 1},
  {id = 92, chance = 82000, maxCount = 26},
}
monster.attacks = {
  {
    name = "melee",
    interval = 2000,
    minDamage = -50,
    maxDamage = -10
  },
}
monster.defenses = {
  defense = 7,
  armor = 7,
}

mType:register(monster)
