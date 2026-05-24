Config = {}

-- Export Location (where players bring cars)
Config.ExportLocation = vector3(-77.5, -1331.8, 29.3)
Config.ExportHeading = 180.0
Config.ExportPedModel = 's_m_y_dealer_01'

-- Hot Car Rotation (every X in-game hours)
Config.HotCarRotationHours = 4

-- Hot Car Bonus Multiplier (extra cash for the hot car)
Config.HotCarMultiplier = 2.5

-- Vehicle Categories and Base Prices
-- You can add/adjust vehicle spawn names and prices
Config.VehiclePrices = {
    -- Compacts (Low tier)
    ['blista'] = 2500,
    ['panto'] = 2000,
    ['issi2'] = 2200,
    ['prairie'] = 2300,
    ['cogcabrio'] = 3000,
    
    -- Sedans (Mid tier)
    ['tailgater'] = 4500,
    ['schafter2'] = 4800,
    ['fugitive'] = 4000,
    ['premier'] = 3500,
    ['washington'] = 3800,
    ['cognoscenti'] = 5500,
    ['cognoscenti2'] = 6000,
    ['superd'] = 7000,
    
    -- Coupes (Mid-High tier)
    ['felon'] = 5000,
    ['felon2'] = 5200,
    ['oracle'] = 4800,
    ['oracle2'] = 5000,
    ['windsor'] = 7500,
    ['windsor2'] = 7800,
    ['f620'] = 5500,
    ['zion'] = 4800,
    ['zion2'] = 5000,
    
    -- Sports (High tier)
    ['elegy2'] = 25000,
    ['feltzer2'] = 28000,
    ['fusilade'] = 22000,
    ['ninef'] = 32000,
    ['ninef2'] = 34000,
    ['rapidgt'] = 38000,
    ['rapidgt2'] = 40000,
    ['schwarzer'] = 30000,
    ['surano'] = 28000,
    ['carbonizzare'] = 45000,
    ['comet'] = 52000,
    ['coquette'] = 48000,
    ['banshee'] = 35000,
    
    -- Super (Top tier)
    ['adder'] = 125000,
    ['bullet'] = 95000,
    ['cheetah'] = 115000,
    ['entityxf'] = 120000,
    ['infernus'] = 105000,
    ['osiris'] = 145000,
    ['reaper'] = 98000,
    ['t20'] = 150000,
    ['turismor'] = 125000,
    ['vacca'] = 95000,
    ['zentorno'] = 165000,
    ['pfister811'] = 110000,
    ['nero'] = 145000,
    ['nero2'] = 175000,
    ['penetrator'] = 98000,
    ['tempesta'] = 130000,
    ['xa21'] = 185000,
    ['prototipo'] = 200000,
    ['scramjet'] = 220000,
    
    -- SUVs
    ['landstalker'] = 8000,
    ['landstalker2'] = 9000,
    ['baller'] = 8500,
    ['baller2'] = 9500,
    ['cavalcade'] = 7000,
    ['cavalcade2'] = 7500,
    ['granger'] = 8000,
    ['gresley'] = 6500,
    ['habanero'] = 6000,
    ['seminole'] = 5500,
    ['seminole2'] = 6000,
    ['xls'] = 10000,
    ['xls2'] = 12000,
    
    -- Offroad
    ['bfinjection'] = 4500,
    ['bifta'] = 5000,
    ['blazer'] = 3000,
    ['brawler'] = 8000,
    ['dubsta3'] = 15000,
    ['dune'] = 4000,
    ['everon'] = 12000,
    ['kalahari'] = 5000,
    ['kamacho'] = 14000,
    ['mesa3'] = 11000,
    ['outlaw'] = 13000,
    ['rancherxl'] = 6000,
    ['rebel'] = 4500,
    ['rebel2'] = 4800,
    ['sandking'] = 9000,
    ['sandking2'] = 9500,
    ['trophytruck'] = 16000,
    
    -- Muscle
    ['blade'] = 5500,
    ['buccaneer'] = 5000,
    ['buccaneer2'] = 5200,
    ['dominator'] = 7000,
    ['dominator2'] = 7500,
    ['dominator3'] = 8000,
    ['dukes'] = 6000,
    ['gauntlet'] = 6500,
    ['gauntlet2'] = 7000,
    ['hotknife'] = 8000,
    ['nightshade'] = 7200,
    ['phoenix'] = 5800,
    ['picador'] = 5200,
    ['sabregt'] = 5500,
    ['sabregt2'] = 5800,
    ['tampa'] = 6000,
    ['vigero'] = 5600,
    ['virgo'] = 5400,
    
    -- Motorcycles
    ['akuma'] = 4500,
    ['bati'] = 6000,
    ['bati2'] = 6200,
    ['carbonrs'] = 8000,
    ['defiler'] = 5500,
    ['double'] = 7000,
    ['hakuchou'] = 7500,
    ['hakuchou2'] = 8500,
    ['hexer'] = 4000,
    ['innovation'] = 6500,
    ['lectro'] = 7000,
    ['nemesis'] = 5000,
    ['nightblade'] = 8000,
    ['pcj'] = 3500,
    ['ruffian'] = 4800,
    ['sanchez'] = 3000,
    ['sanchez2'] = 3200,
    ['shotaro'] = 12000,
    ['thrust'] = 5500,
    ['vader'] = 4500,
    ['vindicator'] = 9000,
    
    -- Vans/Trucks
    ['bison'] = 5500,
    ['bobcatxl'] = 6000,
    ['boxville'] = 5000,
    ['burrito'] = 4500,
    ['gburrito'] = 5800,
    ['gburrito2'] = 6200,
    ['journey'] = 7000,
    ['minivan'] = 4000,
    ['paradise'] = 4800,
    ['pony'] = 4500,
    ['rumpo'] = 5000,
    ['rumpo2'] = 5200,
    ['speedo'] = 4800,
    ['surfer'] = 5500,
    ['taco'] = 4000,
    ['youga'] = 5200,
    ['youga2'] = 5500,
    
    -- Special/Rare
    ['ruiner'] = 4000,
    ['ruston'] = 13000,
    ['sultan'] = 8000,
    ['sultanrs'] = 15000,
    ['kuruma'] = 9500,
    ['pariah'] = 16000,
    ['penumbra'] = 9000,
    ['raiden'] = 14000,
    ['revolter'] = 13000,
    ['schafter3'] = 11000,
    ['schafter4'] = 12000,
    ['sentinel3'] = 12500,
    ['seven70'] = 17000,
    ['specter'] = 16000,
    ['specter2'] = 18000,
    ['streiter'] = 11000,
    ['sultan2'] = 9500,
    ['verlierer2'] = 10500,
}

-- All vehicle spawn names (used for hot car rotation)
Config.AllVehicles = {}
for vehName, _ in pairs(Config.VehiclePrices) do
    table.insert(Config.AllVehicles, vehName)
end

-- Blip settings
Config.Blip = {
    enabled = true,
    sprite = 227,
    color = 5,
    scale = 0.8,
    label = 'Vehicle Exporter'
}

-- Cooldown between exports (seconds)
Config.ExportCooldown = 300 -- 5 minutes

-- Minimum vehicle health required (0-1000)
Config.MinVehicleHealth = 300

-- Distance check for export
Config.ExportDistance = 5.0
