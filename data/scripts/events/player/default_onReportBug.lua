local event = Event()

local categoryNames = {
	[0] = "Map",
	[1] = "Typo",
	[2] = "Technical",
	[3] = "Other",
}

local function formatPosition(position)
	if not position then
		return "N/A"
	end

	return string.format("%d, %d, %d", position.x, position.y, position.z)
end

event.onReportBug = function(self, message, position, category)
	if self:getAccountType() == ACCOUNT_TYPE_NORMAL then
		return false
	end

	local playerPosition = self:getPosition()
	local categoryName = categoryNames[category] or tostring(category)
	local fields = {
		{
			name = "Player",
			value = self:getName(),
			inline = true,
		},
		{
			name = "Category",
			value = categoryName,
			inline = true,
		},
	}

	if position then
		table.insert(fields, {
			name = "Map Position",
			value = formatPosition(position),
			inline = true,
		})
	else
		table.insert(fields, {
			name = "Player Position",
			value = formatPosition(playerPosition),
			inline = true,
		})
	end

	local payload = {
		embeds = {
			{
				title = "Bug Report",
				description = message ~= "" and message or "No message provided.",
				color = 15105570,
				fields = fields,
				timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
			},
		},
	}

	local sent = Discord.sendReportMessage(payload)
	if not sent then
		self:sendTextMessage(MESSAGE_EVENT_DEFAULT, "There was an error when processing your report, please contact a gamemaster.")
		return true
	end

	self:sendTextMessage(MESSAGE_EVENT_DEFAULT, "Your report has been sent to " .. configManager.getString(configKeys.SERVER_NAME) .. " Team.")
	return true
end

event:register()
