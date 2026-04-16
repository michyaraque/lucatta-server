local spell = Spell(SPELL_INSTANT)

function spell.onCastSpell(creature, variant)
	return creature:conjureItem(2260, 2311, 10)
end

spell:group("support")
spell:name("Heavy Magic Missile Rune")
spell:words("adori vis")
spell:level(25)
spell:mana(350)
spell:soul(2)
spell:isAggressive(false)
spell:cooldown(2000)
spell:groupCooldown(2000)
spell:vocation("mage;true", "master mage;true", "shaman;true", "elder shaman;true")
spell:register()
