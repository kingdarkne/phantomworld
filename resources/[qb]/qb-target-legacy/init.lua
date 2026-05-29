function Load(name)
    local resourceName = GetCurrentResourceName()
    local chunk = LoadResourceFile(resourceName, ('data/%s.lua'):format(name))
    if chunk then
        local err
        chunk, err = load(chunk, ('@@%s/data/%s.lua'):format(resourceName, name), 't')
        if err then
            error(('\n^1 %s'):format(err), 0)
        end
        return chunk()
    end
end

-------------------------------------------------------------------------------
-- Settings
-------------------------------------------------------------------------------

local Allowrefuel = false
local AllowElectricRefuel = false

Config = {}

-- It's possible to interact with entities through walls so this should be low
Config.MaxDistance = 5.0

-- Enable debug options
Config.Debug = false

-- Supported values: true, false
Config.Standalone = false

-- Enable outlines around the entity you're looking at
Config.EnableOutline = false

-- Enable default options (Toggling vehicle doors)
Config.EnableDefaultOptions = false

-- Disable the target eye whilst being in a vehicle
Config.DisableInVehicle = false

-- Key to open the target
Config.OpenKey = 'LMENU'   -- Left Alt
Config.OpenControlKey = 19 -- Control for keypress detection also Left Alt for the eye itself, controls are found here https://docs.fivem.net/docs/game-references/controls/

-- Key to open the menu
Config.MenuControlKey = 24 -- Control for keypress detection on the context menu, this is the Right Mouse Button, controls are found here https://docs.fivem.net/docs/game-references/controls/

-------------------------------------------------------------------------------
-- Target Configs
-------------------------------------------------------------------------------

-- These are all empty for you to fill in, refer to the .md files for help in filling these in

Config.CircleZones = {



}

Config.BoxZones = {

    ["firstspawn"] = {
        name = "firstspawn",
        coords = vector3(-1002.7823, -477.6714, 50.0274),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 73.890846,
        maxZ = 75.890846,
        options = {
            {
                event = "abl:ServerIntro:Show",
                icon = "fas fa-door-open",
                label = "Leave Appartment",
            }
        },
        distance = 2.5
    },

    -- CRYPTO SELLING
    ["cryptosell"] = {
        name = "cryptosell",
        coords = vector3(-568.8316, 227.72392, 74.890846),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 73.890846,
        maxZ = 75.890846,
        options = {
            {
                event = "qb-cryptoselling:hmenu",
                icon = "fas fa-circle",
                label = "Sell Crypto Papers",
            }
        },
        distance = 2.5
    },

    ["clubb77boss"] = {
        name = "clubb77boss",
        coords = vector3(244.91291, -3152.755, 3.3443551),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 2.3443551,
        maxZ = 4.3443551,
        options = {
            {
                type = "client",
                event = "qb-bossmenu:client:OpenMenu",
                icon = "fas fa-fish",
                label = "Open Boss Menu",
                job = { ["vanilla"] = 3 }
            }
        },
        distance = 2.5
    },

    -- KISS Dark
    ["kissdark"] = {
        name = "kissdark",
        coords = vector3(-582.3448, -939.8016, 15.350187),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 14.350187,
        maxZ = 16.350187,
        options = {
            {
                event = "dark:kiss",
                icon = "fas fa-kiss",
                label = "Get Blessed From Dark",
            }
        },
        distance = 2.5
    },

    -- OUTFITS AND LOCKERS

    ["pawnlocker"] = {
        name = "pawnlocker",
        coords = vector3(-333.5291, -93.85496, 46.716365),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 45.716365,
        maxZ = 47.716365,
        options = {
            {
                event = "qb-pawn:interact:stash",
                icon = "fas fa-circle",
                label = "Open Personal Locker",
                job = "pawn",
            }
        },
        distance = 2.5
    },

    ["clubb77locker"] = {
        name = "clubb77locker",
        coords = vector3(254.94779, -3151.615, 0.871946),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = -1.871946,
        maxZ = 1.871946,
        options = {
            {
                event = "qb-vanilla:interact:stash",
                icon = "fas fa-circle",
                label = "Open Personal Locker",
                job = "vanilla",
            },
            {
                type = "client",
                event = "Toggle:Duty",
                icon = "far fa-clipboard",
                label = "Sign In / Out",
                job = "vanilla",
            }
        },
        distance = 2.5
    },

    ["lockpick1"] = {
        name = "lockpick1",
        coords = vector3(-706.6069, -913.5006, 19.499462),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 18.499462,
        maxZ = 20.499462,
        options = {
            {
                event = "lockpicks:UseLockpickstore",
                icon = "fas fa-circle",
                label = "Lockpick [x1 Advanced Lockpick]",
                item = "advancedlockpick",
            }
        },
        distance = 2.5
    },

    ["lockpick5"] = {
        name = "lockpick5",
        coords = vector3(24.938266, -1344.945, 29.833364),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 28.833364,
        maxZ = 30.833364,
        options = {
            {
                event = "lockpicks:UseLockpickstore",
                icon = "fas fa-circle",
                label = "Lockpick [x1 Advanced Lockpick]",
                item = "advancedlockpick",
            }
        },
        distance = 2.5
    },

    ["lockpick9"] = {
        name = "lockpick9",
        coords = vector3(-48.35893, -1759.106, 29.782566),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 28.782566,
        maxZ = 30.782566,
        options = {
            {
                event = "lockpicks:UseLockpickstore",
                icon = "fas fa-circle",
                label = "Lockpick [x1 Advanced Lockpick]",
                item = "advancedlockpick",
            }
        },
        distance = 2.5
    },

    ["lockpick14"] = {
        name = "lockpick14",
        coords = vector3(-2967.019, 390.92764, 15.311362),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 14.311362,
        maxZ = 16.311362,
        options = {
            {
                event = "lockpicks:UseLockpickstore",
                icon = "fas fa-circle",
                label = "Lockpick [x1 Advanced Lockpick]",
                item = "advancedlockpick",
            }
        },
        distance = 2.5
    },

    ["lockpick21"] = {
        name = "lockpick21",
        coords = vector3(373.09472, 326.31842, 103.81027),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 102.81027,
        maxZ = 104.81027,
        options = {
            {
                event = "lockpicks:UseLockpickstore",
                icon = "fas fa-circle",
                label = "Lockpick [x1 Advanced Lockpick]",
                item = "advancedlockpick",
            }
        },
        distance = 2.5
    },

    ["lockpick20"] = {
        name = "lockpick20",
        coords = vector3(373.62365, 328.57797, 103.87372),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 102.87372,
        maxZ = 104.87372,
        options = {
            {
                event = "lockpicks:UseLockpickstore",
                icon = "fas fa-circle",
                label = "Lockpick [x1 Advanced Lockpick]",
                item = "advancedlockpick",
            }
        },
        distance = 2.5
    },

    ["lockpick18"] = {
        name = "lockpick18",
        coords = vector3(-3244.554, 1000.6056, 13.126884),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 12.126884,
        maxZ = 14.126884,
        options = {
            {
                event = "lockpicks:UseLockpickstore",
                icon = "fas fa-circle",
                label = "Lockpick [x1 Advanced Lockpick]",
                item = "advancedlockpick",
            }
        },
        distance = 2.5
    },

    ["lockpick17"] = {
        name = "lockpick16",
        coords = vector3(-3242.256, 1000.3637, 13.140783),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 12.140783,
        maxZ = 14.140783,
        options = {
            {
                event = "lockpicks:UseLockpickstore",
                icon = "fas fa-circle",
                label = "Lockpick [x1 Advanced Lockpick]",
                item = "advancedlockpick",
            }
        },
        distance = 2.5
    },

    ["lockpick16"] = {
        name = "lockpick16",
        coords = vector3(-3041.306, 584.21826, 8.1965112),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 7.1965112,
        maxZ = 9.1965112,
        options = {
            {
                event = "lockpicks:UseLockpickstore",
                icon = "fas fa-circle",
                label = "Lockpick [x1 Advanced Lockpick]",
                item = "advancedlockpick",
            }
        },
        distance = 2.5
    },

    ["lockpick15"] = {
        name = "lockpick15",
        coords = vector3(-3039.119, 584.95904, 8.2372174),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 7.2372174,
        maxZ = 9.2372174,
        options = {
            {
                event = "lockpicks:UseLockpickstore",
                icon = "fas fa-circle",
                label = "Lockpick [x1 Advanced Lockpick]",
                item = "advancedlockpick",
            }
        },
        distance = 2.5
    },

    ["lockpick12"] = {
        name = "lockpick12",
        coords = vector3(1164.1585, -322.7141, 69.54441),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 68.54441,
        maxZ = 70.54441,
        options = {
            {
                event = "lockpicks:UseLockpickstore",
                icon = "fas fa-circle",
                label = "Lockpick [x1 Advanced Lockpick]",
                item = "advancedlockpick",
            }
        },
        distance = 2.5
    },

    ["lockpick11"] = {
        name = "lockpick11",
        coords = vector3(1164.5784, -324.7715, 69.533973),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 68.782566,
        maxZ = 70.533973,
        options = {
            {
                event = "lockpicks:UseLockpickstore",
                icon = "fas fa-circle",
                label = "Lockpick [x1 Advanced Lockpick]",
                item = "advancedlockpick",
            }
        },
        distance = 2.5
    },

    ["lockpick10"] = {
        name = "lockpick10",
        coords = vector3(1134.7319, -982.4318, 46.727798),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 45.727798,
        maxZ = 47.727798,
        options = {
            {
                event = "lockpicks:UseLockpickstore",
                icon = "fas fa-circle",
                label = "Lockpick [x1 Advanced Lockpick]",
                item = "advancedlockpick",
            }
        },
        distance = 2.5
    },

    ["lockpick8"] = {
        name = "lockpick8",
        coords = vector3(-47.03275, -1757.587, 29.733654),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 28.733654,
        maxZ = 30.733654,
        options = {
            {
                event = "lockpicks:UseLockpickstore",
                icon = "fas fa-circle",
                label = "Lockpick [x1 Advanced Lockpick]",
                item = "advancedlockpick",
            }
        },
        distance = 2.5
    },

    ["lockpick7"] = {
        name = "lockpick7",
        coords = vector3(24.946395, -1347.333, 29.868452),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 28.868452,
        maxZ = 30.868452,
        options = {
            {
                event = "lockpicks:UseLockpickstore",
                icon = "fas fa-circle",
                label = "Lockpick [x1 Advanced Lockpick]",
                item = "advancedlockpick",
            }
        },
        distance = 2.5
    },


    ["lockpick4"] = {
        name = "lockpick4",
        coords = vector3(-1486.647, -378.4276, 40.503337),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 39.503337,
        maxZ = 41.503337,
        options = {
            {
                event = "lockpicks:UseLockpickstore",
                icon = "fas fa-circle",
                label = "Lockpick [x1 Advanced Lockpick]",
                item = "advancedlockpick",
            }
        },
        distance = 2.5
    },

    ["lockpick3"] = {
        name = "lockpick3",
        coords = vector3(-1222.289, -907.8807, 12.636827),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 11.636827,
        maxZ = 13.636827,
        options = {
            {
                event = "lockpicks:UseLockpickstore",
                icon = "fas fa-circle",
                label = "Lockpick [x1 Advanced Lockpick]",
                item = "advancedlockpick",
            }
        },
        distance = 2.5
    },

    ["lockpick2"] = {
        name = "lockpick2",
        coords = vector3(-706.5634, -915.5321, 19.607269),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 18.607269,
        maxZ = 20.607269,
        options = {
            {
                event = "lockpicks:UseLockpickstore",
                icon = "fas fa-circle",
                label = "Lockpick [x1 Advanced Lockpick]",
                item = "advancedlockpick",
            }
        },
        distance = 2.5
    },

    ["tacolocker"] = {
        name = "tacolocker",
        coords = vector3(389.64135, -323.5827, 46.846298),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 45.846298,
        maxZ = 47.846298,
        options = {
            {
                event = "qb-taco:interact:stash",
                icon = "fas fa-circle",
                label = "Open Personal Locker",
                job = "taco",
            }
        },
        distance = 2.5
    },

    ["judgelocker"] = {
        name = "judgelocker",
        coords = vector3(223.76841, -420.935, 48.284431),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 47.284431,
        maxZ = 49.284431,
        options = {
            {
                event = "qb-judge:interact:stash",
                icon = "fas fa-circle",
                label = "Open Personal Locker",
                job = "judge",
            }
        },
        distance = 2.5
    },

    ["whitewidoeloker"] = {
        name = "whitewidoeloker",
        coords = vector3(174.21662, -234.851, 49.767261),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 48.767261,
        maxZ = 50.767261,
        options = {
            {
                event = "qb-white:stashh",
                icon = "fas fa-circle",
                label = "Open Locker",
                job = "whitewidow",
            }
        },
        distance = 2.5
    },
    -- VANILLA CASHIER
    ["vubill"] = {
        name = "vubill",
        coords = vector3(129.40957, -1285.054, 29.569351),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 5.62,
        maxZ = 29.569351,
        options = {
            {
                type = "client",
                event = "jim-payments:client:Charge",
                icon = "fas fa-dollar",
                label = "Open Cashier",
                job = "vanilla",
            }
        },
        distance = 2.5
    },

    -- CASINO CASHIER
    ["casinocashier"] = {
        name = "casinocashier",
        coords = vector3(1112.6816, -2320.174, 24.760908),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 22.760908,
        maxZ = 24.760908,
        options = {
            {
                type = "client",
                event = "jim-payments:client:Charge",
                icon = "fas fa-dollar",
                label = "Open Cashier",
                job = "casino",
            }
        },
        distance = 2.5
    },

    ["bmbill"] = {
        name = "bmbill",
        coords = vector3(-1201.22, -1137.761, 7.8332786),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 5.62,
        maxZ = 29.569351,
        options = {
            {
                type = "client",
                event = "jim-payments:client:Charge",
                icon = "fas fa-dollar",
                label = "Open Cashier",
                job = "beanmachine",
            }
        },
        distance = 2.5
    },

    ["wwb"] = {
        name = "wwb",
        coords = vector3(188.73085, -241.1639, 53.584095),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 52.584095,
        maxZ = 54.584095,
        options = {
            {
                type = "client",
                event = "jim-payments:client:Charge",
                icon = "fas fa-dollar",
                label = "Open Cashier",
                job = "whitewidow",
            },
            {
                type = "client",
                event = "Toggle:Duty",
                icon = "far fa-clipboard",
                label = "Sign In / Out",
                job = "whitewidow",
            }
        },
        distance = 2.5
    },


    ["yellowjackcas"] = {
        name = "yellowjackcas",
        coords = vector3(1990.7016, 3045.7475, 47.636146),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 46.420505,
        maxZ = 48.420505,
        options = {
            {
                type = "client",
                event = "jim-payments:client:Charge",
                icon = "fas fa-dollar",
                label = "Open Cashier",
                job = "yellowjack",
            },
            {
                type = "client",
                event = "qb-bossmenu:client:OpenMenu",
                icon = "fas fa-clipboard",
                label = "Open Boss Menu",
                job = { ["yellowjack"] = 4 }
            },
            {
                type = "client",
                event = "Toggle:Duty",
                icon = "far fa-clipboard",
                label = "Sign In / Out",
                job = "yellowjack",
            }
        },
        distance = 2.5
    },

    ["coolbeanscashierr"] = {
        name = "coolbeanscashierr",
        coords = vector3(-1200.89, -1136.961, 8.1781806),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 7.1781806,
        maxZ = 9.1781806,
        options = {
            {
                type = "client",
                event = "jim-payments:client:Charge",
                icon = "fas fa-dollar",
                label = "Open Cashier",
                job = "coolbeans",
            },
            {
                type = "client",
                event = "Toggle:Duty",
                icon = "far fa-clipboard",
                label = "Sign In / Out",
                job = "coolbeans",
            }
        },
        distance = 2.5
    },

    ["bsbill"] = {
        name = "bsbill",
        coords = vector3(-1195.477, -893.1959, 14.081523),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 13.081523,
        maxZ = 15.081523,
        options = {
            {
                type = "client",
                event = "jim-payments:client:Charge",
                icon = "fas fa-dollar",
                label = "Open Cashier",
                job = "burgershot",
            },
            {
                type = "client",
                event = "qb-burgershot:tray2",
                icon = "fas fa-box",
                label = "Open Tray",
            }
        },
        distance = 2.5
    },

    ["pwtray"] = {
        name = "pwtray",
        coords = vector3(-320.7291, -95.26486, 47.505573),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 46.505573,
        maxZ = 48.505573,
        options = {
            {
                type = "client",
                event = "qb-pawnshop:table",
                icon = "fa-solid fa-hand-holding",
                label = "Open Table",
            }
        },
        distance = 2.5
    },

    -- ["pwbill"] = {
    --     name = "pwbill",
    --     coords = vector3(-315.8403, -101.7552, 47.884479),
    --     length = 0.7,
    --     width = 0.8,
    --     heading=320,
    --     debugPoly=false,
    --     minZ=45.884479,
    --     maxZ=47.884479,
    --     options = {
    --         {
    --             type = "client",
    --             event = "jim-payments:client:Charge",
    --             icon = "fas fa-dollar",
    --             label = "Open Cashier",
    --             job = "pawn",
    --         }
    --     },
    --     distance = 2.5
    -- },
    -- CASINOBOSS
    ["casibossmenu"] = {
        name = "casibossmenu",
        coords = vector3(1119.8045, -2307.612, 23.585947),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 22.585947,
        maxZ = 24.585947,
        options = {
            {
                type = "client",
                event = "qb-bossmenu:client:OpenMenu",
                icon = "fas fa-fish",
                label = "Open Boss Menu",
                job = { ["casino"] = 3 }
            }
        },
        distance = 2.5
    },

    -- JUDEGBOSS
    ["judgeboss"] = {
        name = "judgeboss",
        coords = vector3(219.074, -421.1314, 47.180156),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 46.180156,
        maxZ = 48.180156,
        options = {
            {
                type = "client",
                event = "qb-bossmenu:client:OpenMenu",
                icon = "fas fa-clipboard",
                label = "Open Boss Menu",
                job = { ["judge"] = 5, 6, 7, 8 }
            }
        },
        distance = 2.5
    },

    -- JUDEGBOSS
    ["redlineshop"] = {
        name = "redlineshop",
        coords = vector3(473.78417, -568.24, 28.627105),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 27.627105,
        maxZ = 29.627105,
        options = {
            {
                type = "client",
                event = "dr-mechanic:client:Store:Menu2",
                icon = "fas fa-clipboard",
                label = "Open Shop",
                job = "redline",
            }
        },
        distance = 2.5
    },

    -- JUDEGBOSS
    ["catvcadeboss"] = {
        name = "catvcadeboss",
        coords = vector3(-596.0739, -1052.651, 22.463743),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 21.463743,
        maxZ = 23.463743,
        options = {
            {
                type = "client",
                event = "qb-bossmenu:client:OpenMenu",
                icon = "fas fa-clipboard",
                label = "Open Boss Menu",
                job = { ["catcafe"] = 4 }
            }
        },
        distance = 2.5
    },

    -- BURGER SHOT
    ["bsbossmenu"] = {
        name = "bsbossmenu",
        coords = vector3(-1195.701, -901.0872, 14.157296),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 13.157296,
        maxZ = 15.157296,
        options = {
            {
                type = "client",
                event = "qb-bossmenu:client:OpenMenu",
                icon = "fas fa-fish",
                label = "Open Boss Menu",
                job = { ["burgershot"] = 4 }
            }
        },
        distance = 2.5
    },

    -- PAWN
    ["pwbossmenu"] = {
        name = "pwbossmenu",
        coords = vector3(-328.1891, -91.11111, 46.350952),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 45.350952,
        maxZ = 47.350952,
        options = {
            {
                type = "client",
                event = "qb-bossmenu:client:OpenMenu",
                icon = "fas fa-clipboard",
                label = "Open Boss Menu",
                job = { ["pawn"] = 2 }
            }
        },
        distance = 2.5
    },

    -- BURGER SHOT
    ["emsbmenu"] = {
        name = "emsbmenu",
        coords = vector3(329.67221, -602.0371, 43.165675),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 42.157296,
        maxZ = 44.157296,
        options = {
            {
                type = "client",
                event = "qb-bossmenu:client:OpenMenu",
                icon = "fas fa-fish",
                label = "Open Boss Menu",
                job = { ["ambulance"] = 4 }
            }
        },
        distance = 2.5
    },

    -- police
    ["psbossmenu"] = {
        name = "psbossmenu",
        coords = vector3(608.01739, -3.50859, 86.814334),
        length = 1.0,
        width = 1.0,
        heading = 0,
        debugPoly = false,
        minZ = 85.189279,
        maxZ = 87.189279,
        options = {
            {
                type = "client",
                event = "qb-bossmenu:client:OpenMenu",
                icon = "fas fa-clipboard",
                label = "Open Boss Menu",
                job = { ["police"] = 31, 32, 33, 34 }
            }
        },
        distance = 2.5
    },
    -- pOLICE EVIDENCE
    -- -- police
    -- ["POLICEANAL"] = {
    --     name = "POLICEANAL",
    --     coords = vector3(564.55303, 7.7116537, 68.754501),
    --     length = 0.7,
    --     width = 0.8,
    --     heading=320,
    --     debugPoly=false,
    --     minZ=67.891435,
    --     maxZ=69.891435,
    --     options = {
    --         {
    --             type = "client",
    --             event = "wasabi_evidence:analyzeEvidence",
    --             icon = "fas fa-clipboard",
    --             label = "Open Analyze Evidence",
    --             job = "police",
    --         }
    --     },
    --     distance = 2.5
    -- },
    -- ["POLICEANALL"] = {
    --     name = "POLICEANALL",
    --     coords = vector3(487.25808, -993.6326, 30.794603),
    --     length = 0.7,
    --     width = 0.8,
    --     heading=320,
    --     debugPoly=false,
    --     minZ=29.794603,
    --     maxZ=31.794603,
    --     options = {
    --         {
    --             type = "client",
    --             event = "wasabi_evidence:fingerprintNearbyPlayer",
    --             icon = "fas fa-clipboard",
    --             label = "Take Suspects Or Fingerprints",
    --             job = "police",
    --         }
    --     },
    --     distance = 2.5
    -- },
    -- ["POLICEANALLL"] = {
    --     name = "POLICEANALLL",
    --     coords = vector3(485.16305, -993.8534, 31.031517),
    --     length = 0.7,
    --     width = 0.8,
    --     heading=320,
    --     debugPoly=false,
    --     minZ=30.031517,
    --     maxZ=32.031517,
    --     options = {
    --         {
    --             type = "client",
    --             event = "wasabi_evidence:accessEvidenceStorage",
    --             icon = "fas fa-clipboard",
    --             label = "Access Evidence Storage",
    --             job = "police",
    --         }
    --     },
    --     distance = 2.5
    -- },

    -- WW BOSSMENU
    ["wwbossmenu"] = {
        name = "wwbossmenu",
        coords = vector3(182.92741, -250.86, 53.482841),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 52.482841,
        maxZ = 54.482841,
        options = {
            {
                type = "client",
                event = "qb-bossmenu:client:OpenMenu",
                icon = "fas fa-fish",
                label = "Open Boss Menu",
                job = { ["whitewidow"] = 2, 3 }
            }
        },
        distance = 2.5
    },

    ["rebossmenu"] = {
        name = "rebossmenu",
        coords = vector3(977.09942, -1731.778, 30.740417),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 5.62,
        maxZ = 34.62,
        options = {
            {
                type = "client",
                event = "qb-bossmenu:client:OpenMenu",
                icon = "fas fa-fish",
                label = "Open Boss Menu",
                job = { ["realestate"] = 4 }
            }
        },
        distance = 2.5
    },

    -- BEAMMACHINE
    ["bm"] = {
        name = "bm",
        coords = vector3(-1183.769, -1138.213, 8.0569472),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 7.0569472,
        maxZ = 9.0569472,
        options = {
            {
                type = "client",
                event = "qb-bossmenu:client:OpenMenu",
                icon = "fas fa-fish",
                label = "Open Boss Menu",
                job = { ["coolbeans"] = 2, 3 }
            }
        },
        distance = 3.5
    },

    -- mechanic
    ["mcbossmenu"] = {
        name = "mcbossmenu",
        coords = vector3(148.932, -3019.414, 7.2398571),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 6.2398571,
        maxZ = 8.2398571,
        options = {
            {
                type = "client",
                event = "Toggle:Duty",
                icon = "far fa-clipboard",
                label = "Sign In / Out",
                job = "mechanic",
            },
            {
                type = "client",
                event = "jim-payments:client:Charge",
                icon = "fas fa-fish",
                label = "Open Cashier",
                job = "mechanic",
            }
        },
        distance = 2.5
    },
    -- krusy
    ["krusyduty"] = {
        name = "krusyduty",
        coords = vector3(-1199.634, -899.6566, 13.411273),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 12.411273,
        maxZ = 14.411273,
        options = {
            {
                type = "client",
                event = "Toggle:Duty",
                icon = "far fa-clipboard",
                label = "Sign In / Out",
                job = "burgershot",
            }
        },
        distance = 2.5
    },
    -- mechanic
    ["mcbossmenu2"] = {
        name = "mcbossmenu2",
        coords = vector3(152.2086, -3053.538, 7.2190604),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 6.2190604,
        maxZ = 8.2190604,
        options = {
            {
                type = "client",
                event = "qb-bossmenu:client:OpenMenu",
                icon = "fas fa-fish",
                label = "Open Boss Menu",
                job = { ["mechanic"] = 2 }
            }
        },
        distance = 2.5
    },

    -- PIZZATHIS BOSS
    ["ptbossmenu"] = {
        name = "ptbossmenu",
        coords = vector3(-1346.14, -1065.76, 7.44),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 6.32,
        maxZ = 8.37133,
        options = {
            {
                type = "client",
                event = "qb-bossmenu:client:OpenMenu",
                icon = "fas fa-fish",
                label = "Open Boss Menu",
                job = { ["pizzathis"] = 4 }
            },
            {
                type = "client",
                event = "Toggle:Duty",
                icon = "far fa-clipboard",
                label = "Sign In / Out",
                job = "pizzathis",
            },
            {
                type = "client",
                event = "jim-payments:client:Charge",
                icon = "fas fa-fish",
                label = "Open Cashier",
                job = "pizzathis",
            }
        },
        distance = 2.5
    },

    -- -- MECHANIC SHOT
    -- ["mchbossmenu"] = {
    --     name = "mchbossmenu",
    --     coords = vector3(-1631.199, -824.0394, 8.8301544),
    --     length = 0.7,
    --     width = 0.8,
    --     heading=320,
    --     debugPoly=false,
    --     minZ=5.62,
    --     maxZ=20.62,
    --     options = {
    --         {
    --             type = "client",
    --             event = "qb-bossmenu:client:OpenMenu",
    --             icon = "fas fa-bag",
    --             label = "Open Boss Menu",
    --             job = "mechanic",
    --         }
    --     },
    --     distance = 2.5
    -- },

    -- TACO
    ["TACObossmenu"] = {
        name = "TACObossmenu",
        coords = vector3(387.58148, -318.2437, 50.429542),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 49.429542,
        maxZ = 51.429542,
        options = {
            {
                type = "client",
                event = "qb-bossmenu:client:OpenMenu",
                icon = "fas fa-clipboard",
                label = "Open Boss Menu",
                job = { ["taco"] = 3, 2 }
            }
        },
        distance = 2.5
    },

    -- KUPA MECHANIC
    -- ["kupamechanic"] = {
    --     name = "kupamechanic",
    --     coords = vector3(-1602.056, -836.2112, 8.9569902),
    --     length = 0.7,
    --     width = 0.8,
    --     heading=320,
    --     debugPoly=false,
    --     minZ=5.62,
    --     maxZ=8.9569902,
    --     options = {
    --         {
    --             type = "client",
    --             event = "jim-payments:client:Charge",
    --             icon = "fas fa-dollar",
    --             label = "Open Cashier",
    --             job = "mechanic",
    --         }
    --     },
    --     distance = 2.5
    -- },

    -- ["fishsales"] = {
    --     name = "fishsales",
    --     coords = vector3(-1850.39, -1239.73, 8.62),
    --     length = 0.7,
    --     width = 0.8,
    --     heading=320,
    --     debugPoly=false,
    --     minZ=5.62,
    --     maxZ=9.62,
    --     options = {
    --         {
    --             type = "client",
    --             event = "qb-fishing:yesellfishes",
    --             icon = "fas fa-fish",
    --             label = "Sell Fish",
    --             job = "all",
    --         }
    --     },
    --     distance = 2.5
    -- },

    -- ["vehicleshop"] = {
    --     name = "vehicleshop",
    --     coords = vector3(-55.87, -1097.46, 26.42),
    --     length = 0.9,
    --     width = 2.0,
    --     heading=30,
    --     debugPoly=false,
    --     minZ=22.82,
    --     maxZ=26.82,
    --     options = {
    --         {
    --             type = "client",
    --             event = "icy-vehicleshop:openShop",
    --             parameters ="CAR_DEALERSHIP",
    --             icon = "fas fa-car",
    --             label = "Dealership",
    --         }
    --     },
    --     distance = 2.5
    -- },

    -- ["TUNStash"] = {
    --     name = "TunStash",
    --     coords = vector3(128.66, -3013.45, 7.04),
    --     length = 1.0,
    --     width = 1.0,
    --     heading=0,
    --     debugPoly=false,
    --     minZ=4.04,
    --     maxZ=8.04,
    --     options = {
    --         {
    --             type = "client",
    --             event = "TunStash",
    --             icon = "fas fa-archive",
    --             label = "Tuner Stash",
    --             job = "tuner",
    --         }
    --     },
    --     distance = 2.5
    -- },


    ["PDPersonal"] = {
        name = "PDPersonal",
        coords = vector3(486.5, -994.71, 30.69),
        length = 1.0,
        width = 1.0,
        heading = 1,
        debugPoly = false,
        minZ = 27.69,
        maxZ = 31.69,
        options = {
            {
                type = "client",
                event = "qb-policejob:interact:stash",
                icon = "fas fa-archive",
                label = "PD Personal Stash",
                job = "police",
            }
        },
        distance = 2.5
    },

    ["VPDPersonal"] = {
        name = "VPDPersonal",
        coords = vector3(602.89453, -1.197042, 83.36786),
        length = 1.0,
        width = 1.0,
        heading = 1,
        debugPoly = false,
        minZ = 82.76786,
        maxZ = 84.76786,
        options = {
            {
                type = "client",
                event = "qb-policejob:interact:stash",
                icon = "fas fa-archive",
                label = "PD Personal Stash",
                job = "police",
            }
        },
        distance = 2.5
    },

    ["VPDPersonal2"] = {
        name = "VPDPersonal2",
        coords = vector3(601.35003, -6.146262, 83.328529),
        length = 1.0,
        width = 1.0,
        heading = 1,
        debugPoly = false,
        minZ = 82.46786,
        maxZ = 84.36786,
        options = {
            {
                type = "client",
                event = "qb-policejob:interact:stash",
                icon = "fas fa-archive",
                label = "PD Personal Stash",
                job = "police",
            }
        },
        distance = 2.5
    },

    ["DAVISPersonal"] = {
        name = "DAVISPersonal",
        coords = vector3(361.40026, -1599.969, 25.451702),
        length = 1.0,
        width = 1.0,
        heading = 1,
        debugPoly = false,
        minZ = 0.69,
        maxZ = 25.451702,
        options = {
            {
                type = "client",
                event = "qb-police:interact:stash",
                icon = "fas fa-archive",
                label = "PD Personal Stash",
                job = "police",
            }
        },
        distance = 2.5
    },

    ["tequilashop"] = {
        name = "tequilashop",
        coords = vector3(-562.71, 289.01, 82.18),
        length = 1.0,
        width = 1.0,
        heading = 265,
        debugPoly = false,
        minZ = 78.78,
        maxZ = 82.78,
        options = {
            {
                type = "client",
                event = "qb-shops:client:tequila",
                icon = "fas fa-archive",
                label = "Tequila Shop",
                job = "tequilala",
            }
        },
        distance = 2.5
    },

    ["casinostore1"] = {
        name = "casinostore1",
        coords = vector3(1115.1046, -2311.546, 24.453968),
        length = 1.0,
        width = 1.0,
        heading = 265,
        debugPoly = false,
        minZ = 23.453968,
        maxZ = 25.453968,
        options = {
            {
                type = "client",
                event = "qb-shops:marketshop",
                icon = "fas fa-dollar",
                label = "Casino Store",
                job = "casino",
            }
        },
        distance = 1.5
    },

    ["casinoshop2"] = {
        name = "casinoshop2",
        coords = vector3(1104.3905, -2309.227, 24.450664),
        length = 1.0,
        width = 1.0,
        heading = 265,
        debugPoly = false,
        minZ = 23.450664,
        maxZ = 25.450664,
        options = {
            {
                type = "client",
                event = "qb-shops:marketshop",
                icon = "fas fa-apple",
                label = "Casino Chip Shop",
                job = "casino",
            }
        },
        distance = 1.5
    },

    -- ["policeshop"] = {
    --     name = "policeshop",
    --     coords = vector3(-374.3997, -349.1192, 43.595195),
    --     length = 1.0,
    --     width = 1.0,
    --     heading=265,
    --     debugPoly = false,
    --     minZ=42.595195,
    --     maxZ=44.595195,
    --     options = {
    --         {
    --             type = "client",
    --             event = "qb-shops:marketshop",
    --             icon = "fas fa-apple",
    --             label = "Police Cafeteria",
    --             job = "police",
    --         }
    --     },
    --     distance = 1.5
    -- },

    ["mechanictools"] = {
        name = "mechanictools",
        coords = vector3(157.41822, -2997.468, 7.3123393),
        length = 1.0,
        width = 1.0,
        heading = 265,
        debugPoly = false,
        minZ = 6.3123393,
        maxZ = 8.3123393,
        options = {
            {
                type = "client",
                event = "qb-shops:marketshop",
                icon = "fas fa-apple",
                label = "Buy Mechanic Dark Tools",
                job = "mechanic",
            }
        },
        distance = 1.5
    },

    ["mechanictools2"] = {
        name = "mechanictools2",
        coords = vector3(477.8092, -569.1679, 28.894729),
        length = 1.0,
        width = 1.0,
        heading = 265,
        debugPoly = false,
        minZ = 27.894729,
        maxZ = 29.894729,
        options = {
            {
                type = "client",
                event = "qb-shops:marketshop",
                icon = "fas fa-apple",
                label = "Buy Redline Dark Tools",
                job = "redline",
            }
        },
        distance = 1.5
    },

    ["tequilalastash"] = {
        name = "tequilalastash",
        coords = vector3(-563.04, 284.42, 82.18),
        length = 1.0,
        width = 1.0,
        heading = 265,
        debugPoly = false,
        minZ = 78.38,
        maxZ = 82.38,
        options = {
            {
                type = "client",
                event = "qb-tequilala:Stash",
                icon = "fas fa-sign-in-alt",
                label = "Open Stash",
                job = "tequilala",
            },
        },
        distance = 2.5
    },
    --- Prison -------
    ["prisonArmory"] = {
        name = "prisonArmory",
        coords = vector3(3876.6374, -18.75106, 6.6585969),
        length = 1.0,
        width = 1.0,
        heading = 0,
        debugPoly = false,
        minZ = 5.6585969,
        maxZ = 7.6585969,
        options = {
            {
                type = "client",
                event = "police:openCArmory",
                icon = "fas fa-shield-alt",
                label = "Corrections Armory",
                job = "corrections"
            }
        },
        distance = 1.5
    },
    -- ["prisonoutfit"] = {
    --     name = "prisonoutfit",
    --     coords = vector3(1833.22, 2572.26, 46.01),
    --     length = 1.0,
    --     width = 1.0,
    --     heading = 270,
    --     debugPoly = false,
    --     minZ=43.01,
    --     maxZ=47.01,
    --     options = {
    --         {
    --             type = "client",
    --             event = "nh-context:opendress2",
    --             icon = "fas fa-shield-alt",
    --             label = "Corrections Clothing",
    --             job = "police"
    --         },
    --     },
    --     distance = 2.5
    -- },

    --duty
    ["prisonDuty"] = {
        name = "prisonDuty",
        coords = vector3(1839.49, 2573.89, 46.01),
        length = 1.0,
        width = 1.0,
        heading = 0,
        debugPoly = false,
        minZ = 42.41,
        maxZ = 46.41,
        options = {
            {
                type = "client",
                event = "Toggle:Duty",
                icon = "far fa-clipboard",
                label = "Sign In / Out",
                job = "police",
            },
        },
        distance = 1.5
    },

    --vpdduty
    ["vpdduty"] = {
        name = "vpdduty",
        coords = vector3(614.77844, 3.982814, 82.589279),
        length = 1.0,
        width = 1.0,
        heading = 0,
        debugPoly = false,
        minZ = 81.589279,
        maxZ = 83.589279,
        options = {
            {
                type = "client",
                event = "Toggle:Duty",
                icon = "far fa-clipboard",
                label = "Sign In / Out",
                job = "police",
            },
        },
        distance = 3.5
    },

    --vpdduty #2
    ["vpdduty2"] = {
        name = "vpdduty2",
        coords = vector3(611.58081, -5.44344, 82.767974),
        length = 1.0,
        width = 1.0,
        heading = 0,
        debugPoly = false,
        minZ = 80.589279,
        maxZ = 83.589279,
        options = {
            {
                type = "client",
                event = "Toggle:Duty",
                icon = "far fa-clipboard",
                label = "Sign In / Out",
                job = "police",
            },
        },
        distance = 3.5
    },


    ---- Sandy -----



    -- ["Sandyoutfit"] = {
    --     name = "Sandyoutfit",
    --     coords = vector3(1842.17, 3681.29, 34.19),
    --     length = 1.0,
    --     width = 1.0,
    --     heading = 300,
    --     debugPoly = false,
    --     minZ=31.39,
    --     maxZ=35.39,
    --     options = {
    --         {
    --             type = "client",
    --             event = "nh-context:opendress2",
    --             icon = "fas fa-shield-alt",
    --             label = "Sheriff Clothing",
    --             job = "police"
    --         },
    --     },
    --     distance = 2.5
    -- },

    ["SNPersonal"] = {
        name = "SNPersonal",
        coords = vector3(1852.4313, 3690.6994, 34.349876),
        length = 1.0,
        width = 1.0,
        heading = 300,
        debugPoly = false,
        minZ = 33.349876,
        maxZ = 35.349876,
        options = {
            {
                type = "client",
                event = "qb-policejob:interact:stash",
                icon = "fas fa-archive",
                label = "Personal Stash",
                job = "police",
            }
        },
        distance = 2.5
    },

    --duty
    ["sandyDuty"] = {
        name = "sandyDuty",
        coords = vector3(1852.4879, 3687.0458, 34.294425),
        length = 1.0,
        width = 1.0,
        heading = 30,
        debugPoly = false,
        minZ = 33.294425,
        maxZ = 35.294425,
        options = {
            {
                type = "client",
                event = "Toggle:Duty",
                icon = "far fa-clipboard",
                label = "Sign In / Out",
                job = "police",
            },
        },
        distance = 1.5
    },

    ["SANDYArmory"] = {
        name = "SANDYArmory",
        coords = vector3(1862.3636, 3691.2036, 34.406513),
        length = 1.0,
        width = 1.0,
        heading = 300,
        debugPoly = false,
        minZ = 33.406513,
        maxZ = 35.406513,
        options = {
            {
                type = "client",
                event = "police:openPDArmory",
                icon = "fas fa-shield-alt",
                label = "Sheriff Armory",
                job = "police"
            }
        },
        distance = 1.5
    },

    ---- Davis ----
    ["DavisArmory"] = {
        name = "DavisArmory",
        coords = vector3(361.72, -1604.13, 25.45),
        length = 1.0,
        width = 1.0,
        heading = 320,
        debugPoly = false,
        minZ = 22.65,
        maxZ = 26.65,
        options = {
            {
                type = "client",
                event = "police:openPDArmory",
                icon = "fas fa-shield-alt",
                label = "Police Armory",
                job = "police"
            }
        },
        distance = 1.5
    },


    --MugShot
    ["Sandymugshot"] = {
        name = "sandymugshot",
        coords = vector3(1847.6896, 3686.5708, 34.687232),
        length = 0.4,
        width = 1.4,
        heading = 300,
        debugPoly = false,
        minZ = 33.687232,
        maxZ = 35.687232,
        options = {
            {
                type = "client",
                event = "qb-mugshot:client:takemugshot",
                icon = "fas fa-camera",
                label = "Take Suspects Mugshots",
                job = "police",
            },
        },
        distance = 2.5
    },

    --vpdmugshot
    ["vpdmugshot"] = {
        name = "vpdmugshot",
        coords = vector3(581.82019, 2.4141292, 69.022132),
        length = 0.4,
        width = 1.4,
        heading = 300,
        debugPoly = false,
        minZ = 68.022132,
        maxZ = 70.022132,
        options = {
            {
                type = "client",
                event = "qb-mugshot:client:takemugshot",
                icon = "fas fa-camera",
                label = "Take Suspects Mugshots",
                job = "police",
            },
            {
                type = "client",
                event = "police:client:fingerprint",
                icon = "fas fa-fingerprint",
                label = "Fingerprint Station",
                job = "police",
            },
        },
        distance = 3.5
    },

    --duty
    ["DavisDuty"] = {
        name = "DavisDuty",
        coords = vector3(381.84, -1596.49, 30.05),
        length = 1.0,
        width = 1.0,
        heading = 230,
        debugPoly = false,
        minZ = 26.05,
        maxZ = 30.05,
        options = {
            {
                type = "client",
                event = "Toggle:Duty",
                icon = "far fa-clipboard",
                label = "Sign In / Out",
                job = "police",
            },
        },
        distance = 1.5
    },

    --MugShot
    ["davismugshot"] = {
        name = "davismugshot",
        coords = vector3(380.39, -1603.18, 25.45),
        length = 1.0,
        width = 1.0,
        heading = 230,
        debugPoly = false,
        minZ = 21.65,
        maxZ = 25.65,
        options = {
            {
                type = "client",
                event = "qb-mugshot:client:takemugshot",
                icon = "fas fa-camera",
                label = "Take Suspects Mugshots",
                job = "police",
            },
        },
        distance = 2.5
    },

    ["pdmugshot"] = {
        name = "pdmugshot",
        coords = vector3(-454.11, 6000.72, 27.58),
        length = 0.4,
        width = 1.2,
        heading = 45,
        debugPoly = false,
        minZ = 24.98,
        maxZ = 28.98,
        options = {
            {
                type = "client",
                event = "qb-mugshot:client:takemugshot",
                icon = "fas fa-camera",
                label = "Take Suspects Mugshots",
                job = "police",
            },
        },
        distance = 2.5
    },
    -- CPDArmory
    ["CPDArmory"] = {
        name = "CPDArmory",
        coords = vector3(-1074.26, -827.79, 19.29),
        length = 0.5,
        width = 4,
        heading = 309,
        debugPoly = false,
        minZ = 16.09,
        maxZ = 20.09,
        options = {
            {
                type = "client",
                event = "police:openPDArmory",
                icon = "fas fa-shield-alt",
                label = "Police Armory",
                job = "police"
            }
        },
        distance = 1.5
    },

    -- VPD ARMORY

    ["VPDARMORY "] = {
        name = "VPDARMORY",
        coords = vector3(605.75036, 21.237039, 83.183845),
        length = 0.5,
        width = 4,
        heading = 309,
        debugPoly = false,
        minZ = 82.183845,
        maxZ = 84.183845,
        options = {
            {
                type = "client",
                event = "police:openPDArmory",
                icon = "fas fa-shield-alt",
                label = "Police Armory",
                job = "police"
            }
        },
        distance = 1.5
    },


    -- PBSO
    ["PBCOArmory"] = {
        name = "PBCOArmory",
        coords = vector3(-447.71, 6017.0, 37.0),
        length = 1.0,
        width = 1.0,
        heading = 225,
        debugPoly = false,
        minZ = 34.2,
        maxZ = 38.2,
        options = {
            {
                type = "client",
                event = "police:openPDArmory",
                icon = "fas fa-shield-alt",
                label = "Police Armory",
                job = "police"
            }
        },
        distance = 1.5
    },


    --duty
    ["PBDuty"] = {
        name = "PBDuty",
        coords = vector3(-447.99, 6013.49, 32.29),
        length = 1.0,
        width = 1.0,
        heading = 224,
        debugPoly = false,
        minZ = 28.49,
        maxZ = 32.49,
        options = {
            {
                type = "client",
                event = "Toggle:Duty",
                icon = "far fa-clipboard",
                label = "Sign In / Out",
                job = "police",
            },
        },
        distance = 1.5
    },

    -- MRPD
    --duty
    ["PDDuty"] = {
        name = "PDDuty",
        coords = vector3(441.77, -982.08, 30.74),
        length = 1.8,
        width = 0.6,
        heading = 330,
        debugPoly = false,
        minZ = 29.74,
        maxZ = 31.03,
        options = {
            {
                type = "client",
                event = "Toggle:Duty",
                icon = "far fa-clipboard",
                label = "Sign In / Out",
                job = "police",
            },
        },
        distance = 1.5
    },

    -- RHPD
    ["RHArmory"] = {
        name = "RHArmory",
        coords = vector3(-403.7539, -383.8854, 24.506479),
        length = 3.4,
        width = 1.6,
        heading = 340,
        debugPoly = false,
        minZ = 23.49,
        maxZ = 31.09,
        options = {
            {
                type = "client",
                event = "police:openPDArmory",
                icon = "fas fa-shield-alt",
                label = "Police Armory",
                job = "police"
            }
        },
        distance = 1.5
    },
    ["RHArmory2"] = {
        name = "RHArmory2",
        coords = vector3(-408.3483, -382.0389, 24.815689),
        length = 3.4,
        width = 1.6,
        heading = 340,
        debugPoly = false,
        minZ = 23.815689,
        maxZ = 25.815689,
        options = {
            {
                type = "client",
                event = "police:openPDArmory",
                icon = "fas fa-shield-alt",
                label = "Police Armory",
                job = "police"
            }
        },
        distance = 1.5
    },
    ["RHASWATrmory"] = {
        name = "RHASWATArmory",
        coords = vector3(-343.3907, -368.1661, 20.114337),
        length = 3.4,
        width = 1.6,
        heading = 340,
        debugPoly = false,
        minZ = 19.49,
        maxZ = 21.09,
        options = {
            {
                type = "client",
                event = "police:openPDArmory",
                icon = "fas fa-shield-alt",
                label = "Police Armory",
                job = "police"
            }
        },
        distance = 1.5
    },
    --duty
    ["rhDuty"] = {
        name = "rhDuty",
        coords = vector3(-377.0601, -353.0434, 32.825347),
        length = 1.8,
        width = 0.6,
        heading = 330,
        debugPoly = false,
        minZ = 29.74,
        maxZ = 33.03,
        options = {
            {
                type = "client",
                event = "Toggle:Duty",
                icon = "far fa-clipboard",
                label = "Sign In / Out",
                job = "police",
            },
        },
        distance = 1.5
    },
    --personalstash
    ["RHPersonal"] = {
        name = "RHPersonal",
        coords = vector3(-406.724, -354.0289, 24.644821),
        length = 1.0,
        width = 1.0,
        heading = 1,
        debugPoly = false,
        minZ = 23.69,
        maxZ = 25.69,
        options = {
            {
                type = "client",
                event = "qb-policejob:interact:stash",
                icon = "fas fa-archive",
                label = "PD Personal Stash",
                job = "police",
            }
        },
        distance = 2.5
    },
    ["pdbadge"] = {
        name = "pdbadge",
        coords = vector3(602.90118, 13.483489, 82.731727),
        length = 0.7,
        width = 0.8,
        heading = 320,
        debugPoly = false,
        minZ = 81.731727,
        maxZ = 83.731727,
        options = {
            {
                type = "server",
                event = "qb-pdbadge:server:createbadge",
                icon = "fas fa-id-badge",
                label = "Create PD badge",
                job = "police",
            }
        },
        distance = 2.5
    },
    --personalstash
    ["RHPersonalKABALA"] = {
        name = "RHPersonalKABALA",
        coords = vector3(-395.7854, -346.164, 32.095264),
        length = 1.0,
        width = 1.0,
        heading = 1,
        debugPoly = false,
        minZ = 31.095264,
        maxZ = 33.095264,
        options = {
            {
                type = "client",
                event = "qb-policejob:interact:stash",
                icon = "fas fa-archive",
                label = "PD Personal Stash",
                job = "police",
            }
        },
        distance = 2.5
    },
    ["RHSWATPersonal"] = {
        name = "RHSWATPersonal",
        coords = vector3(-356.143, -373.3655, 20.077369),
        length = 1.8,
        width = 0.6,
        heading = 330,
        debugPoly = false,
        minZ = 19.74,
        maxZ = 21.03,
        options = {
            {
                type = "client",
                event = "qb-policejob:interact:stash",
                icon = "fas fa-archive",
                label = "PD Personal Stash",
                job = "police",
            }
        },
        distance = 2.5
    },
    --fingerprint
    ["rhfingerprint"] = {
        name = "rhfingerprint",
        coords = vector3(-388.6474, -386.602, 24.636768),
        length = 2.6,
        width = 0.6,
        heading = 350,
        debugPoly = false,
        minZ = 23.63,
        maxZ = 25.046731,
        options = {
            {
                type = "client",
                event = "police:client:fingerprint",
                icon = "fas fa-fingerprint",
                label = "Fingerprint Station",
                job = "police",
            },
        },
        distance = 1.5
    },
    --fingerprint bcso
    ["rbcshfingerprint"] = {
        name = "rbcshfingerprint",
        coords = vector3(1817.9626, 3665.145, 34.170242),
        length = 2.6,
        width = 0.6,
        heading = 350,
        debugPoly = false,
        minZ = 33.170242,
        maxZ = 35.170242,
        options = {
            {
                type = "client",
                event = "police:client:fingerprint",
                icon = "fas fa-fingerprint",
                label = "Fingerprint Station",
                job = "police",
            },
        },
        distance = 1.5
    },
    --MugShot
    ["rhmugshot"] = {
        name = "rhmugshot",
        coords = vector3(-393.0186, -386.647, 25.097877),
        length = 0.5,
        width = 1.2,
        heading = 330,
        debugPoly = false,
        minZ = 23.06,
        maxZ = 26.06,
        options = {
            {
                type = "client",
                event = "qb-mugshot:client:takemugshot",
                icon = "fas fa-camera",
                label = "Take Suspects Mugshots",
                job = "police",
            },
        },
        distance = 2.5
    },
    --MugShot
    ["mrpdmugshotnew"] = {
        name = "mrpdmugshotnew",
        coords = vector3(473.1762, -1011.012, 26.524789),
        length = 0.5,
        width = 1.2,
        heading = 330,
        debugPoly = false,
        minZ = 25.524789,
        maxZ = 27.524789,
        options = {
            {
                type = "client",
                event = "qb-mugshot:client:takemugshot",
                icon = "fas fa-camera",
                label = "Take Suspects Mugshots",
                job = "police",
            },
        },
        distance = 2.5
    },
    --armory
    ["PDArmory"] = {
        name = "PDArmory",
        coords = vector3(482.58, -995.17, 30.69),
        length = 3.4,
        width = 1.6,
        heading = 340,
        debugPoly = false,
        minZ = 29.49,
        maxZ = 31.09,
        options = {
            {
                type = "client",
                event = "police:openPDArmory",
                icon = "fas fa-shield-alt",
                label = "Police Armory",
                job = "police"
            }
        },
        distance = 1.5
    },
    ["SASPArmory"] = {
        name = "SASP Armory",
        coords = vector3(1553.89, 840.5, 77.66),
        length = 0.5,
        width = 4,
        heading = 330,
        debugPoly = false,
        minZ = 74.66,
        maxZ = 78.66,
        options = {
            {
                type = "client",
                event = "police:openPDArmory",
                icon = "fas fa-shield-alt",
                label = "Police Armory",
                job = "police"
            }
        },
        distance = 1.5
    },
    --fingerprint
    ["fingerprint"] = {
        name = "fingerprint",
        coords = vector3(473.68, -1013.4, 26.27),
        length = 2.6,
        width = 0.6,
        heading = 350,
        debugPoly = false,
        minZ = 25.63,
        maxZ = 27.03,
        options = {
            {
                type = "client",
                event = "police:client:fingerprint",
                icon = "fas fa-fingerprint",
                label = "Fingerprint Station",
                job = "police",
            },
        },
        distance = 1.5
    },

    --MugShot
    ["saspmugshot"] = {
        name = "saspmugshot",
        coords = vector3(1559.62, 837.67, 77.66),
        length = 0.5,
        width = 1.2,
        heading = 330,
        debugPoly = false,
        minZ = 75.06,
        maxZ = 79.06,
        options = {
            {
                type = "client",
                event = "qb-mugshot:client:takemugshot",
                icon = "fas fa-camera",
                label = "Take Suspects Mugshots",
                job = "police",
            },
        },
        distance = 2.5
    },

    --MugShot
    ["mcmugshot"] = {
        name = "mcmugshot",
        coords = vector3(473.1, -1011.2, 26.27),
        length = 2.6,
        width = 0.6,
        heading = 350,
        debugPoly = false,
        minZ = 25.26,
        maxZ = 27.23,
        options = {
            {
                type = "client",
                event = "qb-mugshot:client:takemugshot",
                icon = "fas fa-camera",
                label = "Take Suspects Mugshots",
                job = "police",
            },
        },
        distance = 2.5
    },

    --Diving Sell
    ["divingsell"] = {
        name = "divingsell",
        coords = vector3(-1684.69, -1069.01, 13.15),
        length = 2.6,
        width = 0.6,
        heading = 350,
        debugPoly = false,
        minZ = 11.15,
        maxZ = 15.15,
        options = {
            {
                type = "client",
                event = "qb-diving:sellfish",
                icon = "far fa-clipboard",
                label = "Sell your diving stuff",
            },
        },
        distance = 3.5
    },

    -- Rental
    ["NewRentalMenu2"] = {
        name = "NewRentalMenu2",
        coords = vector3(1851.92, 2581.6, 45.67),
        length = 0.7,
        width = 1.0,
        heading = 270,
        debugPoly = false,
        minZ = 42.67,
        maxZ = 46.67,
        options = {
            {
                type = "client",
                event = "qb-rental:vehiclelist2",
                icon = "fas fa-circle",
                label = "Rent vehicle",
            },
        },
        distance = 2.5
    },

    -- Rental PBOAT
    ["NewRentalBOAT"] = {
        name = "NewRentalMenuBOAT",
        coords = vector3(-1248.394, -1843.359, 1.9551823),
        length = 1.7,
        width = 1.0,
        heading = 270,
        debugPoly = false,
        minZ = 0.9551823,
        maxZ = 2.9551823,
        options = {
            {
                type = "client",
                event = "qb-pboat:vehiclelist",
                icon = "fas fa-circle",
                label = "Rent Boat",
            },
            {
                type = "client",
                event = "qb-pboat:vehiclelist2",
                icon = "fas fa-circle",
                label = "Rent Police Boat",
                job = "police",
            },
        },
        distance = 2.5
    },

    -- Rental PRISON
    ["NewRentalPRISON"] = {
        name = "NewRentalMenuPRISON",
        coords = vector3(3848.0549, -42.9, 5.8),
        length = 1.7,
        width = 1.0,
        heading = 270,
        debugPoly = false,
        minZ = 4.8,
        maxZ = 6.8,
        options = {
            {
                type = "client",
                event = "qb-prisonrental:vehiclelist",
                icon = "fas fa-circle",
                label = "Rent Boat",
            },
        },
        distance = 2.5
    },
    -- Rental PRISON
    ["NewRentalPRISON2"] = {
        name = "NewRentalMenuPRISON2",
        coords = vector3(2857.2092, 213.141, 2.8306007),
        length = 1.3,
        width = 1.3,
        heading = 270,
        debugPoly = false,
        minZ = 1.83,
        maxZ = 3.83,
        options = {
            {
                type = "client",
                event = "qb-prisonrental:vehiclelist2",
                icon = "fas fa-circle",
                label = "Rent Car",
            },
        },
        distance = 2.5
    },

    ["tunershop"] = {
        name = "tunershop",
        coords = vector3(136.71, -3051.47, 7.04),
        length = 1.0,
        width = 1.0,
        heading = 0,
        debugPoly = false,
        minZ = 3.84,
        maxZ = 7.84,
        options = {
            {
                type = "client",
                event = "tuner:shop",
                icon = "fas fa-archive",
                label = "Tuner Shop",
                job = "tuner",
            }
        },
        distance = 2.5
    },

    ["tunerDuty"] = {
        name = "tunerDuty",
        coords = vector3(125.32, -3007.14, 7.04),
        length = 1.0,
        width = 1.0,
        heading = 0,
        debugPoly = false,
        minZ = 3.24,
        maxZ = 7.24,
        options = {
            {
                type = "client",
                event = "Toggle:Duty",
                icon = "far fa-clipboard",
                label = "Sign In / Out",
                job = "tuner",
            },
        },
        distance = 2.5
    },


    ["police"] = {
        name = "police",
        coords = vector3(461.0, -983.27, 30.69),
        length = 1.2,
        width = 1.2,
        heading = 0,
        --debugPoly=true,
        minZ = 27.69,
        maxZ = 31.69,
        options = {
            {
                type = "client",
                event = "police:shop",
                icon = "fas fa-archive",
                label = "Snack Machine",
                job = "police",
            }
        },
        distance = 2.5
    },
    --bcso

    ["BCSODuty"] = {
        name = "BCSODuty",
        coords = vector3(1852.80, 3687.80, 34.22),
        length = 0.5,
        width = 0.4,
        heading = 20,
        debugPoly = false,
        minZ = 34.05,
        maxZ = 34.40,
        options = {
            {
                type = "client",
                event = "Toggle:Duty",
                icon = "far fa-clipboard",
                label = "Sign In / Out",
                job = "police",
            },
        },
        distance = 1.5
    },

    ["BCSOArmory"] = {
        name = "BCSOArmory",
        coords = vector3(1861.85, 3688.25, 34.22),
        length = 1.0,
        width = 1.8,
        heading = 30.0,
        debugPoly = false,
        minZ = 34.30,
        maxZ = 35.50,
        options = {
            {
                type = "client",
                event = "police:openPDArmory",
                icon = "fas fa-shield-alt",
                label = "Police Armory",
                job = "police"
            }
        },
        distance = 1.5
    },
    ["BCSOfingerprint"] = {
        name = "BCSOfingerprint",
        coords = vector3(1844.45, 3692.50, 34.19),
        length = 0.4,
        width = 0.4,
        heading = 30.00,
        debugPoly = false,
        minZ = 33.90,
        maxZ = 34.20,
        options = {
            {
                type = "client",
                event = "police:client:fingerprint",
                icon = "fas fa-fingerprint",
                label = "Fingerprint Station",
                job = "police",
            },
        },
        distance = 1.5
    },
    --------/ EMS Stash

    ["EMSstash"] = {
        name = "EMSstash",
        coords = vector3(322.57165, -590.4935, 43.429833),
        length = 0.3,
        width = 2,
        heading = 320,
        debugPoly = false,
        minZ = 42.74,
        maxZ = 44.74,
        options = {
            {
                type = "client",
                event = "hospital:openEMSPersonal",
                icon = "fas fa-shopping-cart",
                label = "Open Personal Stash",
                job = "ambulance",
            }
        },
        distance = 2.5
    },


    ["EMSarmory"] = {
        name = "EMSarmory",
        coords = vector3(325.35556, -590.7023, 43.327542),
        length = 1.0,
        width = 0.6,
        heading = 50,
        debugPoly = false,
        minZ = 42.34,
        maxZ = 44.34,
        options = {
            {
                type = "client",
                event = "ambulance:client:armory",
                icon = "fas fa-shopping-cart",
                label = "Open Ambulance Shop",
                job = "ambulance",
            }
        },
        distance = 2.5
    },

    -- Clothing
    ["EMSClothing"] = {
        name = "EMSClothing",
        coords = vector3(304.89837, -600.0922, 43.364966),
        length = 0.4,
        width = 0.4,
        heading = 340,
        debugPoly = false,
        minZ = 42.48,
        maxZ = 44.48,
        options = {
            {
                type = "client",
                event = "qb-clothing:client:openMenu",
                icon = "fas fa-shield-alt",
                label = "EMS Clothing",
                job = "ambulance"
            },
            {
                type = "client",
                event = "qb-clothing:client:openOutfitMenu",
                icon = "fas fa-shield-alt",
                label = "Outfits",
                job = "ambulance"
            },
        },
        distance = 1.5
    },
    ----- Plastic Surgery

    ["surgery"] = {
        name = "surgery",
        coords = vector3(322.62, -572.57, 43.28),
        length = 2.6,
        width = 1,
        heading = 340,
        debugPoly = false,
        minZ = 42.28,
        maxZ = 44.48,
        options = {
            {
                type = "client",
                event = "qb-plastic:surgery",
                icon = "far fa-clipboard",
                label = "Plastic Surgery",
            }
        },
        distance = 1.5
    },
    ----- Checkin

    --     ["Checkin"] = {
    --     name = "Checkin",
    --     coords = vector3(-816.91, -1237.08, 7.34),
    --     length = 0.9,
    --     width = 0.5,
    --     heading = 320,
    --     debugPoly = false,
    --     minZ = 3.54,
    --     maxZ = 7.34,
    --       options = {
    --         {
    --             type = "client",
    --             event = "Hospital:CheckIn",
    --             icon = "far fa-clipboard",
    --             label = "📋Check In",
    --         }
    --     },
    --     distance = 1.5
    -- },

    ["Pharmacy"] = {
        name = "Pharmacy",
        coords = vector3(-812.15, -1236.99, 7.34),
        length = 1.1,
        width = 2.0,
        heading = 320,
        debugPoly = false,
        minZ = 3.54,
        maxZ = 7.54,
        options = {
            {
                type = "client",
                event = "pharmacy:shop",
                icon = "far fa-clipboard",
                label = "Pharmacy Shop",
            }
        },
        distance = 1.5
    },

    ["checkinush"] = {
        name = "checkinush",
        coords = vector3(310.94793, -585.9857, 43.267623),
        length = 3.1,
        width = 3.0,
        heading = 320,
        debugPoly = false,
        minZ = 42.267623,
        maxZ = 44.267623,
        options = {
            {
                type = "client",
                event = "Hospital:CheckIn",
                icon = "far fa-clipboard",
                label = "📋Check In",
            }
        },
        distance = 3.5
    },

    ["checkinushprison"] = {
        name = "checkinushprison",
        coords = vector3(1769.84, 2571.7482, 45.729892),
        length = 1.1,
        width = 2.0,
        heading = 320,
        debugPoly = false,
        minZ = 44.729892,
        maxZ = 46.729892,
        options = {
            {
                type = "client",
                event = "prison:CheckIn",
                icon = "far fa-clipboard",
                label = "📋Check In",
            }
        },
        distance = 1.5
    },

    ["checkinpolice"] = {
        name = "checkinpolice",
        coords = vector3(474.54693, -1007.318, 27.273466),
        length = 1.1,
        width = 2.0,
        heading = 320,
        debugPoly = false,
        minZ = 26.273466,
        maxZ = 28.273466,
        options = {
            {
                type = "client",
                event = "Police:CheckIn",
                icon = "far fa-clipboard",
                label = "📋Check In",
            }
        },
        distance = 1.5
    },

    ["beekeeping"] = {
        name = "beekeeping",
        coords = vector3(1532.1087, 1728.1524, 109.91768),
        length = 1.1,
        width = 2.0,
        heading = 320,
        debugPoly = false,
        minZ = 108.973466,
        maxZ = 110.973466,
        options = {
            {
                type = "client",
                event = "qb-shops:marketshop",
                icon = "fa-solid fa-shop",
                label = "BeeKeeping Shop",
            },
            {
                type = "client",
                event = "qb-beekeeping:hmenu",
                icon = "fa-solid fa-shop",
                label = "Sell BeeKeeping Stuff",
            }
        },
        distance = 1.5
    },


    -- Pet Store
    -- ["petstore"] = {
    --     name = "petstore",
    --     coords = vector3(-1366.137, 58.309696, 54.098438),
    --     length = 1.1,
    --     width = 2.0,
    --     heading = 320,
    --     debugPoly = false,
    --     minZ=53.029892,
    --     maxZ=55.029892,
    --       options = {
    --         {
    --             type = "client",
    --             event = "qb-shops:marketshop",
    --             icon = "fa-solid fa-shop",
    --             label = "Food Store",
    --         },
    --         {
    --             type = "client",
    --             event = "ORIDN:openmenupets",
    --             icon = "fa-solid fa-dog",
    --             label = "Buy Animal",
    --         }
    --     },
    --     distance = 1.5
    -- },

    ---hunting plus fishing
    ["fishing"] = {
        name = "fishing",
        coords = vector3(-1593.5, 5197.9, 4.36),
        length = 0.60,
        width = 0.60,
        heading = 55.0,
        debugPoly = false,
        minZ = 4.30,
        maxZ = 4.80,
        options = {
            {
                type = "client",
                event = "crfw:client:buyFishingGear",
                icon = "far fa-fish",
                label = "Fishing Gear",
            },
        },
        distance = 2.0
    },


    ["MechStash"] = {
        name = "MechStash",
        coords = vector3(-1421.68, -456.52, 35.91),
        length = 1.0,
        width = 1.0,
        heading = 30,
        debugPoly = false,
        minZ = 32.71,
        maxZ = 36.71,
        options = {
            {
                type = "client",
                event = "MechStash",
                icon = "fas fa-archive",
                label = "Mechanic Stash",
                job = "mechanic",
            }
        },
        distance = 2.5
    },
    -----------GarbageJob
    ["Garbagebus-Return"] = {
        name = "Garbagebus-Return",
        coords = vector3(-334.11, -1565.61, 24.95),
        length = 4.4,
        width = 11.4,
        heading = 330,
        debugPoly = false,
        minZ = 24.15,
        maxZ = 28.15,
        options = {
            {
                type = "client",
                event = "garbage:returnTruck",
                icon = "fas fa-shopping-cart",
                label = "Return GarbageBus",
            },
        },
        distance = 5.0
    },
    ---------Trucker
    ["Trucker"] = {
        name = "Trucker",
        coords = vector3(-552.49, 5348.48, 74.74),
        length = 0.8,
        width = 0.4,
        heading = 340,
        debugPoly = false,
        minZ = 73.94,
        maxZ = 75.94,
        options = {
            {
                type = "client",
                event = "GG:Trucker",
                icon = "fas fa-shopping-cart",
                label = "Start Tracker",
                job = "trucker",
            },
        },
        distance = 3.0
    },
    -- Phone Shop
    ["Phoneshop"] = {
        name = "Phoneshop",
        coords = vector3(-1531.444, -403.4486, 35.635272),
        length = 1.2,
        width = 1.2,
        heading = 340,
        debugPoly = false,
        minZ = 34.64,
        maxZ = 36.64,
        options = {
            {
                type = "client",
                event = "qb-shops:marketshop",
                icon = "fas fa-shopping-cart",
                label = "Phone Store",
            },
        },
        distance = 3.0
    },
    ---------RepairStation
    ["RepairStation"] = {
        name = "RepairStation",
        coords = vector3(532.4, -176.82, 54.22),
        length = 6.4,
        width = 9.2,
        heading = 5,
        debugPoly = false,
        minZ = 53.22,
        maxZ = 57.22,
        options = {
            {
                type = "client",
                event = "khrp:fixCarS",
                icon = "fas fa-car",
                label = "Repair Vehicle",
            },
        },
        distance = 5.0
    },
}
Config.PolyZones = {

}

Config.TargetBones = {
    ["tires"] = {
        bones = { "wheel_lf", "wheel_rf", "wheel_lm1", "wheel_rm1", "wheel_lm2", "wheel_rm2", "wheel_lm3", "wheel_rm3", "wheel_lr", "wheel_rr" },
        options = {
            {
                type = "client",
                event = "Tire:Handler",
                icon = "fa-solid fa-circle-dot",
                label = "Remove Tire",
            },
        },
        distance = 2.0,
    },
    {
        type = "client",
        event = "cdn-fuel:client:SendMenuToServer",
        icon = "fas fa-gas-pump",
        label = "Insert Nozzle",
        canInteract = function() return Allowrefuel end
    },
    {
        type = "client",
        action = function()
            TriggerEvent('cdn-fuel:client:electric:RefuelMenu')
        end,
        icon = "fas fa-bolt",
        label = "Insert Electric Nozzle",
        canInteract = function() return AllowElectricRefuel end
    },
}

Config.TargetEntities = {

}
-- 		models = -1126237515,
--models = -1364697528,
--models =  506770882,
Config.TargetModels = {
    -- ["tacogarage"] = {
    --     models = {
    --         "a_f_y_hipster_02"
    --     },
    --     options = {
    --         {
    --             type = "client",
    --             event = "garage:TacoGarage",
    --             icon = "fas fa-car",
    --             label = "Taco Garage",
    --             job = "taco",
    --         }
    --     },
    -- distance = 2.5,
    -- },
    ['BEE'] = {
        models = { "gate_beehive", "gate_beehive02", "gate_beehive03" },
        options = {
            {
                type = "client",
                event = "row-beekeeping:checkBeehive",
                icon = "fas fa-archive",
                label = "Check",
            },
        },
        distance = 2.5
    },

    ["prisonshop"] = {
        models = {
            `a_m_y_salton_01`,
        },
        options = {
            {
                event = "qb-shops:client:OpenPrisonShop",
                icon = "fas fa-circle",
                label = "Prison Market",
            },
        },
        distance = 2.5
    },

    ["Police Shop"] = {
        models = {
            "s_f_y_cop_01",
        },
        options = {
            {
                type = "client",
                event = "qb-policegarage:Menu",
                icon = "fas fa-car",
                label = "Open Police Garage",
                job = "police",
            },
        },
        distance = 2.5,
    },
    ["Davis Police Shop"] = {
        models = {
            "s_f_y_cop_01",
        },
        options = {
            {
                type = "client",
                event = "qb-policegarage:Menu",
                icon = "fas fa-car",
                label = "Open Police Garage",
                job = "police",
            },
        },
        distance = 2.5,
    },
    ["PD Armory"] = {
        models = {
            "ig_trafficwarden",
        },
        options = {
            {
                type = "client",
                event = "qb-police:interact:armory",
                icon = "fa-shield",
                label = "PD Armory",
                job = "police",
            },
        },
        distance = 2.5,
    },
    ["sea world"] = {
        models = {
            "cs_dom",
        },
        options = {
            {
                type = "client",
                event = "qb-shops:marketshop",
                icon = "fas fa-circle",
                label = "Buy Gear",
            },
        },
        distance = 2.5,
    },

    ["VehicleRental"] = {
        models = {
            'a_m_y_business_03',
        },
        options = {
            {
                type = "client",
                event = "qb-rental:openMenu",
                icon = "fas fa-car",
                label = "Rent Vehicle",
            },
        },
        distance = 4.0
    },
    -- ["youtool shops"] = {
    --     models = {
    --         "s_m_m_lathandy_01",
    --     },
    --     options = {
    --         {
    --             type = "client",
    --             event = "qb-shops:marketshop",
    --             icon = "fas fa-wrench",
    --             label = "Buy Tools",
    --         },
    --     },
    --     distance = 2.5,
    -- },
    ["sea world"] = {
        models = {
            "cs_dom",
        },
        options = {
            {
                type = "client",
                event = "qb-shops:marketshop",
                icon = "fas fa-circle",
                label = "Buy Gear",
            },
        },
        distance = 2.5,
    },
}

Config.GlobalPedOptions = {

}

Config.GlobalVehicleOptions = {
}

Config.GlobalObjectOptions = {

}

Config.GlobalPlayerOptions = {
    options = {
        {
            event = "police:client:RobPlayer",
            icon = "fas fa-user-secret",
            label = "Rob Player",
        },
        {
            type = "client",
            event = "police:client:CuffPlayer",
            icon = "fas fa-hands",
            label = "Cuff / Uncuff",
            job = "police",
            item = 'handcuffs',
        },
        {
            type = "client",
            event = "police:client:EscortPlayer",
            icon = "fas fa-key",
            label = "Escort",
        },
        {
            type = "client",
            event = "police:client:PutPlayerInVehicle",
            icon = "fas fa-chevron-circle-left",
            job = 'police',
            label = "Place in Vehicle",
        },
        {
            type = "client",
            event = "police:client:SetPlayerOutVehicle",
            icon = "fas fa-chevron-circle-right",
            job = 'police',
            label = "Take out of Vehicle",
        },
    }
}

Config.Peds = {
    { -------Bank------
        model = `a_m_y_smartcaspat_01`,
        coords = vector4(-112.22, 6471.01, 30.63, 134.18),
        gender = 'male',
        freeze = true,
        invincible = true,
        blockevents = true,
    },
    { -------Bank------
        model = `a_m_y_smartcaspat_01`,
        coords = vector4(1174.8, 2708.2, 37.09, 178.52),
        gender = 'male',
        freeze = true,
        invincible = true,
        blockevents = true,
    },
    { -------Bank------
        model = `a_m_y_smartcaspat_01`,
        coords = vector4(-2961.14, 483.09, 14.7, 83.84),
        gender = 'male',
        freeze = true,
        invincible = true,
        blockevents = true,
    },
    { -------Bank------
        model = `a_m_y_smartcaspat_01`,
        coords = vector4(-1211.9, -331.9, 36.78, 20.07),
        gender = 'male',
        freeze = true,
        invincible = true,
        blockevents = true,
    },
    { -------Bank------
        model = `a_m_y_smartcaspat_01`,
        coords = vector4(-351.23, -51.28, 48.04, 341.73),
        gender = 'male',
        freeze = true,
        invincible = true,
        blockevents = true,
    },
    { -------Bank------
        model = `a_m_y_smartcaspat_01`,
        coords = vector4(149.46, -1042.09, 28.37, 335.43),
        gender = 'male',
        freeze = true,
        invincible = true,
        blockevents = true,
    },
    { -------Bank------
        model = `a_m_y_smartcaspat_01`,
        coords = vector4(313.84, -280.58, 53.16, 338.31),
        gender = 'male',
        freeze = true,
        invincible = true,
        blockevents = true,
    },
    { -------Bank------
        model = `cs_fbisuit_01`,
        coords = vector4(242.82017, 226.6354, 105.2873, 159.48873),
        gender = 'male',
        freeze = true,
        invincible = true,
        blockevents = true,
    },
    {
        model = `a_m_y_business_02`,
        coords = vector4(-1002.7299, -477.6972, 50.0274, 118.8798),
        networked = false,
        invincible = true,
        blockevents = true,
        -- weapon = {
        --     name = `weapon_carbinerifle`,
        --     ammo = 0,
        --     hidden = false,
        -- },
        target = {
            options = {
                {
                    type = "client",
                    event = "abl:ServerIntro:Show",
                    icon = "fas fa-door-open",
                    label = "Go To Airport",
                    -- job = "police",
                },
            },
            distance = 2.5
        }
    }
}

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------
local function JobCheck() return true end
local function GangCheck() return true end
local function ItemCount() return true end
local function CitizenCheck() return true end

local function AllowRefuel(state, electric)
    if state then
        if electric then
            AllowElectricRefuel = true
        else
            Allowrefuel = true
        end
    else
        if electric then
            AllowElectricRefuel = false
        else
            Allowrefuel = false
        end
    end
end
exports('AllowRefuel', AllowRefuel)

CreateThread(function()
    if not Config.Standalone then
        local QBCore = exports['qb-core']:GetCoreObject()
        local PlayerData = QBCore.Functions.GetPlayerData()

        ItemCount = function(item)
            for _, v in pairs(PlayerData.items) do
                if v.name == item then
                    return true
                end
            end
            return false
        end

        JobCheck = function(job)
            if type(job) == 'table' then
                job = job[PlayerData.job.name]
                if job and PlayerData.job.grade.level >= job then
                    return true
                end
            elseif job == 'all' or job == PlayerData.job.name then
                return true
            end
            return false
        end

        GangCheck = function(gang)
            if type(gang) == 'table' then
                gang = gang[PlayerData.gang.name]
                if gang and PlayerData.gang.grade.level >= gang then
                    return true
                end
            elseif gang == 'all' or gang == PlayerData.gang.name then
                return true
            end
            return false
        end

        CitizenCheck = function(citizenid)
            return citizenid == PlayerData.citizenid or citizenid[PlayerData.citizenid]
        end

        RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
            PlayerData = QBCore.Functions.GetPlayerData()
            SpawnPeds()
        end)

        RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
            PlayerData = {}
            DeletePeds()
        end)

        RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
            PlayerData.job = JobInfo
        end)

        RegisterNetEvent('QBCore:Client:OnGangUpdate', function(GangInfo)
            PlayerData.gang = GangInfo
        end)

        RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
            PlayerData = val
        end)
    else
        local firstSpawn = false
        AddEventHandler('playerSpawned', function()
            if not firstSpawn then
                SpawnPeds()
                firstSpawn = true
            end
        end)
    end
end)

function CheckOptions(data, entity, distance)
    if distance and data.distance and distance > data.distance then return false end
    if data.job and not JobCheck(data.job) then return false end
    if data.gang and not GangCheck(data.gang) then return false end
    if data.item and not ItemCount(data.item) then return false end
    if data.citizenid and not CitizenCheck(data.citizenid) then return false end
    if data.canInteract and not data.canInteract(entity, distance, data) then return false end
    return true
end