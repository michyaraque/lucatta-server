local combat = Combat()
combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_HEALING)
combat:setParameter(COMBAT_PARAM_EFFECT, 141)
combat:setParameter(COMBAT_PARAM_AGGRESSIVE, false)

function onGetFormulaValues(player, skill, attack, factor)
	local min = (player:getLevel() / 5) + (skill * attack * 0.02) + 10
	local max = (player:getLevel() / 5) + (skill * attack * 0.035) + 18
	return min, max
end

combat:setCallback(CALLBACK_PARAM_SKILLVALUE, "onGetFormulaValues")

local spell = Spell(SPELL_INSTANT)

function spell.onCastSpell(creature, variant)
	return combat:execute(creature, variant)
end

spell:group("healing")
spell:id(243)
spell:name("Grit Mend")
spell:words("ren dor")
spell:level(14)
spell:mana(20)
spell:needWeapon(true)
spell:isAggressive(false)
spell:isSelfTarget(true)
spell:cooldown(2400)
spell:groupCooldown(1800)
spell:vocation("warrior;true", "elite warrior;true")
spell:register()
