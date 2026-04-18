PacketHandlers = {}
CustomPacketHandlers = {}

local function hasValidCallback(self, scopeName)
	if not self.onReceive then
		debugPrint(string.format("[Warning - %s::register] need to setup a callback before you can register.", scopeName))
		return false
	end

	if type(self.onReceive) ~= "function" then
		debugPrint(string.format("[Warning - %s::onReceive] a function is expected.", scopeName))
		return false
	end

	return true
end

local function register(self)
	if isScriptsInterface() then
		if not hasValidCallback(self, "PacketHandler") then
			return
		end

		PacketHandlers[self.packetType] = self.onReceive
	end
end

local function clear(self)
	PacketHandlers[self.packetType] = nil
end

function PacketHandler(packetType)
	return {
		clear = clear,
		packetType = packetType,
		register = register,
	}
end

local function onReceiveCustomPacket(player, msg)
	if msg:len() < 1 then
		return
	end

	local packetType = msg:getByte()
	local handler = CustomPacketHandlers[packetType]
	if not handler then
		return
	end

	handler(player, msg)
end

local function registerCustom(self)
	if isScriptsInterface() then
		if not hasValidCallback(self, "CustomPacketHandler") then
			return
		end

		if not LUCATTA_BASE_PACKET then
			debugPrint("[Warning - CustomPacketHandler::register] LUCATTA_BASE_PACKET is not available.")
			return
		end

		local baseHandler = PacketHandlers[LUCATTA_BASE_PACKET]
		if baseHandler and baseHandler ~= onReceiveCustomPacket then
			debugPrint("[Warning - CustomPacketHandler::register] base packet is already bound to a different handler.")
			return
		end

		CustomPacketHandlers[self.packetType] = self.onReceive
		PacketHandlers[LUCATTA_BASE_PACKET] = onReceiveCustomPacket
	end
end

local function clearCustom(self)
	CustomPacketHandlers[self.packetType] = nil

	if LUCATTA_BASE_PACKET and next(CustomPacketHandlers) == nil and PacketHandlers[LUCATTA_BASE_PACKET] == onReceiveCustomPacket then
		PacketHandlers[LUCATTA_BASE_PACKET] = nil
	end
end

function CustomPacketHandler(packetType)
	return {
		clear = clearCustom,
		packetType = packetType,
		register = registerCustom,
	}
end
