local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

local grimoireStorage = PlayerStorageKeys.achievementGrimoire

function onCreatureAppear(cid)				npcHandler:onCreatureAppear(cid)			end
function onCreatureDisappear(cid)			npcHandler:onCreatureDisappear(cid)			end
function onCreatureSay(cid, type, msg)		npcHandler:onCreatureSay(cid, type, msg)	end
function onThink()							npcHandler:onThink()						end

local function greetCallback(cid)
	local player = Player(cid)
	if player:getStorageValue(grimoireStorage) == 0 then
		player:setStorageValue(grimoireStorage, 1)
	end
	return true
end

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end

	if npcHandler.topic[cid] == 0 then
		npcHandler:say("It is said that whoever possesses the grimoire will have the power to control death itself.", cid)
		npcHandler.topic[cid] = 1
	elseif npcHandler.topic[cid] == 1 then
		npcHandler:say("Many believe that the grimoire is not meant for mortals and those who try to obtain it will pay a high price.", cid)
		npcHandler.topic[cid] = 0
	end

	return true
end

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
