local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)				npcHandler:onCreatureAppear(cid)			end
function onCreatureDisappear(cid)			npcHandler:onCreatureDisappear(cid)			end
function onCreatureSay(cid, type, msg)		npcHandler:onCreatureSay(cid, type, msg)	end
function onThink()							npcHandler:onThink()						end

local function greetCallback(cid)
	local player = Player(cid)
	if player:getStorageValue(PlayerStorageKeys.achievementNFT) == 1 then
		npcHandler:setMessage(MESSAGE_GREET, "Thought my JPEG was lost forever. Do you have an interest in {magic}?")
	else
		npcHandler:setMessage(MESSAGE_GREET, "I had procured a valuable NFT of a stone for $2.8 million but unfortunately, it has gone missing. If you could retrieve it for me, I would be most grateful.")
	end
	return true
end

local function creatureSayCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end

	local player = Player(cid)

	if msgcontains(msg, "nft") or msgcontains(msg, "jpeg") or msgcontains(msg, "stone") then
		if player:getStorageValue(PlayerStorageKeys.achievementNFT) ~= 1 then
			npcHandler:say("Excellent! My prized JPEG, returned at last. You have my deepest gratitude.", cid)
			player:setStorageValue(PlayerStorageKeys.achievementNFT, 1)
		else
			npcHandler:say("You already returned my JPEG. Thank you again!", cid)
		end
	elseif msgcontains(msg, "magic") then
		if player:getStorageValue(PlayerStorageKeys.achievementNFT) == 1 then
			npcHandler:say("Ancient legends describe a tome of magic hidden beneath the woodland. That's the extent of my knowledge, best of luck on your journey.", cid)
		end
	end

	return true
end

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
