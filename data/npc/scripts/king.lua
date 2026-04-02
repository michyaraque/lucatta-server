local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

local storage = QuestChain.storage

function onCreatureAppear(cid) npcHandler:onCreatureAppear(cid) end
function onCreatureDisappear(cid) npcHandler:onCreatureDisappear(cid) end
function onCreatureSay(cid, type, msg) npcHandler:onCreatureSay(cid, type, msg) end
function onThink() npcHandler:onThink() end

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end

	local player = Player(cid)

	if msgcontains(msg, "crypt") or msgcontains(msg, "king") or msgcontains(msg, "azrael") or msgcontains(msg, "temple") then
		local cryptState = player:getStorageValue(storage.skeletonCrypt)
		local kingState = player:getStorageValue(storage.skeletonKing)
		local templeState = player:getStorageValue(storage.temple)
		local azraelState = player:getStorageValue(storage.azrael)

		if cryptState < 0 and player:getStorageValue(storage.skeletonKey) >= 1 then
			QuestChain.startQuest(player, storage.skeletonCrypt, 0, storage.skeletonKing, 0)
			npcHandler:say("Enter the crypt, locate the royal chamber, and end the undead ruler below the desert.", cid)
			return true
		end

		if cryptState == 0 then
			npcHandler:say("Reach the royal chamber first. The work is not finished until you stand before the throne below.", cid)
			return true
		end

		if kingState == 0 then
			npcHandler:say("The chamber has been found. Now finish the undead ruler and return with news of his fall.", cid)
			return true
		end

		if kingState == 1 then
			player:setStorageValue(storage.skeletonKing, 2)
			npcHandler:say("Excellent. The desert tombs should stay quieter for a while. The Priest can now look north again.", cid)
			return true
		end

		if templeState < 0 and player:getStorageValue(storage.butcher) >= 2 then
			QuestChain.startQuest(player, storage.temple, 0, storage.azrael, 0)
			npcHandler:say("The path now leads to the temple itself. Enter it, reach the final chamber, and finish Azrael.", cid)
			return true
		end

		if templeState == 0 then
			npcHandler:say("Reach the temple and press deeper into its inner halls before returning here.", cid)
			return true
		end

		if azraelState == 0 then
			npcHandler:say("The final chamber still waits. Strike Azrael down and return to me.", cid)
			return true
		end

		if azraelState == 1 then
			player:setStorageValue(storage.azrael, 2)
			npcHandler:say("Then the worst of this chain has finally been broken.", cid)
			return true
		end
	end

	npcHandler:say("State your business plainly.", cid)
	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
