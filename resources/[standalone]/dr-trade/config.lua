Config = {}

-- QBX uses ox_inventory: prefer ox when ox_inventory or qbx_core is running (still overridable below if needed).
local function _started(name)
    return GetResourceState(name) == 'started'
end
Config.Inventory = (_started('ox_inventory') or _started('qbx_core')) and 'ox' or 'qb'
Config.Debug = false
Config.UseTokens = false
Config.PoliceCallChance = 40

local IronToBarrel = {
    tradeName = 'IronToBarrel',
    fromItems = {
        { name = 'iron', amount = 100 },
    },
    toItems = {
        { name = 'weapon_barrel', amount = 1 }
    },
}

local PlasticToTrigger = {
    tradeName = 'PlasticToTrigger',
    fromItems = {
        { name = 'plastic', amount = 100 }
    },
    toItems = {
        { name = 'weapon_trigger', amount = 1 }
    },
}

local CooperToGrip = {
    tradeName = 'CooperToGrip',
    fromItems = {
        {name = 'copper', amount = 100}
    },
    toItems = {
        { name = 'weapon_grip', amount = 1 }
    },
}


local GlassToMetal = {
    tradeName = 'GlassToMetal',
    fromItems = {
        { name = 'glass', amount = 100 },
        { name = 'still', amount = 100 }
    },
    toItems = {
        { name = 'metal_spring', amount = 1 }
    },
}


Config.Trades = {
    ['IronToBarrel'] = IronToBarrel,
    ['PlasticToTrigger'] = PlasticToTrigger,
    ['CooperToGrip'] = CooperToGrip,
    ['GlassToMetal'] = GlassToMetal,
}