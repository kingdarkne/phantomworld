Config = {}

-- Enable/disable the weapon wheel
Config.Enabled = true

-- Control to open the weapon wheel (default: NUMPAD0)
Config.OpenKey = 82 -- NUMPAD0 key

-- Weapon categories (GTA-Online style)
Config.Categories = {
    {
        name = 'Handguns',
        icon = 'pistol',
        color = '#FFD700',
        weapons = {
            'weapon_pistol',
            'weapon_pistol_mk2',
            'weapon_combatpistol',
            'weapon_appistol',
            'weapon_stungun',
            'weapon_pistol50',
            'weapon_snspistol',
            'weapon_snspistol_mk2',
            'weapon_heavypistol',
            'weapon_vintagepistol',
            'weapon_flaregun',
            'weapon_marksmanpistol',
            'weapon_revolver',
            'weapon_revolver_mk2',
            'weapon_doubleaction',
            'weapon_navyrevolver',
            'weapon_gadgetpistol',
        }
    },
    {
        name = 'Submachine Guns',
        icon = 'smg',
        color = '#FF6347',
        weapons = {
            'weapon_microsmg',
            'weapon_smg',
            'weapon_smg_mk2',
            'weapon_assaultsmg',
            'weapon_combatpdw',
            'weapon_machinepistol',
            'weapon_minismg',
            'weapon_raycarbine',
        }
    },
    {
        name = 'Shotguns',
        icon = 'shotgun',
        color = '#FF8C00',
        weapons = {
            'weapon_pumpshotgun',
            'weapon_pumpshotgun_mk2',
            'weapon_sawnoffshotgun',
            'weapon_assaultshotgun',
            'weapon_bullpupshotgun',
            'weapon_musket',
            'weapon_heavyshotgun',
            'weapon_dbshotgun',
            'weapon_autoshotgun',
            'weapon_combatshotgun',
        }
    },
    {
        name = 'Assault Rifles',
        icon = 'rifle',
        color = '#FF4500',
        weapons = {
            'weapon_assaultrifle',
            'weapon_assaultrifle_mk2',
            'weapon_carbinerifle',
            'weapon_carbinerifle_mk2',
            'weapon_advancedrifle',
            'weapon_specialcarbine',
            'weapon_specialcarbine_mk2',
            'weapon_bullpuprifle',
            'weapon_bullpuprifle_mk2',
            'weapon_compactrifle',
            'weapon_militaryrifle',
            'weapon_heavyrifle',
        }
    },
    {
        name = 'Light Machine Guns',
        icon = 'mg',
        color = '#DC143C',
        weapons = {
            'weapon_mg',
            'weapon_combatmg',
            'weapon_combatmg_mk2',
            'weapon_gusenberg',
        }
    },
    {
        name = 'Sniper Rifles',
        icon = 'sniper',
        color = '#8B0000',
        weapons = {
            'weapon_sniperrifle',
            'weapon_heavysniper',
            'weapon_heavysniper_mk2',
            'weapon_marksmanrifle',
            'weapon_marksmanrifle_mk2',
        }
    },
    {
        name = 'Heavy Weapons',
        icon = 'heavy',
        color = '#9400D3',
        weapons = {
            'weapon_rpg',
            'weapon_grenadelauncher',
            'weapon_minigun',
            'weapon_firework',
            'weapon_railgun',
            'weapon_hominglauncher',
            'weapon_compactlauncher',
            'weapon_rayminigun',
        }
    },
    {
        name = 'Thrown',
        icon = 'thrown',
        color = '#4B0082',
        weapons = {
            'weapon_grenade',
            'weapon_bzgas',
            'weapon_molotov',
            'weapon_stickybomb',
            'weapon_proxmine',
            'weapon_snowball',
            'weapon_pipebomb',
            'weapon_ball',
            'weapon_smokegrenade',
            'weapon_flare',
        }
    },
}

-- Animation settings
Config.Animations = {
    openDuration = 150, -- ms
    closeDuration = 100, -- ms
    selectDuration = 50, -- ms
}

-- Sound settings
Config.Sounds = {
    open = 'WEAPON_SELECT',
    select = 'NAV_UP_DOWN',
    close = 'BACK',
}

-- Integration settings
Config.Integration = {
    -- Enable ox_inventory integration
    useOxInventory = true,
    
    -- Enable qbx_core integration
    useQBXCore = true,
    
    -- Sync weapon state with inventory
    syncWithInventory = true,
    
    -- Auto-equip weapon on select
    autoEquip = true,
}

-- UI Settings
Config.UI = {
    wheelSize = 300, -- pixels
    iconSize = 40, -- pixels
    categorySize = 50, -- pixels
    animationSpeed = 0.3, -- seconds
}
