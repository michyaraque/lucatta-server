local spell = Spell(SPELL_INSTANT)

function spell.onCastSpell(creature, variant)
	return creature:conjureItem(2260, 2310, 3)
end

spell:group("support")
spell:name("Disintegrate Rune")
spell:words("adito tera")
spell:level(21)
spell:mana(200)
spell:soul(3)
spell:isAggressive(false)
spell:cooldown(2000)
spell:groupCooldown(2000)
spell:vocation("mage;true", "shaman;true", "archer;true", "master mage;true", "elder shaman;true", "royal archer;true")
spell:register()
