Config = Config or {}
Locales = Locales or {}

Config.Locales = 'EN' -- TR
Config.TxAdminRestart = true
Config.Random = true
Config.RandomOptions = { min = 21600000, max = 43200000 } -- This setting produces earthquakes between 6 hours and 12 hours
Config.EarthquakeCommand = "earthquake" -- Only works on console