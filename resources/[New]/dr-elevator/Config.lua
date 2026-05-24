
Config = {}

Config.WaitTime = 8000 -- This will set the time for the ProgressBar | 1000 = 1 second

Config.UseLanguage = "en" -- make new languages to your own likng

Config.UseSoundEffect = false -- makes a sound when you use elevator Note: still a work in progress

Config.Elevator = {
    [1] = {
        Sound = "LiftSoundBellRing",
        name = "elevator_1", -- it should be different for each elevator you make
        locations = {
            vector3(-467.8704, -1029.7469, 24.2894),
            vector3(-467.9058, -1029.7120, 29.0892),
            vector3(-467.8320, -1029.6388, 33.6893),
            vector3(-467.7327, -1028.3939, 38.2788),
        },
        -- everything above is related to interaction
        Floors = {
            [0] = {
                Coords = vector4(-467.4932, -1028.6395, 24.2895, 88.8160),
            },
            [1] = {
                Coords = vector4(-467.3921, -1028.4852, 29.0892, 85.1871),
            },
            [2] = {
                Coords = vector4(-467.5596, -1028.7308, 33.6893, 83.3922),
            },
            [3] = {
                Coords = vector4(-467.3502, -1027.6226, 38.2788, 87.2681),
            },
        }
    },
    [2] = {
        Sound = "LiftSoundBellRing",
        name = "elevator_2", -- it should be different for each elevator you make
        locations = {
            vector3(542.0322, 26.7420, 69.5130),
            vector3(611.6670, -13.4255, 82.7623),
            vector3(611.4484, -13.7880, 87.0535),
            vector3(610.0357, -17.9816, 91.5370),

        },
        -- everything above is related to interaction
        Floors = {
            [0] = {
                Coords = vector4(542.0322, 26.7420, 69.5130, 301.2719),
            },
            [1] = {
                Coords = vector4(611.6670, -13.4255, 82.7623, 157.6523),
            },
            [2] = {
                Coords = vector4(611.4484, -13.7880, 87.0535, 160.3398),
            },
            [3] = {
                Coords = vector4(610.0357, -17.9816, 91.5370, 161.9021),
            },
            
        }
    },
    [3] = {
        Sound = "LiftSoundBellRing",
        name = "elevator_3", -- it should be different for each elevator you make
        locations = {
            vector3(-423.5594, -832.8546, -169.4834),
            vector3(-423.6707, -832.7641, -164.6570),
            vector3(-423.5971, -832.9702, -159.8589),
            vector3(-423.4781, -833.0328, -155.9298),

        },
        -- everything above is related to interaction
        Floors = {
            [0] = {
                Coords = vector4(-423.5594, -832.8546, -169.4834, 245.9001),
            },
            [1] = {
                Coords = vector4(-423.6707, -832.7641, -164.6570, 249.0254),
            },
            [2] = {
                Coords = vector4(-423.5971, -832.9702, -159.8589, 246.1455),
            },
            [3] = {
                Coords = vector4(-423.4781, -833.0328, -155.9298, 251.4499),
            },
            
        }
    },
    [4] = {
        Sound = "LiftSoundBellRing",
        name = "elevator_4", -- it should be different for each elevator you make
        locations = {
            vector3(254.47, -1084.03, 29.29),
            vector3(254.45, -1083.87, 36.13),

        },
        -- everything above is related to interaction
        Floors = {
            [0] = {
                Coords = vector4(254.47, -1084.03, 29.29, 269.23),
            },
            [1] = {
                Coords = vector4(254.45, -1083.87, 36.13, 267.2),
           
                
            },
            
            
        }
    },
}





Config.Locals = {
    ["en"] = {
        Waiting = "Waiting for the Elevator...",
        Restricted = "Access Restricted!",
        CurrentFloor = "Current Floor: ",
        Unable = "You Can't Use The Elevator...",
    },
}
