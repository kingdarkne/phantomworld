--[[
  INACTIVE: This resource is stopped in server.cfg. Shops were moved into ox_inventory/data/shops.lua
  (LTDGasoline, PrisonCommissary, LeisureShop, MechanicSupply, extra BlackMarketArms locations).
  Re-enable lusty94_shops only if you need menus/items that are not defined in ox_inventory items.lua.
]]
Config = {}


--
--██╗░░░░░██╗░░░██╗░██████╗████████╗██╗░░░██╗░█████╗░░░██╗██╗
--██║░░░░░██║░░░██║██╔════╝╚══██╔══╝╚██╗░██╔╝██╔══██╗░██╔╝██║
--██║░░░░░██║░░░██║╚█████╗░░░░██║░░░░╚████╔╝░╚██████║██╔╝░██║
--██║░░░░░██║░░░██║░╚═══██╗░░░██║░░░░░╚██╔╝░░░╚═══██║███████║
--███████╗╚██████╔╝██████╔╝░░░██║░░░░░░██║░░░░█████╔╝╚════██║
--╚══════╝░╚═════╝░╚═════╝░░░░╚═╝░░░░░░╚═╝░░░░╚════╝░░░░░░╚═╝


-- Thank you for downloading this script!

-- Below you can change multiple options to suit your server needs.


Config.CoreSettings = {
    Debug = {
        Prints = true, -- sends debug prints to f8 console and txadmin server console
    },
    Target = {
        -- 'textui' = Press E near the ped (ox_lib text UI). No third-eye / ox_target.
        -- 'ox' = ox_target | 'qb' = qb-target | 'custom' = edit cl_funcs.lua
        Type = 'textui',
    },
    Notify = {
        Type = 'ox', -- notification type, support for qb-core notify, okokNotify, mythic_notify and ox_lib notify
        -- EDIT CLIENT/cl_funcs.lua & SERVER/sv_funcs.lua TO ADD YOUR OWN NOTIFY SUPPORT
        --use 'qb' for default qb-core notify
        --use 'okok' for okokNotify
        --use 'mythic' for mythic_notify
        --use 'ox' for ox_lib notify
        --use 'custom' for your own custom notifications system
    },
    Inventory = { -- support for qb-inventory and ox_inventory
    -- EDIT SERVER/sv_funcs.lua TO ADD YOUR OWN INVENTORY SUPPORT
        Type = 'ox',
        --use 'qb' for qb-inventory
        --use 'ox' for ox_inventory
        --use 'custom' for your own custom inventory system
    },
    Security = {
        MaxDistance = 4.0, -- max permitted distance for security checks - do not set this too high and also bare in mind the target distance too
        DropPlayer = true, -- kicks the player from the server if the fail any of the security checks
        BanPlayer = false, -- bans the player from the server if the fail any of the security checks
    },
}



-- Shops that duplicate ox_inventory (`data/shops.lua`: General, Liquor, Ammunation, YouTool, PoliceArmoury, Medicine)
-- have empty `locations` so you do not get two prompts/peds at the same spot. Use ox_inventory + Press E there.
Config.Shops = {
    ['Supermarket'] = { -- the key is the shop name
        info = {
            shopLabel = 'Supermarket', -- label used as the shop header when opening the inventory shop
            targetIcon = 'fa-solid fa-hand-point-up', -- icon used for target interaction
            targetLabel = 'Open Shop', -- label used for target interaction
            distance = 2.0, -- max distance for target interaction
            scenario = 'WORLD_HUMAN_CLIPBOARD', -- define a scenario used for the ped
            args = { shopType = "Supermarket" }, -- args sends the shopType data to the event to determine which inventory shop to open and displays the relevant products available - this must be the same as the key name
        },
        blips = { enabled = false, id = 52, colour = 2, scale = 0.6, title = 'Supermarket' },
        models = { 'mp_m_shopkeep_01' },
        locations = {},
        inventory = { 
            -- define items and their prices below that can be purchased at this particular vendor - ensure these are in your items.lua!
            { name = 'tosti',         price = 2,   amount = 50 },
            { name = 'water_bottle',  price = 2,   amount = 50 },
            { name = 'kurkakola',     price = 2,   amount = 50 },
            { name = 'twerks_candy',  price = 2,   amount = 50 },
            { name = 'snikkel_candy', price = 2,   amount = 50 },
            { name = 'sandwich',      price = 2,   amount = 50 },
            { name = 'lighter',       price = 2,   amount = 50 },
        },
    },
    ['Liqour Store'] = { -- the key is the shop name
        info = {
            shopLabel = 'Liqour Store', -- label used as the shop header when opening the inventory shop
            targetIcon = 'fa-solid fa-hand-point-up', -- icon used for target interaction
            targetLabel = 'Open Shop', -- label used for target interaction
            distance = 2.0, -- max distance for target interaction
            scenario = 'WORLD_HUMAN_CLIPBOARD', -- define a scenario used for the ped
            args = { shopType = "Liqour Store" }, -- args sends the shopType data to the event to determine which inventory shop to open and displays the relevant products available - this must be the same as the key name
        },
        blips = { enabled = false, id = 52, colour = 2, scale = 0.6, title = 'Liqour Store' },
        models = { 'mp_m_shopkeep_01' },
        locations = {},
        inventory = { 
            -- define items and their prices below that can be purchased at this particular vendor - ensure these are in your items.lua!
            { name = 'beer',          price = 5,   amount = 50 },
            { name = 'whiskey',       price = 10,  amount = 50 },
            { name = 'vodka',         price = 20,  amount = 50 },
        },
    },
    ['LTD Gasoline'] = { -- the key is the shop name
        info = {
            shopLabel = 'LTD Gasoline', -- label used as the shop header when opening the inventory shop
            targetIcon = 'fa-solid fa-hand-point-up', -- icon used for target interaction
            targetLabel = 'Open Shop', -- label used for target interaction
            distance = 2.0, -- max distance for target interaction
            scenario = 'WORLD_HUMAN_CLIPBOARD', -- define a scenario used for the ped
            args = { shopType = "LTD Gasoline" }, -- args sends the shopType data to the event to determine which inventory shop to open and displays the relevant products available - this must be the same as the key name
        },
        blips = { -- blip settings for shop
            enabled = true, -- blip enabled
            id = 52, -- blip id
            colour = 2, -- blip colour
            scale = 0.6, -- bliip scale
            title = 'LTD Gasoline', -- blip title
        },
        models = { -- define random ped models below
            'mp_m_shopkeep_01',
        },
        locations = { -- define spawn locations for the vendor must be vector4
            vector4(-47.02, -1758.23, 29.42, 45.05),
            vector4(-706.06, -913.97, 19.22, 88.04),
            vector4(-1820.02, 794.03, 138.09, 135.45),
            vector4(1164.71, -322.94, 69.21, 101.72),
            vector4(1697.87, 4922.96, 42.06, 324.71),
        },
        inventory = { 
            -- define items and their prices below that can be purchased at this particular vendor - ensure these are in your items.lua!
            { name = 'beer',          price = 5,   amount = 50 },
            { name = 'whiskey',       price = 10,  amount = 50 },
            { name = 'vodka',         price = 20,  amount = 50 },
            { name = 'tosti',         price = 2,   amount = 50 },
            { name = 'water_bottle',  price = 2,   amount = 50 },
            { name = 'kurkakola',     price = 2,   amount = 50 },
            { name = 'twerks_candy',  price = 2,   amount = 50 },
            { name = 'snikkel_candy', price = 2,   amount = 50 },
            { name = 'sandwich',      price = 2,   amount = 50 },
            { name = 'lighter',       price = 2,   amount = 50 },
        },
    },
    ['Hardware Store'] = { -- the key is the shop name
        info = {
            shopLabel = 'Hardware Store', -- label used as the shop header when opening the inventory shop
            targetIcon = 'fa-solid fa-hand-point-up', -- icon used for target interaction
            targetLabel = 'Open Shop', -- label used for target interaction
            distance = 2.0, -- max distance for target interaction
            scenario = 'WORLD_HUMAN_CLIPBOARD', -- define a scenario used for the ped
            args = { shopType = "Hardware Store" }, -- args sends the shopType data to the event to determine which inventory shop to open and displays the relevant products available - this must be the same as the key name
        },
        blips = { enabled = false, id = 52, colour = 2, scale = 0.6, title = 'Hardware Store' },
        models = { 'mp_m_waremech_01' },
        locations = {},
        inventory = {
            -- define items and their prices below that can be purchased at this particular vendor - ensure these are in your items.lua!
            --as GUNS are unique items it is wise to only stock 1 of that particular item this prevents issues with stacking serial numbers if purchasing multiple of that item. This logic does not apply to knives or ammunition
            { name = 'lockpick',          price = 200, amount = 50 },
            { name = 'repairkit',         price = 250, amount = 50, requiresJob = { 'mechanic', 'police' }, },
            { name = 'screwdriverset',    price = 350, amount = 50 },
            { name = 'phone',             price = 850, amount = 50 },
            { name = 'radio',             price = 250, amount = 50 },
            { name = 'cleaningkit',       price = 150, amount = 150 },
            { name = 'advancedrepairkit', price = 500, amount = 50, requiresJob = 'mechanic' },
        },
    },
    ['Smoke On The Water'] = { -- the key is the shop name
        info = {
            shopLabel = 'Smoke On The Water', -- label used as the shop header when opening the inventory shop
            targetIcon = 'fa-solid fa-hand-point-up', -- icon used for target interaction
            targetLabel = 'Open Shop', -- label used for target interaction
            distance = 2.0, -- max distance for target interaction
            scenario = 'WORLD_HUMAN_SMOKING_POT', -- define a scenario used for the ped
            args = { shopType = "Smoke On The Water" }, -- args sends the shopType data to the event to determine which inventory shop to open and displays the relevant products available - this must be the same as the key name
        },
        blips = { -- blip settings for shop
            enabled = true, -- blip enabled
            id = 52, -- blip id
            colour = 2, -- blip colour
            scale = 0.6, -- bliip scale
            title = 'Smoke On The Water', -- blip title
        },
        models = { -- define random ped models below
            'a_m_y_hippy_01',
        },
        locations = { -- define spawn locations for the vendor must be vector4
            vector4(-1168.26, -1573.2, 4.66, 105.24),
        },
        inventory = {
            -- define items and their prices below that can be purchased at this particular vendor - ensure these are in your items.lua!
            { name = 'joint',          price = 10,  amount = 50 },
            { name = 'weed_nutrition', price = 20,  amount = 50 },
            { name = 'lighter',        price = 2,   amount = 50 },
            { name = 'empty_weed_bag', price = 2,   amount = 50 },
            { name = 'rolling_paper',  price = 2,   amount = 50 },
        },
    },
    ['Ammunation'] = { -- the key is the shop name
        info = {
            shopLabel = 'Ammunation', -- label used as the shop header when opening the inventory shop
            targetIcon = 'fa-solid fa-hand-point-up', -- icon used for target interaction
            targetLabel = 'Open Shop', -- label used for target interaction
            distance = 2.0, -- max distance for target interaction
            scenario = 'WORLD_HUMAN_CLIPBOARD', -- define a scenario used for the ped
            args = { shopType = "Ammunation" }, -- args sends the shopType data to the event to determine which inventory shop to open and displays the relevant products available - this must be the same as the key name
        },
        blips = { enabled = false, id = 52, colour = 2, scale = 0.6, title = 'Ammunation' },
        models = { 's_m_y_ammucity_01' },
        locations = {},
        inventory = {
            -- define items and their prices below that can be purchased at this particular vendor - ensure these are in your items.lua!
            --as GUNS are unique items it is wise to only stock 1 of that particular item this prevents issues with stacking serial numbers if purchasing multiple of that item. This logic does not apply to knives or ammunition
            
            -- ========== MELEE WEAPONS ==========
            { name = 'weapon_knife',         price = 250,  amount = 250 },
            { name = 'weapon_bat',           price = 250,  amount = 250 },
            { name = 'weapon_hatchet',       price = 250,  amount = 250 },
            { name = 'weapon_crowbar',       price = 250,  amount = 250 },
            { name = 'weapon_wrench',        price = 250,  amount = 250 },
            { name = 'weapon_hammer',        price = 250,  amount = 250 },
            { name = 'weapon_golfclub',      price = 250,  amount = 250 },
            { name = 'weapon_nightstick',    price = 250,  amount = 250 },
            { name = 'weapon_bottle',        price = 250,  amount = 250 },
            { name = 'weapon_dagger',        price = 300,  amount = 250 },
            { name = 'weapon_machete',       price = 350,  amount = 250 },
            { name = 'weapon_switchblade',   price = 400,  amount = 250 },
            { name = 'weapon_battleaxe',     price = 500,  amount = 250 },
            { name = 'weapon_poolcue',       price = 250,  amount = 250 },
            { name = 'weapon_knuckle',       price = 300,  amount = 250 },
            
            -- ========== PISTOLS ==========
            { name = 'weapon_pistol',        price = 2500, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_combatpistol',  price = 3500, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_appistol',      price = 4000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_snspistol',     price = 1500, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_heavypistol',   price = 4500, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_vintagepistol', price = 4000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_pistol50',      price = 6000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_machinepistol', price = 5500, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_revolver',      price = 5000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_revolver_mk2',  price = 6500, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_marksmanpistol', price = 5500, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_doubleaction',  price = 4500, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_pistol_mk2',    price = 5500, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_snspistol_mk2', price = 3500, amount = 1, requiresLicense = 'weapon' },
            
            -- ========== SUBMACHINE GUNS ==========
            { name = 'weapon_microsmg',      price = 8000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_smg',           price = 10000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_smg_mk2',       price = 12000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_assaultsmg',    price = 11000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_minismg',       price = 9000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_combatpdw',     price = 8500, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_machinepistol', price = 5500, amount = 1, requiresLicense = 'weapon' },
            
            -- ========== SHOTGUNS ==========
            { name = 'weapon_pumpshotgun',   price = 15000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_pumpshotgun_mk2', price = 18000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_sawnoffshotgun', price = 12000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_assaultshotgun', price = 20000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_bullpupshotgun', price = 16000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_musket',        price = 14000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_heavyshotgun',  price = 22000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_dbshotgun',     price = 13000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_autoshotgun',   price = 25000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_sweepershotgun', price = 17000, amount = 1, requiresLicense = 'weapon' },
            
            -- ========== ASSAULT RIFLES ==========
            { name = 'weapon_assaultrifle',  price = 25000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_assaultrifle_mk2', price = 30000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_carbinerifle',  price = 22000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_carbinerifle_mk2', price = 27000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_advancedrifle',  price = 24000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_specialcarbine', price = 26000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_specialcarbine_mk2', price = 31000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_bullpuprifle',  price = 23000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_bullpuprifle_mk2', price = 28000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_compactrifle',  price = 20000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_heavyrifle',    price = 29000, amount = 1, requiresLicense = 'weapon' },
            
            -- ========== LIGHT MACHINE GUNS ==========
            { name = 'weapon_mg',            price = 35000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_combatmg',      price = 40000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_combatmg_mk2',  price = 45000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_gusenberg',     price = 32000, amount = 1, requiresLicense = 'weapon' },
            
            -- ========== SNIPER RIFLES ==========
            { name = 'weapon_sniperrifle',   price = 50000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_heavysniper',   price = 60000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_heavysniper_mk2', price = 70000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_marksmanrifle',  price = 45000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_marksmanrifle_mk2', price = 55000, amount = 1, requiresLicense = 'weapon' },
            
            -- ========== HEAVY WEAPONS ==========
            { name = 'weapon_rpg',           price = 100000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_grenadelauncher', price = 80000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_hominglauncher', price = 120000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_minigun',       price = 200000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_firework',       price = 15000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_railgun',       price = 150000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_compactlauncher', price = 90000, amount = 1, requiresLicense = 'weapon' },
            
            -- ========== THROWABLE WEAPONS ==========
            { name = 'weapon_grenade',       price = 5000, amount = 10, requiresLicense = 'weapon' },
            { name = 'weapon_stickybomb',    price = 6000, amount = 10, requiresLicense = 'weapon' },
            { name = 'weapon_proxmine',      price = 7000, amount = 10, requiresLicense = 'weapon' },
            { name = 'weapon_pipebomb',      price = 8000, amount = 10, requiresLicense = 'weapon' },
            { name = 'weapon_smokegrenade',  price = 3000, amount = 10, requiresLicense = 'weapon' },
            { name = 'weapon_molotov',       price = 4000, amount = 10, requiresLicense = 'weapon' },
            { name = 'weapon_flare',         price = 2000, amount = 10, requiresLicense = 'weapon' },
            { name = 'weapon_ball',          price = 1000, amount = 10, requiresLicense = 'weapon' },
            
            -- ========== AMMUNITION ==========
            { name = 'pistol_ammo',          price = 25,   amount = 9999 }, -- Pistol ammo
            { name = 'smg_ammo',             price = 35,   amount = 9999 }, -- SMG ammo
            { name = 'rifle_ammo',           price = 45,   amount = 9999 }, -- Rifle ammo
            { name = 'mg_ammo',              price = 55,   amount = 9999 }, -- Machine gun ammo
            { name = 'shotgun_ammo',         price = 65,   amount = 9999 }, -- Shotgun ammo
            { name = 'sniper_ammo',          price = 75,   amount = 9999 }, -- Sniper ammo
            { name = 'emp_ammo',             price = 1000, amount = 999 }, -- EMP launcher ammo
            { name = 'firework_ammo',        price = 500,  amount = 999 }, -- Firework launcher ammo
            { name = 'grenade_ammo',         price = 800,  amount = 999 }, -- Grenade launcher ammo
            { name = 'rpg_ammo',             price = 1500, amount = 999 }, -- RPG ammo
            { name = 'stickybomb_ammo',      price = 1200, amount = 999 }, -- Sticky bomb ammo
            { name = 'smokegrenade_ammo',    price = 400,  amount = 999 }, -- Smoke grenade ammo
            { name = 'molotov_ammo',         price = 600,  amount = 999 }, -- Molotov ammo
            { name = 'proxmine_ammo',        price = 1000, amount = 999 }, -- Proximity mine ammo
            { name = 'pipebomb_ammo',        price = 800,  amount = 999 }, -- Pipe bomb ammo
            { name = 'minigun_ammo',         price = 200,  amount = 9999 }, -- Minigun ammo
            { name = 'railgun_ammo',         price = 3000, amount = 999 }, -- Railgun ammo
            
            -- ========== WEAPON COMPONENTS ==========
            { name = 'pistol_suppressor',    price = 5000, amount = 100 },
            { name = 'smg_suppressor',       price = 7000, amount = 100 },
            { name = 'rifle_suppressor',     price = 10000, amount = 100 },
            { name = 'sniper_suppressor',    price = 15000, amount = 100 },
            { name = 'pistol_flashlight',    price = 3000, amount = 100 },
            { name = 'smg_flashlight',       price = 4000, amount = 100 },
            { name = 'rifle_flashlight',     price = 5000, amount = 100 },
            { name = 'sniper_flashlight',    price = 6000, amount = 100 },
            { name = 'pistol_scope',         price = 4000, amount = 100 },
            { name = 'smg_scope',            price = 5000, amount = 100 },
            { name = 'rifle_scope',          price = 8000, amount = 100 },
            { name = 'sniper_scope',         price = 12000, amount = 100 },
            { name = 'pistol_grip',          price = 2000, amount = 100 },
            { name = 'smg_grip',             price = 3000, amount = 100 },
            { name = 'rifle_grip',           price = 4000, amount = 100 },
            { name = 'sniper_grip',          price = 5000, amount = 100 },
            
            -- ========== CUSTOM WEAPONS BY LESIIN ==========
            { name = 'weapon_ak47',          price = 32000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_ar15',          price = 35000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_deserteagle',   price = 8000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_fnfnx45',       price = 6000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_glock17',       price = 5500, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_huntingrifle',  price = 45000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_m1911',         price = 5000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_m4',            price = 38000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_m70',           price = 28000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_m9a3',          price = 6500, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_mac10',         price = 12000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_mk14',          price = 55000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_mossberg500',   price = 18000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_remington870',  price = 16000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_scarh',         price = 42000, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_shiv',          price = 1500, amount = 1, requiresLicense = 'weapon' },
            { name = 'weapon_uzi',           price = 14000, amount = 1, requiresLicense = 'weapon' },
        },
    },
    ['Black Market'] = { -- the key is the shop name
        info = {
            shopLabel = 'Black Market', -- label used as the shop header when opening the inventory shop
            targetIcon = 'fa-solid fa-hand-point-up', -- icon used for target interaction
            targetLabel = 'Open Shop', -- label used for target interaction
            distance = 2.0, -- max distance for target interaction
            scenario = 'WORLD_HUMAN_CLIPBOARD', -- define a scenario used for the ped
            args = { shopType = "Black Market" }, -- args sends the shopType data to the event to determine which inventory shop to open and displays the relevant products available - this must be the same as the key name
        },
        blips = { -- blip settings for shop
            enabled = true, -- blip enabled
            id = 52, -- blip id
            colour = 2, -- blip colour
            scale = 0.6, -- bliip scale
            title = 'Black Market', -- blip title
        },
        models = { -- define random ped models below
            'g_m_y_lost_02',
            'g_m_y_ballasout_01',
            'g_m_y_famdnf_01',
            'g_m_m_chigoon_01',
            'g_f_y_lost_01',
            'g_f_importexport_01',
            'g_f_y_vagos_01',
        },
        locations = { -- define spawn locations for the vendor must be vector4
            vector4(1364.38, 6549.21, 14.61, 344.92),
            vector4(2872.72, 4458.63, 48.51, 290.45),
            vector4(2461.2, 1576.13, 33.11, 276.14),
            vector4(972.59, -94.51, 74.84, 50.55),
            vector4(-546.73, -1605.85, 18.87, 279.88),
            vector4(-1998.81, 540.9, 109.55, 218.27),
        },
        inventory = {
            -- define items and their prices below that can be purchased at this particular vendor - ensure these are in your items.lua!
            { name = 'security_card_01',  price = 5000, amount = 50 },
            { name = 'security_card_02',  price = 5000, amount = 50 },
            { name = 'advancedlockpick',  price = 5000, amount = 50 },
            { name = 'electronickit',     price = 5000, amount = 50 },
            { name = 'gatecrack',         price = 5000, amount = 50 },
            { name = 'thermite',          price = 5000, amount = 50 },
            { name = 'trojan_usb',        price = 5000, amount = 50 },
            { name = 'drill',             price = 5000, amount = 50 },
            { name = 'radioscanner',      price = 5000, amount = 50 },
            { name = 'cryptostick',       price = 5000, amount = 50 },
            { name = 'joint',             price = 5000, amount = 50 },
            { name = 'cokebaggy',         price = 5000, amount = 50 },
            { name = 'crack_baggy',       price = 5000, amount = 50 },
            { name = 'xtcbaggy',          price = 5000, amount = 50 },
            { name = 'coke_brick',        price = 5000, amount = 50 },
            { name = 'weed_brick',        price = 5000, amount = 50 },
            { name = 'coke_small_brick',  price = 5000, amount = 50 },
            { name = 'oxy',               price = 5000, amount = 50 },
            { name = 'meth',              price = 5000, amount = 50 },
            { name = 'weed_whitewidow',   price = 5000, amount = 50 },
            { name = 'weed_skunk',        price = 5000, amount = 50 },
            { name = 'weed_purplehaze',   price = 5000, amount = 50 },
            { name = 'weed_ogkush',       price = 5000, amount = 50 },
            { name = 'weed_amnesia',      price = 5000, amount = 50 },
            { name = 'weed_ak47',         price = 5000, amount = 50 },
        },
    },
    ['Prison Canteen'] = { -- the key is the shop name
        info = {
            shopLabel = 'Prison Canteen', -- label used as the shop header when opening the inventory shop
            targetIcon = 'fa-solid fa-hand-point-up', -- icon used for target interaction
            targetLabel = 'Open Shop', -- label used for target interaction
            distance = 2.0, -- max distance for target interaction
            scenario = 'WORLD_HUMAN_CLIPBOARD', -- define a scenario used for the ped
            args = { shopType = "Prison Canteen" }, -- args sends the shopType data to the event to determine which inventory shop to open and displays the relevant products available - this must be the same as the key name
        },
        blips = { -- blip settings for shop
            enabled = true, -- blip enabled
            id = 52, -- blip id
            colour = 2, -- blip colour
            scale = 0.6, -- bliip scale
            title = 'Prison Canteen', -- blip title
        },
        models = { -- define random ped models below
            'mp_m_securoguard_01',
        },
        locations = { -- define spawn locations for the vendor must be vector4
            vector4(1777.59, 2560.52, 45.62, 187.83),
        },
        inventory = {
            -- define items and their prices below that can be purchased at this particular vendor - ensure these are in your items.lua!
            { name = 'sandwich',     price = 4, amount = 50 },
            { name = 'water_bottle', price = 4, amount = 50 },
        },
    },
    ['Leisure Shop'] = { -- the key is the shop name
        info = {
            shopLabel = 'Leisure Shop', -- label used as the shop header when opening the inventory shop
            targetIcon = 'fa-solid fa-hand-point-up', -- icon used for target interaction
            targetLabel = 'Open Shop', -- label used for target interaction
            distance = 2.0, -- max distance for target interaction
            scenario = 'WORLD_HUMAN_CLIPBOARD', -- define a scenario used for the ped
            args = { shopType = "Leisure Shop" }, -- args sends the shopType data to the event to determine which inventory shop to open and displays the relevant products available - this must be the same as the key name
        },
        blips = { -- blip settings for shop
            enabled = true, -- blip enabled
            id = 52, -- blip id
            colour = 2, -- blip colour
            scale = 0.6, -- bliip scale
            title = 'Leisure Shop', -- blip title
        },
        models = { -- define random ped models below
            'a_m_y_beach_01',
        },
        locations = { -- define spawn locations for the vendor must be vector4
            vector4(-1505.91, 1511.95, 115.29, 257.13),
        },
        inventory = {
            -- define items and their prices below that can be purchased at this particular vendor - ensure these are in your items.lua!
            { name = 'parachute',   price = 2500, amount = 10 },
            { name = 'binoculars',  price = 50,   amount = 50 },
            { name = 'diving_gear', price = 2500, amount = 10 },
            { name = 'diving_fill', price = 500,  amount = 10 },
        },
    },
    ['Police Armoury'] = { -- the key is the shop name
        info = {
            shopLabel = 'Police Armoury', -- label used as the shop header when opening the inventory shop
            targetIcon = 'fa-solid fa-hand-point-up', -- icon used for target interaction
            targetLabel = 'Open Shop', -- label used for target interaction
            distance = 2.0, -- max distance for target interaction
            scenario = 'WORLD_HUMAN_CLIPBOARD', -- define a scenario used for the ped
            args = { shopType = "Police Armoury" }, -- args sends the shopType data to the event to determine which inventory shop to open and displays the relevant products available - this must be the same as the key name
        },
        blips = { enabled = false, id = 52, colour = 2, scale = 0.6, title = 'Police Armoury' },
        models = { 'mp_m_securoguard_01' },
        locations = {},
        inventory = {
            -- define items and their prices below that can be purchased at this particular vendor - ensure these are in your items.lua!
            { name = 'weapon_nightstick',   price = 0, amount = 1,  requiresJob = {'police', 'bsco', 'leo',}, },
            { name = 'weapon_flashlight',   price = 0, amount = 1,  requiresJob = {'police', 'bsco', 'leo',}, },
            { name = 'handcuffs',           price = 0, amount = 50, requiresJob = {'police', 'bsco', 'leo',}, },
            { name = 'empty_evidence_bag',  price = 0, amount = 50, requiresJob = {'police', 'bsco', 'leo',}, },
            { name = 'police_stormram',     price = 0, amount = 50, requiresJob = {'police', 'bsco', 'leo',}, },
            { name = 'radio',               price = 0, amount = 50, requiresJob = {'police', 'bsco', 'leo',}, },
            { name = 'heavyarmor',          price = 0, amount = 50, requiresJob = {'police', 'bsco', 'leo',}, },
            { name = 'weapon_stungun',      price = 0, amount = 1,  requiresJob = {'police', 'bsco', 'leo',}, },
            { name = 'pistol_ammo',         price = 0, amount = 50, requiresLicense = 'weapon', requiresJob = {'police', 'bsco', 'leo',}, requiresRank = 1, },
            { name = 'smg_ammo',            price = 0, amount = 50, requiresLicense = 'weapon', requiresJob = {'police', 'bsco', 'leo',}, requiresRank = 2, },
            { name = 'shotgun_ammo',        price = 0, amount = 50, requiresLicense = 'weapon', requiresJob = {'police', 'bsco', 'leo',}, requiresRank = 3, },
            { name = 'rifle_ammo',          price = 0, amount = 50, requiresLicense = 'weapon', requiresJob = {'police', 'bsco', 'leo',}, requiresRank = 3, },
            { name = 'weapon_pistol',       price = 0, amount = 1,  requiresLicense = 'weapon', requiresJob = {'police', 'bsco', 'leo',}, requiresRank = 1, },
            { name = 'weapon_smg',          price = 0, amount = 1,  requiresLicense = 'weapon', requiresJob = {'police', 'bsco', 'leo',}, requiresRank = 2,},
            { name = 'weapon_pumpshotgun',  price = 0, amount = 1,  requiresLicense = 'weapon', requiresJob = {'police', 'bsco', 'leo',}, requiresRank = 3,},
            { name = 'weapon_carbinerifle', price = 0, amount = 1,  requiresLicense = 'weapon', requiresJob = {'police', 'bsco', 'leo',}, requiresRank = 3,},
        },
    },
    ['EMS Supplies'] = { -- the key is the shop name
        info = {
            shopLabel = 'EMS Supplies', -- label used as the shop header when opening the inventory shop
            targetIcon = 'fa-solid fa-hand-point-up', -- icon used for target interaction
            targetLabel = 'Open Shop', -- label used for target interaction
            distance = 2.0, -- max distance for target interaction
            scenario = 'WORLD_HUMAN_CLIPBOARD', -- define a scenario used for the ped
            args = { shopType = "EMS Supplies" }, -- args sends the shopType data to the event to determine which inventory shop to open and displays the relevant products available - this must be the same as the key name
        },
        blips = { enabled = false, id = 52, colour = 2, scale = 0.6, title = 'EMS Supplies' },
        models = { 's_m_m_doctor_01' },
        locations = {},
        inventory = {
            -- define items and their prices below that can be purchased at this particular vendor - ensure these are in your items.lua!
            { name = 'radio',           price = 0, amount = 50, requiresJob = {'ambulance','ems', }, },
            { name = 'bandage',         price = 0, amount = 50, requiresJob = {'ambulance','ems', }, },
            { name = 'painkillers',     price = 0, amount = 50, requiresJob = {'ambulance','ems', }, },
            { name = 'firstaid',        price = 0, amount = 50, requiresJob = {'ambulance','ems', }, },
        },
    },
    ['Mechanic Supplies'] = { -- the key is the shop name
        info = {
            shopLabel = 'Mechanic Supplies', -- label used as the shop header when opening the inventory shop
            targetIcon = 'fa-solid fa-hand-point-up', -- icon used for target interaction
            targetLabel = 'Open Shop', -- label used for target interaction
            distance = 2.0, -- max distance for target interaction
            scenario = 'WORLD_HUMAN_CLIPBOARD', -- define a scenario used for the ped
            args = { shopType = "Mechanic Supplies" }, -- args sends the shopType data to the event to determine which inventory shop to open and displays the relevant products available - this must be the same as the key name
        },
        blips = { -- blip settings for shop
            enabled = true, -- blip enabled
            id = 52, -- blip id
            colour = 2, -- blip colour
            scale = 0.6, -- bliip scale
            title = 'Mechanic Supplies', -- blip title
        },
        models = { -- define random ped models below
            'mp_m_waremech_01',
        },
        locations = { -- define spawn locations for the vendor must be vector4
            vector4(-227.74, -1327.81, 30.89, 274.6),
        },
        inventory = {
            -- define items and their prices below that can be purchased at this particular vendor - ensure these are in your items.lua!
            { name = 'veh_toolbox',       price = 0, amount = 50, requiresJob = {'mechanic', }, },
            { name = 'veh_armor',         price = 0, amount = 50, requiresJob = {'mechanic', }, },
            { name = 'veh_brakes',        price = 0, amount = 50, requiresJob = {'mechanic', }, },
            { name = 'veh_engine',        price = 0, amount = 50, requiresJob = {'mechanic', }, },
            { name = 'veh_suspension',    price = 0, amount = 50, requiresJob = {'mechanic', }, },
            { name = 'veh_transmission',  price = 0, amount = 50, requiresJob = {'mechanic', }, },
            { name = 'veh_turbo',         price = 0, amount = 50, requiresJob = {'mechanic', }, },
            { name = 'veh_interior',      price = 0, amount = 50, requiresJob = {'mechanic', }, },
            { name = 'veh_exterior',      price = 0, amount = 50, requiresJob = {'mechanic', }, },
            { name = 'veh_wheels',        price = 0, amount = 50, requiresJob = {'mechanic', }, },
            { name = 'veh_neons',         price = 0, amount = 50, requiresJob = {'mechanic', }, },
            { name = 'veh_xenons',        price = 0, amount = 50, requiresJob = {'mechanic', }, },
            { name = 'veh_tint',          price = 0, amount = 50, requiresJob = {'mechanic', }, },
            { name = 'veh_plates',        price = 0, amount = 50, requiresJob = {'mechanic', }, },
            { name = 'nitrous',           price = 0, amount = 50, requiresJob = {'mechanic', }, },
            { name = 'tunerlaptop',       price = 0, amount = 50, requiresJob = {'mechanic', }, },
            { name = 'repairkit',         price = 0, amount = 50, requiresJob = {'mechanic', }, },
            { name = 'advancedrepairkit', price = 0, amount = 50, requiresJob = {'mechanic', }, },
            { name = 'tirerepairkit',     price = 0, amount = 50, requiresJob = {'mechanic', }, },
        },
    },
}

--translation settings
Config.Language = {
    Notifications = {
        Busy = 'You are already doing something!',
        Cancelled = 'Transaction cancelled!',
        CantCarry = 'You dont have enough space for that!',
        NoCash = 'You dont have enough cash on you!',
        NoBank = 'You dont have enough money in the bank!',
        Failed = 'Transaction failed!',
        Success = 'Purchase Successful!',
    },
}