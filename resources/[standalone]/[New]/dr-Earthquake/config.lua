Config = Config or {}
Locales = Locales or {}

Config.Locales = 'EN' -- TR
Config.TxAdminRestart = true
Config.Random = true
Config.RandomOptions = { min = 3600000, max = 10800000 } -- This setting produces earthquakes between 1 hour and 3 hours
Config.EarthquakeCommand = "earthquake" -- Only works on console