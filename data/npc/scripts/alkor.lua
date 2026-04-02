local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

local nftItemId = 273
local nftStorage = PlayerStorageKeys.achievementNFT

function onCreatureAppear(cid)				npcHandler:onCreatureAppear(cid)			end
function onCreatureDisappear(cid)			npcHandler:onCreatureDisappear(cid)			end
function onCreatureSay(cid, type, msg)		npcHandler:onCreatureSay(cid, type, msg)	end
function onThink()							npcHandler:onThink()						end

local function greetCallback(cid)
	local player = Player(cid)
	if player:getStorageValue(nftStorage) == 1 then
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
		local state = player:getStorageValue(nftStorage)
		if state < 0 then
			player:setStorageValue(nftStorage, 0)
			npcHandler:say("If you recover my Stone NFT, bring it back to me intact.", cid)
		elseif state == 0 then
			if player:removeItem(nftItemId, 1) then
				npcHandler:say("Excellent! My prized JPEG, returned at last. You have my deepest gratitude.", cid)
				player:setStorageValue(nftStorage, 1)
			else
				npcHandler:say("You have not recovered my Stone NFT yet.", cid)
			end
		else
			npcHandler:say("You already returned my JPEG. Thank you again!", cid)
		end
	elseif msgcontains(msg, "magic") then
		if player:getStorageValue(nftStorage) == 1 then
			npcHandler:say("Ancient legends describe a tome of magic hidden beneath the woodland. That's the extent of my knowledge, best of luck on your journey.", cid)
		end
	end

	return true
end

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
