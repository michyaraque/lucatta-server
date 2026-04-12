local config = {}

local changeGold = Action()

function changeGold.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local coin = config[item:getId()]
	if coin.changeTo and item.type == 100 then
		item:remove()
		player:addItem(coin.changeTo, 1)
	elseif coin.changeBack then
		item:remove(1)
		player:addItem(coin.changeBack, 100)
	else
		return false
	end
	return true
end

local currencyItems = Game.getCurrencyItems()
local registeredCurrencyIds = 0
for index, currency in pairs(currencyItems) do
	local back, to = currencyItems[index - 1], currencyItems[index + 1]
	local currencyId = currency:getId()
	config[currencyId] = { changeBack = back and back:getId(), changeTo = to and to:getId() }
	changeGold:id(currencyId)
	registeredCurrencyIds = registeredCurrencyIds + 1
end

if registeredCurrencyIds > 0 then
	changeGold:register()
else
	print("[Warning - change_gold.lua] No currency ids found, action not registered.")
end
