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

monster.health = 4000
monster.maxHealth = 4000
monster.race = "undead"
monster.corpse = 2000  -- Chest (ajusta al corpse correcto del skeleton en tu cliente)
monster.speed = 200
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

-- Skeleton King periodically summons Death Knights
monster.summon = {
	maxSummons = 4,
	summons = {
		{ name = "Death Knight", chance = 18, interval = 4000, count = 1 },
	},
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
	-- Melee with poison DoT
	{ name = "melee", interval = 2000, chance = 100, minDamage = -30, maxDamage = -90,
	  condition = { type = CONDITION_POISON, totalDamage = 60, interval = 4000 } },

	-- Death wave (frontal beam)
	{ name = "combat", interval = 5000, chance = 20, type = COMBAT_DEATHDAMAGE,
	  minDamage = -40, maxDamage = -90, length = 5, spread = 0,
	  effect = CONST_ME_MORTAREA, target = false },

	-- Bone shards (ranged physical bolts)
	{ name = "combat", interval = 4000, chance = 18, type = COMBAT_PHYSICALDAMAGE,
	  minDamage = -30, maxDamage = -60, range = 7,
	  shootEffect = CONST_ANI_BURSTARROW, effect = CONST_ME_EXPLOSIONAREA, target = true },

	-- Life drain
	{ name = "combat", interval = 6000, chance = 15, type = COMBAT_LIFEDRAIN,
	  minDamage = -30, maxDamage = -70, radius = 2,
	  effect = CONST_ME_MAGIC_RED, target = false },

	-- Paralyze slow
	{ name = "speed", interval = 8000, chance = 15, speed = -600,
	  range = 5, effect = CONST_ME_MAGIC_RED, target = false, duration = 8000 },
}

monster.defenses = {
	defense = 15,
	armor = 15,
	{ name = "combat", interval = 6000, chance = 15, type = COMBAT_HEALING,
	  minDamage = 50, maxDamage = 100, effect = CONST_ME_MAGIC_BLUE, target = false },
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
	"SkeletonKingHealthChange",
}

mType:register(monster)
