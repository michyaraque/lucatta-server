local area = createCombatArea({
	{1, 1, 1, 1, 1},
	{0, 1, 1, 1, 0},
	{0, 0, 1, 0, 0},
	{0, 0, 3, 0, 0}
})

local effects = {
	[DIRECTION_NORTH] = 165,
	[DIRECTION_EAST] = 166,
	[DIRECTION_SOUTH] = 167,
	[DIRECTION_WEST] = 168
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
		local min = (player:getLevel() / 5) + (skill * attack * 0.02) + 6
		local max = (player:getLevel() / 5) + (skill * attack * 0.035) + 11
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
spell:id(245)
spell:name("Steel Arc")
spell:words("vor tal")
spell:level(55)
spell:mana(18)
spell:needDirection(true)
spell:needWeapon(true)
spell:cooldown(3000)
spell:groupCooldown(2000)
spell:vocation("knight;true", "elite knight;true")
spell:register()
