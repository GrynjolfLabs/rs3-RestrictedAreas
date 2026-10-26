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
        -- {
        --     label = "Fort Forinthry - Bank Area",
        --     corners = {
        --         { x = 3285, z = 3562, level = 0 },
        --         { x = 3275, z = 3548, level = 0 },
        --     },
        -- },
        {
            label = "Chaos Elemental",
            corners = {
                { x = 3274, z = 3950, level = 0 },
                { x = 3201, z = 3905, level = 0 },
            },
        },
        {
            label = "KBD",
            corners = {
                { x = 2255, z = 4712, level = 0 },
                { x = 2289, z = 4679, level = 0 },
            },
        },
        {
            label = "KQ",
            corners = {
                { x = 3466, z = 9518, level = 0 },
                { x = 3509, z = 9482, level = 0 },
            },
        },
        {
            label = "Corp",
            corners = {
                { x = 2974, z = 4396, level = 2 },
                { x = 2999, z = 4371, level = 2 },
            },
        },
        {
            label = "Rex Matriarchs",
            corners = {
                { x = 3986, z = 9823, level = 0 },
                { x = 4020, z = 9759, level = 0 },
            },
        },
        {
            label = "Osseus",
            corners = {
                { x = 4043, z = 9800, level = 0 },
                { x = 4062, z = 9783, level = 0 },
            },
        },
    },
    whitelist = {
        -- {
        --     label = "Death's Office Instance",
        --     corners = {
        --         { x = 398, z = 686, level = 0 },
        --         { x = 431, z = 664, level = 0 },
        --     }
        -- },
        -- {
        --     label = "Mole Entrance",
        --     corners = {
        --         { x = 1749, z = 5244, level = 0 },
        --         { x = 1756, z = 5241, level = 0 },
        --     }
        -- },
        {
            label = "Fort Forinthry Crypt",
            corners = {
                { x = 1926, z = 1590, level = 1 },
                { x = 1976, z = 1540, level = 1 },
            }
        },
        {
            label = "Player-Owned Slayer Dungeon",
            corners = {
                { x = 1861, z = 6714, level = 0 },
                { x = 1915, z = 6659, level = 0 },
            }
        },
    },
}

return lists
