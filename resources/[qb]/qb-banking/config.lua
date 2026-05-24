Config = {
    useTarget = GetConvar('UseTarget', 'false') == 'true',
    atmModels = { 'prop_atm_01', 'prop_atm_02', 'prop_atm_03', 'prop_fleeca_atm', 'prop_atm_04', 'prop_fleet_atm_01' },
    useDailyLimit = true,
    dailyLimit = 5000,
    maxAccounts = 2,
    blipInfo = {
        name = 'Phantom Banking',
        sprite = 108,
        color = 2,
        scale = 0.6
    },
    atmBlipInfo = {
        name = 'Phantom ATM',
        sprite = 277,
        color = 2,
        scale = 0.5
    },
    -- All bank branches (Fleeca + Maze Bank) – full banking
    locations = {
        vector3(149.05, -1041.3, 29.37),      -- Legion Square Fleeca
        vector3(313.32, -280.03, 54.17),     -- Alta Fleeca
        vector3(-351.94, -50.72, 49.04),     -- Burton Fleeca
        vector3(-1212.68, -331.83, 37.78),    -- Del Perro Fleeca
        vector3(-2961.67, 482.31, 15.7),     -- Great Ocean Fleeca
        vector3(1175.64, 2707.71, 38.09),    -- Sandy Shores Fleeca
        vector3(247.65, 223.87, 106.29),     -- Maze Bank Tower
        vector3(-111.98, 6470.56, 31.63),    -- Paleto Bay Fleeca
        vector3(-75.59, -818.43, 326.18),    -- Maze Bank West (top)
        vector3(241.22, 227.67, 106.29),     -- Pacific Standard / Maze Bank
        vector3(-137.99, 6460.83, 31.63),    -- Paleto (alt)
    },
    -- Standalone ATM blip locations (use with bank_card or walk up to prop)
    atmLocations = {
        vector3(89.75, 2.4, 68.31),
        vector3(-846.30, -340.40, 38.68),
        vector3(-256.23, -716.01, 33.52),
        vector3(380.79, 323.73, 103.57),
        vector3(-3241.55, 997.54, 12.56),
        vector3(1968.09, 3743.59, 32.35),
        vector3(-1820.52, 792.52, 138.09),
        vector3(1172.50, 2702.50, 38.09),
        vector3(-660.70, -854.07, 24.49),
        vector3(33.18, -1347.22, 29.50),
        vector3(129.22, -1292.70, 29.27),
        vector3(-717.67, -915.65, 19.22),
        vector3(-526.57, -1222.98, 18.45),
        vector3(165.37, 6636.36, 31.61),
        vector3(1701.21, 6426.56, 32.76),
    }
}
