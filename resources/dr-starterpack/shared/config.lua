Config = Config or {}

-- One-time starter package (first character load)
-- Tuned for real-world dealership pricing + freeroam (not GTA money-printer).
-- qbx_core also grants default cash/bank on create (~$500 / $5,000); this ADDS on top.
Config.Starter = {
    -- Start at rank 1 — earn XP in freeroam
    Level = 1,
    XNLRankXP = 0,

    -- Liquid cash on hand
    Cash = 2000,

    -- Bank deposit (safer than dumping everything as cash)
    Bank = 8000,

    -- No free firearm — buy/earn weapons in freeroam
    GunItem = nil,
    AmmoItem = nil,
    AmmoCount = 0,

    ExtraItems = {
        { name = 'phone', count = 1 },
        { name = 'sandwich', count = 5 },
        { name = 'water', count = 5 },
        { name = 'bandage', count = 5 },
        { name = 'lockpick', count = 2 },
    },

    -- ONE free economy / used starter (real-price ballpark). Sports/armored cars are dealers only.
    Cars = {
        { label = 'Panto (~$16.5k city runabout)', model = 'panto' },
        { label = 'Blista (~$22k compact)', model = 'blista' },
        { label = 'Issi (~$21k hatch)', model = 'issi2' },
        { label = 'Asea (~$26.5k sedan)', model = 'asea' },
        { label = 'Premier (~$31k sedan)', model = 'premier' },
        { label = 'Prairie (~$23k coupe)', model = 'prairie' },
        { label = 'Seminole (~$38k family SUV)', model = 'seminole' },
        { label = 'Rebel (~$30k pickup)', model = 'rebel' },
        { label = 'Sanchez (~$7.5k dirt bike)', model = 'sanchez' },
        { label = 'Faggio (~$2.8k scooter)', model = 'faggio' },
    },

    IncludeAddonVehicles = false,

    -- Garage IDs from qbx_garages/config/server.lua
    DefaultGarage = 'motelgarage',
}
