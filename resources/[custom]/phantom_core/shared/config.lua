Config = {}

-- Framework Detection
Config.Framework = GetResourceState('qbx_core') ~= 'missing' and 'qbx' or 'qb'

-- UI Configuration
Config.UI = {
    Notifications = {
        DefaultPosition = 'top-right',
        MaxVisible = 5,
        DefaultDuration = 4000,
        AnimationDuration = 300,
    },
    Progress = {
        DefaultDuration = 5000,
        CanCancel = true,
        CancelKey = 46, -- E key
    },
    Menu = {
        MaxWidth = 600,
        AnimationDuration = 200,
    },
}

-- Vehicle Configuration
Config.Vehicles = {
    Spawner = {
        DefaultSpawnDistance = 30,
        SpawnDelay = 1000,
    },
    Garage = {
        ImpoundFee = 500,
        ImpoundLocations = {
            { coords = vec3(405.15, -1647.47, 29.29), heading = 90.0 },
            { coords = vec3(-234.91, -1339.18, 31.30), heading = 270.0 },
        },
    },
    Fuel = {
        ConsumptionRate = 0.1,
        IdleConsumption = 0.01,
        Prices = {
            regular = 2.5,
            plus = 3.0,
            premium = 3.5,
            diesel = 2.8,
        },
    },
    Tuning = {
        MaxLevel = 5,
        Prices = {
            engine = { 5000, 10000, 20000, 35000, 50000 },
            transmission = { 4000, 8000, 15000, 25000, 40000 },
            brakes = { 3000, 6000, 12000, 20000, 30000 },
            suspension = { 3000, 6000, 12000, 20000, 30000 },
            armor = { 5000, 10000, 20000, 35000, 50000 },
            turbo = { 25000 },
        },
    },
}

-- Player Configuration
Config.Player = {
    Emotes = {
        Categories = {
            { name = 'Greetings', icon = '👋' },
            { name = 'Dance', icon = '💃' },
            { name = 'Actions', icon = '🎭' },
            { name = 'Sports', icon = '⚽' },
            { name = 'Work', icon = '💼' },
        },
    },
    Interactions = {
        MaxDistance = 3.0,
        Key = 38, -- E key
    },
    Radio = {
        DefaultChannel = 1,
        MaxChannels = 100,
        Volume = 1.0,
    },
}

-- Economy Configuration
Config.Economy = {
    Banking = {
        InterestRate = 0.02, -- 2% monthly
        InterestInterval = 30, -- days
        ATMLocations = {
            { coords = vec3(149.51, -1040.20, 29.38) },
            { coords = vec3(-1212.98, -330.84, 37.79) },
            { coords = vec3(-2962.60, 482.63, 15.70) },
            { coords = vec3(112.44, -776.24, 31.43) },
            { coords = vec3(-113.28, 6470.23, 31.63) },
        },
    },
    Shops = {
        Categories = {
            { name = 'Food', icon = '🍔' },
            { name = 'Drinks', icon = '🥤' },
            { name = 'Medical', icon = '💊' },
            { name = 'Electronics', icon = '📱' },
            { name = 'Clothing', icon = '👕' },
        },
        TaxRate = 0.08, -- 8% sales tax
    },
    Jobs = {
        DefaultPaycheck = 500,
        PaycheckInterval = 15, -- minutes
        BonusMultiplier = 1.5,
    },
    Tax = {
        IncomeTaxRate = 0.15, -- 15%
        PropertyTaxRate = 0.05, -- 5%
        LuxuryTaxThreshold = 1000000,
        LuxuryTaxRate = 0.10, -- 10%
    },
}

-- Mechanics Configuration
Config.Mechanics = {
    Skills = {
        MaxLevel = 100,
        XPPerAction = 10,
        XPMultiplier = 1.0,
        Skills = {
            { id = 'strength', name = 'Strength', icon = '💪' },
            { id = 'stamina', name = 'Stamina', icon = '🏃' },
            { id = 'driving', name = 'Driving', icon = '🚗' },
            { id = 'shooting', name = 'Shooting', icon = '🎯' },
            { id = 'hacking', name = 'Hacking', icon = '💻' },
        },
    },
    Housing = {
        MaxProperties = 5,
        PropertyTypes = {
            { name = 'Apartment', maxSlots = 2, price = 100000 },
            { name = 'House', maxSlots = 4, price = 500000 },
            { name = 'Mansion', maxSlots = 8, price = 2000000 },
        },
    },
}

-- Debug Configuration
Config.Debug = false
