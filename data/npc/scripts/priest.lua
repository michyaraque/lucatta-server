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
	local stage = player:getStorageValue(storage.ratStage)

	if (msgcontains(msg, "rat") or msgcontains(msg, "merchant") or msgcontains(msg, "crypt")) and stage == 2 then
		player:setStorageValue(storage.ratStage, 3)
		if player:getStorageValue(storage.ratKills) < 0 then
			player:setStorageValue(storage.ratKills, 0)
		end
		npcHandler:say("Those vermin nest where the old crypt tunnels brush against the town. Clean them out quickly, then report back to the Merchant before they spread again.", cid)
		return true
	end

	if msgcontains(msg, "frontier") or msgcontains(msg, "frozen") or msgcontains(msg, "route") or msgcontains(msg, "lair") or msgcontains(msg, "necromancer") or msgcontains(msg, "butcher") then
		local frontierState = player:getStorageValue(storage.frozenFrontier)
		local heartState = player:getStorageValue(storage.necromancerHeart)
		local butcherState = player:getStorageValue(storage.butcher)

		if frontierState < 0 and player:getStorageValue(storage.skeletonKing) >= 2 then
			QuestChain.startQuest(player, storage.frozenFrontier, 0)
			npcHandler:say("Travel into the freezing lands and step onto the high plateau. Return once you have confirmed the route is still passable.", cid)
			return true
		end

		if frontierState == 0 then
			npcHandler:say("Reach the high plateau in the frontier, then return to me with your report.", cid)
			return true
		end

		if frontierState == 1 then
			player:setStorageValue(storage.frozenFrontier, 2)
			npcHandler:say("Good. If the path is open, our enemies beyond it are next. The Guard will know where to send you.", cid)
			return true
		end

		if heartState < 0 and player:getStorageValue(storage.skeletonCommander) >= 2 then
			QuestChain.startQuest(player, storage.necromancerHeart, 0)
			npcHandler:say("If the Necromancer still chants below, the dead will never stay buried. Bring me his heart as proof that his ritual has ended.", cid)
			return true
		end

		if heartState == 0 then
			if player:getItemCount(item.necromancerHeart) < 1 then
				npcHandler:say("Go to the lair, bring down the Necromancer, and show me his heart.", cid)
				return true
			end

			player:setStorageValue(storage.necromancerHeart, 1)
			npcHandler:say("This heart still thrums with foul power. Then it is true: the Necromancer is gone. Speak with the Merchant next.", cid)
			return true
		end

		if butcherState < 0 and player:getStorageValue(storage.spiderQueen) >= 2 then
			QuestChain.startQuest(player, storage.butcher, 0)
			npcHandler:say("A butcher feeds on trapped souls in the lower crypt. Enter the chamber, destroy him, and return here.", cid)
			return true
		end

		if butcherState == 0 then
			npcHandler:say("The butcher still stands. End him before more souls are trapped there.", cid)
			return true
		end

		if butcherState == 1 then
			player:setStorageValue(storage.butcher, 2)
			npcHandler:say("Those souls may finally rest. The King now waits for the last report.", cid)
			return true
		end
	end

	npcHandler:say("Keep faith. If you need guidance, ask me about the frontier or the lair.", cid)
	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
