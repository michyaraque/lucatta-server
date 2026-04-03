local sweetheartRing = Action()

function sweetheartRing.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if item == player:getSlotItem(CONST_SLOT_RING1) or item == player:getSlotItem(CONST_SLOT_RING2) then
		player:getPosition():sendMagicEffect(CONST_ME_HEARTS)
		return true
	end
	return false
end

sweetheartRing:id(24324)
sweetheartRing:register()
