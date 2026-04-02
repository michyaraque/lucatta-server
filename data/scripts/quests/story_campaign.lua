local function stateDescription(storageId, states)
	return function(player)
		local value = player:getStorageValue(storageId)
		return states[value] or states.default or ""
	end
end

local function progressDescription(storageId, label, target, readyValue, endValue, readyText, completeText)
	return function(player)
		local value = math.max(player:getStorageValue(storageId), 0)
		if value >= endValue then
			return completeText
		end

		if readyValue and value >= readyValue then
			return readyText
		end

		return string.format("%s: %d/%d.", label, math.min(value, target), target)
	end
end

local quests = {
	{
		name = "Beach Crab Contract",
		startStorage = 410101,
		startValue = 0,
		missions = {
			{
				name = "Clear the shore",
				storageId = 410101,
				startValue = 0,
				endValue = 13,
				description = progressDescription(
					410101,
					"Crabs defeated",
					12,
					12,
					13,
					"The beach looks manageable again. Return to Christopher.",
					"Much better. The shore is calm again."
				),
			},
		},
	},
	{
		name = "Osseous Omens",
		startStorage = 410111,
		startValue = 0,
		missions = {
			{
				name = "Consult the desert guide",
				storageId = 410111,
				startValue = 0,
				endValue = 2,
				description = stateDescription(410111, {
					[0] = "Speak with the desert guide and bring the warning back to the Guard.",
					[1] = "You have the warning you needed. Return to the Guard.",
					[2] = "That confirms it. Proof from the crypt itself is next.",
				}),
			},
		},
	},
	{
		name = "Skeleton Key Proof",
		startStorage = 410121,
		startValue = 0,
		missions = {
			{
				name = "Recover the key",
				storageId = 410121,
				startValue = 0,
				endValue = 1,
				description = stateDescription(410121, {
					[0] = "Find the Skeleton Key and present it to the Guard.",
					[1] = "This is enough evidence. The King must hear of it at once.",
				}),
			},
		},
	},
	{
		name = "The Skeleton King Falls",
		startStorage = 410131,
		startValue = 0,
		missions = {
			{
				name = "Enter the royal crypt",
				storageId = 410131,
				startValue = 0,
				endValue = 1,
				description = stateDescription(410131, {
					[0] = "Reach the Skeleton King's domain hidden beneath the desert.",
					[1] = "You found the chamber. Now finish what you started.",
				}),
			},
			{
				name = "Slay the Skeleton King",
				storageId = 410132,
				startValue = 0,
				endValue = 2,
				description = stateDescription(410132, {
					[0] = "Defeat the Skeleton King and return to the King with news of his fall.",
					[1] = "The Skeleton King has fallen. Return to the King.",
					[2] = "Excellent. The desert tombs should stay quieter for a while.",
				}),
			},
		},
	},
	{
		name = "Frozen Frontier",
		startStorage = 410141,
		startValue = 0,
		missions = {
			{
				name = "Reach the high plateau",
				storageId = 410141,
				startValue = 0,
				endValue = 2,
				description = stateDescription(410141, {
					[0] = "Climb into the frozen frontier and reach the high plateau.",
					[1] = "You reached the frontier. Return to the Priest with your report.",
					[2] = "Good. If the path is open, the enemy beyond it is next.",
				}),
			},
		},
	},
	{
		name = "Commander At The Gate",
		startStorage = 410151,
		startValue = 0,
		missions = {
			{
				name = "Kill the Skeleton Commander",
				storageId = 410151,
				startValue = 0,
				endValue = 2,
				description = stateDescription(410151, {
					[0] = "Defeat the Skeleton Commander and return to the Guard.",
					[1] = "The commander is down. Return to the Guard.",
					[2] = "Without leadership, the rest will break apart more easily.",
				}),
			},
		},
	},
	{
		name = "Heart Of The Lair",
		startStorage = 410161,
		startValue = 0,
		missions = {
			{
				name = "Bring proof from the lair",
				storageId = 410161,
				startValue = 0,
				endValue = 1,
				description = stateDescription(410161, {
					[0] = "Recover the Necromancer's Heart and present it to the Priest.",
					[1] = "The lair has been cleansed. The road to deeper horrors is open.",
				}),
			},
		},
	},
	{
		name = "King Of Cows",
		startStorage = 410171,
		startValue = 0,
		missions = {
			{
				name = "Bring back the horn",
				storageId = 410171,
				startValue = 0,
				endValue = 1,
				description = stateDescription(410171, {
					[0] = "Recover the Cow King's Horn and present it to the Merchant.",
					[1] = "The hidden pasture is real, and other secret paths may be within reach.",
				}),
			},
		},
	},
	{
		name = "Alkor's Lost JPEG",
		startStorage = 410181,
		startValue = 0,
		missions = {
			{
				name = "Return the NFT",
				storageId = 410181,
				startValue = 0,
				endValue = 1,
				description = stateDescription(410181, {
					[0] = "Recover the Stone NFT and return it to Alkor.",
					[1] = "Alkor has his NFT back and is willing to share what he knows next.",
				}),
			},
		},
	},
	{
		name = "Olaf's Dragon Remnants",
		startStorage = 410191,
		startValue = 0,
		missions = {
			{
				name = "Return the Dragon Wing",
				storageId = 410191,
				startValue = 0,
				endValue = 1,
				description = stateDescription(410191, {
					[0] = "Recover a Dragon Wing and deliver it to Olaf.",
					[1] = "Olaf keeps his word, and his stories point toward darker relics.",
				}),
			},
		},
	},
	{
		name = "Victor's Crystal Recovery",
		startStorage = 410201,
		startValue = 0,
		missions = {
			{
				name = "Return the Crystal",
				storageId = 410201,
				startValue = 0,
				endValue = 1,
				description = stateDescription(410201, {
					[0] = "Recover the Crystal and deliver it to Victor.",
					[1] = "Victor secures the relic and points you toward the hidden tome.",
				}),
			},
		},
	},
	{
		name = "Whispers Of The Grimoire",
		startStorage = 410211,
		startValue = 0,
		missions = {
			{
				name = "Find the chamber",
				storageId = 410211,
				startValue = 0,
				endValue = 1,
				description = stateDescription(410211, {
					[0] = "Reach the hidden chamber below the woodland where the tome rests.",
					[1] = "You found the chamber. Now learn what the tome is trying to tell you.",
				}),
			},
			{
				name = "Consult the Grimoire",
				storageId = 410212,
				startValue = 0,
				endValue = 2,
				description = stateDescription(410212, {
					[0] = "Speak with the Grimoire itself, then return to Alkor.",
					[1] = "You have the knowledge Alkor wanted. Return to him.",
					[2] = "The path is clear. The brood below must be broken next.",
				}),
			},
		},
	},
	{
		name = "Broodmother Downfall",
		startStorage = 410221,
		startValue = 0,
		missions = {
			{
				name = "Kill the Spider Queen",
				storageId = 410221,
				startValue = 0,
				endValue = 2,
				description = stateDescription(410221, {
					[0] = "Defeat the Spider Queen and return to Alkor.",
					[1] = "The broodmother is dead. Return to Alkor.",
					[2] = "One nest fewer stands between you and the deeper rot.",
				}),
			},
		},
	},
	{
		name = "Butcher Of Lost Souls",
		startStorage = 410231,
		startValue = 0,
		missions = {
			{
				name = "Kill the Butcher",
				storageId = 410231,
				startValue = 0,
				endValue = 2,
				description = stateDescription(410231, {
					[0] = "Defeat the Butcher and return to the Priest.",
					[1] = "The butcher is dead. Return to the Priest.",
					[2] = "Those souls may finally rest. One last judgement remains ahead.",
				}),
			},
		},
	},
	{
		name = "Judgement Of The Fallen",
		startStorage = 410241,
		startValue = 0,
		missions = {
			{
				name = "Enter the Temple of Light",
				storageId = 410241,
				startValue = 0,
				endValue = 1,
				description = stateDescription(410241, {
					[0] = "Reach the Temple of Light and press deeper into its halls.",
					[1] = "You reached the temple. The final chamber lies ahead.",
				}),
			},
			{
				name = "Kill Azrael",
				storageId = 410242,
				startValue = 0,
				endValue = 2,
				description = stateDescription(410242, {
					[0] = "Defeat Azrael and return to the King with the outcome.",
					[1] = "Azrael is down. Return to the King.",
					[2] = "The worst of this chain has finally been broken.",
				}),
			},
		},
	},
}

for _, quest in ipairs(quests) do
	Game.createQuest(quest.name, {
		storageId = quest.startStorage,
		storageValue = quest.startValue,
		missions = quest.missions,
	}):register()
end
