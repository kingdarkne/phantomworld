Config = {}

-- Framework
Config.Framework = GetResourceState('qbx_core') ~= 'missing' and 'qbx' or 'qb'

-- Debug
Config.Debug = false

-- Police Settings
Config.PoliceRequired = {
    fleeca = 2,
    paleto = 3,
    pacific = 4,
    jewelry = 2,
    truck = 1,
}

-- Heist Locations
Config.Heists = {
    -- Fleeca Banks (Small)
    {
        id = 'fleeca_legion',
        name = 'Fleeca Bank - Legion Square',
        type = 'fleeca',
        coords = vec3(150.26, -1045.20, 29.37),
        vaultCoords = vec3(148.92, -1049.99, 29.37),
        hackCoords = vec3(146.53, -1046.10, 29.37),
        drillCoords = vec3(147.73, -1046.60, 29.37),
        exitCoords = vec3(143.62, -1041.23, 29.37),
        heading = 340.0,
        difficulty = 'easy',
        setupCost = 5000,
        payoutMin = 15000,
        payoutMax = 35000,
        cooldown = 30, -- minutes
        hackDuration = 30, -- seconds
        drillDuration = 60, -- seconds
        policeDelay = 30, -- seconds before alert
        blip = { sprite = 500, color = 2, scale = 0.8 },
    },
    {
        id = 'fleeca_hawick',
        name = 'Fleeca Bank - Hawick',
        type = 'fleeca',
        coords = vec3(-1211.25, -336.27, 37.78),
        vaultCoords = vec3(-1209.55, -338.17, 37.78),
        hackCoords = vec3(-1204.99, -338.19, 37.75),
        drillCoords = vec3(-1205.50, -336.30, 37.75),
        exitCoords = vec3(-1200.50, -331.50, 37.75),
        heading = 25.0,
        difficulty = 'easy',
        setupCost = 5000,
        payoutMin = 15000,
        payoutMax = 35000,
        cooldown = 30,
        hackDuration = 30,
        drillDuration = 60,
        policeDelay = 30,
        blip = { sprite = 500, color = 2, scale = 0.8 },
    },
    -- Paleto Bank (Medium)
    {
        id = 'paleto_bank',
        name = 'Blaine County Savings',
        type = 'paleto',
        coords = vec3(-104.20, 6476.11, 31.63),
        vaultCoords = vec3(-105.50, 6472.10, 31.63),
        hackCoords = vec3(-105.00, 6475.50, 31.63),
        thermiteCoords = vec3(-106.50, 6475.00, 31.63),
        drillCoords = vec3(-104.50, 6473.50, 31.63),
        exitCoords = vec3(-107.00, 6480.00, 31.63),
        heading = 45.0,
        difficulty = 'medium',
        setupCost = 15000,
        payoutMin = 50000,
        payoutMax = 100000,
        cooldown = 60,
        hackDuration = 45,
        thermiteDuration = 15,
        drillDuration = 90,
        policeDelay = 20,
        blip = { sprite = 500, color = 5, scale = 1.0 },
    },
    -- Pacific Standard (Hard)
    {
        id = 'pacific_bank',
        name = 'Pacific Standard Bank',
        type = 'pacific',
        coords = vec3(235.15, 216.72, 106.28),
        vaultCoords = vec3(254.50, 225.50, 101.88),
        hackCoords = vec3(261.50, 223.00, 106.28),
        thermiteCoords = vec3(253.00, 228.00, 101.88),
        drillCoords = vec3(255.00, 226.00, 101.88),
        exitCoords = vec3(228.00, 214.00, 105.50),
        heading = 70.0,
        difficulty = 'hard',
        setupCost = 50000,
        payoutMin = 150000,
        payoutMax = 300000,
        cooldown = 120,
        hackDuration = 60,
        thermiteDuration = 20,
        drillDuration = 120,
        policeDelay = 10,
        blip = { sprite = 500, color = 1, scale = 1.2 },
    },
    -- Jewelry Store
    {
        id = 'vangelico',
        name = 'Vangelico Jewelry Store',
        type = 'jewelry',
        coords = vec3(-630.20, -237.50, 38.05),
        vaultCoords = vec3(-623.00, -231.00, 38.05),
        hackCoords = vec3(-631.50, -229.50, 38.05),
        smashCoords = {
            vec3(-625.50, -232.50, 38.05),
            vec3(-626.50, -233.50, 38.05),
            vec3(-627.50, -234.50, 38.05),
            vec3(-624.50, -231.50, 38.05),
            vec3(-623.50, -230.50, 38.05),
            vec3(-622.50, -229.50, 38.05),
        },
        exitCoords = vec3(-633.00, -244.00, 38.05),
        heading = 310.0,
        difficulty = 'medium',
        setupCost = 10000,
        payoutMin = 25000,
        payoutMax = 60000,
        cooldown = 45,
        hackDuration = 20,
        smashCount = 6,
        policeDelay = 15,
        blip = { sprite = 439, color = 46, scale = 0.9 },
    },
}

-- Armored Truck Heists
Config.TruckHeists = {
    enabled = true,
    spawnInterval = 20, -- minutes
    payoutMin = 20000,
    payoutMax = 40000,
    routes = {
        {
            name = 'Los Santos Route',
            startCoords = vec3(-1333.50, -56.50, 50.50),
            endCoords = vec3(233.50, 214.00, 105.50),
            waypoints = {
                vec3(-1200.00, -200.00, 40.00),
                vec3(-800.00, -100.00, 37.00),
                vec3(-400.00, 50.00, 45.00),
                vec3(0.00, 100.00, 68.00),
                vec3(150.00, 150.00, 80.00),
            },
        },
        {
            name = 'Paleto Route',
            startCoords = vec3(170.00, 6636.00, 31.50),
            endCoords = vec3(-104.00, 6476.00, 31.50),
            waypoints = {
                vec3(100.00, 6550.00, 31.50),
                vec3(0.00, 6510.00, 31.50),
                vec3(-50.00, 6490.00, 31.50),
            },
        },
    },
}

-- Loot Types
Config.Loot = {
    cash_bag = {
        model = 'prop_money_bag_01',
        weight = 1.0,
        label = 'Cash Bag',
    },
    gold_bar = {
        model = 'prop_gold_bar',
        weight = 2.0,
        label = 'Gold Bar',
    },
    jewelry_box = {
        model = 'prop_jewel_04a',
        weight = 0.5,
        label = 'Jewelry',
    },
}

-- Minigame Settings
Config.Minigames = {
    hacking = {
        gridSize = 6,
        timeLimit = 30,
        requiredMatches = 3,
    },
    thermite = {
        gridSize = 5,
        timeLimit = 15,
        requiredMatches = 4,
    },
    drilling = {
        speed = 1.0,
        heatLimit = 100,
        targetDepth = 100,
    },
}

-- Police Dispatch
Config.Dispatch = {
    enabled = true,
    alertTitle = '10-90 - Robbery In Progress',
    alertMessage = 'Alarm triggered at {location}',
    blipSprite = 161,
    blipColor = 1,
    blipScale = 1.0,
    flashDuration = 30, -- seconds
}

-- Cooldowns (shared across all players)
Config.GlobalCooldowns = true

-- Max players per heist
Config.MaxPlayersPerHeist = 4
