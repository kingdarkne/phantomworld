Config = {}

Config.Framework = GetResourceState('qbx_core') ~= 'missing' and 'qbx' or 'qb'
Config.Debug = false

-- Admin Permissions (ace permission or specific citizenids)
Config.AdminPerms = {
    acePermission = 'command', -- Requires 'command' ace permission
    citizenids = {}, -- Add specific owner citizenids here if needed
}

-- Event Types
Config.Events = {
    moneyDrop = {
        enabled = true,
        name = 'Money Rain',
        description = 'Money bags falling from the sky!',
        defaultAmount = 5000,
        defaultDuration = 300, -- seconds
        bagModel = 'prop_money_bag_01',
        dropInterval = 2, -- seconds between drops
        maxBags = 50,
        radius = 100.0,
        minDropHeight = 50.0,
        maxDropHeight = 100.0,
        colors = {
            primary = '#00ff64',
            secondary = '#00cc50',
        },
    },
    freeCars = {
        enabled = true,
        name = 'Free Car Giveaway',
        description = 'All vehicles are FREE for a limited time!',
        defaultDuration = 600, -- seconds
        allowedCategories = { 'sports', 'super', 'sedan', 'suv', 'muscle', 'coupe', 'motorcycle' },
        maxCarsPerPlayer = 3,
        spawnLocation = vec3(215.0, -809.0, 30.7),
        colors = {
            primary = '#4488ff',
            secondary = '#2266dd',
        },
    },
    doubleXP = {
        enabled = true,
        name = 'Double XP Weekend',
        description = 'Earn 2x XP on all skills!',
        defaultDuration = 3600, -- seconds (1 hour)
        multiplier = 2.0,
        colors = {
            primary = '#ffaa00',
            secondary = '#dd8800',
        },
    },
    doublePayday = {
        enabled = true,
        name = 'Double Payday',
        description = 'All jobs pay 2x!',
        defaultDuration = 1800, -- 30 min
        multiplier = 2.0,
        colors = {
            primary = '#ff6464',
            secondary = '#dd4444',
        },
    },
    treasureHunt = {
        enabled = true,
        name = 'Treasure Hunt',
        description = 'Find hidden treasures across the map!',
        defaultDuration = 900, -- 15 min
        treasureCount = 10,
        chestModels = { 'prop_chest_01a', 'prop_chest_02a' },
        rewards = {
            { type = 'cash', min = 1000, max = 5000, chance = 50 },
            { type = 'cash', min = 5000, max = 15000, chance = 30 },
            { type = 'cash', min = 15000, max = 50000, chance = 15 },
            { type = 'cash', min = 50000, max = 100000, chance = 5 },
        },
        colors = {
            primary = '#ffcc00',
            secondary = '#ddaa00',
        },
    },
    lottery = {
        enabled = true,
        name = 'Phantom Lottery',
        description = 'Buy tickets for a chance to win BIG!',
        defaultDuration = 600, -- 10 min buy window
        ticketPrice = 1000,
        defaultPrize = 100000,
        colors = {
            primary = '#aa44ff',
            secondary = '#8822dd',
        },
    },
    vipBonus = {
        enabled = true,
        name = 'VIP Bonus Hour',
        description = 'VIP perks for everyone!',
        defaultDuration = 3600,
        vipPerks = {
            storeDiscount = 0.25,
            fuelDiscount = 0.50,
            repairDiscount = 0.50,
            bankInterest = 0.05,
        },
        colors = {
            primary = '#ff44aa',
            secondary = '#dd2288',
        },
    },
}

-- Drop Locations for Money Rain
Config.DropLocations = {
    { name = 'Legion Square', coords = vec3(195.0, -933.0, 30.0), radius = 30.0 },
    { name = 'Pier', coords = vec3(-1600.0, -1050.0, 13.0), radius = 40.0 },
    { name = 'Observatory', coords = vec3(-420.0, 1175.0, 325.0), radius = 25.0 },
    { name = 'Sandy Shores', coords = vec3(1700.0, 3800.0, 35.0), radius = 30.0 },
    { name = 'Vinewood Sign', coords = vec3(750.0, 1200.0, 325.0), radius = 20.0 },
    { name = 'Mount Chiliad', coords = vec3(500.0, 5600.0, 800.0), radius = 35.0 },
    { name = 'Airport', coords = vec3(-1100.0, -2900.0, 13.0), radius = 40.0 },
    { name = 'Maze Bank', coords = vec3(-75.0, -818.0, 326.0), radius = 25.0 },
    { name = 'Del Perro Pier', coords = vec3(-1600.0, -1050.0, 13.0), radius = 40.0 },
    { name = 'Golf Course', coords = vec3(-1350.0, 150.0, 55.0), radius = 30.0 },
}

-- Treasure Hunt Locations
Config.TreasureLocations = {
    vec3(150.0, -1000.0, 30.0),
    vec3(-500.0, -300.0, 35.0),
    vec3(1200.0, -700.0, 60.0),
    vec3(-1500.0, 900.0, 180.0),
    vec3(2500.0, 3700.0, 45.0),
    vec3(-800.0, 5400.0, 35.0),
    vec3(1700.0, 3300.0, 40.0),
    vec3(-2200.0, -400.0, 13.0),
    vec3(900.0, -1800.0, 30.0),
    vec3(-1200.0, -1500.0, 4.0),
    vec3(3000.0, -1700.0, 5.0),
    vec3(-700.0, 600.0, 140.0),
    vec3(1100.0, 2500.0, 45.0),
    vec3(-200.0, 6200.0, 31.0),
    vec3(2800.0, 4300.0, 50.0),
}

-- Free Car Spawns
Config.FreeCarSpawns = {
    vec4(215.0, -809.0, 30.7, 250.0),
    vec4(220.0, -804.0, 30.7, 250.0),
    vec4(225.0, -799.0, 30.7, 250.0),
    vec4(230.0, -794.0, 30.7, 250.0),
    vec4(235.0, -789.0, 30.7, 250.0),
    vec4(210.0, -814.0, 30.7, 250.0),
}

-- UI Settings
Config.UI = {
    announcementDuration = 10000,
    countdownFont = 'Share Tech Mono',
    particleColor = { r = 255, g = 215, b = 0 },
}
