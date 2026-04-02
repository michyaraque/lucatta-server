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
	if msgcontains(msg, "dragon") or msgcontains(msg, "wing") or msgcontains(msg, "serpent") then
		local wingState = player:getStorageValue(storage.dragonWing)

		if wingState < 0 and player:getStorageValue(storage.nft) >= 1 then
			QuestChain.startQuest(player, storage.dragonWing, 0)
			npcHandler:say("Those serpent nests hide remnants of something much older. Bring me a Dragon Wing from their lair.", cid)
			return true
		end

		if wingState == 0 then
			if not QuestChain.finishItemStep(player, storage.dragonWing, item.dragonWing, true) then
				npcHandler:say("Recover a Dragon Wing from the serpent nests and bring it here.", cid)
			else
				npcHandler:say("A real Dragon Wing. Then the old tales were not exaggerations. Victor will want to hear from you next.", cid)
			end
			return true
		end

		if wingState >= 1 then
			npcHandler:say("You already brought me the wing I asked for.", cid)
			return true
		end
	end

	npcHandler:say("If you are hunting old remains, ask me about the dragon wing.", cid)
	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
