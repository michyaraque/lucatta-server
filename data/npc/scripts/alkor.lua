local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

local storage = QuestChain.storage
local item = QuestChain.item

function onCreatureAppear(cid) npcHandler:onCreatureAppear(cid) end
function onCreatureDisappear(cid) npcHandler:onCreatureDisappear(cid) end
function onCreatureSay(cid, type, msg) npcHandler:onCreatureSay(cid, type, msg) end
function onThink() npcHandler:onThink() end

local function greetCallback(cid)
	local player = Player(cid)
	if player:getStorageValue(storage.nft) >= 1 then
		npcHandler:setMessage(MESSAGE_GREET, "My stolen relic is back. If you need direction, ask about the {grimoire}.")
	else
		npcHandler:setMessage(MESSAGE_GREET, "My absurdly expensive stone relic has gone missing. Ask me about the {nft} if you can help.")
	end
	return true
end

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end

	local player = Player(cid)
	local nftState = player:getStorageValue(storage.nft)
	local grimoireState = player:getStorageValue(storage.grimoire)
	local spiderState = player:getStorageValue(storage.spiderQueen)

	if msgcontains(msg, "nft") or msgcontains(msg, "jpeg") or msgcontains(msg, "stone") then
		if nftState < 0 then
			if player:getStorageValue(storage.cowHorn) < 1 then
				npcHandler:say("Come back after you have finished the work tied to that hidden pasture.", cid)
			else
				QuestChain.startQuest(player, storage.nft, 0)
				npcHandler:say("Find the stone relic and bring it back to me intact.", cid)
			end
		elseif nftState == 0 then
			if not QuestChain.finishItemStep(player, storage.nft, item.nft, true) then
				npcHandler:say("You have not recovered my relic yet.", cid)
			else
				npcHandler:say("My relic, returned at last. If you keep working with me, ask about the grimoire beneath the woodland.", cid)
			end
		else
			npcHandler:say("You already returned the relic. Thank you again.", cid)
		end
		return true
	end

	if msgcontains(msg, "grimoire") or msgcontains(msg, "magic") or msgcontains(msg, "tome") then
		if player:getStorageValue(storage.crystal) >= 1 and player:getStorageValue(storage.grimoireChamber) < 0 then
			QuestChain.startQuest(player, storage.grimoireChamber, 0, storage.grimoire, 0)
			npcHandler:say("The relics all point to one thing now: a grimoire buried beneath the woodland. Find it, read what you can, then return to me.", cid)
			return true
		end

		if player:getStorageValue(storage.grimoireChamber) == 0 then
			npcHandler:say("Reach the hidden chamber below the woodland first. The tome will not come to you.", cid)
			return true
		end

		if grimoireState == 1 then
			player:setStorageValue(storage.grimoire, 2)
			QuestChain.startQuest(player, storage.spiderQueen, 0)
			npcHandler:say("Then the path is clear: the brood below must be broken next. Find the Spider Queen and return once the nest is shattered.", cid)
			return true
		end

		if spiderState == 0 then
			npcHandler:say("The broodmother still stands. Bring her down.", cid)
			return true
		end

		if spiderState == 1 then
			player:setStorageValue(storage.spiderQueen, 2)
			npcHandler:say("Good. One nest fewer between us and the deeper rot. The Priest should hear what comes next.", cid)
			return true
		end

		if nftState >= 1 then
			npcHandler:say("Ancient legends speak of a tome buried beneath the woodland. When the time is right, that is where you should go.", cid)
			return true
		end
	end

	npcHandler:say("Ask me about the nft or the grimoire if you need direction.", cid)
	return true
end

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
