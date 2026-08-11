--[[
    dr-mapblips: Puts blips on the map so you always see POIs.
    Banks, parking, garages, hangars, boathouses, shops, services, etc.
]]
-- Blip sprites: 108=bank, 357=car, 52=store, 61=hospital, 60=police, 356=boat, 360=heli, 68=tow/depot, 176=services, 366=clothing, 71=barber, 110=ammo, 487=city hall, 102=surgeon, 477=truck, 526=security

local blips = {}
local blipId = 0

local function addBlip(coords, title, sprite, colour, scale)
    scale = scale or 0.65
    blipId = blipId + 1
    local key = "dr_mapblips_" .. blipId
    AddTextEntry(key, title or "Location")
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, scale)
    SetBlipColour(blip, colour or 2)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName(key)
    EndTextCommandSetBlipName(blip)
    blips[#blips + 1] = blip
    return blip
end

local function createMapBlips()
    if #blips > 0 then return end -- already created

    -- ========== BANKS (omes_banking — walk-in ATMs / tellers) ==========
    addBlip(vector3(310.93, -284.44, 54.16), "Fleeca Bank", 108, 2)
    addBlip(vector3(146.61, -1046.02, 29.37), "Fleeca Bank", 108, 2)
    addBlip(vector3(-1211.07, -336.68, 37.78), "Fleeca Bank", 108, 2)
    addBlip(vector3(-2956.68, 481.34, 15.70), "Fleeca Bank", 108, 2)
    addBlip(vector3(-354.15, -55.11, 49.04), "Fleeca Bank", 108, 2)
    addBlip(vector3(1176.40, 2712.75, 38.09), "Fleeca Bank", 108, 2)
    
    -- ========== PACIFIC BANK ==========
    addBlip(vector3(253.41, 225.21, 106.29), "Pacific Standard Bank", 108, 2)
    
    -- ========== PALETO BANK ==========
    addBlip(vector3(-104.38, 6477.57, 31.63), "Paleto Bank", 108, 2)
    
    -- ========== POWER STATIONS (Bank Heist Targets) ==========
    addBlip(vector3(2835.24, 1505.68, 24.72), "Power Station (Heist Target)", 68, 1)
    addBlip(vector3(2811.76, 1500.6, 24.72), "Power Station (Heist Target)", 68, 1)
    addBlip(vector3(2137.73, 1949.62, 93.78), "Power Station (Heist Target)", 68, 1)
    addBlip(vector3(708.92, 117.49, 80.95), "Power Station (Heist Target)", 68, 1)
    addBlip(vector3(670.23, 128.14, 80.95), "Power Station (Heist Target)", 68, 1)
    addBlip(vector3(692.17, 160.28, 80.94), "Power Station (Heist Target)", 68, 1)
    addBlip(vector3(2459.16, 1460.94, 36.2), "Power Station (Heist Target)", 68, 1)
    addBlip(vector3(2280.45, 2964.83, 46.75), "Power Station (Heist Target)", 68, 1)
    addBlip(vector3(2059.68, 3683.8, 34.58), "Power Station (Heist Target)", 68, 1)
    addBlip(vector3(2589.5, 5057.38, 44.91), "Power Station (Heist Target)", 68, 1)
    addBlip(vector3(1343.61, 6388.13, 33.4), "Power Station (Heist Target)", 68, 1)
    addBlip(vector3(236.61, 6406.1, 31.83), "Power Station (Heist Target)", 68, 1)
    addBlip(vector3(-293.1, 6023.54, 31.54), "Power Station (Heist Target)", 68, 1)

    -- ========== HOUSE ROBBERY LOCATIONS ==========
    addBlip(vector3(-784.72, 459.77, 100.39), "House Robbery Target", 366, 1)
    addBlip(vector3(-762.21, 430.96, 100.2), "House Robbery Target", 366, 1)
    addBlip(vector3(-678.01, 512.13, 113.53), "House Robbery Target", 366, 1)
    addBlip(vector3(-640.92, 520.61, 109.88), "House Robbery Target", 366, 1)
    addBlip(vector3(-622.84, 488.88, 108.88), "House Robbery Target", 366, 1)
    addBlip(vector3(-595.55, 530.28, 107.75), "House Robbery Target", 366, 1)
    addBlip(vector3(-536.67, 477.36, 103.19), "House Robbery Target", 366, 1)
    addBlip(vector3(-526.64, 516.97, 112.94), "House Robbery Target", 366, 1)
    addBlip(vector3(-554.48, 541.26, 110.71), "House Robbery Target", 366, 1)
    
    -- ========== STORE ROBBERY LOCATIONS (24/7) ==========
    addBlip(vector3(28.28, -1339.18, 29.5), "24/7 Store (Robbery)", 52, 1)
    addBlip(vector3(-47.22, -1757.96, 29.43), "24/7 Store (Robbery)", 52, 1)
    addBlip(vector3(-707.31, -914.38, 19.22), "24/7 Store (Robbery)", 52, 1)
    addBlip(vector3(-1222.91, -906.96, 12.33), "24/7 Store (Robbery)", 52, 1)
    addBlip(vector3(1165.31, -322.57, 69.21), "24/7 Store (Robbery)", 52, 1)
    addBlip(vector3(-1487.21, -379.03, 40.16), "24/7 Store (Robbery)", 52, 1)
    addBlip(vector3(-3041.19, 585.35, 7.91), "24/7 Store (Robbery)", 52, 1)
    addBlip(vector3(1134.2, -982.24, 46.42), "24/7 Store (Robbery)", 52, 1)
    addBlip(vector3(1165.93, 2709.41, 38.16), "24/7 Store (Robbery)", 52, 1)
    addBlip(vector3(2678.1, 3280.67, 55.24), "24/7 Store (Robbery)", 52, 1)
    addBlip(vector3(1961.29, 3740.67, 32.34), "24/7 Store (Robbery)", 52, 1)
    addBlip(vector3(549.36, 2671.34, 42.16), "24/7 Store (Robbery)", 52, 1)
    addBlip(vector3(373.55, 325.56, 103.57), "24/7 Store (Robbery)", 52, 1)
    addBlip(vector3(2557.46, 382.28, 108.62), "24/7 Store (Robbery)", 52, 1)
    addBlip(vector3(2673.42, 3286.54, 55.24), "24/7 Store (Robbery)", 52, 1)
    
    -- ========== LIQUOR STORE ROBBERY LOCATIONS ==========
    addBlip(vector3(-1222.91, -906.96, 12.33), "Liquor Store (Robbery)", 52, 2)
    addBlip(vector3(-1487.21, -379.03, 40.16), "Liquor Store (Robbery)", 52, 2)
    addBlip(vector3(-2967.82, 390.91, 15.04), "Liquor Store (Robbery)", 52, 2)
    addBlip(vector3(1165.93, 2709.41, 38.16), "Liquor Store (Robbery)", 52, 2)
    addBlip(vector3(-1487.21, -379.03, 40.16), "Liquor Store (Robbery)", 52, 2)
    addBlip(vector3(1135.66, -982.79, 46.42), "Liquor Store (Robbery)", 52, 2)
    
    -- ========== PUBLIC PARKING / GARAGES (qb-garages) ==========
    addBlip(vector3(274.29, -334.15, 44.92), "Parking - Motel", 357, 3)
    addBlip(vector3(883.96, -4.71, 78.76), "Parking - Casino", 357, 3)
    addBlip(vector3(-330.01, -780.33, 33.96), "Parking - San Andreas", 357, 3)
    addBlip(vector3(-1160.86, -741.41, 19.63), "Parking - Spanish Ave", 357, 3)
    addBlip(vector3(69.84, 12.6, 68.96), "Parking - Caears 24", 357, 3)
    addBlip(vector3(-453.7, -786.78, 30.56), "Parking - Caears 24 (2)", 357, 3)
    addBlip(vector3(364.37, 297.83, 103.49), "Parking - Laguna", 357, 3)
    addBlip(vector3(-773.12, -2033.04, 8.88), "Parking - Airport", 357, 3)
    addBlip(vector3(-1185.32, -1500.64, 4.38), "Parking - Beach", 357, 3)
    addBlip(vector3(1137.77, 2663.54, 37.9), "Parking - Motor Hotel", 357, 3)
    addBlip(vector3(883.99, 3649.67, 32.87), "Parking - Liquor", 357, 3)
    addBlip(vector3(1737.03, 3718.88, 34.05), "Parking - Shore", 357, 3)
    addBlip(vector3(76.88, 6397.3, 31.23), "Parking - Bell Farms", 357, 3)
    addBlip(vector3(165.75, -3227.2, 5.89), "Parking - Dumbo", 357, 3)
    addBlip(vector3(213.2, -796.05, 30.86), "Parking - Pillbox Garage", 357, 3)
    addBlip(vector3(2552.68, 4671.8, 33.95), "Parking - Grapeseed", 357, 3)

    -- ========== DEPOTS ==========
    addBlip(vector3(401.76, -1632.57, 29.29), "Depot Lot", 68, 3)
    addBlip(vector3(-1270.01, -3377.53, 14.33), "Air Depot", 359, 3)
    addBlip(vector3(-742.95, -1407.58, 5.5), "LSYMC Depot", 356, 3)
    addBlip(vector3(2334.42, 3118.62, 48.2), "Big Rig Depot", 68, 2)

    -- ========== HANGARS / AIR ==========
    addBlip(vector3(-979.06, -2995.48, 13.95), "Airport Hangar", 360, 3)
    addBlip(vector3(-722.15, -1472.79, 5.0), "Higgins Helitours", 360, 3)
    addBlip(vector3(1737.89, 3288.13, 41.14), "Sandy Shores Hangar", 360, 3)
    addBlip(vector3(-1828.25, 2975.44, 32.81), "Fort Zancudo Hangar", 360, 3)

    -- ========== BOATHOUSES / SEA ==========
    addBlip(vector3(-785.95, -1497.84, -0.09), "LSYMC Boathouse", 356, 3)
    addBlip(vector3(-278.21, 6638.13, 7.55), "Paleto Boathouse", 356, 3)
    addBlip(vector3(1298.56, 4212.42, 33.25), "Millars Boathouse", 356, 3)

    -- ========== BIG RIG PARKING ==========
    addBlip(vector3(161.23, -3188.73, 5.97), "Big Rig Parking - Dumbo", 357, 2)
    addBlip(vector3(137.67, 6632.99, 31.67), "Big Rig Parking - Pop's", 357, 2)
    addBlip(vector3(-2529.37, 2342.67, 33.06), "Big Rig Parking - Ron's", 357, 2)
    addBlip(vector3(2561.67, 476.68, 108.49), "Big Rig Parking - Ron's (2)", 357, 2)
    addBlip(vector3(-41.24, -2550.63, 6.01), "Big Rig Parking - Ron's (3)", 357, 2)

    -- ========== 24/7 STORES ==========
    addBlip(vector3(25.74, -1347.32, 29.49), "24/7 Store", 52, 0)
    addBlip(vector3(-3038.93, 585.95, 7.90), "24/7 Store", 52, 0)
    addBlip(vector3(-3241.93, 1001.46, 12.83), "24/7 Store", 52, 0)
    addBlip(vector3(1728.16, 6414.16, 35.03), "24/7 Store", 52, 0)
    addBlip(vector3(1961.24, 3740.52, 32.34), "24/7 Store", 52, 0)
    addBlip(vector3(373.55, 325.56, 103.56), "24/7 Store", 52, 0)
    addBlip(vector3(-2967.79, 390.91, 15.04), "24/7 Store", 52, 0)
    addBlip(vector3(2678.92, 3280.55, 55.24), "24/7 Store", 52, 0)
    addBlip(vector3(2557.46, 382.28, 108.62), "24/7 Store", 52, 0)
    addBlip(vector3(-1486.53, -377.96, 40.16), "24/7 Store", 52, 0)

    -- ========== PLASTIC SURGEON (illenium-appearance — surgeon shop) ==========
    addBlip(vector3(298.78, -572.81, 43.26), "Plastic Surgeon", 102, 48)

    -- ========== CLOTHING STORES (illenium / legacy clothing) ==========
    addBlip(vector3(1693.32, 4823.48, 41.06), "Clothing Store", 366, 47)
    addBlip(vector3(-712.22, -155.35, 37.42), "Clothing Store", 366, 47)
    addBlip(vector3(-1192.94, -772.69, 17.33), "Clothing Store", 366, 47)
    addBlip(vector3(425.24, -806.01, 28.49), "Clothing Store", 366, 47)
    addBlip(vector3(-162.66, -303.40, 38.73), "Clothing Store", 366, 47)
    addBlip(vector3(75.95, -1392.89, 28.38), "Clothing Store", 366, 47)
    addBlip(vector3(-822.19, -1074.13, 10.33), "Clothing Store", 366, 47)
    addBlip(vector3(-1450.71, -236.83, 48.81), "Clothing Store", 366, 47)
    addBlip(vector3(4.25, 6512.81, 30.88), "Clothing Store", 366, 47)
    addBlip(vector3(615.18, 2762.93, 41.09), "Clothing Store", 366, 47)
    addBlip(vector3(1196.79, 2709.56, 37.22), "Clothing Store", 366, 47)
    addBlip(vector3(-3171.45, 1043.86, 19.86), "Clothing Store", 366, 47)
    addBlip(vector3(-1100.96, 2710.21, 18.11), "Clothing Store", 366, 47)
    addBlip(vector3(121.76, -224.60, 53.56), "Clothing Store", 366, 47)

    -- ========== BARBER (qb-clothing) ==========
    addBlip(vector3(-814.3, -183.8, 36.6), "Barber", 71, 0)
    addBlip(vector3(136.8, -1708.4, 28.3), "Barber", 71, 0)
    addBlip(vector3(-1282.6, -1116.8, 6.0), "Barber", 71, 0)
    addBlip(vector3(1931.5, 3729.7, 31.8), "Barber", 71, 0)
    addBlip(vector3(1212.8, -472.9, 65.2), "Barber", 71, 0)
    addBlip(vector3(-32.9, -152.3, 56.1), "Barber", 71, 0)
    addBlip(vector3(-278.1, 6228.5, 30.7), "Barber", 71, 0)

    -- ========== HOSPITALS ==========
    addBlip(vector3(311.15, -590.48, 43.28), "Pillbox Hospital", 61, 1)
    addBlip(vector3(-449.67, -340.83, 34.50), "Mount Zonah Medical", 61, 1)
    addBlip(vector3(1839.74, 3672.98, 34.28), "Sandy Shores Hospital", 61, 1)
    addBlip(vector3(-247.76, 6331.23, 32.43), "Paleto Medical", 61, 1)

    -- ========== POLICE ==========
    addBlip(vector3(428.23, -984.28, 30.71), "MRPD", 60, 3)
    addBlip(vector3(-1094.57, -809.12, 19.29), "Vespucci PD", 60, 3)
    addBlip(vector3(-445.26, 6015.88, 31.72), "Paleto Sheriff", 60, 3)
    addBlip(vector3(1853.21, 3689.54, 34.27), "Sandy Shores Sheriff", 60, 3)

    -- ========== VEHICLE DEALER (PDM) ==========
    addBlip(vector3(-55.87, -1097.46, 26.42), "Vehicle Dealer (PDM)", 326, 3)

    -- ========== CITY HALL (qbx_cityhall-main — ID, licenses, jobs) ==========
    addBlip(vector3(-262.79, -964.18, 30.22), "City Hall (ID & Licenses)", 487, 0)

    -- ========== SERVICES (generic / misc) ==========
    addBlip(vector3(243.27, -1092.27, 29.29), "City Services (misc)", 176, 44)
    addBlip(vector3(412.34, 314.81, 103.13), "Pawn Shop", 52, 5)
    addBlip(vector3(240.3, -1379.89, 33.74), "Driving School", 225, 3)

    -- ========== AMMUNATION ==========
    addBlip(vector3(22.56, -1105.54, 29.79), "Ammunation", 110, 0)
    addBlip(vector3(810.25, -2157.67, 29.62), "Ammunation", 110, 0)
    addBlip(vector3(842.41, -1033.41, 28.19), "Ammunation", 110, 0)
    addBlip(vector3(-662.18, -935.30, 21.83), "Ammunation", 110, 0)
    addBlip(vector3(-330.29, 6083.88, 31.45), "Ammunation", 110, 0)
    addBlip(vector3(1693.41, 3760.16, 34.71), "Ammunation", 110, 0)
    addBlip(vector3(252.90, -50.00, 69.94), "Ammunation", 110, 0)
    addBlip(vector3(-1117.58, 2698.61, 18.55), "Ammunation", 110, 0)
    addBlip(vector3(2567.69, 294.38, 108.73), "Ammunation", 110, 0)
    addBlip(vector3(-3172.50, 1087.66, 20.84), "Ammunation", 110, 0)

    -- ========== GAS STATIONS (common) ==========
    addBlip(vector3(49.42, 2778.79, 58.04), "Gas Station", 361, 1)
    addBlip(vector3(263.89, 2606.46, 44.98), "Gas Station", 361, 1)
    addBlip(vector3(1039.95, 2671.13, 39.55), "Gas Station", 361, 1)
    addBlip(vector3(1207.65, 2660.17, 37.90), "Gas Station", 361, 1)
    addBlip(vector3(2539.69, 2594.19, 37.94), "Gas Station", 361, 1)
    addBlip(vector3(2679.85, 3263.94, 55.24), "Gas Station", 361, 1)
    addBlip(vector3(2005.05, 3773.88, 32.40), "Gas Station", 361, 1)
    addBlip(vector3(1687.15, 4929.39, 42.08), "Gas Station", 361, 1)
    addBlip(vector3(1701.31, 6416.03, 32.76), "Gas Station", 361, 1)
    addBlip(vector3(179.85, 6602.83, 31.86), "Gas Station", 361, 1)
    addBlip(vector3(-2554.99, 2334.40, 33.08), "Gas Station", 361, 1)
    addBlip(vector3(-70.21, -1761.79, 29.53), "Gas Station", 361, 1)
    addBlip(vector3(2581.32, 362.04, 108.47), "Gas Station", 361, 1)
    addBlip(vector3(176.63, -1562.00, 29.27), "Gas Station", 361, 1)
    addBlip(vector3(-724.62, -935.16, 19.21), "Gas Station", 361, 1)
    addBlip(vector3(-526.02, -1211.00, 18.18), "Gas Station", 361, 1)
    addBlip(vector3(-2096.62, -320.29, 13.17), "Gas Station", 361, 1)
    addBlip(vector3(-1437.62, -276.73, 46.21), "Gas Station", 361, 1)

    -- ========== CAR WASH / MECHANIC (common) ==========
    addBlip(vector3(-699.84, -932.68, 19.01), "Los Santos Customs", 72, 5)
    addBlip(vector3(-337.04, -136.44, 39.01), "LS Customs", 72, 5)
    addBlip(vector3(-1155.53, -2007.18, 13.18), "LS Customs", 72, 5)
    addBlip(vector3(731.90, -1088.77, 22.17), "LS Customs", 72, 5)
    addBlip(vector3(1174.78, 2640.93, 37.75), "LS Customs", 72, 5)
    addBlip(vector3(110.99, 6626.39, 31.89), "LS Customs", 72, 5)

    -- ========== PRISON ==========
    addBlip(vector3(1845.90, 2585.97, 45.67), "Bolingbroke Prison", 188, 1)

    -- ========== CASINO ==========
    addBlip(vector3(925.33, 46.15, 81.11), "Diamond Casino", 617, 0)

    -- ========== AIRPORT ==========
    addBlip(vector3(-1037.72, -2737.69, 20.17), "LSIA", 307, 3)
    addBlip(vector3(1744.58, 3272.04, 41.11), "Sandy Shores Airfield", 307, 3)

    -- ========== APARTMENTS (qb-apartments) ==========
    addBlip(vector3(-667.02, -1105.24, 14.63), "Apartment - South Rockford", 475, 3)
    addBlip(vector3(-1288.52, -430.51, 35.15), "Apartment - Morningwood", 475, 3)
    addBlip(vector3(269.73, -640.75, 42.02), "Apartment - Integrity Way", 475, 3)
    addBlip(vector3(-619.29, 37.69, 43.59), "Apartment - Tinsel Towers", 475, 3)
    addBlip(vector3(291.52, -1078.67, 29.41), "Apartment - Fantastic Plaza", 475, 3)

    -- ========== CAR / BOAT RENTAL (dr-rental) ==========
    addBlip(vector3(-1040.69, -2729.97, 13.80), "Car Rental - LSIA", 326, 38)
    addBlip(vector3(1852.37, 2582.12, 45.67), "Car Rental - Prison", 326, 38)
    addBlip(vector3(2494.52, 1496.70, 38.93), "Car Rental - Vinewood", 326, 38)
    addBlip(vector3(-580.51, 5368.83, 70.38), "Car Rental - Paleto", 326, 38)
    addBlip(vector3(1240.54, -3239.0, 6.03), "Car Rental - La Puerta", 326, 38)
    addBlip(vector3(-806.81, -1497.10, 1.60), "Boat Rental", 356, 38)
    addBlip(vector3(-1038.97, -2730.85, 20.21), "Car Rental - Airport", 326, 38)
    addBlip(vector3(-735.58, -1028.97, 12.80), "Car Rental - Vespucci", 326, 38)

    -- ========== RECYCLING (jim-recycle) ==========
    addBlip(vector3(750.18, -1401.90, 26.54), "Recycle Center", 365, 2)
    addBlip(vector3(57.76, 6470.24, 31.43), "Recycle Center - Paleto", 365, 2)
    addBlip(vector3(757.06, -1399.68, 26.57), "Bottle Bank", 642, 2)
    addBlip(vector3(84.01, -220.32, 54.64), "Bottle Bank", 642, 2)
    addBlip(vector3(31.88, -1315.58, 29.52), "Bottle Bank", 642, 2)
    addBlip(vector3(29.08, -1769.99, 29.61), "Bottle Bank", 642, 2)
    addBlip(vector3(394.08, -877.48, 29.35), "Bottle Bank", 642, 2)
    addBlip(vector3(-1267.97, -812.08, 17.11), "Bottle Bank", 642, 2)

    -- ========== BURGER SHOT (y_burgershot) ==========
    addBlip(vector3(-1198.0, -900.0, 14.0), "Burger Shot", 106, 1)

    -- ========== VINEWOOD PD ==========
    addBlip(vector3(602.40, -28.65, 91.71), "Vinewood PD", 60, 3)

    -- ========== LIQUOR STORES (Rob's Liquor - standard) ==========
    addBlip(vector3(-1222.93, -908.55, 12.33), "Rob's Liquor", 93, 0)
    addBlip(vector3(-1486.53, -378.13, 40.16), "Rob's Liquor", 93, 0)
    addBlip(vector3(1134.25, -982.54, 46.42), "Rob's Liquor", 93, 0)
    addBlip(vector3(-2966.49, 390.91, 15.04), "Rob's Liquor", 93, 0)
    addBlip(vector3(1165.33, 2710.09, 38.16), "Rob's Liquor", 93, 0)
    addBlip(vector3(372.99, 325.77, 103.57), "Rob's Liquor", 93, 0)

    -- ========== TATTOO (common locations) ==========
    addBlip(vector3(1322.65, -1651.97, 52.28), "Tattoo Shop", 75, 0)
    addBlip(vector3(-1153.68, -1425.66, 4.95), "Tattoo Shop", 75, 0)
    addBlip(vector3(322.29, 180.46, 103.59), "Tattoo Shop", 75, 0)
    addBlip(vector3(-3170.07, 1075.05, 20.83), "Tattoo Shop", 75, 0)
    addBlip(vector3(1864.13, 3747.73, 33.03), "Tattoo Shop", 75, 0)
    addBlip(vector3(-294.24, 6200.00, 31.49), "Tattoo Shop", 75, 0)

    -- ========== PAYPHONE (for reference) ==========
    addBlip(vector3(273.91, -978.50, 29.37), "Payphone", 77, 0)
    addBlip(vector3(-1038.45, -2736.30, 20.17), "Payphone", 77, 0)

    -- ========== BENNYS / LSCUSTOMS (extra) ==========
    addBlip(vector3(-205.57, -1308.67, 31.29), "Benny's Original", 72, 5)
    addBlip(vector3(-211.21, -1324.88, 30.89), "LS Customs - Burton", 72, 5)

    -- ========== GOLF / TENNIS / YACHT ==========
    addBlip(vector3(-1336.72, 59.08, 52.71), "Golf Club", 109, 2)
    addBlip(vector3(-1498.83, -359.97, 43.00), "Tennis Club", 109, 2)
    addBlip(vector3(-2047.32, -1032.11, 11.98), "Del Perro Pier", 410, 3)
    addBlip(vector3(-794.58, 1510.13, 2.59), "Yacht", 410, 3)

    -- ========== NIGHTCLUB / STRIP ==========
    addBlip(vector3(127.07, -1297.48, 29.27), "Vanilla Unicorn", 121, 5)

    -- ========== CAYO PERICO (mnr_cayo) – island center so blip shows on map ==========
    addBlip(vector3(5046.0, -5106.0, 6.0), "Cayo Perico Island", 307, 2)

    -- ========== PATOCHE BRIDGE (bridge to Cayo – blip at bridge approach) ==========
    addBlip(vector3(5475.0, -5106.0, 2.0), "Bridge to Cayo", 410, 3)

    -- ========== TRUCKING / TOW / GARBAGE (qb-trucker, qb-towjob, qb-garbagejob) ==========
    addBlip(vector3(153.68, -3211.88, 5.91), "Trucker Job (Truck Shed)", 477, 2)
    addBlip(vector3(471.39, -1311.03, 29.21), "Towing HQ", 68, 5)
    addBlip(vector3(-313.84, -1522.82, 27.56), "Garbage Job", 318, 2)
    addBlip(vector3(-252.22, -965.07, 31.22), "Post OP", 478, 2)
    addBlip(vector3(903.32, -2193.57, 30.54), "Taxi / Downtown Cabs", 198, 5)

    -- ========== RENZU SPAWN / KEY POIs (same names as renzu_spawn for consistency) ==========
    addBlip(vector3(-257.46, -981.22, 31.22), "Job Center", 407, 46)
    addBlip(vector3(223.5, -867.02, 30.49), "Legion Square", 419, 0)
    addBlip(vector3(-184.34, -1295.03, 31.3), "Bennys Motorworks (spawn)", 72, 5)
    addBlip(vector3(-537.59, -217.2, 37.65), "Rockford Hills City Hall (spawn)", 487, 0)
    addBlip(vector3(126.39, 6625.41, 31.79), "Paleto Garage (spawn)", 357, 3)

    -- ========== SECURITY JOB (qb-securityjob) ==========
    addBlip(vector3(-6.49, -662.16, 33.48), "Security Job", 526, 2)

    -- ========== BURGER SHOT ==========
    addBlip(vector3(-1194.48, -897.34, 13.89), "Burger Shot", 106, 1)

    -- ========== RECYCLING (jim-recycle) ==========
    addBlip(vector3(744.68, -1401.77, 26.55), "Recycling Center", 365, 2)

    -- ========== HUNTING / FISHING ==========
    addBlip(vector3(-679.14, 5834.32, 17.33), "Hunting Cabin", 141, 25)
    addBlip(vector3(-1820.19, -1220.47, 13.02), "Fishing Spot / Pier", 68, 3)

    print("^2[dr-mapblips]^7 Added " .. #blips .. " blips to the map.")
end

-- Run when player is loaded (QB / Qbox)
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    CreateThread(function()
        Wait(1000)
        createMapBlips()
    end)
end)

RegisterNetEvent('qbx_core:client:playerLoggedIn', function()
    CreateThread(function()
        Wait(1000)
        createMapBlips()
    end)
end)

-- Run on resource start if player already in game
CreateThread(function()
    Wait(3000)
    if LocalPlayer.state.isLoggedIn then
        createMapBlips()
    end
end)

-- Fallback: once session is active, create POI blips even if login event was missed
CreateThread(function()
    while not NetworkIsSessionStarted() do
        Wait(200)
    end
    Wait(8000)
    createMapBlips()
end)

-- If QBCore load event fires before this resource starts, isLoggedIn still triggers blips
CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(200)
    end
    local sid = GetPlayerServerId(PlayerId())
    if sid and sid > 0 then
        AddStateBagChangeHandler('isLoggedIn', ('player:%s'):format(sid), function(_, _, value)
            if value then
                CreateThread(function()
                    Wait(1000)
                    createMapBlips()
                end)
            end
        end)
    end
end)

-- Clean up on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for i = 1, #blips do
        if DoesBlipExist(blips[i]) then
            RemoveBlip(blips[i])
        end
    end
end)
