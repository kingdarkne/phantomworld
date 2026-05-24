-- ================================================
-- Trucking delivery mission config
-- ================================================
-- Used when Config.TruckingMissionForOrderDeliveries = true.
-- Staff drive a truck to pickup, attach the trailer, and complete delivery.

TruckingConfig = {}

-- Truck cab model (e.g. "hauler", "phantom")
TruckingConfig.TruckModel = "hauler"

-- Trailer for small/medium vehicles (car trailer)
TruckingConfig.TrailerSmallVehicle = "tr2"

-- Trailer for large vehicles (container trailer)
TruckingConfig.TrailerLargeVehicle = "tr2"

-- Truck appearance (empty = default; can use GetVehicleProperties data)
TruckingConfig.TruckProperties = {

}

-- Cargo trailer appearance (empty = default)
TruckingConfig.CargoProperties = {

}

-- ================================================
-- Map markers
-- ================================================

TruckingConfig.Markers = {

  -- Truck spawn marker
  spawn = {

    type = 0,           -- marker type (0 = up arrow)

    size = 0.5,         -- size in metres

    color = {r = 230, g = 126, b = 34, a = 200},  -- RGBA

    bobUpAndDown = true,

    faceCamera = false,

    rotate = false

  },

  -- Pickup marker
  pickup = {

    type = 0,

    size = 0.5,

    color = {r = 230, g = 126, b = 34, a = 200},

    bobUpAndDown = true,

    faceCamera = false,

    rotate = false

  },

  -- Drop-off marker
  dropoff = {

    type = 1,           -- cylinder zone

    size = 3.0,

    color = {r = 230, g = 126, b = 34, a = 200},

    bobUpAndDown = false,

    faceCamera = false,

    rotate = false

  }

}

-- ================================================
-- Trailer attachment
-- ================================================

TruckingConfig.TrailerAttachment = {

  maxDistance = 3.0,

  maxAngle = 45.0,

  requireFront = true

}

-- ================================================
-- Map blips
-- ================================================

TruckingConfig.Blips = {

  spawn = {

    sprite = 477,

    color = 47,

    scale = 1.0,

    label = "Truck spawn"

  },

  pickup = {

    sprite = 478,

    color = 47,

    scale = 1.0,

    label = "Cargo pickup"

  },

  dropoff = {

    sprite = 50,

    color = 47,

    scale = 1.0,

    label = "Delivery destination"

  }

}

-- ================================================
-- Pickup locations
-- ================================================
-- Each entry: name, coords vector4(x, y, z, heading), blipColor

TruckingConfig.PickupLocations = {

  {

    name = "Elysian Island",

    coords = vector4(1200.46, -3238.60, 5.79, 0.00),

    blipColor = 47

  },

  {

    name = "Elysian Island",

    coords = vector4(1054.20, -3154.57, 5.90, 180.00),

    blipColor = 47

  },

  {

    name = "Port container yard",

    coords = vector4(863.25, -2927.89, 5.90, 270.00),

    blipColor = 47

  },

  {

    name = "Docks - freight warehouse",

    coords = vector4(804.98, -2911.98, 6.00, 270.00),

    blipColor = 47

  },

  {

    name = "Cypress Flats - RON storage",

    coords = vec4(630.34, -2748.96, 6.1, 304.89),

    blipColor = 5

  },

  {

    name = "Cypress Flats - industrial park",

    coords = vector4(878.57, -2178.94, 30.52, 175.00),

    blipColor = 5

  },

  {

    name = "La Mesa - logistics hub",

    coords = vector4(858.13, -1712.15, 25.14, 352.00),

    blipColor = 5

  },

  {

    name = "El Burro Heights - storage facility",

    coords = vector4(1526.53, -2113.84, 76.77, 0.00),

    blipColor = 5

  },

  {

    name = "LSIA - freight terminal",

    coords = vector4(-782.29, -2661.93, 13.99, 60.00),

    blipColor = 3

  },

  {

    name = "Grand Senora Desert - logistics hub",

    coords = vector4(1777.37, 3309.64, 41.22, 298.00),

    blipColor = 5

  },

  {

    name = "Sandy Shores - industrial site",

    coords = vector4(2537.24, 2584.06, 37.94, 12.00),

    blipColor = 5

  },

  {

    name = "Paleto Bay - freight yard",

    coords = vector4(-361.33, 6065.99, 31.50, 311.00),

    blipColor = 47

  },

  {

    name = "East Vinewood - import facility",

    coords = vector4(875.16, -953.48, 28.06, 2.00),

    blipColor = 5

  },

  {

    name = "Murrieta Heights - distribution centre",

    coords = vector4(1207.16, -1230.24, 35.23, 270.33),

    blipColor = 5

  },

  {

    name = "Docks - freight warehouse",

    coords = vector4(758.59, -1656.02, 31.38, 354.00),

    blipColor = 5

  },

  {

    name = "Elysian Island",

    coords = vec4(166.6, -3297.93, 5.22, 269.91),

    blipColor = 5

  },

  {

    name = "Elysian Island",

    coords = vec4(130.21, -3337.48, 5.36, 268.56),

    blipColor = 5

  },

  {

    name = "Elysian Island",

    coords = vec4(287.65, -3209.35, 5.16, 269.95),

    blipColor = 5

  },

  {

    name = "Elysian Island",

    coords = vec4(305.19, -3091.21, 5.17, 0.25),

    blipColor = 5

  },

  {

    name = "Elysian Island",

    coords = vec4(244.01, -2791.55, 5.34, 218.72),

    blipColor = 5

  },

  {

    name = "Docks - freight warehouse",

    coords = vec4(607.76, -2997.28, 5.38, 179.53),

    blipColor = 5

  },

  {

    name = "Docks - freight warehouse",

    coords = vec4(600.28, -2930.8, 5.38, 180.67),

    blipColor = 5

  },

  {

    name = "Docks - freight warehouse",

    coords = vec4(892.76, -3155.41, 5.24, 179.6),

    blipColor = 5

  },

  {

    name = "Docks - freight warehouse",

    coords = vec4(896.6, -3155.53, 5.24, 179.14),

    blipColor = 5

  },

  {

    name = "Docks - freight warehouse",

    coords = vec4(900.82, -3155.85, 5.24, 180.41),

    blipColor = 5

  },

  {

    name = "Docks - freight warehouse",

    coords = vec4(928.91, -3184.42, 5.24, 0.88),

    blipColor = 5

  },

  {

    name = "Buccaneer Way",

    coords = vec4(594.59, -2767.71, 5.39, 329.99),

    blipColor = 5

  },

  {

    name = "Buccaneer Way",

    coords = vec4(631.09, -2748.45, 5.44, 305.14),

    blipColor = 5

  }, 

}
