Config = {}

Config.Framework = GetResourceState('qbx_core') ~= 'missing' and 'qbx' or 'qb'
Config.Debug = false

-- Arena Locations
Config.Arenas = {
    {
        id = 'bank_assault',
        name = 'Bank Assault',
        description = 'Robbers attempt to breach the bank vault while cops defend.',
        type = 'objective',
        coords = vec3(235.0, 216.0, 106.0),
        team1Spawn = vec3(228.0, 214.0, 105.0), -- Cops
        team2Spawn = vec3(260.0, 220.0, 106.0), -- Robbers
        objectives = {
            { name = 'Vault Door', coords = vec3(254.5, 225.5, 101.9), captureTime = 60 },
            { name = 'Cash Desk', coords = vec3(248.0, 222.0, 106.0), captureTime = 30 },
        },
        roundTime = 300,
        maxPlayers = 8,
        minPlayers = 4,
    },
    {
        id = 'hostage_rescue',
        name = 'Hostage Rescue',
        description = 'Cops must rescue hostages from the robbers.',
        type = 'objective',
        coords = vec3(440.0, -983.0, 30.7),
        team1Spawn = vec3(450.0, -990.0, 30.0), -- Cops
        team2Spawn = vec3(430.0, -975.0, 30.0), -- Robbers
        objectives = {
            { name = 'Hostage 1', coords = vec3(440.0, -983.0, 30.7), rescueTime = 10 },
            { name = 'Hostage 2', coords = vec3(445.0, -985.0, 30.7), rescueTime = 10 },
        },
        roundTime = 240,
        maxPlayers = 10,
        minPlayers = 4,
    },
    {
        id = 'gang_war',
        name = 'Gang War',
        description = 'Team deathmatch in the industrial district.',
        type = 'tdm',
        coords = vec3(800.0, -2200.0, 30.0),
        team1Spawn = vec3(790.0, -2210.0, 30.0),
        team2Spawn = vec3(810.0, -2190.0, 30.0),
        roundTime = 300,
        scoreLimit = 30,
        maxPlayers = 12,
        minPlayers = 2,
    },
    {
        id = 'downtown_siege',
        name = 'Downtown Siege',
        description = 'Robbers control the rooftops, cops must clear them out.',
        type = 'objective',
        coords = vec3(0.0, -600.0, 80.0),
        team1Spawn = vec3(-10.0, -610.0, 80.0), -- Cops
        team2Spawn = vec3(10.0, -590.0, 80.0), -- Robbers
        objectives = {
            { name = 'Rooftop Control', coords = vec3(0.0, -600.0, 80.0), captureTime = 45 },
        },
        roundTime = 360,
        maxPlayers = 16,
        minPlayers = 4,
    },
}

-- Loadouts
Config.Loadouts = {
    cop = {
        weapons = {
            { name = 'weapon_pistol', ammo = 120 },
            { name = 'weapon_carbinerifle', ammo = 180 },
            { name = 'weapon_nightstick', ammo = 1 },
            { name = 'weapon_stungun', ammo = 5 },
        },
        items = {
            { name = 'armor', amount = 2 },
            { name = 'bandage', amount = 5 },
        },
        skin = 's_m_y_cop_01',
    },
    swat = {
        weapons = {
            { name = 'weapon_pistol', ammo = 120 },
            { name = 'weapon_carbinerifle_mk2', ammo = 240 },
            { name = 'weapon_smg', ammo = 200 },
            { name = 'weapon_flashlight', ammo = 1 },
        },
        items = {
            { name = 'armor', amount = 3 },
            { name = 'bandage', amount = 8 },
        },
        skin = 's_m_y_swat_01',
    },
    robber = {
        weapons = {
            { name = 'weapon_pistol', ammo = 90 },
            { name = 'weapon_smg', ammo = 150 },
            { name = 'weapon_crowbar', ammo = 1 },
        },
        items = {
            { name = 'armor', amount = 1 },
            { name = 'bandage', amount = 3 },
        },
        skin = 'g_m_y_mexgoon_03',
    },
    heavy = {
        weapons = {
            { name = 'weapon_pistol50', ammo = 90 },
            { name = 'weapon_combatmg', ammo = 300 },
            { name = 'weapon_pumpshotgun', ammo = 40 },
        },
        items = {
            { name = 'armor', amount = 2 },
            { name = 'bandage', amount = 5 },
        },
        skin = 'g_m_y_lost_03',
    },
}

-- Match Settings
Config.MatchSettings = {
    lobbyWaitTime = 60, -- seconds to wait for players
    roundEndDelay = 10, -- seconds between rounds
    matchEndDelay = 15, -- seconds before returning to lobby
    maxRounds = 5,
    friendlyFire = false,
    autoBalance = true,
    spectatorEnabled = true,
}

-- Rewards
Config.Rewards = {
    winXP = 500,
    lossXP = 200,
    killXP = 50,
    objectiveXP = 100,
    winMoney = 10000,
    lossMoney = 3000,
}

-- Team Colors
Config.TeamColors = {
    cops = { r = 0, g = 100, b = 255 },
    robbers = { r = 255, g = 50, b = 50 },
}
