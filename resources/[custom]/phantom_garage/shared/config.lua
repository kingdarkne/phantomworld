Config = {}

Config.Framework = GetResourceState('qbx_core') ~= 'missing' and 'qbx' or 'qb'
Config.Debug = false

-- Garage Types (GTA Online style)
Config.GarageTypes = {
    {
        id = '2car_apartment',
        name = '2-Car Garage',
        slots = 2,
        price = 25000,
        interior = 'low',
        blip = { sprite = 357, color = 0 },
    },
    {
        id = '6car_garage',
        name = '6-Car Garage',
        slots = 6,
        price = 75000,
        interior = 'medium',
        blip = { sprite = 357, color = 2 },
    },
    {
        id = '10car_garage',
        name = '10-Car Garage',
        slots = 10,
        price = 150000,
        interior = 'high',
        blip = { sprite = 357, color = 5 },
    },
    {
        id = 'penthouse_garage',
        name = 'Penthouse Garage',
        slots = 10,
        price = 300000,
        interior = 'penthouse',
        blip = { sprite = 357, color = 46 },
    },
    {
        id = 'office_garage',
        name = 'Office Garage',
        slots = 10,
        price = 250000,
        interior = 'office',
        blip = { sprite = 357, color = 26 },
    },
}

-- Garage Locations (GTA Online style buildings)
Config.GarageLocations = {
    -- 2-Car Garages (Apartment garages)
    { type = '2car_apartment', coords = vec3(-44.5, -585.5, 38.2), label = 'Alta Street Garage' },
    { type = '2car_apartment', coords = vec3(-719.0, -975.0, 24.0), label = 'Del Perro Garage' },
    { type = '2car_apartment', coords = vec3(-1455.0, -530.0, 34.0), label = 'Morningwood Garage' },

    -- 6-Car Garages
    { type = '6car_garage', coords = vec3(228.5, -793.0, 30.7), label = 'Pillbox Garage' },
    { type = '6car_garage', coords = vec3(73.0, -876.0, 30.5), label = 'Legion Square Garage' },
    { type = '6car_garage', coords = vec3(-338.0, -137.0, 39.0), label = 'Hawick Garage' },

    -- 10-Car Garages
    { type = '10car_garage', coords = vec3(-72.0, -1822.0, 26.9), label = 'Davis Garage' },
    { type = '10car_garage', coords = vec3(478.0, -1880.0, 26.1), label = 'La Mesa Garage' },
    { type = '10car_garage', coords = vec3(1000.0, -2340.0, 30.5), label = 'Elysian Island Garage' },
    { type = '10car_garage', coords = vec3(1730.0, 3300.0, 41.2), label = 'Sandy Shores Garage' },

    -- Penthouse Garages
    { type = 'penthouse_garage', coords = vec3(-680.0, -401.0, 34.5), label = 'Eclipse Penthouse' },
    { type = 'penthouse_garage', coords = vec3(-300.0, 230.0, 85.0), label = 'Vinewood Penthouse' },

    -- Office Garages
    { type = 'office_garage', coords = vec3(-138.0, -621.0, 168.0), label = 'Maze Bank Tower' },
    { type = 'office_garage', coords = vec3(-75.0, -823.0, 321.0), label = 'Lombank West' },
}

-- Interior Configs
Config.Interiors = {
    low = {
        ipl = 'apa_v_mp_h_01_a',
        spawnCoords = vec4(228.0, -1000.0, -99.0, 0.0),
        vehicleOffsets = {
            vec4(229.5, -995.0, -99.5, 180.0),
            vec4(225.5, -995.0, -99.5, 180.0),
        },
    },
    medium = {
        ipl = 'apa_v_mp_h_01_c',
        spawnCoords = vec4(200.0, -1000.0, -99.0, 0.0),
        vehicleOffsets = {
            vec4(202.0, -995.0, -99.5, 180.0),
            vec4(198.0, -995.0, -99.5, 180.0),
            vec4(202.0, -1000.0, -99.5, 180.0),
            vec4(198.0, -1000.0, -99.5, 180.0),
            vec4(202.0, -1005.0, -99.5, 180.0),
            vec4(198.0, -1005.0, -99.5, 180.0),
        },
    },
    high = {
        ipl = 'apa_v_mp_h_01_b',
        spawnCoords = vec4(175.0, -1000.0, -99.0, 0.0),
        vehicleOffsets = {
            vec4(177.0, -995.0, -99.5, 180.0),
            vec4(173.0, -995.0, -99.5, 180.0),
            vec4(169.0, -995.0, -99.5, 180.0),
            vec4(177.0, -1000.0, -99.5, 180.0),
            vec4(173.0, -1000.0, -99.5, 180.0),
            vec4(169.0, -1000.0, -99.5, 180.0),
            vec4(177.0, -1005.0, -99.5, 180.0),
            vec4(173.0, -1005.0, -99.5, 180.0),
            vec4(169.0, -1005.0, -99.5, 180.0),
            vec4(177.0, -1010.0, -99.5, 180.0),
        },
    },
    penthouse = {
        ipl = 'apa_v_mp_h_01_b',
        spawnCoords = vec4(150.0, -1000.0, -99.0, 0.0),
        vehicleOffsets = {
            vec4(152.0, -995.0, -99.5, 180.0),
            vec4(148.0, -995.0, -99.5, 180.0),
            vec4(144.0, -995.0, -99.5, 180.0),
            vec4(152.0, -1000.0, -99.5, 180.0),
            vec4(148.0, -1000.0, -99.5, 180.0),
            vec4(144.0, -1000.0, -99.5, 180.0),
            vec4(152.0, -1005.0, -99.5, 180.0),
            vec4(148.0, -1005.0, -99.5, 180.0),
            vec4(144.0, -1005.0, -99.5, 180.0),
            vec4(152.0, -1010.0, -99.5, 180.0),
        },
    },
    office = {
        ipl = 'apa_v_mp_h_01_b',
        spawnCoords = vec4(125.0, -1000.0, -99.0, 0.0),
        vehicleOffsets = {
            vec4(127.0, -995.0, -99.5, 180.0),
            vec4(123.0, -995.0, -99.5, 180.0),
            vec4(119.0, -995.0, -99.5, 180.0),
            vec4(127.0, -1000.0, -99.5, 180.0),
            vec4(123.0, -1000.0, -99.5, 180.0),
            vec4(119.0, -1000.0, -99.5, 180.0),
            vec4(127.0, -1005.0, -99.5, 180.0),
            vec4(123.0, -1005.0, -99.5, 180.0),
            vec4(119.0, -1005.0, -99.5, 180.0),
            vec4(127.0, -1010.0, -99.5, 180.0),
        },
    },
}

-- Vehicle categories for garage organization
Config.VehicleCategories = {
    sports = 'Sports',
    super = 'Super',
    sedan = 'Sedan',
    suv = 'SUV',
    coupe = 'Coupe',
    muscle = 'Muscle',
    offroad = 'Off-Road',
    motorcycle = 'Motorcycle',
    classic = 'Classic',
    other = 'Other',
}

-- Insurance settings
Config.Insurance = {
    enabled = true,
    claimCost = 500,
    claimDelay = 5, -- minutes after destruction
}

-- Impound settings
Config.Impound = {
    enabled = true,
    fee = 1000,
    locations = {
        vec3(409.0, -1623.0, 29.3),
        vec3(-230.0, -1162.0, 23.0),
    },
}
