Game.createQuest("Rat Extermination", {
	storageId = 410001,
	storageValue = 1,
	missions = {
		{
			name = "Receive the contract",
			storageId = 410001,
			startValue = 1,
			endValue = 1,
			description = "Accept the Merchant's rat control contract.",
		},
		{
			name = "Consult the Guard",
			storageId = 410001,
			startValue = 1,
			endValue = 2,
			description = function(player)
				local value = player:getStorageValue(410001)
				if value >= 2 then
					return "The Guard points you toward the Priest. He thinks the crypt tunnels are part of the problem."
				end

				return "Ask the Guard what he has seen near the storehouses."
			end,
		},
		{
			name = "Hear the Priest's advice",
			storageId = 410001,
			startValue = 2,
			endValue = 3,
			description = function(player)
				local value = player:getStorageValue(410001)
				if value >= 3 then
					return "The Priest warned you to clear the nests quickly before they spread deeper into town."
				end

				return "Ask the Priest how to deal with the rats nesting near the old crypt."
			end,
		},
		{
			name = "Clear the infestation",
			storageId = 410002,
			startValue = 0,
			endValue = 21,
			description = function(player)
				local value = math.max(player:getStorageValue(410002), 0)
				if value >= 21 then
					return "Excellent work. The warehouse district should be safer now."
				end

				if value >= 20 then
					return "That should keep the infestation under control. Return to the Merchant."
				end

				return string.format("Keep going. You have slain %d/20 rats so far.", value)
			end,
		},
	},
}):register()
