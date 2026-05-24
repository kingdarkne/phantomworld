Config = {}

-- ================================================
-- Base language and format settings
-- ================================================

-- Locale (e.g. cn, en, jp, de — use "en" for English UI strings)
Config.Locale = "en"

-- Number and date format ("en-US" = US style, "zh-CN" = China style)
Config.NumberAndDateFormat = "en-US"

-- Currency format (%s is the amount placeholder, e.g. "$%s" -> "$1000")
Config.Currency = "$%s"

-- Speed unit ("kph" or "mph")
Config.SpeedUnit = "mph"

-- Distance unit ("km" or "mi")
Config.DistanceUnit = "mi"

-- ================================================
-- Framework and integrations
-- ================================================

-- Game framework ("auto", "esx", "qb", "qbox")
Config.Framework = "auto"

-- Fuel script ("ox_fuel", "LegacyFuel", "ps-fuel", "cdn-fuel", or false to disable)
Config.FuelSystem = false

-- Vehicle keys ("qb-vehiclekeys", "qs-vehiclekeys", "vehicles_keys", "mk_vehiclekeys", or false)
Config.VehicleKeys = false

-- Notifications ("auto", "ox_lib", "qb", "esx", etc.)
Config.Notifications = "auto"

-- Interaction ("textui" or "target")
Config.InteractionMethod = "textui"

-- Draw text UI ("ox_lib", "qtarget", "bt-target", etc.)
Config.DrawText = "ox_lib"

-- Target system ("auto", "ox_target", "qb-target", "bt-target")
Config.Target = "auto"

-- 3D text ("auto", "ox_lib", "native")
Config.DrawText3d = "auto"

-- Radial menu ("ox_lib", "qb-menu", or false)
Config.RadialMenu = "ox_lib"

-- Use framework jobs for employees (true = framework job; false = built-in employees)
Config.UseFrameworkJobs = false

-- ================================================
-- Showroom key prompts
-- ================================================

-- Open showroom prompt text
Config.OpenShowroomPrompt = "[E] Open showroom"

-- Key to open showroom (38 = E)
Config.OpenShowroomKeyBind = 38

-- View vehicle in showroom prompt text
Config.ViewInShowroomPrompt = "[E] View in showroom"

-- Key for showroom view (38 = E)
Config.ViewInShowroomKeyBind = 38

-- Open dealership management prompt text
Config.OpenManagementPrompt = "[E] Dealership management"

-- Key for management (38 = E)
Config.OpenManagementKeyBind = 38

-- Sell vehicle prompt text
Config.SellVehiclePrompt = "[E] Sell vehicle"

-- Key to sell (38 = E)
Config.SellVehicleKeyBind = 38

-- ================================================
-- Vehicle spawn and performance
-- ================================================

-- Spawn vehicles with server setter (true = server sync, slower; false = client spawn)
Config.SpawnVehiclesWithServerSetter = false

-- ================================================
-- Finance settings
-- ================================================

-- Default number of finance payments (e.g. 12 = pay over 12 instalments)
Config.FinancePayments = 12

-- Down payment fraction (0.1 = 10% of vehicle price)
Config.FinanceDownPayment = 0.1

-- Interest rate (0.1 = 10%; total = price × (1 + rate))
Config.FinanceInterest = 0.1

-- Payment interval (in-game hours)
Config.FinancePaymentInterval = 12

-- Hours after a failed payment before repossession
Config.FinancePaymentFailedHoursUntilRepo = 1

-- Max financed vehicles per player at once
Config.MaxFinancedVehiclesPerPlayer = 5

-- Process finance for offline players (deduct / repossess while offline)
Config.FinanceProcessOfflinePlayers = true

-- Show vehicle images in lists (requires images under vehicle_images)
Config.ShowVehicleImages = false

-- ================================================
-- Plates and test drive
-- ================================================

-- Licence plate format ("1AA111AA" style)
Config.PlateFormat = "1AA111AA"

-- Hide vehicle stats in UI (speed, torque, etc.)
Config.HideVehicleStats = false

-- Test drive plate
Config.TestDrivePlate = "ELBORP"

-- Test drive length in seconds (120 = 2 minutes)
Config.TestDriveTimeSeconds = 120

-- Test drive not in routing bucket (true = main world; false = isolated bucket)
Config.TestDriveNotInBucket = false

-- Max concurrent test drives per dealership
Config.DealershipMaxActiveTestDrives = 5

-- Plate for static display vehicles
Config.DisplayVehiclesPlate = "DEALER"

-- Hide purchase prompt on display vehicles (showroom only)
Config.DisplayVehiclesHidePurchasePrompt = false

-- ================================================
-- Orders and stock
-- ================================================

-- Deliver orders via trucking mission (true = truck run; false = timed delivery)
Config.TruckingMissionForOrderDeliveries = false

-- Dealer purchase cost as fraction of sale price (0.8 = 80% cost, 20% margin)
Config.DealerPurchasePrice = 0.8

-- Order delivery time in minutes
Config.VehicleOrderTime = 1

-- Managers can change vehicle prices
Config.ManagerCanChangePriceOfVehicles = true

-- Map blip name (%s = dealership name)
Config.BlipNameFormat = "Dealership: %s"

-- ================================================
-- Vehicle categories (display labels)
-- ================================================

Config.Categories = {

  planes = "Planes",

  sportsclassics = "Sports Classics",

  sedans = "Sedans",

  compacts = "Compacts",

  motorcycles = "Motorcycles",

  super = "Super",

  offroad = "Off-road",

  helicopters = "Helicopters",

  coupes = "Coupes",

  muscle = "Muscle",

  boats = "Boats",

  vans = "Vans",

  sports = "Sports",

  suvs = "SUV",

  commercial = "Commercial",

  cycles = "Cycles",

  industrial = "Industrial"

}

-- ================================================
-- Employee permissions
-- ================================================
-- Permissions:
--   ADMIN            = Full admin access
--   MANAGE_INVENTORY = Orders and stock
--   VIEW_RECORDS     = View sales records
--   SELL             = Sell vehicles and test drives
--   DELIVER          = Deliver orders

Config.EmployeePermissions = {

  -- Manager: full access
  ["Manager"] = {

    "ADMIN",

  },

  -- Supervisor: inventory, records, sell, deliver
  ["Supervisor"] = {

    "MANAGE_INVENTORY",

    "VIEW_RECORDS",

    "SELL",

    "DELIVER",

  },

  -- Sales: sell, records, deliver
  ["Sales"] = {

    "SELL",

    "VIEW_RECORDS",

    "DELIVER",

  },

}

-- ================================================
-- Chat commands
-- ================================================

-- Command to view personal finance (/myfinance)
Config.MyFinanceCommand = "myfinance"

-- Direct sale command (sales staff)
Config.DirectSaleCommand = "directsale"

-- Dealership admin command
Config.DealerAdminCommand = "dealeradmin"

-- ================================================
-- Advanced
-- ================================================

-- Streaming distance for entities (metres; higher = more load)
Config.EntityStreamingDistance = 100.0

-- Remove generator props near dealerships
Config.RemoveGeneratorsAroundDealership = true

-- Auto-run SQL installer (set false after first install)
Config.AutoRunSQL = true

-- Return to previous routing bucket after test drive (false = default world)
Config.ReturnToPreviousRoutingBucket = false

-- Hide bottom-right watermark
Config.HideWatermark = true

-- Debug logging (disable on production)
Config.Debug = false
