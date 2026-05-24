-- Phantom Garage - Server Main
local playerGarages = {}
local garageVehicles = {}

-- Buy garage
lib.callback.register('phantom_garage:server:buyGarage', function(source, garageTypeId, locationIndex)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return { success = false, message = 'Player not found' } end

    local garageType = nil
    for _, gt in ipairs(Config.GarageTypes) do
        if gt.id == garageTypeId then
            garageType = gt
            break
        end
    end
    if not garageType then return { success = false, message = 'Invalid garage type' } end

    local location = Config.GarageLocations[locationIndex]
    if not location then return { success = false, message = 'Invalid location' } end

    -- Check if already owns this garage
    local owned = MySQL.query.await('SELECT * FROM phantom_garages WHERE citizenid = ? AND location_index = ?', {
        Player.PlayerData.citizenid, locationIndex
    })
    if owned and #owned > 0 then
        return { success = false, message = 'Already own this garage' }
    end

    -- Check funds
    if Player.PlayerData.money.cash < garageType.price then
        return { success = false, message = 'Need $' .. garageType.price .. ' cash' }
    end

    -- Deduct
    Player.Functions.RemoveMoney('cash', garageType.price, 'garage-purchase')

    -- Save
    MySQL.insert('INSERT INTO phantom_garages (citizenid, garage_type, location_index, label, slots, purchased_at) VALUES (?, ?, ?, ?, ?, ?)', {
        Player.PlayerData.citizenid,
        garageTypeId,
        locationIndex,
        location.label,
        garageType.slots,
        os.time(),
    })

    return { success = true }
end)

-- Get garage vehicles
lib.callback.register('phantom_garage:server:getGarageVehicles', function(source, garageType)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return {} end

    local vehicles = MySQL.query.await([[
        SELECT * FROM phantom_garage_vehicles
        WHERE citizenid = ? AND garage_type = ? AND stored = 1
        ORDER BY slot_index ASC
    ]], { Player.PlayerData.citizenid, garageType })

    local result = {}
    if vehicles then
        for _, v in ipairs(vehicles) do
            table.insert(result, {
                id = v.id,
                model = v.vehicle_model,
                plate = v.plate,
                mods = json.decode(v.mods or '{}'),
                colors = json.decode(v.colors or '{}'),
                fuel = v.fuel,
                sellPrice = math.floor(v.purchase_price * 0.6),
            })
        end
    end
    return result
end)

-- Store vehicle
lib.callback.register('phantom_garage:server:storeVehicle', function(source, vehicleData)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return { success = false } end

    -- Count vehicles in this garage
    local count = MySQL.query.await([[
        SELECT COUNT(*) as count FROM phantom_garage_vehicles
        WHERE citizenid = ? AND garage_type = ? AND stored = 1
    ]], { Player.PlayerData.citizenid, vehicleData.garageType })

    local garageType = nil
    for _, gt in ipairs(Config.GarageTypes) do
        if gt.id == vehicleData.garageType then
            garageType = gt
            break
        end
    end

    if not garageType then return { success = false, message = 'Invalid garage' } end
    if count and count[1] and count[1].count >= garageType.slots then
        return { success = false, message = 'Garage full (' .. garageType.slots .. ' vehicles max)' }
    end

    -- Check if vehicle already stored
    local existing = MySQL.query.await('SELECT id FROM phantom_garage_vehicles WHERE citizenid = ? AND plate = ?', {
        Player.PlayerData.citizenid, vehicleData.plate
    })

    if existing and #existing > 0 then
        -- Update existing
        MySQL.update([[
            UPDATE phantom_garage_vehicles SET
            mods = ?, colors = ?, fuel = ?, stored = 1, garage_type = ?
            WHERE id = ?
        ]], {
            json.encode(vehicleData.mods),
            json.encode(vehicleData.colors),
            vehicleData.fuel,
            vehicleData.garageType,
            existing[1].id,
        })
    else
        -- Insert new
        MySQL.insert([[
            INSERT INTO phantom_garage_vehicles
            (citizenid, vehicle_model, plate, mods, colors, fuel, garage_type, stored, purchase_price)
            VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?)
        ]], {
            Player.PlayerData.citizenid,
            vehicleData.model,
            vehicleData.plate,
            json.encode(vehicleData.mods),
            json.encode(vehicleData.colors),
            vehicleData.fuel,
            vehicleData.garageType,
            0, -- purchase price unknown for owned vehicles
        })
    end

    return { success = true }
end)

-- Sell vehicle
lib.callback.register('phantom_garage:server:sellVehicle', function(source, vehicleId)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return { success = false } end

    local vehicle = MySQL.query.await('SELECT * FROM phantom_garage_vehicles WHERE id = ? AND citizenid = ?', {
        vehicleId, Player.PlayerData.citizenid
    })

    if not vehicle or #vehicle == 0 then
        return { success = false, message = 'Vehicle not found' }
    end

    local sellPrice = math.floor((vehicle[1].purchase_price or 10000) * 0.6)
    Player.Functions.AddMoney('cash', sellPrice, 'vehicle-sale')

    MySQL.update('DELETE FROM phantom_garage_vehicles WHERE id = ?', { vehicleId })

    return { success = true, price = sellPrice }
end)

-- Vehicle taken out
RegisterNetEvent('phantom_garage:server:vehicleTakenOut', function(vehicleId)
    local src = source
    MySQL.update('UPDATE phantom_garage_vehicles SET stored = 0 WHERE id = ?', { vehicleId })
end)

-- DB Init
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS phantom_garages (
                id INT AUTO_INCREMENT PRIMARY KEY,
                citizenid VARCHAR(50) NOT NULL,
                garage_type VARCHAR(50) NOT NULL,
                location_index INT NOT NULL,
                label VARCHAR(100),
                slots INT DEFAULT 2,
                purchased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_citizenid (citizenid)
            )
        ]])

        MySQL.query([[
            CREATE TABLE IF NOT EXISTS phantom_garage_vehicles (
                id INT AUTO_INCREMENT PRIMARY KEY,
                citizenid VARCHAR(50) NOT NULL,
                vehicle_model VARCHAR(50) NOT NULL,
                plate VARCHAR(20),
                mods JSON,
                colors JSON,
                fuel FLOAT DEFAULT 100.0,
                garage_type VARCHAR(50) NOT NULL,
                stored TINYINT DEFAULT 1,
                slot_index INT DEFAULT 0,
                purchase_price INT DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_citizenid (citizenid),
                INDEX idx_garage (garage_type)
            )
        ]])

        print('^2[Phantom Garage]^7 Server loaded')
    end
end)
