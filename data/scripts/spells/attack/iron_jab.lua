local combat = Combat()
combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_PHYSICALDAMAGE)
combat:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_HITAREA)
combat:setParameter(COMBAT_PARAM_DISTANCEEFFECT, CONST_ANI_WEAPONTYPE)
combat:setParameter(COMBAT_PARAM_BLOCKARMOR, true)
combat:setParameter(COMBAT_PARAM_USECHARGES, true)

function onGetFormulaValues(player, skill, attack, factor)
	local min = (player:getLevel() / 5) + (skill * attack * 0.015) + 4
	local max = (player:getLevel() / 5) + (skill * attack * 0.03) + 8
	return -min, -max
end

combat:setCallback(CALLBACK_PARAM_SKILLVALUE, "onGetFormulaValues")

local spell = Spell(SPELL_INSTANT)

function spell.onCastSpell(creature, variant)
	return combat:execute(creature, variant)
end

spell:group("attack")
spell:id(244)
spell:name("Iron Jab")
spell:words("tor vak")
spell:level(2)
spell:mana(12)
spell:range(4)
spell:needTarget(true)
spell:needWeapon(true)
spell:blockWalls(true)
spell:cooldown(1800)
spell:groupCooldown(1500)
spell:vocation("warrior;true", "elite warrior;true")
spell:register()
