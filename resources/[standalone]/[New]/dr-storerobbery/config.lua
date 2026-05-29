Config = {}

Config.MinCops = 0

Config.RegisterCooldown = 600

Config.Reward = { min = 1500, max = 100000 }

Config.RedRegisters = {
    [1]  = true,
    [7]  = true,
    [8]  = true,
    [10] = true,
    [11] = true,
    [16] = true,
    [18] = true,
}

Config.XPReward = 500
Config.RobTime = 15000
Config.WantedStars = 2

Config.MembershipBonus = {
    gold = 2.0,
    diamond = 4.0,
}

Config.ClerkModels = {
    `mp_m_shopkeep_01`,
    `s_f_y_shop_mid`,
    `s_f_y_shop_low`,
}

-- One clerk per store (aligned with mz-storerobbery safe locations).
Config.Stores = {
    { id = 1,  label = 'Grove LTD',           registerIndex = 14, clerk = vector4(-43.43, -1748.30, 29.42, 50.0) },
    { id = 2,  label = 'Morningwood Liquor',  registerIndex = 17, clerk = vector4(-1478.94, -375.50, 40.16, 135.0) },
    { id = 3,  label = 'Vespucci Liquor',     registerIndex = 16, clerk = vector4(-1220.85, -916.05, 12.32, 32.0) },
    { id = 4,  label = 'Little Seoul LTD',    registerIndex = 11, clerk = vector4(-709.74, -904.15, 19.21, 90.0) },
    { id = 5,  label = 'Innocence Blvd 24/7', registerIndex = 1,  clerk = vector4(28.21, -1339.14, 29.49, 267.0) },
    { id = 6,  label = 'El Rancho 24/7',      registerIndex = 12, clerk = vector4(1126.77, -980.10, 45.41, 274.0) },
    { id = 7,  label = 'Mirror Park 24/7',    registerIndex = 10, clerk = vector4(1159.46, -314.05, 69.20, 100.0) },
    { id = 8,  label = 'Vinewood 24/7',       registerIndex = 8,  clerk = vector4(378.17, 333.44, 103.56, 252.0) },
    { id = 9,  label = 'Richman Glen LTD',    registerIndex = 15, clerk = vector4(-1829.27, 798.76, 138.19, 133.0) },
    { id = 10, label = 'Grand Senora 24/7',   registerIndex = 2,  clerk = vector4(-2959.64, 387.08, 14.04, 265.0) },
    { id = 11, label = 'Chumash 24/7',        registerIndex = 2,  clerk = vector4(-3047.88, 585.61, 7.90, 17.0) }, -- shares register zone with Grand Senora west
    { id = 12, label = 'Banham 24/7',         registerIndex = 3,  clerk = vector4(-3250.02, 1004.43, 12.83, 354.0) },
    { id = 13, label = 'Harmony 24/7',        registerIndex = 13, clerk = vector4(546.41, 2662.80, 42.15, 93.0) },
    { id = 14, label = 'Ace Liquor',          registerIndex = 19, clerk = vector4(1169.31, 2717.79, 37.15, 180.0) },
    { id = 15, label = 'Route 68 24/7',       registerIndex = 6,  clerk = vector4(2672.69, 3286.63, 55.24, 327.0) },
    { id = 16, label = 'Sandy Shores 24/7',   registerIndex = 5,  clerk = vector4(1959.26, 3748.92, 32.34, 303.0) },
    { id = 17, label = 'Paleto 24/7',         registerIndex = 4,  clerk = vector4(1734.78, 6420.84, 35.03, 246.0) },
    { id = 18, label = 'Grapeseed 24/7',      registerIndex = 4,  clerk = vector4(-168.40, 6318.80, 30.58, 225.0) },
    { id = 19, label = 'Mount Chiliad 24/7',  registerIndex = 4,  clerk = vector4(168.95, 6644.74, 31.70, 225.0) },
}

Config.Registers = {
    { coords = vector3(24.47, -1347.37, 29.50), heading = 267.0 },
    { coords = vector3(-3039.10, 584.24, 7.91), heading = 17.0 },
    { coords = vector3(-3242.24, 999.98, 12.83), heading = 354.0 },
    { coords = vector3(1728.67, 6415.88, 35.04), heading = 246.0 },
    { coords = vector3(1960.23, 3740.44, 32.34), heading = 303.0 },
    { coords = vector3(2678.20, 3279.39, 55.24), heading = 327.0 },
    { coords = vector3(2557.23, 380.83, 108.62), heading = 0.0 },
    { coords = vector3(372.58, 326.41, 103.56), heading = 252.0 },
    { coords = vector3(-48.42, -1757.88, 29.42), heading = 47.0 },
    { coords = vector3(1164.46, -322.18, 69.21), heading = 100.0 },
    { coords = vector3(-706.16, -913.53, 19.22), heading = 90.0 },
    { coords = vector3(1134.20, -982.47, 46.41), heading = 274.0 },
    { coords = vector3(549.38, 2671.10, 42.17), heading = 93.0 },
    { coords = vector3(-47.07, -1758.64, 29.42), heading = 45.0 },
    { coords = vector3(-706.07, -914.40, 19.22), heading = 90.0 },
    { coords = vector3(-1820.55, 794.52, 138.09), heading = 133.0 },
    { coords = vector3(-1221.99, -908.29, 12.33), heading = 32.0 },
    { coords = vector3(-1486.26, -377.98, 40.16), heading = 135.0 },
    { coords = vector3(1165.93, 2710.80, 38.16), heading = 180.0 },
}

-- Legacy hash list for aim detection fallback
Config.StoreClerkModels = Config.ClerkModels
