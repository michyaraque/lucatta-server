Discord = {}

Discord.Emojis = {
    SkullLegendary = "<:skull_legendary:1461846008748179657>"
}

local DEFAULT_TIMEOUT = 5000

local function buildPayload(message)
    if type(message) == "table" then
        local payload = {}
        for key, value in pairs(message) do
            payload[key] = value
        end

        if payload.allowed_mentions == nil then
            payload.allowed_mentions = { parse = {} }
        end

        return payload
    end

    return {
        content = tostring(message or ""),
        allowed_mentions = { parse = {} },
    }
end

local function sendMessage(message, webhook)
    local httpClientRequest = HttpClientRequest()
    local headers = {
        ["Content-Type"] = "application/json"
    }
    local payload = buildPayload(message)
    local data = json.encode(payload)

    httpClientRequest:setTimeout(DEFAULT_TIMEOUT)
    return httpClientRequest:post(webhook, function(response)
        if not response.success then
            print(string.format("[Discord] Webhook request failed: %s", response.errorMessage))
            return
        end

        if response.statusCode >= 400 then
            print(string.format("[Discord] Webhook returned status %d: %s", response.statusCode, response.bodyData or ""))
        end
    end, headers, data)
end

function Discord.sendUpgradeMessage(message)
    local webhook = "https://discord.com/api/webhooks/1395577713506648075/OoIbSG0AuxhUn1GOMKMoeXXbOF4QFRgqnliLkWtK6bF7lOYVx8r9rjmFW8JChtR0bzho"
    return sendMessage(message, webhook)
end

function Discord.sendDropMessage(message)
    local webhook = "https://discord.com/api/webhooks/1395578238255894638/DUyjDFfN1tKZmIw6SpgxbPvWyOgpeIyXaPea9MalkARlSnNHykBQfuz8lM8nNBgB5ryZ"
    return sendMessage(message, webhook)
end

function Discord.sendReportMessage(message)
    local webhook = "https://discord.com/api/webhooks/1491403201348370463/80Be2MPGNYW46BUc_ksUWgtw-4Q8yJtkTjcuRyK_dxfuqTa2H-QHhlbJyYF1cDFEMgHL"
    return sendMessage(message, webhook)
end
