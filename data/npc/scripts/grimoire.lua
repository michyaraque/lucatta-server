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
	if player:getStorageValue(storage.grimoireChamber) >= 1 and player:getStorageValue(storage.grimoire) == 0 then
		npcHandler:setMessage(MESSAGE_GREET, "The pages whisper. Ask about the {grimoire} if you want answers.")
	else
		npcHandler:setMessage(MESSAGE_GREET, "The pages remain silent.")
	end
	return true
end

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end

	local player = Player(cid)
	if (msgcontains(msg, "grimoire") or msgcontains(msg, "read") or msgcontains(msg, "whisper")) and player:getStorageValue(storage.grimoireChamber) >= 1 then
		if QuestChain.advanceExact(player, storage.grimoire, 0, 1) then
			npcHandler:say("The tome speaks of nests, queens, souls, and a fallen judge waiting beyond the temple.", cid)
		elseif player:getStorageValue(storage.grimoire) >= 1 then
			npcHandler:say("The warning has already been given. Return with what you learned.", cid)
		else
			npcHandler:say("You are not ready to understand these pages.", cid)
		end
		return true
	end

	npcHandler:say("Ask about the grimoire if you want the pages to answer.", cid)
	return true
end

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
