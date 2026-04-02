local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

local ratQuestStage = 410001
local ratQuestKills = 410002

function onCreatureAppear(cid)				npcHandler:onCreatureAppear(cid)			end
function onCreatureDisappear(cid)			npcHandler:onCreatureDisappear(cid)			end
function onCreatureSay(cid, type, msg)		npcHandler:onCreatureSay(cid, type, msg)	end
function onThink()							npcHandler:onThink()						end

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end

	local player = Player(cid)
	local stage = player:getStorageValue(ratQuestStage)

	if (msgcontains(msg, "rat") or msgcontains(msg, "merchant") or msgcontains(msg, "crypt")) and stage == 2 then
		player:setStorageValue(ratQuestStage, 3)
		if player:getStorageValue(ratQuestKills) < 0 then
			player:setStorageValue(ratQuestKills, 0)
		end
		npcHandler:say("Those vermin nest where the old crypt tunnels brush against the town. Clean them out quickly, then report back to the Merchant before they spread again.", cid)
		return true
	end

	if npcHandler.topic[cid] == 0 then
		npcHandler:say("Stay faithful, even where the old crypt brushes against the town.", cid)
		npcHandler.topic[cid] = 1
	elseif npcHandler.topic[cid] == 1 then
		npcHandler:say("Rot gathers fastest in the places people stop watching.", cid)
		npcHandler.topic[cid] = 0
	end

	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
