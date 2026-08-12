Config = {}

-- Menu settings
Config.Menu = {
    enabled = true,
    openKey = 'F9', -- Key to open the menu (F3 = emotes)
    command = 'vehicles', -- Command to open the menu
}

-- Vehicle categories
Config.Categories = {
    {
        name = 'Personal Vehicles',
        icon = '🚗',
        description = 'Your owned vehicles',
        type = 'owned'
    },
    {
        name = 'Rented Vehicles',
        icon = '🔑',
        description = 'Rented vehicles',
        type = 'rented'
    },
    {
        name = 'Job Vehicles',
        icon = '🚓',
        description = 'Job-specific vehicles',
        type = 'job'
    },
}

-- Spawn settings
Config.Spawn = {
    distance = 30, -- Max distance to spawn vehicle
    spawnInVehicle = true, -- Spawn player inside vehicle
    clearArea = true, -- Clear area before spawning
    despawnPrevious = false, -- Despawn previous vehicle
}

-- Integration settings
Config.Integration = {
    useQBXGarages = true, -- Use qbx_garages for owned vehicles
    useQBXVehicleKeys = true, -- Use qbx_vehiclekeys for key system
}

-- UI Settings
Config.UI = {
    theme = 'dark', -- dark or light
    animations = true, -- Enable animations
    sounds = true, -- Enable sounds
}
