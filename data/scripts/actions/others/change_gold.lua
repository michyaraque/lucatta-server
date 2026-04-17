local floor = math.floor

local config = {}
local changeGold = Action()

local function getChangeInfo(itemId, itemWorth, stackSize)
	local coin = config[itemId]
	if not coin then
		return false
	end

	local totalWorth = itemWorth * stackSize

	if coin.changeToId then
		local amount = totalWorth / coin.changeToWorth
		if amount > 0 and floor(amount) == amount then
			return coin.changeToId, amount
		end
	elseif coin.changeBackId then
		local amount = totalWorth / coin.changeBackWorth
		if amount > 0 and floor(amount) == amount then
			return coin.changeBackId, amount
		end
	end

	return false
end

function changeGold.onUse(player, item)
	local itemId = item:getId()
	local itemWorth = item:getType():getWorth()
	local stackSize = item:getCount()

	local outputId, outputAmount = getChangeInfo(itemId, itemWorth, stackSize)
	if not outputId then
		return false
	end

	item:remove()
	player:addItem(outputId, outputAmount)
	return true
end

local currencyItems = Game.getCurrencyItems()
local sortedCurrencies = {}

for _, currency in pairs(currencyItems) do
	sortedCurrencies[#sortedCurrencies + 1] = currency
end

table.sort(sortedCurrencies, function(a, b)
	return a:getWorth() < b:getWorth()
end)

local registered = 0
for i, currency in ipairs(sortedCurrencies) do
	local currencyId = currency:getId()

	config[currencyId] = {
		changeBackId = sortedCurrencies[i - 1] and sortedCurrencies[i - 1]:getId(),
		changeBackWorth = sortedCurrencies[i - 1] and sortedCurrencies[i - 1]:getWorth(),
		changeToId = sortedCurrencies[i + 1] and sortedCurrencies[i + 1]:getId(),
		changeToWorth = sortedCurrencies[i + 1] and sortedCurrencies[i + 1]:getWorth()
	}

	changeGold:id(currencyId)
	registered = registered + 1
end

if registered > 0 then
	changeGold:register()
else
	print("[Warning - change_gold.lua] No currency ids found, action not registered.")
end