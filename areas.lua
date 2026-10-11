-- Update this file with new areas to blacklist or whitelist for instances

---@class RestrictedAreasCorner
---@field x integer
---@field z integer
---@field level integer

---@class RestrictedAreasArea
---@field label string
---@field corners RestrictedAreasCorner[]

---@class RestrictedAreasLists
---@field blacklist RestrictedAreasArea[]
---@field whitelist RestrictedAreasArea[]

---@type RestrictedAreasLists
local lists = {
    blacklist = {},
    whitelist = {},
}

return lists
