Config = Config or {}

-- One-time starter package (first character load)
Config.Starter = {
    -- Rank/level
    Level = 20,
    XNLRankXP = 92500, -- GTA Online rank 20 threshold (XNLRankBar "driving" XP)

    -- Money
    Cash = 25000000, -- 25 million

    -- Weapons/items (ox_inventory item names)
    GunItem = 'weapon_pistol',
    AmmoItem = 'pistol_ammo',
    AmmoCount = 25,

    ExtraItems = {
        { name = 'phone', count = 1 },
        { name = 'sandwich', count = 10 },
        { name = 'water_bottle', count = 10 },
    },

    -- Car selection (player can pick ONE)
    Cars = {
        -- Models are taken from `qbx_core/shared/vehicles.lua`
        { label = 'Sultan', model = 'sultan' },
        { label = 'Buffalo', model = 'buffalo' },
        { label = 'Blista', model = 'blista' },
        { label = 'Futo', model = 'futo' },
        { label = 'Elegy RH8', model = 'elegy' },
        { label = 'Kuruma', model = 'kuruma' },
        { label = 'Banshee', model = 'banshee' },
        { label = 'Granger', model = 'granger' },
    },

    -- Also include addon vehicles from other resources (parses vehicles.meta modelName's).
    -- This will only add models that exist in vehicle handling data and are loaded by the game.
    -- NOTE: enabling this can create a huge list; keep false unless you really want it.
    IncludeAddonVehicles = false,

    -- Where the chosen car is stored (garage name from your garage system / qbx_vehicles)
    -- Garage IDs are taken from `qb-garages/config.lua`
    DefaultGarage = 'pillboxgarage',
}

