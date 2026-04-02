local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

local storage = QuestChain.storage
local item = QuestChain.item
local rewardGold = 100
local rewardExperience = 500
local rewardScroll = 74
local rewardScrollCount = 10
local rewardJewel = 1000

function onCreatureAppear(cid)				npcHandler:onCreatureAppear(cid)			end
function onCreatureDisappear(cid)			npcHandler:onCreatureDisappear(cid)			end
function onCreatureSay(cid, type, msg)		npcHandler:onCreatureSay(cid, type, msg)	end
function onThink()							npcHandler:onThink()						end

local function greetCallback(cid)
	local player = Player(cid)
	local stage = player:getStorageValue(storage.ratStage)

	if stage >= 4 then
		if player:getStorageValue(storage.cowHorn) >= 1 then
			npcHandler:setMessage(MESSAGE_GREET, "You already proved the hidden pasture is real.")
		elseif player:getStorageValue(storage.necromancerHeart) >= 1 then
			npcHandler:setMessage(MESSAGE_GREET, "If you want new business, ask me about the {cow} realm.")
		else
			npcHandler:setMessage(MESSAGE_GREET, "You already solved the rat infestation for me.")
		end
	else
		npcHandler:setMessage(MESSAGE_GREET, "I need help dealing with a rat infestation around town. If you want the {contract}, say so.")
	end

	return true
end

local function giveRatReward(player, cid)
	player:addMoney(rewardGold)
	player:addExperience(rewardExperience, true)
	player:addItem(rewardScroll, rewardScrollCount)
	player:addItem(rewardJewel, 1)
	player:setStorageValue(storage.ratKills, 21)
	player:setStorageValue(storage.ratStage, 4)
	npcHandler:say("Excellent work. The warehouse district should be safer now. Here is your payment.", cid)
end

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end

	local player = Player(cid)
	local stage = player:getStorageValue(storage.ratStage)
	local kills = player:getStorageValue(storage.ratKills)

	if msgcontains(msg, "contract") or msgcontains(msg, "rat") or msgcontains(msg, "job") then
		if stage < 1 then
			npcHandler:say("I need someone reliable. Speak to the Guard first, then ask the Priest for advice, clear out 20 rats, and return to me. Will you handle it?", cid)
			npcHandler.topic[cid] = 1
		elseif stage == 1 then
			npcHandler:say("Good. Start with the Guard. He has been watching the storehouses more closely than anyone else.", cid)
		elseif stage == 2 then
			npcHandler:say("The Guard sent you to the Priest. Hear the warning before you start killing rats blindly.", cid)
		elseif stage == 3 then
			if kills >= 20 then
				giveRatReward(player, cid)
			else
				npcHandler:say("Keep at it. You still need to thin the infestation before I can pay you.", cid)
			end
		else
			npcHandler:say("You already solved the rat infestation for me.", cid)
		end
	elseif msgcontains(msg, "yes") and npcHandler.topic[cid] == 1 then
		player:setStorageValue(storage.ratStage, 1)
		player:setStorageValue(storage.ratKills, -1)
		npcHandler:say("Good. Then start with the Guard. He has been watching the storehouses more closely than anyone else.", cid)
		npcHandler.topic[cid] = 0
	elseif msgcontains(msg, "no") and npcHandler.topic[cid] == 1 then
		npcHandler:say("Very well. Come back when you are ready to take the contract.", cid)
		npcHandler.topic[cid] = 0
	elseif msgcontains(msg, "reward") or msgcontains(msg, "payment") then
		if stage == 3 and kills >= 20 then
			giveRatReward(player, cid)
		elseif stage >= 4 then
			npcHandler:say("I already paid you for the rat contract.", cid)
		else
			npcHandler:say("Finish the contract first.", cid)
		end
	elseif msgcontains(msg, "cow") or msgcontains(msg, "horn") or msgcontains(msg, "portal") or msgcontains(msg, "pasture") then
		local cowState = player:getStorageValue(storage.cowHorn)
		if cowState < 0 and player:getStorageValue(storage.necromancerHeart) >= 1 then
			QuestChain.startQuest(player, storage.cowHorn, 0)
			npcHandler:say("If the Cow King is real, bring me his horn so I know that route can be exploited safely.", cid)
		elseif cowState == 0 then
			if player:getItemCount(item.cowHorn) < 1 then
				npcHandler:say("Enter the hidden pasture, defeat the Cow King, and show me his horn.", cid)
			else
				player:setStorageValue(storage.cowHorn, 1)
				npcHandler:say("A horn from the Cow King himself. Ridiculous, profitable, and exactly the proof I wanted. Alkor has been asking for capable help lately.", cid)
			end
		elseif cowState >= 1 then
			npcHandler:say("You already proved the Cow King was real.", cid)
		else
			npcHandler:say("Finish the contract first, then we can talk about stranger opportunities.", cid)
		end
	end

	return true
end

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
