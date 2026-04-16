-- Skeleton King - Boss Events
-- Arena: {x=148, y=51, z=7} to {x=162, y=70, z=7}
--
-- PHASES:
--   Phase 1 (100-60%): Tactical — bone throws, telegraphed death wave, DKs guard the king
--   Phase 2  (60-30%): Enraged  — faster attacks, curse players, bone rain on random arena tiles
--   Phase 3   (<30%): Desperate — one emergency self-heal, bone storm (large radius), final wave

local ARENA = {
	from = Position(148, 51, 7),
	to   = Position(162, 70, 7),
}

local STORAGE = {
	phase         = 66100,  -- 1=normal, 2=enraged, 3=desperate
	waveSpawned   = 66101,  -- tick counter for periodic reinforcements
	spawning      = 66102,  -- prevent overlapping summon bursts
	spawned       = 66103,  -- 0=not yet spawned intro, 1=intro done
	noHitTicks    = 66104,  -- ticks without damage (for boss reset)
	lastHp        = 66105,  -- HP at previous tick
	healed        = 66106,  -- 0=emergency heal not used, 1=used
	waveTelegraph = 66107,  -- 0=idle, 1=wave telegraphed (next tick fires it)
	curseTick     = 66108,  -- tick counter for random curse
	boneRainTick  = 66109,  -- tick counter for bone rain
	dashTick      = 66110,  -- tick counter for charge dash
	dashing       = 66111,  -- 1 while speed boost is active
}

local BOSS_RESET_TICKS = 45
local CHEST_DECAY_SECS = 45

local lastGreetedTarget = 0

local SPAWN_POSITIONS = {
	Position(149, 53, 7), Position(161, 53, 7),
	Position(149, 68, 7), Position(161, 68, 7),
	Position(155, 61, 7), Position(152, 57, 7),
	Position(158, 57, 7), Position(152, 65, 7),
	Position(158, 65, 7),
}

-- Random positions across the full arena floor for bone rain
local ARENA_FLOOR_POSITIONS = {}
do
	for x = 149, 161, 2 do
		for y = 52, 69, 2 do
			ARENA_FLOOR_POSITIONS[#ARENA_FLOOR_POSITIONS + 1] = Position(x, y, 7)
		end
	end
end

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

local MAX_DEATH_KNIGHTS = 3

local function countArenaDeathKnights(bossPos)
	local count = 0
	local creatures = Game.getSpectators(bossPos, false, false, 9, 9, 11, 11)
	for _, creature in ipairs(creatures) do
		if creature:isMonster() and creature:getName():lower() == "death knight" then
			count = count + 1
		end
	end
	return count
end

local function cleanArena(bossPos)
	local creatures = Game.getSpectators(bossPos, false, false, 9, 9, 11, 11)
	local toRemove = {}
	for _, creature in ipairs(creatures) do
		if creature:isMonster() and creature:getName():lower() == "death knight" then
			creature:getPosition():sendMagicEffect(CONST_ME_MORTAREA)
			toRemove[#toRemove + 1] = creature:getId()
		end
	end
	-- Remove all in one deferred call so the server sends all DELETE_ON_MAP
	-- packets in the same network burst — prevents client tile stack desync
	-- caused by interleaved MOVE_CREATURE + DELETE_ON_MAP packets.
	addEvent(function()
		for _, cid in ipairs(toRemove) do
			local c = Creature(cid)
			if c then c:remove() end
		end
	end, 0)
end

local function spawnWarriorWave(boss, count)
	if boss:getStorageValue(STORAGE.spawning) == 1 then
		return
	end

	local bossPos  = boss:getPosition()
	local existing = countArenaDeathKnights(bossPos)
	local canSpawn = MAX_DEATH_KNIGHTS - existing
	if canSpawn <= 0 then return end

	count = math.min(count, canSpawn)
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
		if b then b:setStorageValue(STORAGE.spawning, 0) end
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

-- Fire a death wave directly on boss position (called after telegraph)
local function fireDeathWave(bossId)
	local boss = Creature(bossId)
	if not boss then return end
	boss:say("FEEL THE VOID!", TALKTYPE_MONSTER_YELL)
	-- The wave is handled by the monster.attacks entry — we just need the visual+voice telegraph.
	-- We trigger an extra area effect to reinforce the hit feeling.
	boss:getPosition():sendMagicEffect(CONST_ME_MORTAREA)
end

-- Bone rain: fire visual + damage rings on random arena tiles
local function doBoneRain(bossId, arenaPlayers)
	local boss = Creature(bossId)
	if not boss then return end

	boss:say("RAIN OF BONES!", TALKTYPE_MONSTER_YELL)

	-- Pick 4-6 random tiles and fire effects + delayed damage
	local count = math.random(4, 6)
	local chosen = {}
	for i = 1, count do
		chosen[i] = ARENA_FLOOR_POSITIONS[math.random(#ARENA_FLOOR_POSITIONS)]
	end

	-- Warning visual: red circle (effect 176, 20 frames x 75ms = 1500ms total)
	for _, pos in ipairs(chosen) do
		pos:sendMagicEffect(176)
	end

	-- Impact after 1500ms (matches animation duration)
	-- Use Tile:getCreatures() for exact tile hit — Game.getSpectators(pos, 0,0,0,0)
	-- expands to full viewport when range args are 0 (map.cpp:403-406).
	addEvent(function()
		for _, pos in ipairs(chosen) do
			pos:sendMagicEffect(CONST_ME_MORTAREA)
			local tile = Tile(pos)
			if tile then
				local creatures = tile:getCreatures()
				if creatures then
					for _, c in ipairs(creatures) do
						if c:isPlayer() then
							local dmg = math.random(40, 80)
							c:addHealth(-dmg)
							c:sendTextMessage(MESSAGE_EVENT_DEFAULT, "A bone crashes into you for " .. dmg .. " damage!")
						end
					end
				end
			end
		end
	end, 1500)
end

-- ============================================================
--  onThink — intro + phases + telegraphs + boss reset
-- ============================================================
local skeletonKingThink = CreatureEvent("SkeletonKingThink")

function skeletonKingThink.onThink(boss, interval)
	if not boss or not boss:isMonster() then
		return true
	end

	-- ── Intro: first tick after spawn ─────────────────────────────
	if boss:getStorageValue(STORAGE.spawned) ~= 1 then
		boss:setStorageValue(STORAGE.spawned,       1)
		boss:setStorageValue(STORAGE.phase,         1)
		boss:setStorageValue(STORAGE.waveSpawned,   0)
		boss:setStorageValue(STORAGE.spawning,      0)
		boss:setStorageValue(STORAGE.noHitTicks,    0)
		boss:setStorageValue(STORAGE.lastHp,        boss:getHealth())
		boss:setStorageValue(STORAGE.healed,        0)
		boss:setStorageValue(STORAGE.waveTelegraph, 0)
		boss:setStorageValue(STORAGE.curseTick,     0)
		boss:setStorageValue(STORAGE.boneRainTick,  0)
		boss:setStorageValue(STORAGE.dashTick,      0)
		boss:setStorageValue(STORAGE.dashing,       0)
		lastGreetedTarget = 0

		local bossPos = boss:getPosition()
		bossPos:sendMagicEffect(CONST_ME_MORTAREA)
		addEvent(function() bossPos:sendMagicEffect(CONST_ME_MAGIC_RED) end, 300)
		addEvent(function() bossPos:sendMagicEffect(CONST_ME_MORTAREA)  end, 600)

		boss:say("FOOLS! You dare enter my crypt?! GUARDS — RISE!", TALKTYPE_MONSTER_YELL)

		addEvent(function(cid)
			local b = Creature(cid)
			if not b then return end
			spawnWarriorWave(b, 3)
		end, 1500, boss:getId())

		return true
	end

	local currentHp  = boss:getHealth()
	local maxHp      = boss:getMaxHealth()
	local hpPct      = (currentHp / maxHp) * 100
	local phase      = boss:getStorageValue(STORAGE.phase)
	local bossPos    = boss:getPosition()
	local arenaPlayers = getArenaPlayers(bossPos)

	-- ── Shout on new target ─────────────────────────────────────
	local target = boss:getTarget()
	if target and target:isPlayer() then
		local tid = target:getId()
		if tid ~= lastGreetedTarget then
			lastGreetedTarget = tid
			local greets = {
				"So, " .. target:getName() .. "... another mortal who wishes to join my army of bones!",
				target:getName() .. "! Your skull will make a fine goblet!",
				"INTRUDER! " .. target:getName() .. ", I will grind your bones to dust!",
				"Ah, " .. target:getName() .. "... I have been expecting you. SUFFER!",
				"You cannot kill what is already dead, " .. target:getName() .. "!",
			}
			boss:say(greets[math.random(#greets)], TALKTYPE_MONSTER_YELL)
		end
	end

	-- ── Boss reset: HP unchanged for BOSS_RESET_TICKS ───────────
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

	-- ════════════════════════════════════════════════════════════
	--  PHASE TRANSITIONS
	-- ════════════════════════════════════════════════════════════

	-- ── Phase 2: Enraged (below 60%) ────────────────────────────
	if hpPct <= 60 and phase < 2 then
		phase = 2
		boss:setStorageValue(STORAGE.phase, 2)
		boss:setStorageValue(STORAGE.waveSpawned, 0)
		boss:setStorageValue(STORAGE.curseTick, 0)
		boss:setStorageValue(STORAGE.boneRainTick, 0)

		bossPos:sendMagicEffect(CONST_ME_MAGIC_RED)
		addEvent(function() bossPos:sendMagicEffect(CONST_ME_MORTAREA) end, 400)
		addEvent(function() bossPos:sendMagicEffect(CONST_ME_MAGIC_RED) end, 800)

		boss:say("ENOUGH! My patience has ended — feel the WRATH of the undead!", TALKTYPE_MONSTER_YELL)
		broadcastToArena(arenaPlayers,
			"The Skeleton King's eyes blaze with crimson light — his fury is unleashed!")

		addEvent(function(cid)
			local b = Creature(cid)
			if not b then return end
			spawnWarriorWave(b, 4)
			b:say("WARRIORS! Spread out — tear them APART!", TALKTYPE_MONSTER_SAY)
		end, 1500, boss:getId())
	end

	-- ── Phase 3: Desperate (below 30%) ──────────────────────────
	if hpPct <= 30 and phase < 3 then
		phase = 3
		boss:setStorageValue(STORAGE.phase, 3)

		bossPos:sendMagicEffect(CONST_ME_MORTAREA)
		addEvent(function() bossPos:sendMagicEffect(CONST_ME_MAGIC_RED) end, 300)
		addEvent(function() bossPos:sendMagicEffect(CONST_ME_MORTAREA)  end, 600)
		addEvent(function() bossPos:sendMagicEffect(CONST_ME_MAGIC_RED) end, 900)

		boss:say("I CANNOT DIE! I AM ETERNAL! RISE, MY ETERNAL WARRIORS — RIIISE!", TALKTYPE_MONSTER_YELL)
		broadcastToArena(arenaPlayers,
			"The Skeleton King lets out a bone-chilling scream — dark energy floods the crypt!")

		-- Emergency self-heal (one time only)
		if boss:getStorageValue(STORAGE.healed) == 0 then
			boss:setStorageValue(STORAGE.healed, 1)
			addEvent(function(cid)
				local b = Creature(cid)
				if not b then return end
				local healAmt = math.floor(maxHp * 0.20)  -- heals 20% max HP
				b:addHealth(healAmt)
				b:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
				addEvent(function() b:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE) end, 400)
				b:say("THE DARKNESS MENDS MY BONES! I AM... UNBREAKABLE!", TALKTYPE_MONSTER_YELL)
				broadcastToArena(getArenaPlayers(b:getPosition()),
					"The Skeleton King absorbs dark energy — his wounds begin to close!")
			end, 2000, boss:getId())
		end

		-- Final desperate wave
		addEvent(function(cid)
			local b = Creature(cid)
			if not b then return end
			spawnWarriorWave(b, 6)
			b:say("DROWN THEM IN BONES! KILL THEM ALL!", TALKTYPE_MONSTER_YELL)
		end, 4000, boss:getId())
	end

	-- ════════════════════════════════════════════════════════════
	--  PHASE-BASED DYNAMIC MECHANICS
	-- ════════════════════════════════════════════════════════════

	-- ── Telegraph: Death Wave (all phases, every ~12-18s) ───────
	local telegraphState = boss:getStorageValue(STORAGE.waveTelegraph)
	if telegraphState == 1 then
		-- Telegraph already fired last tick — fire the wave now
		boss:setStorageValue(STORAGE.waveTelegraph, 0)
		fireDeathWave(boss:getId())
	elseif math.random(1, 100) <= (phase >= 2 and 12 or 7) then
		-- Chance per tick to telegraph; higher in later phases
		boss:setStorageValue(STORAGE.waveTelegraph, 1)
		boss:say("DEATH COMES FOR YOU ALL!", TALKTYPE_MONSTER_YELL)
		broadcastToArena(arenaPlayers, "The Skeleton King raises his arms — a death wave is forming!")
		bossPos:sendMagicEffect(CONST_ME_MAGIC_RED)
	end

	-- ── Charge Dash (all phases, every ~20-28s) ─────────────────
	-- Boss gets a temporary speed burst to close gap on target, like utani gran hur.
	-- Telegraph: shake effect + voice. Dash lasts 2.5s then speed returns to normal.
	do
		local dashTick = boss:getStorageValue(STORAGE.dashTick) + 1
		-- Phase 1: ~28s, Phase 2: ~20s, Phase 3: ~14s
		local dashThresh = phase == 3 and 14 or (phase == 2 and 20 or 28)

		if boss:getStorageValue(STORAGE.dashing) == 1 then
			-- Currently dashing — handled by addEvent below, just count ticks
		end

		if dashTick >= dashThresh and boss:getStorageValue(STORAGE.dashing) == 0 then
			boss:setStorageValue(STORAGE.dashTick, 0)
			boss:setStorageValue(STORAGE.dashing, 1)

			local dashLines = {
				"I WILL CRUSH YOU!",
				"YOU CANNOT OUTRUN DEATH!",
				"STAND STILL AND DIE!",
				"NOWHERE TO RUN!",
			}
			boss:say(dashLines[math.random(#dashLines)], TALKTYPE_MONSTER_YELL)
			bossPos:sendMagicEffect(CONST_ME_MORTAREA)
			bossPos:sendMagicEffect(CONST_ME_MAGIC_RED)

			-- Apply speed boost
			boss:changeSpeed(350)

			-- Remove boost after 2500ms
			addEvent(function(cid)
				local b = Creature(cid)
				if not b then return end
				b:changeSpeed(-350)
				b:setStorageValue(STORAGE.dashing, 0)
			end, 2500, boss:getId())
		else
			boss:setStorageValue(STORAGE.dashTick, dashTick)
		end
	end

	-- ── Bone Rain (phase 2+, every ~15s) ────────────────────────
	if phase >= 2 then
		local rainTick = boss:getStorageValue(STORAGE.boneRainTick) + 1
		local rainThresh = (phase == 3) and 12 or 15
		if rainTick >= rainThresh then
			boss:setStorageValue(STORAGE.boneRainTick, 0)
			doBoneRain(boss:getId(), arenaPlayers)
		else
			boss:setStorageValue(STORAGE.boneRainTick, rainTick)
		end
	end

	-- ── Random Curse: slow a player (phase 2+, every ~20s) ──────
	if phase >= 2 and #arenaPlayers > 0 then
		local curseTick = boss:getStorageValue(STORAGE.curseTick) + 1
		local curseThresh = (phase == 3) and 14 or 20
		if curseTick >= curseThresh then
			boss:setStorageValue(STORAGE.curseTick, 0)
			local victim = arenaPlayers[math.random(#arenaPlayers)]
			local curseLines = {
				"YOU are CURSED, " .. victim:getName() .. "!",
				"Your legs turn to LEAD, " .. victim:getName() .. "!",
				"The grave claims your speed, " .. victim:getName() .. "!",
			}
			boss:say(curseLines[math.random(#curseLines)], TALKTYPE_MONSTER_YELL)
			victim:sendTextMessage(MESSAGE_EVENT_ADVANCE,
				"The Skeleton King curses you — your limbs feel like lead!")
			-- Apply speed penalty via condition
			local speedCondition = Condition(CONDITION_PARALYZE)
			speedCondition:setParameter(CONDITION_PARAM_SPEED, -300)
			speedCondition:setParameter(CONDITION_PARAM_TICKS, 6000)
			victim:addCondition(speedCondition)
			victim:getPosition():sendMagicEffect(CONST_ME_MAGIC_RED)
		else
			boss:setStorageValue(STORAGE.curseTick, curseTick)
		end
	end

	-- ── Periodic reinforcements (phase 2+, every ~25s) ──────────
	if phase >= 2 then
		local waveTick = boss:getStorageValue(STORAGE.waveSpawned) + 1
		local waveThresh = (phase == 3) and 18 or 25
		if waveTick >= waveThresh then
			boss:setStorageValue(STORAGE.waveSpawned, 0)
			local count = (phase == 3) and 3 or 2
			spawnWarriorWave(boss, count)
			local waveLines = {
				"More warriors to serve their King!",
				"Rise from the earth — RISE!",
				"The dead are never truly gone...",
			}
			boss:say(waveLines[math.random(#waveLines)], TALKTYPE_MONSTER_SAY)
		else
			boss:setStorageValue(STORAGE.waveSpawned, waveTick)
		end
	end

	return true
end

skeletonKingThink:register()

-- ============================================================
--  Reward loot pool
-- ============================================================
local REWARD_LOOT = {
	{ id = 92,   chance = 100000, maxCount = 200 },
	{ id = 35,   chance = 80000,  maxCount = 5   },
	{ id = 110,  chance = 70000,  maxCount = 5   },
	{ id = 328,  chance = 35000,  maxCount = 1   },
	{ id = 24,   chance = 30000,  maxCount = 1   },
	{ id = 145,  chance = 30000,  maxCount = 1   },
	{ id = 65,   chance = 25000,  maxCount = 1   },
	{ id = 62,   chance = 25000,  maxCount = 1   },
	{ id = 74,   chance = 15000,  maxCount = 1   },
	{ id = 192,  chance = 10000,  maxCount = 1   },
	{ id = 123,  chance = 8000,   maxCount = 1   },
	{ id = 155,  chance = 6000,   maxCount = 1   },
	{ id = 249,  chance = 4000,   maxCount = 1   },
	{ id = 76,   chance = 3000,   maxCount = 1   },
	{ id = 1002, chance = 2000,   maxCount = 1   },
	{ id = 209,  chance = 1500,   maxCount = 1   },
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
	local damageMap    = boss:getDamageMap()
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

	if #participants == 0 or totalDamage == 0 then return end

	local chest = Game.createItem(CHEST_ITEMID, 1, CHEST_POS)
	if not chest then return end

	chest:setAttribute(ITEM_ATTRIBUTE_DURATION, CHEST_DECAY_SECS)
	chest:decay()

	local rewarded = 0
	for _, entry in ipairs(participants) do
		local share = entry.damage / totalDamage
		if share >= MIN_SHARE then
			local bag = Game.createItem(ITEM_BAG, 1)
			if bag then
				bag:setAttribute(ITEM_ATTRIBUTE_DESCRIPTION,
					("Reward for %s (%.1f%% damage)"):format(entry.player:getName(), share * 100))
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
	-- Capture position immediately — corpse may decay before delayed events fire
	local px, py, pz = corpse:getPosition().x, corpse:getPosition().y, corpse:getPosition().z
	local bossPos = Position(px, py, pz)

	bossPos:sendMagicEffect(CONST_ME_MORTAREA)
	addEvent(function() bossPos:sendMagicEffect(CONST_ME_MAGIC_BLUE) end, 300)
	addEvent(function() bossPos:sendMagicEffect(CONST_ME_MORTAREA)   end, 600)
	addEvent(function() bossPos:sendMagicEffect(CONST_ME_MAGIC_BLUE) end, 900)
	addEvent(function() bossPos:sendMagicEffect(CONST_ME_MORTAREA)   end, 1200)

	local spectators = Game.getSpectators(bossPos, false, true, 8, 8, 10, 10)
	for _, spec in ipairs(spectators) do
		if spec:isPlayer() then
			spec:sendTextMessage(MESSAGE_EVENT_ADVANCE,
				"The Skeleton King collapses! His bones scatter across the crypt floor — the undead army dissolves into dust...")
		end
	end

	-- Immediate clean + second sweep in case some DKs are mid-path
	cleanArena(bossPos)
	addEvent(function() cleanArena(bossPos) end, 1500)

	addEvent(function(bossId)
		local b = Creature(bossId)
		if b then buildRewardChest(b, bossPos) end
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
