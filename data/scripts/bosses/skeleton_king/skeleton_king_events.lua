-- Skeleton King - Boss Events
-- Arena: {x=148, y=51, z=7} to {x=162, y=70, z=7}

local ARENA = {
	from = Position(148, 51, 7),
	to   = Position(162, 70, 7),
}

local STORAGE = {
	phase         = 66100,  -- current phase (1=normal, 2=enraged <50%, 3=desperate <20%)
	waveSpawned   = 66101,  -- tick counter for periodic reinforcements
	spawning      = 66102,  -- prevent overlapping summon bursts
	spawned       = 66103,  -- 0 = not yet spawned intro, 1 = intro done
	noHitTicks    = 66104,  -- ticks without damage (for boss reset)
	lastHp        = 66105,  -- HP at previous tick (to detect if anyone is hitting)
}

-- Ticks (~1s each) with no HP change before the boss resets
local BOSS_RESET_TICKS = 45
-- Seconds the reward chest stays before disappearing
local CHEST_DECAY_SECS = 45

-- Last target ID greeted — shout once per new target
local lastGreetedTarget = 0

-- Spawn positions across the arena floor
local SPAWN_POSITIONS = {
	Position(149, 53, 7), Position(161, 53, 7),
	Position(149, 68, 7), Position(161, 68, 7),
	Position(155, 61, 7), Position(152, 57, 7),
	Position(158, 57, 7), Position(152, 65, 7),
	Position(158, 65, 7),
}

local function getArenaPlayers(bossPos)
	local spectators = Game.getSpectators(bossPos, false, true, 8, 8, 10, 10)
	local players = {}
	for _, spec in ipairs(spectators) do
		if spec:isPlayer() then
			local pos = spec:getPosition()
			if pos.x >= ARENA.from.x and pos.x <= ARENA.to.x
			and pos.y >= ARENA.from.y and pos.y <= ARENA.to.y
			and pos.z == ARENA.from.z then
				players[#players + 1] = spec
			end
		end
	end
	return players
end

local function broadcastToArena(players, msg)
	for _, player in ipairs(players) do
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, msg)
	end
end

local function cleanArena(bossPos)
	local creatures = Game.getSpectators(bossPos, false, false, 9, 9, 11, 11)
	for _, creature in ipairs(creatures) do
		if creature:isMonster() and creature:getName():lower() == "death knight" then
			creature:getPosition():sendMagicEffect(CONST_ME_MORTAREA)
			creature:remove()
		end
	end
end

local function spawnWarriorWave(boss, count)
	if boss:getStorageValue(STORAGE.spawning) == 1 then
		return
	end
	boss:setStorageValue(STORAGE.spawning, 1)

	local spawned = 0
	for _, pos in ipairs(SPAWN_POSITIONS) do
		if spawned >= count then break end
		local warrior = Game.createMonster("Death Knight", pos, false, true)
		if warrior then
			pos:sendMagicEffect(CONST_ME_MORTAREA)
			spawned = spawned + 1
		end
	end

	addEvent(function(cid)
		local b = Creature(cid)
		if b then
			b:setStorageValue(STORAGE.spawning, 0)
		end
	end, 5000, boss:getId())
end

local function resetBoss(boss)
	local bossPos = boss:getPosition()
	broadcastToArena(getArenaPlayers(bossPos),
		"The Skeleton King grows weary of waiting... his bones crumble to dust. He will return.")
	bossPos:sendMagicEffect(CONST_ME_MORTAREA)
	cleanArena(bossPos)
	lastGreetedTarget = 0
	boss:remove()
end

-- ============================================================
--  onThink  -  intro + phases + boss reset
-- ============================================================
local skeletonKingThink = CreatureEvent("SkeletonKingThink")

function skeletonKingThink.onThink(boss, interval)
	if not boss or not boss:isMonster() then
		return true
	end

	-- ── Intro: first tick after spawn ─────────────────────────
	if boss:getStorageValue(STORAGE.spawned) ~= 1 then
		boss:setStorageValue(STORAGE.spawned,     1)
		boss:setStorageValue(STORAGE.phase,       1)
		boss:setStorageValue(STORAGE.waveSpawned, 0)
		boss:setStorageValue(STORAGE.spawning,    0)
		boss:setStorageValue(STORAGE.noHitTicks,  0)
		boss:setStorageValue(STORAGE.lastHp,      boss:getHealth())
		lastGreetedTarget = 0

		boss:say("FOOLS! You dare enter my crypt?! GUARDS — RISE!", TALKTYPE_MONSTER_YELL)
		boss:getPosition():sendMagicEffect(CONST_ME_MORTAREA)

		addEvent(function(cid)
			local b = Creature(cid)
			if not b then return end
			spawnWarriorWave(b, 3)
		end, 1500, boss:getId())

		return true
	end

	local currentHp = boss:getHealth()
	local hpPct     = (currentHp / boss:getMaxHealth()) * 100
	local phase     = boss:getStorageValue(STORAGE.phase)

	-- ── Shout on new target ────────────────────────────────────
	local target = boss:getTarget()
	if target and target:isPlayer() then
		local tid = target:getId()
		if tid ~= lastGreetedTarget then
			lastGreetedTarget = tid
			local greets = {
				"So, another fool dares to face me... " .. target:getName() .. "!",
				target:getName() .. "! Your bones will decorate my throne!",
				"INTRUDER! " .. target:getName() .. ", you will SUFFER!",
				"Ah, " .. target:getName() .. "... I've been expecting you. Die!",
			}
			boss:say(greets[math.random(#greets)], TALKTYPE_MONSTER_YELL)
		end
	end

	-- ── Boss reset: HP unchanged for BOSS_RESET_TICKS ─────────
	-- Detects inactivity without needing onHealthChange at all.
	local lastHp = boss:getStorageValue(STORAGE.lastHp)
	if currentHp == lastHp then
		local noHitTicks = boss:getStorageValue(STORAGE.noHitTicks) + 1
		boss:setStorageValue(STORAGE.noHitTicks, noHitTicks)
		if noHitTicks >= BOSS_RESET_TICKS then
			resetBoss(boss)
			return true
		end
	else
		boss:setStorageValue(STORAGE.noHitTicks, 0)
		boss:setStorageValue(STORAGE.lastHp, currentHp)
	end

	local bossPos     = boss:getPosition()
	local arenaPlayers = getArenaPlayers(bossPos)

	-- ── Phase 2: Enraged (below 50%) ──────────────────────────
	if hpPct <= 50 and phase < 2 then
		boss:setStorageValue(STORAGE.phase, 2)
		boss:setStorageValue(STORAGE.waveSpawned, 0)

		boss:say("ENOUGH! Feel the WRATH of the undead legion!", TALKTYPE_MONSTER_YELL)
		bossPos:sendMagicEffect(CONST_ME_MAGIC_RED)
		spawnWarriorWave(boss, 5)

		addEvent(function(cid)
			local b = Creature(cid)
			if not b then return end
			b:say("My bones grow stronger from your futile attacks!", TALKTYPE_MONSTER_SAY)
		end, 2000, boss:getId())
	end

	-- ── Phase 3: Desperate (below 20%) ────────────────────────
	if hpPct <= 20 and phase < 3 then
		boss:setStorageValue(STORAGE.phase, 3)

		boss:say("I CANNOT DIE! RISE, MY ETERNAL WARRIORS! RIIISE!", TALKTYPE_MONSTER_YELL)
		bossPos:sendMagicEffect(CONST_ME_MORTAREA)
		broadcastToArena(arenaPlayers,
			"The Skeleton King lets out a bone-chilling scream as his body begins to glow!")
		spawnWarriorWave(boss, 8)

		addEvent(function(cid)
			local b = Creature(cid)
			if not b then return end
			b:addHealth(400)
			b:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
			b:say("The dark energy mends my bones... I am INVINCIBLE!", TALKTYPE_MONSTER_YELL)
		end, 3000, boss:getId())
	end

	-- ── Periodic reinforcements (every ~30s in phases 2/3) ────
	if phase >= 2 then
		local tick = boss:getStorageValue(STORAGE.waveSpawned) + 1
		if tick >= 30 then
			boss:setStorageValue(STORAGE.waveSpawned, 0)
			spawnWarriorWave(boss, (phase == 3) and 4 or 2)
			boss:say("More warriors to serve their King!", TALKTYPE_MONSTER_SAY)
		else
			boss:setStorageValue(STORAGE.waveSpawned, tick)
		end
	end

	-- ── Below 35%: random curse message ───────────────────────
	if hpPct <= 35 and math.random(1, 100) <= 8 then
		if #arenaPlayers > 0 then
			local cursed = arenaPlayers[math.random(#arenaPlayers)]
			cursed:sendTextMessage(MESSAGE_EVENT_ADVANCE,
				"The Skeleton King points a bony finger at you — you feel a deathly curse spreading through your veins!")
			boss:say("You... CURSED!", TALKTYPE_MONSTER_YELL)
		end
	end

	return true
end

skeletonKingThink:register()

-- ============================================================
--  Reward loot pool
-- ============================================================
local REWARD_LOOT = {
	-- Currency
	{ id = 92,   chance = 100000, maxCount = 200 },  -- Gold Coins

	-- Consumables
	{ id = 35,   chance = 80000,  maxCount = 5   },  -- Health Potion
	{ id = 110,  chance = 70000,  maxCount = 5   },  -- Rejuvenation Potion

	-- Mid-tier armor/weapons (common)
	{ id = 328,  chance = 35000,  maxCount = 1   },  -- Plate Helmet
	{ id = 24,   chance = 30000,  maxCount = 1   },  -- Plate Armor
	{ id = 145,  chance = 30000,  maxCount = 1   },  -- Plate Shield
	{ id = 65,   chance = 25000,  maxCount = 1   },  -- Red Sword
	{ id = 62,   chance = 25000,  maxCount = 1   },  -- Morning Star

	-- Upgrade materials
	{ id = 74,   chance = 15000,  maxCount = 1   },  -- Upgrade Scroll
	{ id = 192,  chance = 10000,  maxCount = 1   },  -- Socket Stone

	-- Boss-specific / rare
	{ id = 123,  chance = 8000,   maxCount = 1   },  -- Skeleton King's thoracic cage
	{ id = 155,  chance = 6000,   maxCount = 1   },  -- Skeleton Key
	{ id = 249,  chance = 4000,   maxCount = 1   },  -- Soul Stone
	{ id = 76,   chance = 3000,   maxCount = 1   },  -- Superior Upgrade Scroll
	{ id = 1002, chance = 2000,   maxCount = 1   },  -- Rare Jewel Skull
	{ id = 209,  chance = 1500,   maxCount = 1   },  -- Platinum Ring

}

local CHEST_POS    = Position(155, 60, 7)
local CHEST_ITEMID = 2000
local MIN_SHARE    = 0.01

local function rollLootIntoContainer(container, shareMultiplier)
	local rolls = math.max(1, math.floor(shareMultiplier * 3 + 0.5))
	for _ = 1, rolls do
		for _, entry in ipairs(REWARD_LOOT) do
			local adjustedChance = math.floor(entry.chance * math.min(shareMultiplier * 2, 1))
			if math.random(1, 100000) <= adjustedChance then
				local count = entry.maxCount > 1 and math.random(1, entry.maxCount) or 1
				container:addItem(entry.id, count)
			end
		end
	end
end

local function buildRewardChest(boss, bossPos)
	local damageMap   = boss:getDamageMap()
	local participants = {}
	local totalDamage  = 0

	for creatureId, data in pairs(damageMap) do
		local creature = Creature(creatureId)
		if creature and creature:isPlayer() then
			local dmg = data.total or 0
			if dmg > 0 then
				participants[#participants + 1] = { player = creature, damage = dmg }
				totalDamage = totalDamage + dmg
			end
		end
	end

	if #participants == 0 or totalDamage == 0 then
		return
	end

	local chest = Game.createItem(CHEST_ITEMID, 1, CHEST_POS)
	if not chest then
		return
	end

	chest:setAttribute(ITEM_ATTRIBUTE_DURATION, CHEST_DECAY_SECS)
	chest:decay()

	local rewarded = 0
	for _, entry in ipairs(participants) do
		local share = entry.damage / totalDamage
		if share >= MIN_SHARE then
			local bag = Game.createItem(ITEM_BAG, 1)
			if bag then
				bag:setAttribute(ITEM_ATTRIBUTE_DESCRIPTION,
					("Reward for %s (%.1f%% damage)"):format(
						entry.player:getName(), share * 100))
				rollLootIntoContainer(bag, share)
				chest:addItemEx(bag)
				rewarded = rewarded + 1

				entry.player:sendTextMessage(MESSAGE_EVENT_ADVANCE,
					("Your reward bag is in the chest at the center of the arena! "
					.. "(%.1f%% damage — chest disappears in %d seconds)"):format(
						share * 100, CHEST_DECAY_SECS))
			end
		end
	end

	if rewarded > 0 then
		CHEST_POS:sendMagicEffect(CONST_ME_MAGIC_BLUE)
		CHEST_POS:sendMagicEffect(CONST_ME_TELEPORT)
	end
end

-- ============================================================
--  onDeath
-- ============================================================
local skeletonKingDeath = CreatureEvent("SkeletonKingDeath")

function skeletonKingDeath.onDeath(boss, corpse, killer, mostDamageKiller, lastHitUnjustified, mostDamageUnjustified)
	local bossPos = corpse:getPosition()

	bossPos:sendMagicEffect(CONST_ME_MORTAREA)
	addEvent(function() bossPos:sendMagicEffect(CONST_ME_MAGIC_BLUE) end, 500)
	addEvent(function() bossPos:sendMagicEffect(CONST_ME_MORTAREA)   end, 1000)

	local spectators = Game.getSpectators(bossPos, false, true, 8, 8, 10, 10)
	for _, spec in ipairs(spectators) do
		if spec:isPlayer() then
			spec:sendTextMessage(MESSAGE_EVENT_ADVANCE,
				"The Skeleton King has been defeated! His undead power crumbles and the crypt falls silent...")
		end
	end

	addEvent(function()
		cleanArena(bossPos)
	end, 2000)

	addEvent(function(bossId)
		local b = Creature(bossId)
		if b then
			buildRewardChest(b, bossPos)
		end
	end, 3000, boss:getId())

	lastGreetedTarget = 0

	if mostDamageKiller and mostDamageKiller:isPlayer() then
		broadcastMessage(
			mostDamageKiller:getName() .. " has slain the mighty Skeleton King!",
			MESSAGE_EVENT_ADVANCE)
	end

	return true
end

skeletonKingDeath:register()

-- Death Knight ya está definido en data/scripts/monsters/deathknight.lua
