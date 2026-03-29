local TILE_WIDGET_OPCODE = 200

-- Define positions where widgets should appear
-- You can add more properties here later (e.g., widget type, text, color)
local widgetPositions = {
    --[[ { pos = Position(113, 78, 7), id = "test_widget_2", text = "Chronos Fountain", color = "black", shine = true } ]]
}

TileWidgets = {
    positions = widgetPositions
}

function TileWidgets.broadcastPositions()
    local players = Game.getPlayers()
    for _, player in ipairs(players) do
        TileWidgets.sendPositions(player)
    end
end

-- Send an update for a specific widget to all players who can see it
function TileWidgets.sendToSpectators(pos, id, text, color)
    local spectators = Game.getSpectators(pos, false, true)
    local data = {
        action = "update",
        id = id,
        text = text,
        color = color
    }
    local json_data = json.encode(data)
    
    for _, spectator in ipairs(spectators) do
        spectator:sendExtendedOpcode(TILE_WIDGET_OPCODE, json_data)
    end
end

-- Helper to update local state and broadcast
function TileWidgets.updateWidget(id, text, color)
    for _, wp in ipairs(TileWidgets.positions) do
        if wp.id == id then
            wp.text = text
            wp.color = color
            TileWidgets.sendToSpectators(wp.pos, id, text, color)
            return true
        end
    end
    return false
end

function TileWidgets.sendUpdate(player, id, text, color)
    local data = {
        action = "update",
        id = id,
        text = text,
        color = color
    }
    player:sendExtendedOpcode(TILE_WIDGET_OPCODE, json.encode(data))
end

function TileWidgets.sendPositions(player)
    local data = {}
    for _, wp in ipairs(TileWidgets.positions) do
        table.insert(data, {
            x = wp.pos.x,
            y = wp.pos.y,
            z = wp.pos.z,
            id = wp.id,
            text = wp.text,
            color = wp.color,
            shine = wp.shine
        })
    end
    
    player:sendExtendedOpcode(TILE_WIDGET_OPCODE, json.encode(data))
end

local loginEvent = CreatureEvent("TileWidgetsLogin")
loginEvent:type("login")
function loginEvent.onLogin(player)
    player:registerEvent("TileWidgetsExtended")
    TileWidgets.sendPositions(player)
    return true
end
loginEvent:register()

local extendedEvent = CreatureEvent("TileWidgetsExtended")
extendedEvent:type("extendedopcode")
function extendedEvent.onExtendedOpcode(player, opcode, buffer)
    -- Client requesting data (e.g. on init or reload)
    TileWidgets.sendPositions(player)
    return true
end
extendedEvent:register()

-- Automatically send updates to all online players when this script is reloaded/loaded
TileWidgets.broadcastPositions()
