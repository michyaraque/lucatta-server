-- Skeleton King - Boss MonsterType
-- Arena: {x=148, y=51, z=7} to {x=162, y=70, z=7}

local mType = Game.createMonsterType("Skeleton King")
local monster = {}

monster.description = "the Skeleton King"
monster.experience = 5000
monster.outfit = {
	lookType = 3,   -- Skeleton look (adjust to correct lookType in your client)
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

monster.health = 2000
monster.maxHealth = 2000
monster.race = "undead"
monster.corpse = 2000  -- Chest (ajusta al corpse correcto del skeleton en tu cliente)
monster.speed = 220
monster.manaCost = 0

monster.changeTarget = {
	interval = 6000,
	chance = 12,
}

monster.strategiesTarget = {
	nearest = 60,
	health = 15,
	damage = 15,
	random = 10,
}

monster.flags = {
	summonable = false,
	attackable = true,
	hostile = true,
	convinceable = false,
	pushable = false,
	boss = true,
	illusionable = false,
	canPushItems = true,
	canPushCreatures = true,
	staticAttackChance = 85,
	targetDistance = 1,
	healthHidden = false,
	canWalkOnEnergy = false,
	canWalkOnFire = true,
	canWalkOnPoison = false,
}

monster.light = {
	level = 2,
	color = 215,
}

monster.voices = {
	interval = 8000,
	chance = 15,
	{ text = "I am eternal! You cannot kill what is already dead!", yell = true },
	{ text = "Bow before your King!", yell = false },
	{ text = "My warriors will feast on your bones!", yell = false },
	{ text = "The undead army is ENDLESS!", yell = true },
	{ text = "Your flesh will rot in my domain!", yell = false },
	{ text = "None shall leave this crypt alive!", yell = false },
	{ text = "You dare challenge the Skeleton King?!", yell = true },
	{ text = "Rise, my warriors! Protect your KING!", yell = true },
	{ text = "Death is only the beginning...", yell = false },
}

monster.loot = {
	-- El loot del cadáver es menor; el loot bueno va al cofre de recompensa.
	{ id = 92,   chance = 100000, maxCount = 100 },  -- Gold Coins
	{ id = 318,  chance = 50000,  maxCount = 3   },  -- Silver Bar
	{ id = 319,  chance = 25000,  maxCount = 1   },  -- Gold Bar
	{ id = 35,   chance = 60000,  maxCount = 3   },  -- Health Potion
	{ id = 155,  chance = 10000,  maxCount = 1   },  -- Skeleton Key
	{ id = 123,  chance = 5000,   maxCount = 1   },  -- Skeleton King's thoracic cage
}

monster.attacks = {
	-- Melee: heavy hit + poison DoT (phase 1 bread-and-butter)
	{ name = "melee", interval = 2000, chance = 100, minDamage = -30, maxDamage = -90,
	  condition = { type = CONDITION_POISON, totalDamage = 60, interval = 4000 } },

	-- Bone throw: frequent ranged pressure, forces movement
	{ name = "combat", interval = 3000, chance = 70, type = COMBAT_PHYSICALDAMAGE,
	  minDamage = -25, maxDamage = -55, range = 7,
	  shootEffect = 3, effect = CONST_ME_POFF, target = true },

	-- Death beam: telegraphed via onThink voice before engine fires it
	{ name = "combat", interval = 6000, chance = 18, type = COMBAT_DEATHDAMAGE,
	  minDamage = -50, maxDamage = -100, length = 6, spread = 0,
	  effect = CONST_ME_MORTAREA, target = false },

	-- Life drain ring: punishes standing still
	{ name = "combat", interval = 7000, chance = 15, type = COMBAT_LIFEDRAIN,
	  minDamage = -30, maxDamage = -65, radius = 2,
	  effect = CONST_ME_MAGIC_RED, target = false },
}

monster.defenses = {
	defense = 15,
	armor = 15,
	-- No passive healing: emergency heal is a scripted one-time event in phase 3 (skeleton_king_events.lua)
}

monster.elements = {
	{ type = COMBAT_PHYSICALDAMAGE, percent = 10 },
	{ type = COMBAT_ENERGYDAMAGE,   percent = 80 },
	{ type = COMBAT_EARTHDAMAGE,    percent = 100 },
	{ type = COMBAT_FIREDAMAGE,     percent = -20 },  -- weak to fire
	{ type = COMBAT_LIFEDRAIN,      percent = 100 },
	{ type = COMBAT_MANADRAIN,      percent = 0 },
	{ type = COMBAT_DROWNDAMAGE,    percent = 0 },
	{ type = COMBAT_ICEDAMAGE,      percent = 20 },
	{ type = COMBAT_HOLYDAMAGE,     percent = -30 },  -- weak to holy
	{ type = COMBAT_DEATHDAMAGE,    percent = 100 },
}

monster.immunities = {
	{ type = "paralyze",  condition = true },
	{ type = "outfit",    condition = false },
	{ type = "invisible", condition = true },
	{ type = "bleed",     condition = false },
	{ type = "poison",    condition = true },
}

monster.events = {
	"SkeletonKingThink",
	"SkeletonKingDeath",
}

mType:register(monster)
