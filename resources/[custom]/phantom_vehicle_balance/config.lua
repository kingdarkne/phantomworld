Config = {}

Config.Debug = false

-- Multipliers are applied to each vehicle's existing handling, so custom
-- handling.meta files still define each car's personality.
Config.CategoryBalance = {
    compacts = { maxSpeed = 0.78, driveForce = 0.82 },
    sedans = { maxSpeed = 0.83, driveForce = 0.86 },
    suvs = { maxSpeed = 0.88, driveForce = 0.90 },
    vans = { maxSpeed = 0.82, driveForce = 0.85 },
    utility = { maxSpeed = 0.80, driveForce = 0.86 },
    service = { maxSpeed = 0.80, driveForce = 0.84 },
    industrial = { maxSpeed = 0.76, driveForce = 0.82 },
    commercial = { maxSpeed = 0.78, driveForce = 0.84 },

    offroad = { maxSpeed = 0.92, driveForce = 0.96 },
    coupes = { maxSpeed = 0.95, driveForce = 0.98 },
    muscle = { maxSpeed = 0.98, driveForce = 1.02 },
    sportsclassics = { maxSpeed = 1.00, driveForce = 1.02 },

    sports = { maxSpeed = 1.06, driveForce = 1.05 },
    super = { maxSpeed = 1.12, driveForce = 1.08 },
    motorcycles = { maxSpeed = 1.03, driveForce = 1.02 },
    emergency = { maxSpeed = 0.95, driveForce = 1.00 },
}

-- Fallbacks for streamed addon cars that are not listed in qbx_core.
Config.ClassBalance = {
    [0] = { maxSpeed = 0.78, driveForce = 0.82 }, -- Compacts
    [1] = { maxSpeed = 0.83, driveForce = 0.86 }, -- Sedans
    [2] = { maxSpeed = 0.88, driveForce = 0.90 }, -- SUVs
    [3] = { maxSpeed = 0.95, driveForce = 0.98 }, -- Coupes
    [4] = { maxSpeed = 0.98, driveForce = 1.02 }, -- Muscle
    [5] = { maxSpeed = 1.00, driveForce = 1.02 }, -- Sports Classics
    [6] = { maxSpeed = 1.06, driveForce = 1.05 }, -- Sports
    [7] = { maxSpeed = 1.12, driveForce = 1.08 }, -- Super
    [8] = { maxSpeed = 1.03, driveForce = 1.02 }, -- Motorcycles
    [9] = { maxSpeed = 0.92, driveForce = 0.96 }, -- Off-road
    [10] = { maxSpeed = 0.76, driveForce = 0.82 }, -- Industrial
    [11] = { maxSpeed = 0.80, driveForce = 0.86 }, -- Utility
    [12] = { maxSpeed = 0.82, driveForce = 0.85 }, -- Vans
    [17] = { maxSpeed = 0.80, driveForce = 0.84 }, -- Service
    [18] = { maxSpeed = 0.95, driveForce = 1.00 }, -- Emergency
    [20] = { maxSpeed = 0.78, driveForce = 0.84 }, -- Commercial
    [22] = { maxSpeed = 1.10, driveForce = 1.06 }, -- Open Wheel
}

Config.SkipClasses = {
    [13] = true, -- Cycles
    [14] = true, -- Boats
    [15] = true, -- Helicopters
    [16] = true, -- Planes
    [19] = true, -- Military
    [21] = true, -- Trains
}
