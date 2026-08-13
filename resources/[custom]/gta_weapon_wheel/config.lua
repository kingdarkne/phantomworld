Config = {}

-- Enable/disable the custom weapon wheel
Config.Enabled = true

-- TAB (control 37) — replaces ox/native GTA weapon wheel
Config.OpenKey = 37
Config.OpenKeyName = 'TAB'

-- Hide/block the native GTA weapon wheel HUD while this resource is active
Config.BlockNativeWheel = true

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
        }
    },
    {
        name = 'Shotguns',
        icon = 'shotgun',
        color = '#4169E1',
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
        color = '#32CD32',
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
            'weapon_tacticalrifle',
        }
    },
    {
        name = 'Heavy Weapons',
        icon = 'heavy',
        color = '#DC143C',
        weapons = {
            'weapon_mg',
            'weapon_combatmg',
            'weapon_combatmg_mk2',
            'weapon_gusenberg',
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
        name = 'Sniper Rifles',
        icon = 'sniper',
        color = '#9400D3',
        weapons = {
            'weapon_sniperrifle',
            'weapon_heavysniper',
            'weapon_heavysniper_mk2',
            'weapon_marksmanrifle',
            'weapon_marksmanrifle_mk2',
            'weapon_precisionrifle',
        }
    },
    {
        name = 'Melee',
        icon = 'melee',
        color = '#808080',
        weapons = {
            'weapon_knife',
            'weapon_nightstick',
            'weapon_hammer',
            'weapon_bat',
            'weapon_golfclub',
            'weapon_crowbar',
            'weapon_bottle',
            'weapon_dagger',
            'weapon_hatchet',
            'weapon_knuckle',
            'weapon_machete',
            'weapon_flashlight',
            'weapon_switchblade',
            'weapon_poolcue',
            'weapon_wrench',
            'weapon_battleaxe',
            'weapon_stone_hatchet',
        }
    },
    {
        name = 'Thrown',
        icon = 'thrown',
        color = '#FF8C00',
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

Config.UI = {
    radius = 280,
    itemSize = 64,
    centerSize = 100,
    animationSpeed = 200,
    backgroundColor = 'rgba(0, 0, 0, 0.75)',
    selectedColor = '#FFD700',
}

Config.Sounds = {
    open = 'SELECT',
    close = 'BACK',
    select = 'SELECT',
    hover = 'NAV_UP_DOWN',
}

Config.Integration = {
    useOxInventory = true,
    useQbxCore = true,
    autoEquip = true,
}
