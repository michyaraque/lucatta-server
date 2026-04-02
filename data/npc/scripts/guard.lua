local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

local storage = QuestChain.storage
local item = QuestChain.item

function onCreatureAppear(cid) npcHandler:onCreatureAppear(cid) end
function onCreatureDisappear(cid) npcHandler:onCreatureDisappear(cid) end
function onCreatureSay(cid, type, msg) npcHandler:onCreatureSay(cid, type, msg) end
function onThink() npcHandler:onThink() end

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end

	local player = Player(cid)

	if (msgcontains(msg, "rat") or msgcontains(msg, "merchant") or msgcontains(msg, "storehouse")) and player:getStorageValue(storage.ratStage) == 1 then
		player:setStorageValue(storage.ratStage, 2)
		npcHandler:say("The rats keep pouring out near the old storehouses. If you want the full story, speak to the Priest. He knows the crypt passages below that district.", cid)
		return true
	end

	if msgcontains(msg, "desert") or msgcontains(msg, "undead") or msgcontains(msg, "report") or msgcontains(msg, "quest") then
		local omenState = player:getStorageValue(storage.osseousOmens)
		local keyState = player:getStorageValue(storage.skeletonKey)
		local commanderState = player:getStorageValue(storage.skeletonCommander)

		if omenState < 0 and player:getStorageValue(storage.beachCrab) >= 13 then
			QuestChain.startQuest(player, storage.osseousOmens, 0)
			npcHandler:say("Scouts keep bringing me half-truths about bones walking in the desert. Speak to Paul at the desert outpost and bring me a reliable report.", cid)
			return true
		end

		if omenState == 0 then
			npcHandler:say("Head for the desert outpost and speak with Paul. He knows those ruins better than any scout I have.", cid)
			return true
		end

		if omenState == 1 then
			player:setStorageValue(storage.osseousOmens, 2)
			QuestChain.startQuest(player, storage.skeletonKey, 0)
			npcHandler:say("That confirms it. Bring me the Skeleton Key from those cursed halls. That will prove the old seal is truly broken.", cid)
			return true
		end

		if keyState == 0 then
			if player:getItemCount(item.skeletonKey) < 1 then
				npcHandler:say("Find the Skeleton Key in the crypt and show it to me.", cid)
				return true
			end

			player:setStorageValue(storage.skeletonKey, 1)
			npcHandler:say("So the key still exists. That means the old king's prison can be opened again. Take this news to the King.", cid)
			return true
		end

		if commanderState < 0 and player:getStorageValue(storage.frozenFrontier) >= 2 then
			QuestChain.startQuest(player, storage.skeletonCommander, 0)
			npcHandler:say("The frontier dead are moving with discipline. Find the Skeleton Commander, bring him down, and report back to me.", cid)
			return true
		end

		if commanderState == 0 then
			npcHandler:say("The commander is still out there. Break his command before the dead regroup.", cid)
			return true
		end

		if commanderState == 1 then
			player:setStorageValue(storage.skeletonCommander, 2)
			npcHandler:say("Good. Without leadership, the rest will break apart more easily. The Priest will want proof from the lair below.", cid)
			return true
		end
	end

	npcHandler:say("Stay alert. If you are here for work, ask me about the desert.", cid)
	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
