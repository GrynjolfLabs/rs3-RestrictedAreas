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
    blacklist = {
        {
            label = "Fort Forinthry - Bank Area",
            corners = {
                { x = 3285, z = 3562, level = 0 },
                { x = 3275, z = 3548, level = 0 },
            },
        },
    },
    whitelist = {
        {
            label = "Death's Office Instance",
            corners = {
                { x = 398, z = 686, level = 0 },
                { x = 431, z = 664, level = 0 },
            }
        },
        {
            label = "Mole Entrance",
            corners = {
                { x = 1749, z = 5244, level = 0 },
                { x = 1756, z = 5241, level = 0 },
            }
        },
    },
}

return lists
