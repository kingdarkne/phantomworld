Config = {}

-- MySQL Configuration
Config.Mysql = 'oxmysql' -- 'mysql-async', 'ghmattisql', 'oxmysql'

-- UI Configuration
Config.usePopui = false -- POPUI or Drawmarker Floating Text
Config.showmarker = true -- Drawmarker and Floating Text

-- Job Configuration
Config.job = 'mechanic' -- job permission
Config.UseRenzu_jobs = true -- to have profits for each upgrades
Config.PayoutShare = 0.5 -- 0.5 = 50% (how much profit share)

-- Prop Configuration
Config.DefaultProp = 'hei_prop_heist_box' -- default prop when carrying a parts

-- Custom Features
-- if you want CUSTOM ENGINE UPGRADE, TURBO and TIRES make sure to true this all
Config.UseCustomTurboUpgrade = true -- use renzu_custom Turbo System
Config.useturbosound = true -- use custom BOV Sound for each turbo
Config.turbosoundSync = true -- true = Server Sync Sound? or false = only the driver can hear it
Config.UseCustomEngineUpgrade = true -- enable disable custom engine upgrade
Config.UseCustomTireUpgrade = true -- enable disable custom tires upgrade
Config.RepairCost = 1500 -- repair cost

-- Shop Locations
Config.Shops = {
    [1] = {
        name = 'Bennys Original Motorworks',
        job = false, -- false = everyone can use
        coord = vector4(-205.68, -1312.12, 30.89, 0.0),
        marker = {
            type = 1,
            scale = vector3(1.5, 1.5, 1.0),
            color = {r = 255, g = 255, b = 0, a = 100},
        },
        blip = {
            sprite = 446,
            color = 5,
            scale = 0.7,
            label = 'Bennys Motorworks',
        },
    },
    [2] = {
        name = 'Los Santos Customs',
        job = false, -- false = everyone can use
        coord = vector4(-338.72, -136.31, 38.57, 0.0),
        marker = {
            type = 1,
            scale = vector3(1.5, 1.5, 1.0),
            color = {r = 255, g = 255, b = 0, a = 100},
        },
        blip = {
            sprite = 446,
            color = 5,
            scale = 0.7,
            label = 'Los Santos Customs',
        },
    },
    [3] = {
        name = 'Los Santos Customs Airport',
        job = false, -- false = everyone can use
        coord = vector4(-1155.53, -2013.36, 13.16, 0.0),
        marker = {
            type = 1,
            scale = vector3(1.5, 1.5, 1.0),
            color = {r = 255, g = 255, b = 0, a = 100},
        },
        blip = {
            sprite = 446,
            color = 5,
            scale = 0.7,
            label = 'LSC Airport',
        },
    },
    [4] = {
        name = 'Los Santos Customs Harmony',
        job = false, -- false = everyone can use
        coord = vector4(1176.88, 2640.25, 37.75, 0.0),
        marker = {
            type = 1,
            scale = vector3(1.5, 1.5, 1.0),
            color = {r = 255, g = 255, b = 0, a = 100},
        },
        blip = {
            sprite = 446,
            color = 5,
            scale = 0.7,
            label = 'LSC Harmony',
        },
    },
    [5] = {
        name = 'Los Santos Customs Paleto',
        job = false, -- false = everyone can use
        coord = vector4(107.52, 6625.29, 31.79, 0.0),
        marker = {
            type = 1,
            scale = vector3(1.5, 1.5, 1.0),
            color = {r = 255, g = 255, b = 0, a = 100},
        },
        blip = {
            sprite = 446,
            color = 5,
            scale = 0.7,
            label = 'LSC Paleto',
        },
    },
}

-- Turbo Configurations
Config.TurboConfig = {
    ['RACING'] = {
        power = 25, -- power increase percentage
        torque = 20,
        acceleration = 15,
        sound = 'turbo_racing',
    },
    ['SPORTS'] = {
        power = 15,
        torque = 12,
        acceleration = 10,
        sound = 'turbo_sports',
    },
    ['STREET'] = {
        power = 8,
        torque = 6,
        acceleration = 5,
        sound = 'turbo_street',
    },
}

-- Tire Configurations
Config.TireConfig = {
    ['DRAG'] = {
        traction = 3.0,
        grip = 2.5,
        label = 'Drag Tires',
    },
    ['RACING'] = {
        traction = 2.5,
        grip = 2.2,
        label = 'Racing Tires',
    },
    ['SPORTS'] = {
        traction = 2.0,
        grip = 1.8,
        label = 'Sports Tires',
    },
    ['STREET'] = {
        traction = 1.5,
        grip = 1.3,
        label = 'Street Tires',
    },
}

-- Engine Upgrade Configurations
Config.EngineConfig = {
    ['LEVEL_1'] = {
        power = 10,
        torque = 8,
        label = 'Stage 1',
    },
    ['LEVEL_2'] = {
        power = 20,
        torque = 15,
        label = 'Stage 2',
    },
    ['LEVEL_3'] = {
        power = 35,
        torque = 25,
        label = 'Stage 3',
    },
    ['LEVEL_4'] = {
        power = 50,
        torque = 35,
        label = 'Stage 4',
    },
}

-- Vehicle Parts that can be carried
Config.CarryableParts = {
    ['spoiler'] = {prop = 'prop_car_spoiler_01', label = 'Spoiler'},
    ['bumper_f'] = {prop = 'prop_car_bumper_01', label = 'Front Bumper'},
    ['bumper_r'] = {prop = 'prop_car_bumper_02', label = 'Rear Bumper'},
    ['skirt'] = {prop = 'prop_car_skirt_01', label = 'Side Skirt'},
    ['exhaust'] = {prop = 'prop_car_exhaust_01', label = 'Exhaust'},
    ['hood'] = {prop = 'prop_car_hood_01', label = 'Hood'},
    ['roof'] = {prop = 'prop_car_roof_01', label = 'Roof'},
}

-- Custom Paint Configuration
Config.EnableCustomPaint = true
Config.EnableRGBPaint = true
Config.EnableMattePaint = true
Config.EnableMetallicPaint = true
Config.EnableChromePaint = true

-- Parts Inventory System
Config.EnablePartsInventory = true
Config.MaxPartsInventory = 20

-- Stock Room Configuration
Config.EnableStockRoom = true
Config.StockRoomRefreshTime = 300 -- seconds

-- Spray Paint Configuration
Config.EnableSprayPaint = true
Config.SprayPaintCost = 500
Config.SprayPaintColors = {
    {label = 'Black', color = vector3(0, 0, 0)},
    {label = 'White', color = vector3(255, 255, 255)},
    {label = 'Red', color = vector3(255, 0, 0)},
    {label = 'Blue', color = vector3(0, 0, 255)},
    {label = 'Green', color = vector3(0, 255, 0)},
    {label = 'Yellow', color = vector3(255, 255, 0)},
    {label = 'Orange', color = vector3(255, 165, 0)},
    {label = 'Purple', color = vector3(128, 0, 128)},
    {label = 'Pink', color = vector3(255, 192, 203)},
    {label = 'Cyan', color = vector3(0, 255, 255)},
}

-- Framework Detection
local function _resStarted(name)
    return GetResourceState(name) == 'started'
end

local function _resFrameworkReady(name)
    local s = GetResourceState(name)
    return s == 'started' or s == 'starting'
end

local _qbLike = _resFrameworkReady('qb-core') or _resFrameworkReady('qbx_core')
Config.framework = _resStarted('es_extended') and 'ESX' or (_qbLike and 'QBCORE' or nil)

if not Config.framework then
    print('^1[renzu_customs]^7 NO FRAMEWORK DETECTED')
end
