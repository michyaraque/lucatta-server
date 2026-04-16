local area = createCombatArea({
	{0, 0, 1, 0, 0},
	{0, 0, 1, 0, 0},
	{0, 0, 1, 0, 0},
	{0, 0, 1, 0, 0},
	{0, 0, 1, 0, 0},
	{0, 0, 3, 0, 0}
})

local effects = {
	[DIRECTION_NORTH] = 169,
	[DIRECTION_EAST] = 170,
	[DIRECTION_SOUTH] = 171,
	[DIRECTION_WEST] = 172
}

local combats = {}

for direction, effect in pairs(effects) do
	local combat = Combat()
	combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_PHYSICALDAMAGE)
	combat:setParameter(COMBAT_PARAM_EFFECT, effect)
	combat:setParameter(COMBAT_PARAM_BLOCKARMOR, true)
	combat:setParameter(COMBAT_PARAM_USECHARGES, true)
	combat:setArea(area)

	function onGetFormulaValues(player, skill, attack, factor)
		local min = (player:getLevel() / 5) + (skill * attack * 0.03) + 8
		local max = (player:getLevel() / 5) + (skill * attack * 0.05) + 14
		return -min, -max
	end

	combat:setCallback(CALLBACK_PARAM_SKILLVALUE, "onGetFormulaValues")
	combats[direction] = combat
end

local spell = Spell(SPELL_INSTANT)

function spell.onCastSpell(creature, variant)
	local combat = combats[creature:getDirection()] or combats[DIRECTION_NORTH]
	return combat:execute(creature, variant)
end

spell:group("attack")
spell:id(247)
spell:name("Splitter Drive")
spell:words("kor ven")
spell:level(25)
spell:mana(26)
spell:needDirection(true)
spell:needWeapon(true)
spell:cooldown(4500)
spell:groupCooldown(2000)
spell:vocation("warrior;true", "elite warrior;true")
spell:register()
