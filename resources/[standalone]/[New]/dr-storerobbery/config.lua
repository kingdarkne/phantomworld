Config = {}

-- Minimum number of on-duty cops required to start a robbery
Config.MinCops = 2

-- Cooldown per register (seconds)
Config.RegisterCooldown = 600 -- 10 minutes

-- Reward range (cash) per robbery (before membership multipliers)
Config.Reward = { min = 1500, max = 100000 }

-- High risk "red zone" bonus:
-- Registers listed here will use a much higher base reward
-- so with membership they can pay out crazy money.
-- Key is the register index from Config.Registers (1-based).
Config.RedRegisters = {
    -- Downtown / city hot spots
    [1]  = true, -- Innocence Blvd 24/7
    [7]  = true, -- North Rockford 24/7
    [8]  = true, -- Vinewood 24/7
    [10] = true, -- Mirror Park 24/7
    [11] = true, -- Little Seoul 24/7
    [16] = true, -- LTD Little Seoul
    [18] = true, -- Rob's Liquor Vespucci
}

-- XP reward per robbery (if dr-rankxp is running)
Config.XPReward = 500

-- Time to rob a register (ms)
Config.RobTime = 15000

-- Membership bonus multipliers (tier -> extra money)
-- Final payout = baseReward * (1 + value)
-- With these settings and max base 100k:
--   gold  -> up to 300k
--   diamond -> up to 500k
Config.MembershipBonus = {
    gold = 2.0,    -- +200% (x3 total)
    diamond = 4.0, -- +400% (x5 total)
}

-- Models for store clerks that can be robbed
Config.StoreClerkModels = {
    `mp_m_shopkeep_01`,
    `s_m_m_ammucountry`,
    `s_f_y_shop_low`,
    `s_f_y_shop_mid`,
    `s_f_y_shop_high`,
}

-- Locations of store registers grouped by store.
-- Each store can have one or more registers.
Config.Registers = {
    -- 24/7 STORES
    { coords = vector3(24.47, -1347.37, 29.50), heading = 267.0 },   -- Innocence Blvd 24/7
    { coords = vector3(-3039.10, 584.24, 7.91), heading = 17.0 },    -- Great Ocean Hwy 24/7 (Chumash)
    { coords = vector3(-3242.24, 999.98, 12.83), heading = 354.0 },  -- Great Ocean Hwy 24/7 (Banham)
    { coords = vector3(1728.67, 6415.88, 35.04), heading = 246.0 },  -- Paleto 24/7
    { coords = vector3(1960.23, 3740.44, 32.34), heading = 303.0 },  -- Sandy 24/7
    { coords = vector3(2678.20, 3279.39, 55.24), heading = 327.0 },  -- Route 68 24/7
    { coords = vector3(2557.23, 380.83, 108.62), heading = 0.0 },    -- North Rockford 24/7
    { coords = vector3(372.58, 326.41, 103.56), heading = 252.0 },   -- Vinewood 24/7
    { coords = vector3(-48.42, -1757.88, 29.42), heading = 47.0 },   -- Grove 24/7
    { coords = vector3(1164.46, -322.18, 69.21), heading = 100.0 },  -- Mirror Park 24/7
    { coords = vector3(-706.16, -913.53, 19.22), heading = 90.0 },   -- Little Seoul 24/7
    { coords = vector3(1134.20, -982.47, 46.41), heading = 274.0 },  -- El Rancho 24/7
    { coords = vector3(549.38, 2671.10, 42.17), heading = 93.0 },    -- Harmony 24/7

    -- LTD GASOLINE
    { coords = vector3(-47.07, -1758.64, 29.42), heading = 45.0 },   -- LTD Grove
    { coords = vector3(-706.07, -914.40, 19.22), heading = 90.0 },   -- LTD Little Seoul
    { coords = vector3(-1820.55, 794.52, 138.09), heading = 133.0 }, -- LTD Richman Glen

    -- LIQUOR STORES
    { coords = vector3(-1221.99, -908.29, 12.33), heading = 32.0 },  -- Rob's Liquor Vespucci
    { coords = vector3(-1486.26, -377.98, 40.16), heading = 135.0 }, -- Rob's Liquor Morningwood
    { coords = vector3(1165.93, 2710.80, 38.16), heading = 180.0 },  -- Ace Liquor
}

