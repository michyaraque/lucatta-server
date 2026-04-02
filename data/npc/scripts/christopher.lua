local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

local storage = QuestChain.storage

function onCreatureAppear(cid) npcHandler:onCreatureAppear(cid) end
function onCreatureDisappear(cid) npcHandler:onCreatureDisappear(cid) end
function onCreatureSay(cid, type, msg) npcHandler:onCreatureSay(cid, type, msg) end
function onThink() npcHandler:onThink() end

local function greetCallback(cid)
	local player = Player(cid)
	local crabState = player:getStorageValue(storage.beachCrab)

	if crabState >= 13 then
		npcHandler:setMessage(MESSAGE_GREET, "The shore has been peaceful ever since you handled those crabs.")
	elseif crabState >= 12 then
		npcHandler:setMessage(MESSAGE_GREET, "The beach already looks calmer. Tell me about the {shore}.")
	elseif crabState >= 0 then
		npcHandler:setMessage(MESSAGE_GREET, "Those crabs are still ruining the beach. Ask me about the {shore} once you are ready.")
	elseif player:getStorageValue(storage.ratStage) >= 4 then
		npcHandler:setMessage(MESSAGE_GREET, "Vacation is impossible with those crabs everywhere. Ask me about the {shore} if you want the job.")
	else
		npcHandler:setMessage(MESSAGE_GREET, "Finish helping the town with its rat problem first. Then we can talk about the {shore}.")
	end

	return true
end

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end

	local player = Player(cid)
	local crabState = player:getStorageValue(storage.beachCrab)

	if msgcontains(msg, "shore") or msgcontains(msg, "crab") or msgcontains(msg, "contract") or msgcontains(msg, "help") then
		if crabState < 0 then
			if player:getStorageValue(storage.ratStage) < 4 then
				npcHandler:say("Handle the infestation in town first. After that, come back and we will clear the beach.", cid)
			else
				QuestChain.startQuest(player, storage.beachCrab, 0)
				npcHandler:say("Good. Sweep the beach and come back once the shoreline is safe again.", cid)
			end
		elseif crabState >= 12 and crabState < 13 then
			player:setStorageValue(storage.beachCrab, 13)
			npcHandler:say("Much better. I can finally enjoy the shore again. If you want more dangerous work, the Guard has been collecting reports from the desert.", cid)
		elseif crabState >= 13 then
			npcHandler:say("The beach is still calm thanks to you.", cid)
		else
			npcHandler:say("Clear out 12 crabs along the shore, then come back to me.", cid)
		end
		return true
	end

	npcHandler:say("If you want work, ask me about the shore.", cid)
	return true
end

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
