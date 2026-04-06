
local ITEM_BAG = 37
local WOODEN_SHIELD = 143
local LEATHER_BELT = 85
local LEATHER_ARMOR = 22
local SWORD = 61

function onLogin(player)
	if player:getLastLoginSaved() == 0 then
		local bag = player:addItem(ITEM_BAG, 1)
		bag:addItem(WOODEN_SHIELD, 1)
		bag:addItem(LEATHER_BELT, 1)
		bag:addItem(LEATHER_ARMOR, 1)
		bag:addItem(SWORD, 1)
	end
	return true
end
