local LOGIC_NAME = "RestrictedAreas"
local DEBUG_DRAW_NAME = "RestrictedAreasDebug"

-- Flip this on while recording tiles, then reload. The top-left corner is the
-- tile to paste into areas.lua: the live tile, or the source tile in an Instance.
local DEBUG = false
local DEBUG_IGNORE_DEPTH = false

local lists = require("areas")

---@class RestrictedAreasApi
---@field IsRestricted fun(): boolean
---@field Subscribe fun(name: string, callback: fun(restricted: boolean))
---@field Unsubscribe fun(name: string)
local api = {}

-- Keyed by the name Subscribe was given. A second Subscribe for that name
-- replaces the callback. pairs order is not the call order; notify snapshots
-- the callbacks first so a listener cannot change who runs for this change.
---@type table<string, fun(restricted: boolean)>
local listeners = {}

-- Nil only while nobody is subscribed. Remembering it across that gap would
-- hand the next subscriber a transition they were not present for.
---@type boolean|nil
local baseline = nil

---@param pos CoordGrid|nil
---@return boolean
local function positionReadable(pos)
    -- Client tiles are userdata and the test double is a table. Level 0 is a
    -- real plane, so only a missing field counts as unreadable.
    return pos ~= nil and pos.x ~= nil and pos.z ~= nil and pos.level ~= nil
end

---@return CoordGrid|nil
local function readLiveTile()
    if not Player.IsAvailable() then
        return nil
    end
    local entity = Player.GetEntity()
    if entity == nil then
        return nil
    end
    local tile = entity.coordGrid
    if not positionReadable(tile) then
        return nil
    end
    return tile
end

---@param corner RestrictedAreasCorner|nil
---@return boolean
local function cornerComplete(corner)
    return type(corner) == "table"
        and corner.x ~= nil
        and corner.z ~= nil
        and corner.level ~= nil
end

---@param entry RestrictedAreasArea
---@return integer|nil x1
---@return integer|nil x2
---@return integer|nil z1
---@return integer|nil z2
---@return integer|nil level1
---@return integer|nil level2
local function areaBounds(entry)
    if type(entry) ~= "table" or type(entry.corners) ~= "table" then
        return nil
    end
    local first = entry.corners[1]
    local second = entry.corners[2]
    -- One bad Area must not reject the rest of the list.
    if not cornerComplete(first) or not cornerComplete(second) then
        return nil
    end
    local x1, x2 = first.x, second.x
    if x1 > x2 then
        x1, x2 = x2, x1
    end
    local z1, z2 = first.z, second.z
    if z1 > z2 then
        z1, z2 = z2, z1
    end
    local level1, level2 = first.level, second.level
    if level1 > level2 then
        level1, level2 = level2, level1
    end
    return x1, x2, z1, z2, level1, level2
end

---@param entry RestrictedAreasArea
---@param pos CoordGrid
---@return boolean
local function areaContains(entry, pos)
    local x1, x2, z1, z2, level1, level2 = areaBounds(entry)
    if x1 == nil then
        return false
    end
    return pos.x >= x1 and pos.x <= x2
        and pos.z >= z1 and pos.z <= z2
        and pos.level >= level1 and pos.level <= level2
end

---@param list RestrictedAreasArea[]|nil
---@param pos CoordGrid
---@return boolean
local function inList(list, pos)
    if type(list) ~= "table" then
        return false
    end
    for i = 1, #list do
        if areaContains(list[i], pos) then
            return true
        end
    end
    return false
end

-- GetRegionSourceForCoordGrid returns the bottom-left of an 8-tile source
-- block, not the tile the player is standing on. The block stays put while
-- you walk through it, then jumps, which slides a sheet anchored on the raw
-- value and then snaps it back.
local SOURCE_BLOCK = 8

---@param live CoordGrid
---@return RestrictedAreasCorner|nil
local function playerSourceTile(live)
    local origin = World.GetRegionSourceForCoordGrid(live)
    if not positionReadable(origin) then
        return nil
    end
    return {
        x = origin.x + live.x % SOURCE_BLOCK,
        z = origin.z + live.z % SOURCE_BLOCK,
        level = origin.level,
    }
end

--- Checked tile: the live tile outside an Instance, the source tile inside one.
--- Nil means that tile cannot be read, which is Restricted.
---@return CoordGrid|RestrictedAreasCorner|nil tile
---@return boolean inInstance
local function checkedTile()
    local live = readLiveTile()
    if live == nil then
        return nil, false
    end
    if World.IsRegion() then
        local source = playerSourceTile(live)
        if source == nil then
            return nil, true
        end
        return source, true
    end
    return live, false
end

---@return boolean
function api.IsRestricted()
    local pos, inInstance = checkedTile()
    if pos == nil then
        return true
    end
    if inList(lists.blacklist, pos) then
        return true
    end
    if inInstance and not inList(lists.whitelist, pos) then
        return true
    end
    return false
end

local function stopTicking()
    Event.Logic.Unsubscribe(LOGIC_NAME)
    baseline = nil
end

---@param restricted boolean
local function notify(restricted)
    -- Snapshot so a callback that subscribes, replaces, or unsubscribes cannot
    -- skip or duplicate the listeners that were current for this change.
    local batch = {}
    for name, callback in pairs(listeners) do
        batch[#batch + 1] = { name = name, callback = callback }
    end
    for i = 1, #batch do
        local item = batch[i]
        if listeners[item.name] == item.callback then
            local ok, err = pcall(item.callback, restricted)
            if not ok then
                log("RestrictedAreas listener failed: " .. tostring(err))
            end
        end
    end
end

local function onLogic()
    local now = api.IsRestricted()
    if baseline == nil or now == baseline then
        baseline = now
        return
    end
    baseline = now
    notify(now)
end

---@param name string
---@param callback fun(restricted: boolean)
function api.Subscribe(name, callback)
    local replacing = listeners[name] ~= nil
    if not replacing and next(listeners) == nil then
        -- Sample before the listener is recorded so a failure here leaves
        -- nobody subscribed and the tick unarmed. The sample is not delivered:
        -- a listener reads IsRestricted() for the current value.
        baseline = api.IsRestricted()
        Event.Logic.Subscribe(LOGIC_NAME, onLogic)
    end
    listeners[name] = callback
end

---@param name string
function api.Unsubscribe(name)
    if listeners[name] == nil then
        return
    end
    listeners[name] = nil
    if next(listeners) == nil then
        stopTicking()
    end
end

local DEBUG_TEXT_X = 8
local DEBUG_TEXT_Y = 8
local DEBUG_LINE_HEIGHT = 20

---@type ui.Canvas|nil
local debugCanvas = nil

---@param tile CoordGrid
---@return string
local function cornerLine(tile)
    return string.format(
        "{ x = %d, z = %d, level = %d },",
        math.floor(tile.x),
        math.floor(tile.z),
        math.floor(tile.level)
    )
end

-- Canvas colours are 0xRRGGBBAA. A 6-digit value drops red and uses the old blue byte as alpha.
local DEBUG_COLOUR = 0xFFFFFFFF
local DEBUG_RESTRICTED_COLOUR = 0xFF0000FF
local DEBUG_SHADOW_COLOUR = 0x000000FF
local DEBUG_AREA_COLOUR = 0xFF0000C0
local DEBUG_WHITELIST_COLOUR = 0x00FF00C0
-- Tiles past this are off screen, and each one is still a shape draw.
local DEBUG_DRAW_RANGE = 30

---@param surface ui.Canvas
---@param x integer
---@param y integer
---@param text string
---@param font integer
---@param colour integer
local function drawDebugLine(surface, x, y, text, font, colour)
    surface:AddText(x + 1, y + 1, text, font, DEBUG_SHADOW_COLOUR)
    surface:AddText(x, y, text, font, colour)
end

---@return ui.Canvas|nil
local function ensureDebugCanvas()
    if debugCanvas ~= nil then
        return debugCanvas
    end
    local parent = ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__GAME_AREA)
    if parent == nil then
        return nil
    end
    local created = ui.Canvas.new(parent)
    created:SetPos(0, 0)
    created:SetSize(0, 0, 1.0, 1.0)
    created.clickthrough = true
    debugCanvas = created
    return debugCanvas
end

---@type ShapeData|nil
local debugTileShape = nil

local function tileSheet()
    if debugTileShape ~= nil then
        return debugTileShape
    end
    local half = 256
    local shape = ShapeData.new()
    shape.positions = {
        Vector3.new(-half, 0, -half),
        Vector3.new(half, 0, -half),
        Vector3.new(half, 0, half),
        Vector3.new(-half, 0, half),
    }
    shape.tris = { 0, 1, 2, 0, 2, 3, 0, 2, 1, 0, 3, 2 }
    debugTileShape = shape
    return shape
end

---@param level integer
---@param x integer
---@param z integer
---@param colour integer
local function drawTileAt(level, x, z, colour)
    -- Copy tiles in an Instance sit past the overworld 0-12799 range. The
    -- client still builds a CoordGrid for them.
    if level < 0 or level > 3 or x < 0 or z < 0 then
        return
    end
    local grid = CoordGrid.new(level, math.floor(x / 64), math.floor(z / 64), x % 64, z % 64)
    if grid == nil then
        return
    end
    local fine = grid:ToCoordFine(true)
    if fine == nil then
        return
    end
    local position = fine.position
    if position == nil then
        return
    end
    local height, ok = World.GetGroundHeight(level, math.floor(position.x), math.floor(position.z))
    local y = 40
    if ok then
        y = height + 40
    elseif fine.y ~= nil then
        y = fine.y + 40
    end
    ShapeList.Draw{
        shapeData = tileSheet(),
        translation = Vector3.new(position.x, y, position.z),
        ignoreDepth = DEBUG_IGNORE_DEPTH,
        colour = colour,
    }
end

---@param entry RestrictedAreasArea
---@param colour integer
---@param shiftX integer
---@param shiftZ integer
---@param shiftLevel integer
---@param originX integer
---@param originZ integer
local function drawAreaVolume(entry, colour, shiftX, shiftZ, shiftLevel, originX, originZ)
    local x1, x2, z1, z2, level1, level2 = areaBounds(entry)
    if x1 == nil then
        return
    end
    local minX = originX - DEBUG_DRAW_RANGE
    local maxX = originX + DEBUG_DRAW_RANGE
    local minZ = originZ - DEBUG_DRAW_RANGE
    local maxZ = originZ + DEBUG_DRAW_RANGE
    if x2 < minX or x1 > maxX or z2 < minZ or z1 > maxZ then
        return
    end
    if x1 < minX then
        x1 = minX
    end
    if x2 > maxX then
        x2 = maxX
    end
    if z1 < minZ then
        z1 = minZ
    end
    if z2 > maxZ then
        z2 = maxZ
    end
    for level = level1, level2 do
        for x = x1, x2 do
            for z = z1, z2 do
                drawTileAt(level + shiftLevel, x + shiftX, z + shiftZ, colour)
            end
        end
    end
end

---@param list RestrictedAreasArea[]|nil
---@param colour integer
---@param shiftX integer
---@param shiftZ integer
---@param shiftLevel integer
---@param originX integer
---@param originZ integer
local function drawAreaList(list, colour, shiftX, shiftZ, shiftLevel, originX, originZ)
    if type(list) ~= "table" then
        return
    end
    for i = 1, #list do
        drawAreaVolume(list[i], colour, shiftX, shiftZ, shiftLevel, originX, originZ)
    end
end

---@param inInstance boolean
local function drawDebugAreas(inInstance)
    local live = readLiveTile()
    if live == nil then
        return
    end
    -- Area corners are source tiles. Inside an Instance the copy is that map
    -- shifted onto the live grid, so distance from the source tile matches
    -- distance from the sheet under your feet.
    local originX, originZ = live.x, live.z
    local shiftX, shiftZ, shiftLevel = 0, 0, 0
    if inInstance then
        local source = playerSourceTile(live)
        if source == nil then
            return
        end
        originX = source.x
        originZ = source.z
        shiftX = live.x - source.x
        shiftZ = live.z - source.z
        shiftLevel = live.level - source.level
        drawAreaList(lists.whitelist, DEBUG_WHITELIST_COLOUR, shiftX, shiftZ, shiftLevel, originX, originZ)
    end
    drawAreaList(lists.blacklist, DEBUG_AREA_COLOUR, shiftX, shiftZ, shiftLevel, originX, originZ)
end

local function onDebugDraw()
    if not DEBUG then
        if debugCanvas ~= nil then
            debugCanvas:Clear()
        end
        return
    end
    local tile, inInstance = checkedTile()
    drawDebugAreas(inInstance)
    local surface = ensureDebugCanvas()
    if surface == nil then
        return
    end
    surface:Clear()
    local font = id.Font.MUSEO_SANS_15PT_REGULAR
    local restricted = api.IsRestricted()
    local colour = DEBUG_COLOUR
    if restricted then
        colour = DEBUG_RESTRICTED_COLOUR
    end
    local y = DEBUG_TEXT_Y
    if tile ~= nil then
        drawDebugLine(surface, DEBUG_TEXT_X, y, cornerLine(tile), font, colour)
        y = y + DEBUG_LINE_HEIGHT
    end
    local verdict = "not restricted"
    if restricted then
        verdict = "restricted"
    end
    drawDebugLine(surface, DEBUG_TEXT_X, y, verdict, font, colour)
    if inInstance then
        y = y + DEBUG_LINE_HEIGHT
        drawDebugLine(surface, DEBUG_TEXT_X, y, "is in instance", font, colour)
    end
end

Event.Draw.Subscribe(DEBUG_DRAW_NAME, onDebugDraw)

-- Disable and plugins_reload. Drop the tick so a disabled copy goes quiet.
-- The client destroys the debug canvas itself.
function PluginShutdown()
    listeners = {}
    stopTicking()
    Event.Draw.Unsubscribe(DEBUG_DRAW_NAME)
    debugCanvas = nil
end

RestrictedAreas = api

return api
