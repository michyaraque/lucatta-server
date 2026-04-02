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
	if msgcontains(msg, "crystal") or msgcontains(msg, "shaman") or msgcontains(msg, "relic") then
		local crystalState = player:getStorageValue(storage.crystal)

		if crystalState < 0 and player:getStorageValue(storage.dragonWing) >= 1 then
			QuestChain.startQuest(player, storage.crystal, 0)
			npcHandler:say("Dark shamans stole a crystal of immense power. Recover it before they twist it further.", cid)
			return true
		end

		if crystalState == 0 then
			if not QuestChain.finishItemStep(player, storage.crystal, item.crystal, true) then
				npcHandler:say("Bring the crystal back from the shamans and return it to me.", cid)
			else
				npcHandler:say("The crystal is back. Good. In the wrong hands, this would have fed a catastrophe. Alkor should hear about what it points to.", cid)
			end
			return true
		end

		if crystalState >= 1 then
			npcHandler:say("The crystal is already secured.", cid)
			return true
		end
	end

	npcHandler:say("If you are here for the relic, ask me about the crystal.", cid)
	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
