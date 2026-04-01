local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)				npcHandler:onCreatureAppear(cid)			end
function onCreatureDisappear(cid)			npcHandler:onCreatureDisappear(cid)			end
function onCreatureSay(cid, type, msg)		npcHandler:onCreatureSay(cid, type, msg)	end
function onThink()							npcHandler:onThink()						end

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end

	if npcHandler.topic[cid] == 0 then
		npcHandler:say("An ancient undead lord is said to dwell here.", cid)
		npcHandler.topic[cid] = 1
	elseif npcHandler.topic[cid] == 1 then
		npcHandler:say("Nobody knows exactly what he looks like...", cid)
		npcHandler.topic[cid] = 2
	elseif npcHandler.topic[cid] == 2 then
		npcHandler:say("...for none has lived to tell the tale.", cid)
		npcHandler.topic[cid] = 3
	elseif npcHandler.topic[cid] == 3 then
		npcHandler:say("It's not too late to turn around and go home, kid.", cid)
		npcHandler.topic[cid] = 0
	end

	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
