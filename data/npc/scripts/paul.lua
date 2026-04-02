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
	if player:getStorageValue(storage.osseousOmens) == 0 then
		npcHandler:setMessage(MESSAGE_GREET, "You are here about the desert ruins. Ask me about the {crypt}.")
	else
		npcHandler:setMessage(MESSAGE_GREET, "The dunes stay quiet only when people respect what sleeps beneath them.")
	end
	return true
end

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end

	local player = Player(cid)
	if (msgcontains(msg, "crypt") or msgcontains(msg, "desert") or msgcontains(msg, "ruins")) and player:getStorageValue(storage.osseousOmens) == 0 then
		player:setStorageValue(storage.osseousOmens, 1)
		npcHandler:say("The old crypt has awakened again. If you insist on going deeper, be prepared to face far more than loose bones.", cid)
		return true
	end

	npcHandler:say("If you came for a warning, ask about the crypt.", cid)
	return true
end

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
