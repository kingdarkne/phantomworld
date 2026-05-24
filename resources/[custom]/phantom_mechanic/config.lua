Config = {}

-- Player mechanic job only (staff `duty` job does not get tablet access)
Config.Job = 'mechanic'
Config.RequireOnDuty = true
Config.BlockedJobs = {
    duty = true,
}

-- Must match kaves_mechanic Config.MechanicShops / Config.Locations
Config.Shops = {
    { coords = vec3(-211.2, -1323.79, 30.22), radius = 4.0 },
    { coords = vec3(-338.72, -136.31, 38.57), radius = 4.0 },
    { coords = vec3(-1155.53, -2013.36, 13.16), radius = 4.0 },
    { coords = vec3(1176.88, 2640.25, 37.75), radius = 4.0 },
    { coords = vec3(107.52, 6625.29, 31.79), radius = 4.0 },
}
