local LOGIC_NAME = "RestrictedAreas"

local lists = require("areas")

---@class RestrictedAreasApi
---@field IsRestricted fun(): boolean
---@field Subscribe fun(name: string, callback: fun(restricted: boolean))
---@field Unsubscribe fun(name: string)
local api = {}

---@class RestrictedAreasListener
---@field name string
---@field callback fun(restricted: boolean)

---@type RestrictedAreasListener[]
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
---@param pos CoordGrid
---@return boolean
local function areaContains(entry, pos)
    if type(entry) ~= "table" or type(entry.corners) ~= "table" then
        return false
    end
    local first = entry.corners[1]
    local second = entry.corners[2]
    -- One bad Area must not reject the rest of the list.
    if not cornerComplete(first) or not cornerComplete(second) then
        return false
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

--- Checked tile: the live tile outside an Instance, the source tile inside one.
--- Nil means that tile cannot be read, which is Restricted.
---@return CoordGrid|nil tile
---@return boolean inInstance
local function checkedTile()
    local live = readLiveTile()
    if live == nil then
        return nil, false
    end
    if World.IsRegion() then
        local source = World.GetRegionSourceForCoordGrid(live)
        if not positionReadable(source) then
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

---@param name string
---@return integer|nil
local function findListener(name)
    for i = 1, #listeners do
        if listeners[i].name == name then
            return i
        end
    end
    return nil
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
    for i = 1, #listeners do
        batch[i] = listeners[i]
    end
    for i = 1, #batch do
        local item = batch[i]
        local index = findListener(item.name)
        if index ~= nil and listeners[index].callback == item.callback then
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
    local index = findListener(name)
    if index ~= nil then
        listeners[index].callback = callback
        return
    end
    if #listeners == 0 then
        -- Sample before the listener is recorded so a failure here leaves
        -- nobody subscribed and the tick unarmed. The sample is not delivered:
        -- a listener reads IsRestricted() for the current value.
        baseline = api.IsRestricted()
        Event.Logic.Subscribe(LOGIC_NAME, onLogic)
    end
    listeners[#listeners + 1] = { name = name, callback = callback }
end

---@param name string
function api.Unsubscribe(name)
    local index = findListener(name)
    if index == nil then
        return
    end
    table.remove(listeners, index)
    if #listeners == 0 then
        stopTicking()
    end
end

-- Disable and plugins_reload. Drop the tick so a disabled copy goes quiet.
function PluginShutdown()
    listeners = {}
    stopTicking()
end

RestrictedAreas = api

return api
