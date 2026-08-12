Config = {}

-- Freeroam-first: soft RP, easy job pickup, Press E everywhere we can
Config.TextUI = '[E] Interact'
Config.InteractKey = 38 -- E
Config.InteractDist = 2.0

Config.JobPeds = {
    {
        label = 'Job Board — Freeroam Work',
        model = `a_m_y_business_02`,
        coords = vec4(-267.0, -958.5, 31.22, 205.0), -- near city hall / Legion
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        blip = { sprite = 408, color = 5, scale = 0.8 },
        jobs = {
            { id = 'unemployed', label = 'Civilian (Unemployed)', desc = 'Go freeroam — no clock-in' },
            { id = 'trucker', label = 'Trucker', desc = 'Haul cargo across the map' },
            { id = 'garbage', label = 'Garbage Collector', desc = 'Trash runs for quick cash' },
            { id = 'tow', label = 'Tow Driver', desc = 'Impound & roadside assists' },
            { id = 'taxi', label = 'Taxi Driver', desc = 'Pick up fares around the city' },
            { id = 'mechanic', label = 'Mechanic', desc = 'Fix & mod vehicles' },
            { id = 'burgershot', label = 'Burger Shot', desc = 'Flip burgers for tips' },
            { id = 'security', label = 'Security Guard', desc = 'Protect businesses' },
            { id = 'recycle', label = 'Recycling', desc = 'Sort scrap at the yard' },
            { id = 'hunter', label = 'Hunter', desc = 'Hunt wildlife up north' },
        },
    },
    {
        label = 'Mission Row Desk',
        model = `s_m_y_cop_01`,
        coords = vec4(441.0, -981.0, 30.69, 90.0),
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        blip = { sprite = 60, color = 29, scale = 0.7 },
        jobs = {
            { id = 'police', label = 'LSPD Officer', desc = 'Clock in as freeroam LEO' },
            { id = 'unemployed', label = 'Clock Out', desc = 'Return to civilian' },
        },
    },
    {
        label = 'Pillbox Intake',
        model = `s_m_m_doctor_01`,
        coords = vec4(311.2, -594.5, 43.28, 70.0),
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        blip = { sprite = 61, color = 1, scale = 0.7 },
        jobs = {
            { id = 'ambulance', label = 'EMS / Medic', desc = 'Respond to medical calls' },
            { id = 'unemployed', label = 'Clock Out', desc = 'Return to civilian' },
        },
    },
    {
        label = 'Underground Contact',
        model = `g_m_y_mexgoon_02`,
        coords = vec4(127.2, -1298.8, 29.27, 300.0), -- Vanilla Unicorn alley vibe
        scenario = 'WORLD_HUMAN_SMOKING',
        blip = { sprite = 480, color = 1, scale = 0.65 },
        jobs = {
            { id = 'unemployed', label = 'Stay Off Grid', desc = 'No official job' },
            { id = 'criminal', label = 'Street Hustler', desc = 'Opens phone contracts (robbery/hit)' },
        },
        criminal = true,
    },
}

-- Press E shop zones (opens ox_inventory shop if registered, else notify)
Config.ShopZones = {
    { label = '24/7 Market', coords = vec3(25.7, -1347.3, 29.5), radius = 2.2, shop = 'General' },
    { label = '24/7 Market', coords = vec3(-3038.71, 585.9, 7.9), radius = 2.2, shop = 'General' },
    { label = '24/7 Market', coords = vec3(-3241.47, 1001.14, 12.83), radius = 2.2, shop = 'General' },
    { label = '24/7 Market', coords = vec3(1728.66, 6414.16, 35.03), radius = 2.2, shop = 'General' },
    { label = '24/7 Market', coords = vec3(1697.99, 4924.4, 42.06), radius = 2.2, shop = 'General' },
    { label = '24/7 Market', coords = vec3(1961.48, 3739.96, 32.34), radius = 2.2, shop = 'General' },
    { label = '24/7 Market', coords = vec3(547.79, 2671.79, 42.15), radius = 2.2, shop = 'General' },
    { label = '24/7 Market', coords = vec3(2679.25, 3280.12, 55.24), radius = 2.2, shop = 'General' },
    { label = '24/7 Market', coords = vec3(2557.94, 382.05, 108.62), radius = 2.2, shop = 'General' },
    { label = '24/7 Market', coords = vec3(373.55, 325.56, 103.56), radius = 2.2, shop = 'General' },
    { label = 'Rob\'s Liquor', coords = vec3(-1222.77, -908.19, 12.32), radius = 2.2, shop = 'Liquor' },
    { label = 'Rob\'s Liquor', coords = vec3(-1487.7, -378.53, 40.16), radius = 2.2, shop = 'Liquor' },
    { label = 'Rob\'s Liquor', coords = vec3(-2967.79, 391.49, 15.04), radius = 2.2, shop = 'Liquor' },
    { label = 'Rob\'s Liquor', coords = vec3(1165.28, 2709.4, 38.15), radius = 2.2, shop = 'Liquor' },
    { label = 'Ammunation', coords = vec3(22.0, -1107.2, 29.8), radius = 2.4, shop = 'Ammunation' },
    { label = 'Ammunation', coords = vec3(810.25, -2157.60, 29.62), radius = 2.4, shop = 'Ammunation' },
    { label = 'Ammunation', coords = vec3(1693.44, 3759.5, 34.71), radius = 2.4, shop = 'Ammunation' },
    { label = 'Clothing Store', coords = vec3(72.3, -1399.1, 29.4), radius = 2.5, appearance = true },
    { label = 'Clothing Store', coords = vec3(-703.8, -152.3, 37.4), radius = 2.5, appearance = true },
    { label = 'Clothing Store', coords = vec3(-167.9, -299.0, 39.7), radius = 2.5, appearance = true },
    { label = 'Clothing Store', coords = vec3(428.7, -800.1, 29.5), radius = 2.5, appearance = true },
    { label = 'Clothing Store', coords = vec3(-829.4, -1073.7, 11.5), radius = 2.5, appearance = true },
    { label = 'Bank', coords = vec3(149.46, -1040.52, 29.37), radius = 2.2, bank = true },
    { label = 'Bank', coords = vec3(314.23, -278.83, 54.17), radius = 2.2, bank = true },
    { label = 'Bank', coords = vec3(-350.8, -49.57, 49.04), radius = 2.2, bank = true },
}
