local waypointPanel = {
	actionId = 1001,
	maskBits = 30,
	discoverDistance = 5,
	travelDistance = 10,
	teleportOffsetX = 1,
	states = {
		locked = 0,
		found = 1,
		premium = 2,
	},
	packets = {
		opcode = 201,
		subOpcodes = {
			update = 1,
			open = 2,
			goTo = 3,
		},
	},
	waypoints = {
		{ id = 0, name = "Village", position = Position(49, 213, 7) },
		{ id = 1, name = "No Man's Land", position = Position(70, 90, 7) },
		{ id = 2, name = "Volcanic Mountains", position = Position(63, 51, 7) },
		{ id = 3, name = "Freezing Lands", position = Position(78, 451, 7) },
		{ id = 4, name = "High Plateau", position = Position(22, 391, 7) },
		{ id = 5, name = "Necromancer Lair", position = Position(35, 342, 7) },
		{ id = 6, name = "Woodland", position = Position(100, 678, 7) },
		{ id = 7, name = "Castle ruins", position = Position(98, 606, 7) },
		{ id = 8, name = "Gateway", position = Position(128, 546, 7) },
		{ id = 9, name = "Lost Temple", position = Position(39, 593, 7) },
	},
	premiumLocks = {},
}

waypointPanel.byId = {}
waypointPanel.nearbyIndex = {}

for _, entry in ipairs(waypointPanel.waypoints) do
	waypointPanel.byId[entry.id] = entry
end

function waypointPanel.getPositionKey(position)
	return position.x + position.y * 65536 + position.z * 4294967296
end

function waypointPanel.addNearbyIndex(distance)
	local index = {}

	for _, entry in ipairs(waypointPanel.waypoints) do
		for offsetX = -distance, distance do
			for offsetY = -distance, distance do
				local position = Position(entry.position.x + offsetX, entry.position.y + offsetY, entry.position.z)
				local key = waypointPanel.getPositionKey(position)
				local currentId = index[key]
				local current = currentId and waypointPanel.byId[currentId] or nil

				if not current or position:getDistance(entry.position) < position:getDistance(current.position) then
					index[key] = entry.id
				end
			end
		end
	end

	waypointPanel.nearbyIndex[distance] = index
end

function waypointPanel.getStorageKey(waypointId)
	return PlayerStorageKeys.waypointMaskBase + math.floor(waypointId / waypointPanel.maskBits)
end

function waypointPanel.getBit(waypointId)
	return bit.lshift(1, waypointId % waypointPanel.maskBits)
end

function waypointPanel.hasUnlocked(player, waypointId)
	local value = math.max(player:getStorageValue(waypointPanel.getStorageKey(waypointId)), 0)
	return bit.band(value, waypointPanel.getBit(waypointId)) ~= 0
end

function waypointPanel.unlock(player, waypointId)
	local storageKey = waypointPanel.getStorageKey(waypointId)
	local currentValue = math.max(player:getStorageValue(storageKey), 0)
	local nextValue = bit.bor(currentValue, waypointPanel.getBit(waypointId))

	if nextValue ~= currentValue then
		player:setStorageValue(storageKey, nextValue)
	end
end

function waypointPanel.isPremiumLocked(player, waypointId)
	local requiredStorage = waypointPanel.premiumLocks[waypointId]
	if not requiredStorage then
		return false
	end

	return player:getStorageValue(requiredStorage) ~= 1
end

function waypointPanel.getStates(player)
	local states = {}

	for index, entry in ipairs(waypointPanel.waypoints) do
		if waypointPanel.hasUnlocked(player, entry.id) then
			states[index] = waypointPanel.states.found
		elseif waypointPanel.isPremiumLocked(player, entry.id) then
			states[index] = waypointPanel.states.premium
		else
			states[index] = waypointPanel.states.locked
		end
	end

	return states
end

function waypointPanel.sendStates(player)
	player:sendExtendedOpcode(waypointPanel.packets.opcode, json.encode({
		subOpcode = waypointPanel.packets.subOpcodes.update,
		waypoints = waypointPanel.getStates(player),
	}))
end

function waypointPanel.sendOpen(player, waypointId)
	player:sendExtendedOpcode(waypointPanel.packets.opcode, json.encode({
		subOpcode = waypointPanel.packets.subOpcodes.open,
		waypointId = waypointId,
	}))
end

function waypointPanel.findNearby(player, maxDistance)
	local waypointId = waypointPanel.nearbyIndex[maxDistance][waypointPanel.getPositionKey(player:getPosition())]
	return waypointId and waypointPanel.byId[waypointId] or nil
end

function waypointPanel.open(player)
	local nearby = waypointPanel.findNearby(player, waypointPanel.discoverDistance)
	if not nearby then
		player:sendCancelMessage("You are not near any waypoint.")
		return true
	end

	if not waypointPanel.hasUnlocked(player, nearby.id) then
		waypointPanel.unlock(player, nearby.id)
	end

	waypointPanel.sendStates(player)
	waypointPanel.sendOpen(player, nearby.id)
	return true
end

function waypointPanel.discover(player)
	local nearby = waypointPanel.findNearby(player, waypointPanel.discoverDistance)
	if not nearby then
		player:sendCancelMessage("You are not near any waypoint.")
		return
	end

	if waypointPanel.hasUnlocked(player, nearby.id) then
		player:sendCancelMessage("You have already found this waypoint.")
		return
	end

	waypointPanel.unlock(player, nearby.id)
	waypointPanel.sendStates(player)
end

function waypointPanel.travel(player, waypointId)
	local target = waypointPanel.byId[waypointId]
	if not target then
		return
	end

	local nearby = waypointPanel.findNearby(player, waypointPanel.travelDistance)
	if not nearby then
		player:sendCancelMessage("You are not near any waypoint.")
		return
	end

	if nearby.id == waypointId then
		player:sendCancelMessage("You are already at the waypoint.")
		return
	end

	if waypointPanel.isPremiumLocked(player, waypointId) then
		player:sendCancelMessage("You cannot use this waypoint yet.")
		return
	end

	if not waypointPanel.hasUnlocked(player, waypointId) then
		player:sendCancelMessage("You need to find the waypoint first.")
		return
	end

	local fromPosition = player:getPosition()
	local destination = Position(target.position.x + waypointPanel.teleportOffsetX, target.position.y, target.position.z)
	player:teleportTo(destination)
	fromPosition:sendMagicEffect(CONST_ME_TELEPORT)
	destination:sendMagicEffect(CONST_ME_TELEPORT)
end

local action = Action()

function action.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	return waypointPanel.open(player)
end

action:aid(waypointPanel.actionId)
action:register()

local loginEvent = CreatureEvent("WaypointPanelLogin")

function loginEvent.onLogin(player)
	player:registerEvent("WaypointPanelExtended")
	waypointPanel.sendStates(player)
	return true
end

loginEvent:type("login")
loginEvent:register()

local extendedEvent = CreatureEvent("WaypointPanelExtended")

function extendedEvent.onExtendedOpcode(player, opcode, buffer)
	if opcode ~= waypointPanel.packets.opcode then
		return true
	end

	local status, data = pcall(json.decode, buffer)
	if not status or type(data) ~= "table" then
		return true
	end

	if data.subOpcode == waypointPanel.packets.subOpcodes.goTo then
		waypointPanel.travel(player, tonumber(data.waypointId) or -1)
	end

	return true
end

extendedEvent:type("extendedopcode")
extendedEvent:register()

waypointPanel.addNearbyIndex(waypointPanel.discoverDistance)
waypointPanel.addNearbyIndex(waypointPanel.travelDistance)
