Revscriptsys is a new alternative way to register scripts so that you don't need to do it via XML. You just need to place your lua scripts inside data/scripts/, or any subfolder of it if you want. Monster scripts are, however, placed in a different path: data/monster/ (or any subfolder of it, like before). This system supports the usage of different metatables in the same script (Actions, MoveEvents, GlobalEvents...). This comes in hand if you do prolonged quests (for example), which otherwise would need separate files for each metatable. The script must contain a header and footer, as shown in the following example.

Action onUse example:

local testAction = Action() -- this is our header, the first thing we have to write (except for configuration tables and such)

function testAction.onUse(player, item, fromPosition, target, toPosition, isHotkey) -- now we can design the action itself
	return print("We used this item: " .. item.itemid)
end

testAction:id(2550) -- the item is a scythe
testAction:register() -- this is our footer, it has to be the last function executed
Available metatables:
Action()

CreatureEvent("name")

GlobalEvent("name")

MonsterType("name")

MoveEvent()

Spell("name")

TalkAction("words")

Weapon(WEAPON_TYPE)

Action()
Interfaces:

onUse
Methods:
id(ids)
aid(ids)
uid(ids)
allowFarUse(bool)
blockWalls(bool)
checkFloor(bool)
Example:

local action = Action()

function action.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if target.itemid == 2739 then
		target:transform(2737)
		target:decay()
		Game.createItem(2694, 1, toPosition)
		return true
	end
	return destroyItem(player, target, toPosition)
end

action:id(2550)
action:register()
Added in version: 1.3

[To the top]

Action:id(ids)
Description:

Registers the Action by chosen itemid(s)
Parameters:
id(s)
Returns: N/A
Example:

local action = Action()

action:id(1000) -- only registering one itemid
action:id(1000,1001,1002,...) -- registering several itemids

action:register()
Added in version: 1.3

[To the top]

Action:aid(ids)
Description:

Registers the Action by chosen actionid(s)
Parameters:
aid(s)
Returns: N/A
Example:

local action = Action()

action:aid(1000) -- only registering one actionid
action:aid(1000,1001,1002,...) -- registering several actionids

action:register()
Added in version: 1.3

[To the top]

Action:uid(ids)
Description:

Registers the Action by chosen uniqueid(s)
Parameters:
uid(s)
Returns: N/A
Example:

local action = Action()

action:uid(1000) -- only registering one uniqueid
action:uid(1000,1001,1002,...) -- registering several uniqueids

action:register()
Added in version: 1.3

[To the top]

Action:allowFarUse(bool)
Description:

Determines whether the item can be used on a target from a distance or not.
default: false
Parameters:
boolean value (true or false)
Returns: N/A
Example:

local action = Action()

action:allowFarUse(true)

action:register()
Added in version: 1.3

[To the top]

Action:blockWalls(bool)
Description:

Determines whether the item can be used on a target even if there is a wall between the Player and the target.
default: true
Parameters:
boolean value (true or false)
Returns: N/A
Example:

local action = Action()

action:blockWalls(false)

action:register()
Added in version: 1.3

[To the top]

Action:checkFloor(bool)
Description:

Determines whether the item must be used on a target which is on the same floor level as the Player's.
default: true
Parameters:
boolean value true/false
Returns: N/A
Example:

local action = Action()

action:checkFloor(false)

action:register()
Added in version: 1.3

[To the top]

CreatureEvent("name")
Interfaces:

onLogin(player)
onLogout(player)
onThink(creature, interval)
onPrepareDeath(creature, killer)
onDeath(creature, corpse, killer, mostDamageKiller, lastHitUnjustified, mostDamageUnjustified)
onKill(creature, target)
onAdvance(player, skill, oldLevel, newLevel)
onModalWindow(player, modalWindowId, buttonId, choiceId)
onTextEdit(player, item, text)
onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
onManaChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
onExtendedOpCode(player, opcode, buffer)
Methods:
none
Example:

local creatureevent = CreatureEvent("example")

function creatureevent.onLogin(player)
	player:sendTextMessage(MESSAGE_STATUS_DEFAULT, "Welcome!")
	return true
end

creatureevent:register()
Added in version: 1.3

[To the top]

CreatureEvent("name").onLogout(player)
Interface:

onLogout(player)
Example:

local creatureevent = CreatureEvent("example")

function creatureevent.onLogout(player)
	player:getPosition():sendMagicEffect(CONST_ME_POFF)
	return true
end

creatureevent:register()
Added in version: 1.3

[To the top]

CreatureEvent("name").onThink(creature, interval)
Interface:

onThink(creature, interval)
Example:

local creatureevent = CreatureEvent("example")

function creatureevent.onThink(creature, interval)
	return true
end

creatureevent:register()
Added in version: 1.3

[To the top]

CreatureEvent("name").onPrepareDeath(creature, killer)
Interface:

onPrepareDeath(creature, killer)
Example:

local creatureevent = CreatureEvent("example")

function creatureevent.onPrepareDeath(creature, killer)
	return true
end

creatureevent:register()
Added in version: 1.3

[To the top]

CreatureEvent("name").onDeath(creature, corpse, killer, mostDamageKiller, lastHitUnjustified, mostDamageUnjustified)
Interface:

onDeath(creature, corpse, killer, mostDamageKiller, lastHitUnjustified, mostDamageUnjustified)
Example:

local creatureevent = CreatureEvent("example")

function creatureevent.onDeath(creature, corpse, killer, mostDamageKiller, lastHitUnjustified, mostDamageUnjustified)
	return true
end

creatureevent:register()
Added in version: 1.3

[To the top]

CreatureEvent("name").onKill(creature, target)
Interface:

onKill(creature, target)
Example:

local creatureevent = CreatureEvent("example")

function creatureevent.onKill(creature, target)
	return true
end

creatureevent:register()
Added in version: 1.3

[To the top]

CreatureEvent("name").onAdvance(player, skill, oldLevel, newLevel)
Interface:

onAdvance(player, skill, oldLevel, newLevel)
Example:

local creatureevent = CreatureEvent("example")

function creatureevent.onAdvance(player, skill, oldLevel, newLevel)
	return true
end

creatureevent:register()
Added in version: 1.3

[To the top]

CreatureEvent("name").onModalWindow(player, modalWindowId, buttonId, choiceId)
Interface:

onModalWindow(player, modalWindowId, buttonId, choiceId)
Example:

local creatureevent = CreatureEvent("example")

function creatureevent.onModalWindow(player, modalWindowId, buttonId, choiceId)
	return true
end

creatureevent:register()
Added in version: 1.3

[To the top]

CreatureEvent("name").onTextEdit(player, item, text)
Interface:

onTextEdit(player, item, text)
Example:

local creatureevent = CreatureEvent("example")

function creatureevent.onTextEdit(player, item, text)
	return true
end

creatureevent:register()
Added in version: 1.3

[To the top]

CreatureEvent("name").onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
Interface:

onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
Example:

local creatureevent = CreatureEvent("example")

function creatureevent.onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
	return primaryDamage, primaryType, secondaryDamage, secondaryType
end

creatureevent:register()
Added in version: 1.3

[To the top]

CreatureEvent("name").onManaChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
Interface:

onManaChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
Example:

local creatureevent = CreatureEvent("example")

function creatureevent.onManaChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
	return primaryDamage, primaryType, secondaryDamage, secondaryType
end

creatureevent:register()
Added in version: 1.3

[To the top]

CreatureEvent("name").onExtendedOpCode(player, opcode, buffer)
Interface:

onExtendedOpCode(player, opcode, buffer)
Example:

local creatureevent = CreatureEvent("example")

function creatureevent.onExtendedOpCode(player, opcode, buffer)
	return true
end

creatureevent:register()
Added in version: 1.3

[To the top]

GlobalEvent("name")
Interfaces:

onThink(interval)
onTime(interval)
onStartup()
onShutdown()
onRecord(current, old)
Methods:
time(time)
interval(ms)
Example:

local globalevent = GlobalEvent("example")

function globalevent.onThink(...)
	return true
end

globalevent:interval(1000) -- will be executed every 1000ms
globalevent:register()
Added in version: 1.3

[To the top]

GlobalEvent("name").onTime(interval)
Interface:

onTime(interval)
Example:

local globalevent = GlobalEvent("example")

function globalevent.onTime(interval)
	broadcastMessage("Good morning!", MESSAGE_STATUS_DEFAULT)
	return true
end

globalevent:time("08:00") -- will be executed each day on 8am
globalevent:register()
Added in version: 1.3

[To the top]

GlobalEvent("name").onStartup()
Interface:

onStartup()
Example:

local globalevent = GlobalEvent("example")

function globalevent.onStartup()
	broadcastMessage("Server started!", MESSAGE_STATUS_DEFAULT)
	return true
end

globalevent:register()
Added in version: 1.3

[To the top]

GlobalEvent("name").onShutdown()
Interface:

onShutdown()
Example:

local globalevent = GlobalEvent("example")

function globalevent.onShutdown()
	broadcastMessage("Shutting down, see you soon!", MESSAGE_STATUS_DEFAULT)
	return true
end

globalevent:register()
Added in version: 1.3

[To the top]

GlobalEvent("name").onRecord(current, old)
Interface:

onRecord(current, old)
Example:

local globalevent = GlobalEvent("example")

function globalevent.onRecord(current, old)
	return true
end

globalevent:register()
Added in version: 1.3

[To the top]

MonsterType("name")
Description:

We have created a table masking system, in order to make MonsterTypes easier to maintain/create example
Interfaces:
onThink(...)
onAppear(...)
onDisappear()
onMove(...)
onSay(...)
Methods:
Create a new MonsterType:
Game.createMonsterType(name)
Boolean functions:
isAttackable(bool)
isConvinceable(bool)
isSummonable(bool)
isIllusionable(bool)
isHostile(bool)
isPushable(bool)
isHealthHidden(bool)
canPushItems(bool)
canPushCreatures(bool)
canPushCreatures(bool)
Integer Functions:
health(health)
maxHealth(maxHealth)
experience(exp)
addElement(type, percent)
maxSummons(ammount)
armor(armor)
defense(defense)
corpseId(id)
manaCost(mana)
baseSpeed(speed)
light(color, level)
staticAttackChance(chance)
targetDistance(distance)
yellChance(chance)
yellSpeedTicks(ticks)
changeTargetChance(chance)
changeTargetSpeed(interval)
String Functions:
name(name)
nameDescription(description)
combatImmunity(immunity)
conditionImmunity(immunity)
addVoice(sentence, interval, chance, yell)
registerEvent(name)
addSummonname, interval, chance)
race(race)
Get Functions:
getAttackList()
getDefenseList()
getElementList()
getVoices()
getLoot()
getCreatureEvents()
getSummonList()
Userdata Functions:
addAttack(monsterspell)
addDefense(monsterspell)
addLoot(loot)
outfit(outfit)
Added in version: 1.3
[To the top]

How to create a MonsterType from scratch.
Example:

local mType = Game.createMonsterType("example")
local monster = {}
monster.description = "an example"
monster.experience = 1
monster.outfit = {
	lookType = 37
}

monster.health = 99200
monster.maxHealth = monster.health
monster.race = "fire"
monster.corpse = 5995
monster.speed = 280
monster.maxSummons = 2

monster.changeTarget = {
	interval = 4*1000,
	chance = 20
}

monster.flags = {
	summonable = false,
	attackable = true,
	hostile = true,
	convinceable = false,
	illusionable = false,
	canPushItems = true,
	canPushCreatures = true,
	targetDistance = 1,
	staticAttackChance = 70
}

monster.summons = {
	{name = "demon", chance = 10, interval = 2*1000}
}

monster.voices = {
	interval = 5000,
	chance = 10,
	{text = "I'm an example", yell = false},
	{text = "You shall bow", yell = false}
}

monster.loot = {
	{id = "gold coin", chance = 60000, maxCount = 100},
	{id = "bag", chance = 60000,
		child = {
			{id = "platinum coin", chance = 60000, maxCount = 100},
			{id = "crystal coin", chance = 60000, maxCount = 100}
		}
	}
}

monster.attacks = {
	{name = "melee", attack = 130, skill = 70, effect = CONST_ME_DRAWBLOOD, interval = 2*1000},
	{name = "energy strike", range = 1, chance = 10, interval = 2*1000, minDamage = -210, maxDamage = -300, target = true},
	{name = "combat", type = COMBAT_MANADRAIN, chance = 10, interval = 2*1000, minDamage = 0, maxDamage = -120, target = true, range = 7, effect = CONST_ME_MAGIC_BLUE},
	{name = "combat", type = COMBAT_FIREDAMAGE, chance = 20, interval = 2*1000, minDamage = -150, maxDamage = -250, radius = 1, target = true, effect = CONST_ME_FIREAREA, shootEffect = CONST_ANI_FIRE},
	{name = "speed", chance = 15, interval = 2*1000, speed = -700, radius = 1, target = true, duration = 30*1000, effect = CONST_ME_MAGIC_RED},
	{name = "firefield", chance = 10, interval = 2*1000, range = 7, radius = 1, target = true, shootEffect = CONST_ANI_FIRE},
	{name = "combat", type = COMBAT_LIFEDRAIN, chance = 10, interval = 2*1000, length = 8, spread = 0, minDamage = -300, maxDamage = -490, effect = CONST_ME_PURPLEENERGY}
}

monster.defenses = {
	defense = 55,
	armor = 55,
	{name = "combat", type = COMBAT_HEALING, chance = 15, interval = 2*1000, minDamage = 180, maxDamage = 250, effect = CONST_ME_MAGIC_BLUE},
	{name = "speed", chance = 15, interval = 2*1000, speed = 320, effect = CONST_ME_MAGIC_RED}
}

monster.elements = {
	{type = COMBAT_PHYSICALDAMAGE, percent = 30},
	{type = COMBAT_DEATHDAMAGE, percent = 30},
	{type = COMBAT_ENERGYDAMAGE, percent = 50},
	{type = COMBAT_EARTHDAMAGE, percent = 40},
	{type = COMBAT_ICEDAMAGE, percent = -10},
	{type = COMBAT_HOLYDAMAGE, percent = -10}
}

monster.immunities = {
	{type = "fire", combat = true, condition = true},
	{type = "drown", condition = true},
	{type = "lifedrain", combat = true},
	{type = "paralyze", condition = true},
	{type = "invisible", condition = true}
}

mType.onThink = function(monster, interval)
	print("I'm thinking")
end

mType.onAppear = function(monster, creature)
	if monster:getId() == creature:getId() then
		print(monster:getId(), creature:getId())
	end
end

mType.onDisappear = function(monster, creature)
	if monster:getId() == creature:getId() then
		print(monster:getId(), creature:getId())
	end
end

mType.onMove = function(monster, creature, fromPosition, toPosition)
	if monster:getId() == creature:getId() then
		print(monster:getId(), creature:getId(), fromPosition, toPosition)
	end
end

mType.onSay = function(monster, creature, type, message)
	print(monster:getId(), creature:getId(), type, message)
end

mType:register(monster)
Added in version: 1.3

[To the top]

MoveEvent()
Interfaces:

onEquip(player, item, slot, isCheck)
onDeEquip(player, item, slot, isCheck)
onStepIn(creature, item, position, fromPosition)
onStepOut(creature, item, position, fromPosition)
onAddItem(moveitem, tileitem, position)
onRemoveItem(moveitem, tileitem, position)
Methods:
level(lvl)
magiclevel(lvl)
slot(slot)
id(ids)
aid(ids)
uid(ids)
position(positions)
premium(bool)
vocation(vocName[, showInDescription = false, lastVoc = false])
Example:

local moveevent = MoveEvent()

function moveevent.onEquip(player, item, slot, isCheck)
	return true
end

moveevent:register()
Added in version: 1.3

[To the top]

MoveEvent().onEquip(player, item, slot, isCheck)
Interface:

onEquip(player, item, slot, isCheck)
Example:

local moveevent = MoveEvent()

function moveevent.onEquip(player, item, slot, isCheck)
	return true
end

moveevent:register()
Added in version: 1.3

[To the top]

MoveEvent().onDeEquip(player, item, slot, isCheck)
Interface:

onDeEquip(player, item, slot, isCheck)
Example:

local moveevent = MoveEvent()

function moveevent.onDeEquip(player, item, slot, isCheck)
	return true
end

moveevent:register()
Added in version: 1.3

[To the top]

MoveEvent().onStepIn(creature, item, position, fromPosition)
Interface:

onStepIn(creature, item, position, fromPosition)>
Example:

local moveevent = MoveEvent()

function moveevent.onStepIn(creature, item, position, fromPosition)
	return true
end

moveevent:register()
Added in version: 1.3

[To the top]

MoveEvent().onStepOut(creature, item, position, fromPosition)
Interface:

onStepOut(creature, item, position, fromPosition)>
Example:

local moveevent = MoveEvent()

function moveevent.onStepOut(creature, item, position, fromPosition)
	return true
end

moveevent:register()
Added in version: 1.3

[To the top]

MoveEvent().onAddItem(moveitem, tileitem, position)
Interface:

onAddItem(moveitem, tileitem, position)>
Example:

local moveevent = MoveEvent()

function moveevent.onAddItem(moveitem, tileitem, position)
	return true
end

moveevent:register()
Added in version: 1.3

[To the top]

MoveEvent().onRemoveItem(moveitem, tileitem, position)
Interface:

onAddItem(moveitem, tileitem, position)>
Returns: N/A
Example:

local moveevent = MoveEvent()

function moveevent.onRemoveItem(moveitem, tileitem, position)
	return true
end

moveevent:register()
Added in version: 1.3

[To the top]

MoveEvent:level(lvl)
Description:

Registers the MoveEvent by chosen level
Parameters:
id(s)
Returns: N/A
Example:

local moveevent = MoveEvent()

moveevent:level(50)

moveevent:register()
Added in version: 1.3

[To the top]

MoveEvent:magiclevel(lvl)
Description:

Registers the MoveEvent by chosen magic level
Parameters:
id(s)
Returns: N/A
Example:

local moveevent = MoveEvent()

moveevent:magiclevel(25)

moveevent:register()
Added in version: 1.3

[To the top]

MoveEvent:id(ids)
Description:

Registers the MoveEvent by chosen itemid(s)
Parameters:
id(s)
Returns: N/A
Example:

local moveevent = MoveEvent()

moveevent:id(1000) -- only registering one itemid
moveevent:id(1000,1001,1002,...) -- registering several itemids

moveevent:register()
Added in version: 1.3

[To the top]

MoveEvent:aid(ids)
Description:

Registers the MoveEvent by chosen actionid(s)
Parameters:
aid(s)
Returns: N/A
Example:

local moveevent = MoveEvent()

moveevent:aid(1000) -- only registering one actionid
moveevent:aid(1000,1001,1002,...) -- registering several actionids

moveevent:register()
Added in version: 1.3

[To the top]

MoveEvent:uid(ids)
Description:

Registers the MoveEvent by chosen uniqueid(s)
Parameters:
uid(s)
Returns: N/A
Example:

local moveevent = MoveEvent()

moveevent:uid(1000) -- only registering one uniqueid
moveevent:uid(1000,1001,1002,...) -- registering several uniqueids

moveevent:register()
Added in version: 1.3

[To the top]

MoveEvent:position(positions)
Description:

Registers the MoveEvent by chosen position(s)
Parameters:
position(s)
Returns: N/A
Example:

local moveevent = MoveEvent()

moveevent:position({x = 0, y = 0, z = 0}) -- only registering one position

moveevent:register()
Added in version: 1.3

[To the top]

MoveEvent:premium(bool)
Description:

Determines whether the MoveEvent will be triggered by premium players or not
default: false
Parameters:
boolean value (true or false)
Returns: N/A
Example:

local moveevent = MoveEvent()

moveevent:premium(true)

moveevent:register()
Added in version: 1.3

[To the top]

MoveEvent:vocation(vocName[, showInDescription = false, lastVoc = false])
Description:

Determines whether the MoveEvent will be triggered by a specific vocation. Optional parameters will determine if the vocation specified will be shown in the description and if it is the last vocation shown in description.
Parameters:
vocName (string), showInDescription (boolean), lastVoc
Returns: N/A
Example:

local moveevent = MoveEvent()

moveevent:vocation("Sorcerer", true, true) --

moveevent:register()
Added in version: 1.3

[To the top]

Spell(words, name or id)
Interfaces:

onCastSpell(creature, var, isHotkey)
Methods:
getManaCost(player)
getSoulCost()
isPremium()
isLearnable()
Example:

local combat = Combat()
combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_FIREDAMAGE)
combat:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_FIREAREA)
combat:setArea(createCombatArea(AREA_CIRCLE5X5))

function onGetFormulaValues(player, level, magicLevel)
	local min = (level / 5) + (magicLevel * 8) + 50
	local max = (level / 5) + (magicLevel * 12) + 75
	return -min, -max
end

combat:setCallback(CALLBACK_PARAM_LEVELMAGICVALUE, "onGetFormulaValues")

local spell = Spell("instant")

function spell.onCastSpell(creature, variant)
	return combat:execute(creature, variant)
end

spell:name("Hell's Core")
spell:words("exevo gran mas flam")
spell:group("attack")
spell:vocation("sorcerer", "master sorcerer")
spell:id(24)
spell:cooldown(40 * 1000)
spell:groupCooldown(4 * 1000)
spell:level(60)
spell:mana(1100)
spell:isSelfTarget(true)
spell:isPremium(true)
spell:register()
Added in version: 1.3

[To the top]

Spell(words, name or id).onCastSpell(creature, var, isHotkey)
Interface:

onCastSpell(creature, var, isHotkey)
Returns: N/A
Example:

local spell = Spell("Hell's Core")

function spell.onCastSpell(creature, var, isHotkey)
	return true
end

spell:register()
Added in version: 1.3

[To the top]

Spell:getManaCost(player)
Description:

Returns the mana that the player will spend when casting the spell
Parameters:
player
Returns: N/A
Example:

local spell = Spell("Hell's Core")

function spell.onCastSpell(creature, var, isHotkey)
	if spell:getManaCost(creature) >= 500 then
		creature:sendTextMessage(MESSAGE_STATUS_DEFAULT, "You spent 500 mana or more while casting this spell!")
	else
		creature:sendTextMessage(MESSAGE_STATUS_DEFAULT, "You spent less than 500 mana right now.")
	end
	return true
end

spell:register()
Added in version: 1.3

[To the top]

Spell:getSoulCost()
Description:

Returns the soul that the player will spend when casting the spell
Parameters:
none
Returns: N/A
Example:

local spell = Spell("Hell's Core")

function spell.onCastSpell(creature, var, isHotkey)
	if spell:getSoulCost() >= 50 then
		creature:sendTextMessage(MESSAGE_STATUS_DEFAULT, "You just lost half your soul (at least)!")
	else
		creature:sendTextMessage(MESSAGE_STATUS_DEFAULT, "You didn't spend too much soul when casting this spell.")
	end
	return true
end

spell:register()
Added in version: 1.3

[To the top]

Spell:isPremium()
Description:

Returns whether the player that cast the spell is premium or not
Parameters:
none
Returns: N/A
Example:

local spell = Spell("Hell's Core")

function spell.onCastSpell(creature, var, isHotkey)
	if spell:isPremium() then
		creature:sendTextMessage(MESSAGE_STATUS_DEFAULT, "You are premium.")
	else
		creature:sendTextMessage(MESSAGE_STATUS_DEFAULT, "You are not premium.")
	end
	return true
end

spell:register()
Added in version: 1.3

[To the top]

Spell:isLearnable()
Description:

Returns whether the player that cast the spell is able to learn the spell or not
Parameters:
none
Returns: N/A
Example:

local spell = Spell("Hell's Core")

function spell.onCastSpell(creature, var, isHotkey)
	if spell:isLearnable() then
		creature:sendTextMessage(MESSAGE_STATUS_DEFAULT, "You may learn this spell when you become more powerful!")
	else
		creature:sendTextMessage(MESSAGE_STATUS_DEFAULT, "This spell is not suitable for you...")
	end
	return true
end

spell:register()
Added in version: 1.3

[To the top]

TalkAction(words)
Interfaces:

onSay(callback)
Methods:
separator(sep)
Example:

local talkaction = TalkAction("!hello")

function talkaction.onSay(player, words, param, type)
	player:say("Hello!", TALKTYPE_YELL)
	return true
end

talkaction:register()
Added in version: 1.3

[To the top]

TalkAction(words).onSay(callback)
Interface:

onSay(callback)
Returns: N/A
Example:

local talkaction = TalkAction("!bye")

function talkaction.onSay(player, words, param, type)
	player:say("Bye...", TALKTYPE_WHISPER)
	return true
end

talkaction:register()
Added in version: 1.3

[To the top]

TalkAction:separator(sep)
Description:

Determines talkaction separator
Parameters:
sep
Returns: N/A
Example:

local talkaction = TalkAction("!bye")

talkaction:separator("-")

talkaction:register()
Added in version: 1.3

[To the top]

Weapon(WEAPON_TYPE)
Interfaces:

onUseWeapon(player, var)
Methods:
separator(sep)
Example:

local weapon = Weapon(WEAPON_AMMO)

local area = createCombatArea({
	{1, 1, 1},
	{1, 3, 1},
	{1, 1, 1}
})

local combat = Combat()
combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_PHYSICALDAMAGE)
combat:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_EXPLOSIONAREA)
combat:setParameter(COMBAT_PARAM_DISTANCEEFFECT, CONST_ANI_BURSTARROW)
combat:setParameter(COMBAT_PARAM_BLOCKARMOR, true)
combat:setFormula(COMBAT_FORMULA_SKILL, 0, 0, 1, 0)
combat:setArea(area)

function weapon.onUseWeapon(player, variant)
	if player:getSkull() == SKULL_BLACK then
		return false
	end

	return combat:execute(player, variant)
end

weapon:register()
Added in version: 1.3

[To the top]

Weapon(WEAPON_TYPE).onUseWeapon(player, variant)
Interface:

onUseWeapon(player, variant)
Returns: N/A
Example:

local weapon = Weapon(WEAPON_AMMO)

local area = createCombatArea({
	{1, 1, 1},
	{1, 3, 1},
	{1, 1, 1}
})

local combat = Combat()
combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_PHYSICALDAMAGE)
combat:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_EXPLOSIONAREA)
combat:setParameter(COMBAT_PARAM_DISTANCEEFFECT, CONST_ANI_BURSTARROW)
combat:setParameter(COMBAT_PARAM_BLOCKARMOR, true)
combat:setFormula(COMBAT_FORMULA_SKILL, 0, 0, 1, 0)
combat:setArea(area)

-- variant.number = target id
function weapon.onUseWeapon(player, variant)
	if player:getSkull() == SKULL_BLACK then
		return false
	end

	return combat:execute(player, variant)
end

weapon:register()
Added in version: 1.3
