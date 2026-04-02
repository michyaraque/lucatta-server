local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

local ratQuestStage = 410001
local ratQuestKills = 410002
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
	local stage = player:getStorageValue(ratQuestStage)

	if stage >= 4 then
		npcHandler:setMessage(MESSAGE_GREET, "You already solved the rat infestation for me.")
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
	player:setStorageValue(ratQuestKills, 21)
	player:setStorageValue(ratQuestStage, 4)
	npcHandler:say("Excellent work. The warehouse district should be safer now. Here is your payment.", cid)
end

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end

	local player = Player(cid)
	local stage = player:getStorageValue(ratQuestStage)
	local kills = player:getStorageValue(ratQuestKills)

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
		player:setStorageValue(ratQuestStage, 1)
		player:setStorageValue(ratQuestKills, -1)
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
	end

	return true
end

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
