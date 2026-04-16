local spell = Spell(SPELL_INSTANT)

function spell.onCastSpell(creature, variant)
	return creature:conjureItem(0, 2260, 1)
end

spell:group("support")
spell:name("Blank Rune")
spell:words("adori blank")
spell:level(20)
spell:mana(50)
spell:soul(1)
spell:isAggressive(false)
spell:cooldown(2000)
spell:groupCooldown(2000)
spell:vocation("shaman;true", "elder shaman;true", "archer;true", "royal archer;true", "mage;true", "master mage;true")
spell:register()
