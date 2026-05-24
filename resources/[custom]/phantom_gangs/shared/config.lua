Config = {}

Config.Framework = GetResourceState('qbx_core') ~= 'missing' and 'qbx' or 'qb'
Config.Debug = false

-- Gang Creation
Config.GangCreation = {
    enabled = true,
    cost = 50000,
    minLevel = 10,
    maxGangs = 10,
    maxMembers = 20,
    maxTerritories = 5,
}

-- Gang Ranks
Config.Ranks = {
    { id = 1, name = 'Recruit', label = 'Recruit', permissions = {} },
    { id = 2, name = 'Soldier', label = 'Soldier', permissions = { 'capture' } },
    { id = 3, name = 'Enforcer', label = 'Enforcer', permissions = { 'capture', 'invite', 'kick' } },
    { id = 4, name = 'Lieutenant', label = 'Lieutenant', permissions = { 'capture', 'invite', 'kick', 'manage' } },
    { id = 5, name = 'Boss', label = 'Boss', permissions = { 'capture', 'invite', 'kick', 'manage', 'disband', 'war' } },
}

-- Territories
Config.Territories = {
    {
        id = 'grovestreet',
        name = 'Grove Street',
        coords = vec3(85.0, -1958.0, 20.8),
        radius = 80.0,
        blipColor = 2,
        income = 5000,
        captureTime = 300, -- seconds
        type = 'residential',
        benefits = {
            drugMultiplier = 1.2,
            weaponDiscount = 0.1,
        },
    },
    {
        id = 'vinewood',
        name = 'Vinewood Hills',
        coords = vec3(500.0, 600.0, 140.0),
        radius = 100.0,
        blipColor = 46,
        income = 8000,
        captureTime = 420,
        type = 'luxury',
        benefits = {
            drugMultiplier = 1.5,
            xpBonus = 1.3,
        },
    },
    {
        id = 'industrial',
        name = 'Industrial District',
        coords = vec3(800.0, -2200.0, 30.0),
        radius = 120.0,
        blipColor = 21,
        income = 6000,
        captureTime = 360,
        type = 'industrial',
        benefits = {
            weaponDiscount = 0.2,
            vehicleDiscount = 0.15,
        },
    },
    {
        id = 'docks',
        name = 'Port of LS',
        coords = vec3(-600.0, -2200.0, 10.0),
        radius = 150.0,
        blipColor = 5,
        income = 7000,
        captureTime = 480,
        type = 'port',
        benefits = {
            drugMultiplier = 1.4,
            weaponDiscount = 0.15,
        },
    },
    {
        id = 'downtown',
        name = 'Downtown LS',
        coords = vec3(200.0, -900.0, 30.0),
        radius = 90.0,
        blipColor = 1,
        income = 10000,
        captureTime = 600,
        type = 'commercial',
        benefits = {
            drugMultiplier = 1.3,
            xpBonus = 1.5,
            weaponDiscount = 0.1,
        },
    },
    {
        id = 'sandy',
        name = 'Sandy Shores',
        coords = vec3(1800.0, 3800.0, 35.0),
        radius = 100.0,
        blipColor = 38,
        income = 4000,
        captureTime = 240,
        type = 'rural',
        benefits = {
            vehicleDiscount = 0.2,
        },
    },
    {
        id = 'mirrorpark',
        name = 'Mirror Park',
        coords = vec3(1200.0, -700.0, 60.0),
        radius = 70.0,
        blipColor = 7,
        income = 7500,
        captureTime = 360,
        type = 'suburban',
        benefits = {
            drugMultiplier = 1.2,
            xpBonus = 1.2,
        },
    },
    {
        id = 'paleto',
        name = 'Paleto Bay',
        coords = vec3(-150.0, 6400.0, 35.0),
        radius = 80.0,
        blipColor = 8,
        income = 3500,
        captureTime = 240,
        type = 'rural',
        benefits = {
            weaponDiscount = 0.1,
        },
    },
}

-- Gang War Settings
Config.WarSettings = {
    enabled = true,
    minMembers = 3,
    duration = 600, -- seconds
    cooldown = 1800, -- seconds between wars
    scoreLimit = 50,
    killPoints = 5,
    capturePoints = 20,
    winBonus = 25000,
    loseBonus = 5000,
}

-- Red Zone Settings
Config.RedZones = {
    enabled = true,
    showOnMap = true,
    alpha = 80,
    flashSpeed = 1000,
    captureColor = { r = 255, g = 0, b = 0, a = 80 },
    friendlyColor = { r = 0, g = 255, b = 0, a = 60 },
    enemyColor = { r = 255, g = 0, b = 0, a = 60 },
    neutralColor = { r = 128, g = 128, b = 128, a = 40 },
}

-- UI Colors by Gang
Config.GangColors = {
    default = { r = 200, g = 0, b = 0 },
    green = { r = 0, g = 200, b = 0 },
    blue = { r = 0, g = 100, b = 200 },
    purple = { r = 128, g = 0, b = 128 },
    orange = { r = 255, g = 140, b = 0 },
    yellow = { r = 255, g = 215, b = 0 },
    white = { r = 255, g = 255, b = 255 },
    black = { r = 50, g = 50, b = 50 },
}

-- Income Interval
Config.IncomeInterval = 30 -- minutes
