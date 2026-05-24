Config = {}

Config.Framework = GetResourceState('qbx_core') ~= 'missing' and 'qbx' or 'qb'
Config.Debug = false

-- Weapon Wheel Settings (GTA Online style)
Config.WeaponWheel = {
    -- Disabled: server uses `ox_inventory` weapon wheel integration instead.
    enabled = false,
    holdKey = 37, -- Tab key
    quickSwitchKeys = { 157, 158, 160, 164, 165, 159 }, -- 1-6 keys
    categories = {
        { name = 'Melee', slot = 1, icon = '🔪', weapons = {'weapon_knife', 'weapon_bat', 'weapon_crowbar', 'weapon_golfclub', 'weapon_hammer', 'weapon_hatchet'} },
        { name = 'Handguns', slot = 2, icon = '🔫', weapons = {'weapon_pistol', 'weapon_pistol_mk2', 'weapon_combatpistol', 'weapon_appistol', 'weapon_pistol50'} },
        { name = 'Submachine Guns', slot = 3, icon = '🔫', weapons = {'weapon_microsmg', 'weapon_smg', 'weapon_smg_mk2', 'weapon_assaultsmg'} },
        { name = 'Assault Rifles', slot = 4, icon = '🔫', weapons = {'weapon_assaultrifle', 'weapon_assaultrifle_mk2', 'weapon_carbinerifle', 'weapon_carbinerifle_mk2', 'weapon_advancedrifle', 'weapon_specialcarbine'} },
        { name = 'Shotguns', slot = 5, icon = '🔫', weapons = {'weapon_pumpshotgun', 'weapon_pumpshotgun_mk2', 'weapon_sawnoffshotgun', 'weapon_assaultshotgun', 'weapon_bullpupshotgun'} },
        { name = 'Heavy Weapons', slot = 6, icon = '💣', weapons = {'weapon_mg', 'weapon_combatmg', 'weapon_combatmg_mk2', 'weapon_gusenberg', 'weapon_minigun', 'weapon_rpg'} },
    },
    animationSpeed = 0.15,
    weaponPreviewScale = 1.5,
}

-- Ammu-Nation Store Locations
Config.AmmuNationLocations = {
    { coords = vec3(-3172.0, 1087.0, 20.8), name = 'Ammu-Nation Great Ocean Hwy' },
    { coords = vec3(2571.0, 294.0, 108.7), name = 'Ammu-Nation Palomino Fwy' },
    { coords = vec3(-1306.0, -394.0, 36.7), name = 'Ammu-Nation Morningwood' },
    { coords = vec3(-663.0, -939.0, 21.8), name = 'Ammu-Nation Little Seoul' },
    { coords = vec3(842.0, -1033.0, 28.2), name = 'Ammu-Nation La Mesa' },
    { coords = vec3(21.0, -1107.0, 29.8), name = 'Ammu-Nation Pillbox Hill' },
    { coords = vec3(810.0, -2157.0, 29.6), name = 'Ammu-Nation Popular St' },
    { coords = vec3(-1117.0, 2698.0, 18.6), name = 'Ammu-Nation Sandy Shores' },
    { coords = vec3(1693.0, 3760.0, 34.7), name = 'Ammu-Nation Grapeseed' },
    { coords = vec3(-330.0, 6083.0, 31.5), name = 'Ammu-Nation Paleto Bay' },
}

-- Weapon Locker Locations (for storing weapons)
Config.WeaponLockers = {
    { coords = vec3(-52.0, -251.0, 45.0), name = 'PD Armory' },
    { coords = vec3(312.0, -597.0, 43.3), name = 'Hospital Security' },
    { coords = vec3(-115.0, -607.0, 36.3), name = 'FIB Lockers' },
    { coords = vec3(1845.0, 3690.0, 34.3), name = 'Sandy PD' },
    { coords = vec3(-450.0, 6016.0, 31.7), name = 'Paleto PD' },
}

-- Weapon Prices (GTA Online style pricing)
Config.WeaponPrices = {
    -- Melee
    weapon_knife = 100,
    weapon_bat = 150,
    weapon_crowbar = 150,
    weapon_golfclub = 200,
    weapon_hammer = 100,
    weapon_hatchet = 200,
    weapon_knuckle = 150,
    weapon_machete = 250,
    weapon_wrench = 150,
    weapon_poolcue = 100,

    -- Handguns
    weapon_pistol = 800,
    weapon_pistol_mk2 = 1200,
    weapon_combatpistol = 1200,
    weapon_appistol = 2800,
    weapon_pistol50 = 3000,
    weapon_snspistol = 600,
    weapon_snspistol_mk2 = 900,
    weapon_heavypistol = 1800,
    weapon_vintagepistol = 1200,
    weapon_revolver = 1200,

    -- SMGs
    weapon_microsmg = 2400,
    weapon_smg = 3000,
    weapon_smg_mk2 = 4200,
    weapon_assaultsmg = 4200,
    weapon_combatpdw = 3600,
    weapon_machinepistol = 2800,
    weapon_minismg = 2400,

    -- Rifles
    weapon_assaultrifle = 4500,
    weapon_assaultrifle_mk2 = 6000,
    weapon_carbinerifle = 4500,
    weapon_carbinerifle_mk2 = 6000,
    weapon_advancedrifle = 5400,
    weapon_specialcarbine = 6000,
    weapon_specialcarbine_mk2 = 7800,
    weapon_bullpuprifle = 4800,
    weapon_bullpuprifle_mk2 = 6600,
    weapon_compactrifle = 4200,

    -- Shotguns
    weapon_pumpshotgun = 2000,
    weapon_pumpshotgun_mk2 = 2800,
    weapon_sawnoffshotgun = 1800,
    weapon_assaultshotgun = 6000,
    weapon_bullpupshotgun = 3600,
    weapon_musket = 2400,
    weapon_heavyshotgun = 4800,
    weapon_dbshotgun = 1800,
    weapon_autoshotgun = 5400,

    -- Heavy
    weapon_mg = 6600,
    weapon_combatmg = 7500,
    weapon_combatmg_mk2 = 9000,
    weapon_gusenberg = 4800,
    weapon_minigun = 50000,
    weapon_rpg = 7500,
    weapon_grenadelauncher = 9000,
    weapon_hominglauncher = 18000,
    weapon_compactlauncher = 7200,
    weapon_firework = 15000,
    weapon_railgun = 25000,

    -- Sniper
    weapon_sniperrifle = 9000,
    weapon_heavysniper = 12000,
    weapon_heavysniper_mk2 = 15000,
    weapon_marksmanrifle = 9000,
    weapon_marksmanrifle_mk2 = 12000,
}

-- Ammo Prices
Config.AmmoPrices = {
    pistol = 50, -- per 24 rounds
    smg = 80,
    rifle = 120,
    shotgun = 100,
    sniper = 150,
    heavy = 200,
}

-- Weapon Tints
Config.WeaponTints = {
    prices = {
        normal = 0,
        green = 500,
        gold = 2500,
        pink = 1000,
        army = 750,
        lspd = 750,
        orange = 500,
        platinum = 3000,
    },
    colors = {
        { id = 0, name = 'Classic Black', price = 0 },
        { id = 1, name = 'Green', price = 500 },
        { id = 2, name = 'Gold', price = 2500 },
        { id = 3, name = 'Hot Pink', price = 1000 },
        { id = 4, name = 'Army', price = 750 },
        { id = 5, name = 'LSPD', price = 750 },
        { id = 6, name = 'Orange', price = 500 },
        { id = 7, name = 'Platinum', price = 3000 },
    },
}

-- Attachments (simplified)
Config.Attachments = {
    prices = {
        clip_extended = 500,
        clip_tracer = 1000,
        clip_incendiary = 1500,
        clip_hollowpoint = 1200,
        clip_fmj = 2000,
        suppressor = 1500,
        scope = 2000,
        grip = 800,
        flashlight = 500,
        laser = 1500,
    },
}

-- License Requirements
Config.RequireLicense = true
Config.WeaponLicensePrice = 5000
Config.WeaponLicenseLocations = {
    vec3(240.0, -1380.0, 33.7), -- City Hall area
}
