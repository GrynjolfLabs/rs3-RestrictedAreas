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
        {
            label = "Barrows",
            corners = {
                { x = 3520, z = 9568, level = 0 },
                { x = 3583, z = 9727, level = 0 },
            }
        },
        {
            label = "Barrows - Akrisae",
            corners = {
                { x = 4067, z = 5706, level = 0 },
                { x = 4078, z = 5727, level = 0 },
            }
        },
        {
            label = "Dagannoth Kings",
            corners = {
                { x = 2898, z = 4436, level = 0 },
                { x = 2929, z = 4463, level = 0 },
            }
        },
        {
            label = "Kree'arra",
            corners = {
                { x = 2816, z = 5295, level = 0 },
                { x = 2842, z = 5310, level = 0 },
            }
        },
        {
            label = "General Graardor",
            corners = {
                { x = 2863, z = 5351, level = 0 },
                { x = 2879, z = 5375, level = 0 },
            }
        },
        {
            label = "K'ril Tsutsaroth",
            corners = {
                { x = 2914, z = 5332, level = 0 },
                { x = 2940, z = 5314, level = 0 },
            }
        },
        {
            label = "Commander Zilyana",
            corners = {
                { x = 2911, z = 5256, level = 0 },
                { x = 2935, z = 5240, level = 0 },
            }
        },
        {
            label = "Nex",
            corners = {
                { x = 2910, z = 5188, level = 0 },
                { x = 2941, z = 5219, level = 0 },
            }
        },
        {
            label = "Araxxi",
            corners = {
                { x = 4489, z = 6244, level = 1 },
                { x = 4602, z = 6280, level = 1 },
            }
        },
        {
            label = "Exiled Kalphite Queen",
            corners = {
                { x = 2946, z = 1692, level = 0 },
                { x = 2984, z = 1717, level = 0 },
            }
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
        {
            label = "Player-owned house - Plot",
            corners = {
                { x = 5120, z = 127, level = 0 },
                { x = 5183, z = 64,  level = 3 },
            }
        },
        {
            label = "Player-owned house - Homestead",
            corners = {
                { x = 3940, z = 2274, level = 0 },
                { x = 4189, z = 2006, level = 3 },
            }
        },
        {
            label = "Player-owned house - Aquarium",
            corners = {
                { x = 1537, z = 6657, level = 0 },
                { x = 1559, z = 6679, level = 0 },
            }
        },
        {
            label = "MTA Tele 1",
            corners = {
                { x = 3337, z = 9669, level = 2 },
                { x = 3372, z = 9693, level = 2 },
            },
        },
        {
            label = "MTA Tele 2",
            corners = {
                { x = 3361, z = 9706, level = 0 },
                { x = 3385, z = 9724, level = 0 },
            },
        },
        {
            label = "MTA Tele 3",
            corners = {
                { x = 3336, z = 9706, level = 1 },
                { x = 3366, z = 9721, level = 1 },
            },
        },
        {
            label = "MTA Tele 4",
            corners = {
                { x = 3334, z = 9673, level = 0 },
                { x = 3356, z = 9693, level = 0 },
            },
        },
        {
            label = "MTA Tele 5",
            corners = {
                { x = 3371, z = 9705, level = 1 },
                { x = 3388, z = 9723, level = 1 },
            },
        },
        {
            label = "MTA Tele 6",
            corners = {
                { x = 3337, z = 9698, level = 2 },
                { x = 3369, z = 9723, level = 2 },
            },
        },
        {
            label = "MTA Tele 7",
            corners = {
                { x = 3362, z = 9666, level = 0 },
                { x = 3386, z = 9701, level = 0 },
            },
        },
        {
            label = "MTA Tele 8",
            corners = {
                { x = 3331, z = 9700, level = 0 },
                { x = 3354, z = 9722, level = 0 },
            },
        },
        {
            label = "MTA Tele 9",
            corners = {
                { x = 3369, z = 9672, level = 1 },
                { x = 3388, z = 9701, level = 1 },
            },
        },
        {
            label = "MTA Tele 10",
            corners = {
                { x = 3337, z = 9673, level = 1 },
                { x = 3365, z = 9695, level = 1 },
            },
        },
        {
            label = "Dream of Iaia",
            corners = {
                { x = 2116, z = 1529, level = 0 },
                { x = 2178, z = 1603, level = 0 },
            },
        },
        {
            label = "Thalmund's Forge",
            corners = {
                { x = 2279, z = 7352, level = 0 },
                { x = 2304, z = 7371, level = 0 },
            },
        },
        {
            label = "Freneskae - The Pit",
            corners = {
                { x = 4051, z = 6285, level = 0 },
                { x = 4069, z = 6332, level = 0 },
            },
        },
        {
            label = "Freneskae - The Cradle",
            corners = {
                { x = 4243, z = 6223, level = 0 },
                { x = 4264, z = 6244, level = 0 },
            },
        },
    },
}

return lists
