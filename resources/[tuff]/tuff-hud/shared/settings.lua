-- Do not touch.
Framework                      = (GetResourceState("es_extended") == "started" and exports['es_extended']:getSharedObject()) or
    (GetResourceState("qbx_core") == "started" and exports['qbx_core']:GetCoreObject()) or nil

Settings                       = {}
Settings.Fuel                  = (GetResourceState("ox_fuel") == "started" and "ox_fuel") or
    (GetResourceState("x-fuel") == "started" and "x-fuel") or
    (GetResourceState("LegacyFuel") == "started" and "LegacyFuel") or
    (GetResourceState("cdn-fuel") == "started" and "cdn-fuel") or
    (GetResourceState("Renewed-Fuel") == "started" and "Renewed-Fuel") or
    (GetResourceState("qb-fuel") == "started" and "qb-fuel") or (GetResourceState("lc_fuel") == "started" and "lc_fuel") or
    (GetResourceState("ps-fuel") == "started" and "ps-fuel") or
    (GetResourceState("rcore_fuel") == "started" and "rcore_fuel") or
    (GetResourceState("lj-fuel") == "started" and "lj-fuel") or "native"
Settings.Framework             = (GetResourceState("es_extended") == "started" and "ESX") or
    (GetResourceState("qbx_core") == "started" and "Qbox") or
    nil

-- if you have framework hud will show thing for framework
-- for example if you doesn't have framework it will not show job, money etc
-- if you have framework but you don't want those things just disable them in settings
Settings.FrameworkSystems      = Settings.Framework ~= nil

Settings.DisableStress         = not Settings.FrameworkSystems and true or
    false                             -- Enable/Disable stress status icon
Settings.StressSystem          = Settings.FrameworkSystems and true or
    false                             -- Enable/Disable stress system (if you have it in your framework you can disable this and just show the icon)

Settings.RealTime              = true -- Enable/Disable real time for player info hud
Settings.Currency              = "$"  -- Currency symbol shown for bank/cash in HUD
Settings.LowFuelAlertThreshold = 20   -- Play the low fuel alert when fuel is at this % or lower

-- Enable debug logs for development.
-- Set to `true` to print debug messages prefixed with `[tuff-hud][DEBUG]` in the client console.
Settings.Debug                 = false


Settings.PlayerInfoSpecificLocks = {
    -- default: player can change it in HUD settings
    -- always_show: always visible and cannot be changed in HUD settings
    -- always_hide: always hidden and cannot be changed in HUD settings
    LOGO = "default",
    ID = "default",
    TIME = "default",
    DATE = "default",
    BANK = "default",
    CASH = "default",
    BLACKMONEY = "default",
    JOB = "default"
}

Settings.FlyThroughtWindShield = true    -- Enable/Disable fly through windshield

Settings.SettingsCommand = "hudsettings" -- Command to open settings menu
Settings.SettingsKeybind = {
    enabled = true,
    key = "i",
    description = "Open settings menu"
}


Settings.SeatbeltDisabledVehicleClasses = { -- https://docs.fivem.net/natives/?_0x29439776AAA00A62
    8,                                      -- motorcycles
    13,                                     -- bicycles
    -- 14, -- boats
    -- 15, -- helicopters
    -- 16, -- planes
}

Settings.SeatbeltDisabledVehicleModels = {
    -- "polmav",
    -- "seashark",
}

Settings.Logo = {
    width = "5vh",
    height = "5vh",
    rounded = "100px"
}


Settings.MinimapTypes = {
    SQUARE = {
        moveX = 0.0,
        moveY = 0.0,
        defaultX = 0.0,
        defaultY = -0.09,
        width = 0.165,
        height = 0.205,
        blurOffsetX = -0.01,
        blurOffsetY = 0.081,
        blurWidthOffset = 0.102,
        blurHeightOffset = 0.135,
        clipType = 0,
        useSquareMask = true
    },
    CIRCLE = {
        moveX = 0.0,
        moveY = 0.0,
        defaultX = 0.0,
        defaultY = -0.09,
        width = 0.145,
        height = 0.215,
        blurOffsetX = -0.02,
        blurOffsetY = 0.01,
        blurWidthOffset = 0.03,
        blurHeightOffset = 0.03,
        clipType = 1,
        useSquareMask = false
    }
}


Settings.Default = {     -- settings for hud by default
    FPS = "60",          --   30    |   60   | 90
    MAP = "always",      --  never  | always | car (only in car)
    MAPTYPE = "SQUARE",  -- "SQUARE" | "CIRCLE"
    COMPASS = "ALWAYS",  --  "CAR" (only in car) | "FOOT" (only on foot) | "ALWAYS" | "NEVER"
    COMPASSCOLOR = "#C4FF48",
    WAYPOINT = "show",   --  show   |  hide
    WAYPOINTCOLOR = "#C4FF48",
    SPEEDUNIT = "kmh",   --   kmh   |  mph
    SPEEDTYPE = 1,       --    1    |   2   | 3
    HIDESPEED = 0,       --    0    |   1    (hide speed in car)
    CINEMATIC = 0,       --    0    |   1    (hide radar and hud)
    SEATBELTWARNING = 1, --    0    |   1    (enable seatbelt warning)
    LOWFUELWARNING = 1,  --    0    |   1    (enable low fuel warning)
    PLAYERINFO = {
        SHOW = true,     --  true   | false
        SPECIFIC = {
            LOGO = true,
            ID = true,
            TIME = true,
            DATE = true,
            BANK = true,
            CASH = true,
            BLACKMONEY = true,
            JOB = true
        },
        STATUS = {
            HIDE = false,      -- true | false (if status system not used no need for changeing)
            SHOWPERCENTAGE = { -- Show icons below or equal to the set %, except armor and stress which show above or equal
                HEALTH = 100,
                ARMOR = 1,
                FOOD = 100,
                WATER = 100,
                OXYGEN = 99,
                STRESS = 0,
                STAMINA = 99
            },
            COLOR = { -- Default status colors
                MICROPHONE = "#F0F7FA",
                HEALTH = "#FF635C",
                ARMOR = "#F0F7FA",
                FOOD = "#FFD373",
                WATER = "#00D0FF",
                OXYGEN = "#00FFA6",
                STRESS = "#B672FF", -- if stress system used
                STAMINA = "#C4FF48"
            }
        }
    }
}
