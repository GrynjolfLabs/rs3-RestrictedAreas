-- Fakes for the local player, the world, and the logic tick.

local fakes = {}

local state = {
    available = true,
    tile = { x = 3200, z = 3200, level = 0 },
    instance = false,
    source = nil,
}

local logic = {
    name = nil,
    callback = nil,
}

local drawSubscriptions = 0
local canvasCreations = 0

local draw = {
    name = nil,
    callback = nil,
}

local drawn = {
    texts = {},
}

function fakes.reset()
    state.available = true
    state.tile = { x = 3200, z = 3200, level = 0 }
    state.instance = false
    state.source = nil
    drawn.texts = {}
end

--- Overworld tile the local player is standing on. nil hides the tile.
function fakes.setPlayer(x, z, level)
    state.available = true
    if x == nil then
        state.tile = nil
    else
        state.tile = { x = x, z = z, level = level }
    end
end

function fakes.setPlayerUnavailable()
    state.available = false
    state.tile = nil
end

--- Instance on/off. source nil means the source tile cannot be read.
function fakes.setInstance(on, source)
    state.instance = on == true
    state.source = source
end

function fakes.install()
    _G.Player = {
        IsAvailable = function()
            return state.available
        end,
        GetEntity = function()
            if not state.available or state.tile == nil then
                return nil
            end
            return { isValid = true, coordGrid = state.tile }
        end,
    }

    _G.World = {
        IsAvailable = function()
            return true
        end,
        IsRegion = function()
            return state.instance
        end,
        GetRegionSourceForCoordGrid = function(_coord)
            if not state.instance then
                return nil
            end
            return state.source
        end,
    }

    _G.Event = {
        Logic = {
            Subscribe = function(name, callback)
                logic.name = name
                logic.callback = callback
            end,
            Unsubscribe = function(name)
                if logic.name == name then
                    logic.name = nil
                    logic.callback = nil
                end
            end,
        },
        Draw = {
            Subscribe = function(name, callback)
                drawSubscriptions = drawSubscriptions + 1
                draw.name = name
                draw.callback = callback
            end,
            Unsubscribe = function(name)
                if draw.name == name then
                    draw.name = nil
                    draw.callback = nil
                end
            end,
        },
    }

    _G.ui = {
        Interfaces = {
            GetComponent = function()
                return {}
            end,
        },
        Canvas = {
            new = function()
                canvasCreations = canvasCreations + 1
                local canvas = {}
                function canvas:SetPos() end
                function canvas:SetSize() end
                function canvas:Clear()
                    drawn.texts = {}
                end
                function canvas:AddText(x, y, text, font, colour)
                    drawn.texts[#drawn.texts + 1] = {
                        x = x,
                        y = y,
                        text = text,
                        font = font,
                        colour = colour,
                    }
                end
                return canvas
            end,
        },
    }

    _G.id = {
        Component = {
            TOPLEVEL_V2__GAME_AREA = 1,
        },
        Font = {
            MUSEO_SANS_15PT_REGULAR = 2,
        },
    }

    _G.log = function() end
end

--- Runs one logic tick when the plugin is subscribed. Returns whether a tick ran.
function fakes.pump()
    if logic.callback == nil then
        return false
    end
    logic.callback({ logicTick = 1 })
    return true
end

function fakes.isTicking()
    return logic.callback ~= nil
end

function fakes.drawSubscriptions()
    return drawSubscriptions
end

function fakes.canvasCreations()
    return canvasCreations
end

function fakes.drawnTexts()
    return drawn.texts
end

--- Runs one draw when the debug overlay is subscribed. Returns whether it ran.
function fakes.pumpDraw()
    if draw.callback == nil then
        return false
    end
    draw.callback({ timeDeltaSecs = 0 })
    return true
end

return fakes
