Config = {
  BankAccountName = "bank",   -- ESX account name for bank.

  DroneSounds = true,         -- Should the drones make sound?

  MaxVelocity = 250.0,        -- Max drone speed (* drone stats.speed)
  BoostSpeed  = 3.0,          -- How much the boost ability multiplies max speed
  BoostAccel  = 2.0,          -- How much the boost ability multiplies acceleration
  BoostDrain  = 1.0,          -- Boost ability drain speed when used
  BoostFill   = 0.2,          -- Boost ability recharge speed.
  TazerFill   = 0.2,          -- Tazer ability recharge speed.

  -- Shop = {                 
  --   show_blip   = false,
  --   blip_sprite = 627,
  --   blip_color  = 2,
  --   blip_scale  = 0.5,
  --   blip_text   = "Technology store",
  --   blip_disp   = 2,
  --   location    = vector4(-656.69,-858.13,23.10,0.0),
  --   droneoffset = vector3(0.0,0.0,1.5),
  --   camoffset2  = vector3(0.0,0.0,1.85),
  --   camoffset1  = vector3(0.12,0.4,1.5),
  -- },

  Drones = {
    [1] = {
      label = "Drone",                                      -- Visible text.
      name = "drone",                                       -- Item name.
      public = true,                                        -- Can be used by anybody?
      price = 10000,                                        -- Price
      model = GetHashKey('ch_prop_arcade_drone_01b'),       -- Model
      stats = {
        speed   = 1.0,               -- max speed multiplier
        agility = 1.0,               -- acceleration/deceleration multiplier
        range   = 100.0,             -- range (drone display begins fading out when leaving range)

        -- Max Stats:
        maxSpeed    = 2,             
        maxAgility  = 2,
        maxRange    = 200,
      },
      abilities = {
        infrared     = false,   -- infrared/heat-vision
        nightvision = false,    -- nightvision
        boost       = false,    -- boost
        tazer       = false,    -- tazer 
        explosive   = false,    -- explosion
      },
      restrictions = {},  -- enter job names in here (e.g: {'police','mechanic'}) to restrict the drone purchase to these jobs only, or leave it empty (e.g: {}) for no job restrictions.
      singleuse = false,
      -- bannerUrl = "banner1.png";  -- set the banner image to display at the shop while previewing this drone.
    },

    [2] = {
      label = "LSPD Drone",
      name = "drone_lspd",
      public = true,
      price = 10000,
      model = GetHashKey('ch_prop_casino_drone_02a'),
      stats = {
        speed   = 0.5,
        agility = 1.5,
        range   = 100.0,

        maxSpeed    = 2,
        maxAgility  = 2,
        maxRange    = 200,
      },
      abilities = {
        infrared     = true,
        nightvision = true,
        boost       = false,
        tazer       = false,
        explosive   = false,
      },
      restrictions = {},
      singleuse = false,
    },

    [3] = {
      label = "Nano Drone",
      name = "drone_nano",
      public = true,
      price = 10000,
      model = GetHashKey('ch_prop_arcade_drone_01b'),
      stats = {
        speed   = 1.0,
        agility = 1.0,
        range   = 100.0,

        -- Max Stats:
        maxSpeed    = 2,             
        maxAgility  = 2,
        maxRange    = 200,
      },
      abilities = {
        infrared     = false,
        nightvision = false,
        boost       = false,
        tazer       = false,
        explosive   = false,
      },
      restrictions = {},
      singleuse = true,
    },
  },

  Controls = {
    Drone = {
      ["inspect"] = {
        codes = {38},
        text = "Technology store",
      },
      ["pickup_drone"] = {
        codes = {38},
        text = "Get the Drone",
      },
      ["direction"] = {
        codes = {32,33,34,35},
        text = "Direction",
      },
      ["height"] = {
        codes = {21,22},
        text = "height",
      },
      ["centercam"] = {
        codes = {214},
        text = "center camera",
      },
      ["zoom"] = {
        codes = {16,17},
        text = "zoom"
      },
      ["nightvision"] = {
        codes = {140},
        text = "nightvision"
      },
      ["infrared"] = {
        codes = {75},
        text = "Infrared"
      },
      ["tazer"] = {
        codes = {157},
        text = "tazer"
      },
      ["explosive"] = {
        codes = {158},
        text = "explosive"
      },
      ["boost"] = {
        codes = {160},
        text = "boost"
      },
      ["home"] = {
        codes = {213},
        text = "back home",
      },
      ["disconnect"] = {
        codes = {200},
        text = "disconnect"
      },
    },
    Homing = {
      ["cancel"] = {
        codes = {213},
        text = "cancel",
      },
      ["disconnect"] = {
        codes = {200},
        text = "disconnect"
      },
    }
  },
}

mLibs = exports["meta_libs"]