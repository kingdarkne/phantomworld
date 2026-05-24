Config = Config or {}

Config.UseTarget = GetConvar('UseTarget', 'false') ==
'false'                                                       -- Use qb-target interactions (don't change this, go to your server.cfg and add `setr UseTarget true` to use this and just that from true to false or the other way around)

Config.AvailableJobs = {                                     -- Only used when not using qb-jobs.
    ['trucker'] = { ['label'] = 'Trucker', ['isManaged'] = false },
    ['taxi'] = { ['label'] = 'Taxi', ['isManaged'] = false },
    ['tow'] = { ['label'] = 'Tow Truck', ['isManaged'] = false },
    ['reporter'] = { ['label'] = 'News Reporter', ['isManaged'] = false },
    ['garbage'] = { ['label'] = 'Garbage Collector', ['isManaged'] = false },
    ['security'] = { ['label'] = 'Security', ['isManaged'] = false },
    ['bus'] = { ['label'] = 'Bus Driver', ['isManaged'] = false },
    ['hotdog'] = { ['label'] = 'Hot Dog Stand', ['isManaged'] = false }
}

Config.Cityhalls = {
    { -- Cityhall 1
        coords = vec3(243.2737, -1092.2705, 29.2943),
        showBlip = true,
        blipData = {
            sprite = 176,
            display = 4,
            scale = 0.9,
            colour = 44,
            title = 'City Services'
        },
        licenses = {
            ["id_card"] = {
                label = "ID Card",
                cost = 50,
           
            },
        }
    },
}

Config.DrivingSchools = {
    { -- Driving School 1
        coords = vec3(240.3, -1379.89, 33.74),
        showBlip = false,
        blipData = {
            sprite = 225,
            display = 4,
            scale = 0.65,
            colour = 3,
            title = 'Driving School'
        },
        instructors = {
            'DJD56142',
            'DXT09752',
            'SRI85140',
        }
    },
}

Config.Peds = {
    -- Cityhall Ped
    {
        model = 'a_m_m_business_01',
        coords = vec4(243.2737, -1092.2705, 28.2943, 358.8888),
        scenario = 'WORLD_HUMAN_STAND_MOBILE',
        cityhall = true,
        zoneOptions = { -- Used for when UseTarget is false
            length = 3.0,
            width = 3.0,
            debugPoly = false
        }
    },
    -- {
    --     model = 'a_m_m_business_01',
    --     coords = vec4(240.91, -1379.2, 32.74, 138.96),
    --     scenario = 'WORLD_HUMAN_STAND_MOBILE',
    --     drivingschool = false,
    --     zoneOptions = { -- Used for when UseTarget is false
    --         length = 3.0,
    --         width = 3.0
    --     }
    -- }
}
