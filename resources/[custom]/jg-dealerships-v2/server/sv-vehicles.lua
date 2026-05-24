Vehicles = Vehicles or {}

Vehicles.Server = Vehicles.Server or {}

local vehicleDataCache = {}

function Vehicles.Server.GetAll()

    local vehicles = MySQL.query.await([[

        SELECT vehicle.spawn_code,

        MAX(vehicle.brand) AS brand,

        MAX(vehicle.model) AS model,

        MAX(vehicle.category) AS category,

        MAX(vehicle.price) AS price,

        MAX(vehicle.price_limits_enabled) AS price_limits_enabled,

        MAX(vehicle.min_price) AS min_price,

        MAX(vehicle.max_price) AS max_price,

        MAX(vehicle.unlimited_stock) AS unlimited_stock,

        MAX(vehicle.global_stock_limit) AS global_stock_limit,

        MAX(vehicle.created_at) AS created_at,

        CASE 

          WHEN COUNT(location.id) > 0 THEN

            CONCAT('[', GROUP_CONCAT(

              JSON_OBJECT(

                'id', location.id,

                'name', location.name

              )

            ), ']')

          ELSE '[]'

        END AS locations,

        COALESCE((SELECT SUM(quantity) FROM dealership_orders WHERE dealership_orders.vehicle = vehicle.spawn_code), 0) AS global_stock_ordered

        FROM dealership_vehicles vehicle

        LEFT JOIN dealership_stock stock ON vehicle.spawn_code = stock.vehicle

        LEFT JOIN dealership_locations location ON location.id = stock.dealership

        GROUP BY vehicle.spawn_code

        ORDER BY MAX(vehicle.created_at) DESC

    ]])

    local results = {}

    vehicleDataCache = {}

    for _, vehicle in pairs(vehicles) do

        table.insert(results, {

            spawn_code = vehicle.spawn_code,

            brand = vehicle.brand,

            model = vehicle.model,

            category = vehicle.category,

            price = vehicle.price,

            price_limits_enabled = vehicle.price_limits_enabled,

            min_price = vehicle.min_price,

            max_price = vehicle.max_price,

            unlimited_stock = vehicle.unlimited_stock,

            global_stock_limit = vehicle.global_stock_limit,

            global_stock_ordered = vehicle.global_stock_ordered,

            locations = json.decode(vehicle.locations),

            created_at = vehicle.created_at

        })

    end

    return results

end

function Vehicles.Server.Create(vehicleData)

    local spawnCode = Trim(vehicleData.spawn_code)

    MySQL.insert.await([[

        INSERT INTO dealership_vehicles

        (spawn_code, hashkey, brand, model, category, price, price_limits_enabled, min_price, max_price, unlimited_stock, global_stock_limit)

        VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)

    ]], {

        spawnCode,

        joaat(spawnCode),

        vehicleData.brand,

        vehicleData.model,

        vehicleData.category,

        vehicleData.price,

        vehicleData.price_limits_enabled and 1 or 0,

        vehicleData.min_price,

        vehicleData.max_price,

        (vehicleData.unlimited_stock == false) and 0 or 1,

        vehicleData.global_stock_limit

    })

    for _, location in ipairs(vehicleData.locations) do

        MySQL.insert.await([[

            INSERT IGNORE INTO dealership_stock

            (vehicle, dealership, price)

            VALUES (?, ?, ?)

        ]], {

            spawnCode,

            location.id,

            vehicleData.price

        })

        Showroom.Server.UpdateVehicleCache(spawnCode, location.id)

    end

    return true

end

function Vehicles.Server.Update(spawnCode, vehicleData, updateAllPrices)

    spawnCode = Trim(spawnCode)

    MySQL.query.await([[

        UPDATE dealership_vehicles

        SET brand = ?, model = ?, category = ?, price = ?,

            price_limits_enabled = ?, min_price = ?, max_price = ?,

            unlimited_stock = ?, global_stock_limit = ?

        WHERE spawn_code = ?

    ]], {

        vehicleData.brand,

        vehicleData.model,

        vehicleData.category,

        vehicleData.price,

        vehicleData.price_limits_enabled,

        vehicleData.min_price,

        vehicleData.max_price,

        vehicleData.unlimited_stock,

        vehicleData.global_stock_limit,

        spawnCode

    })

    local locationIds = {}

    for _, location in pairs(vehicleData.locations) do

        table.insert(locationIds, location.id)

    end

    if #vehicleData.locations > 0 then

        MySQL.query.await([[

            DELETE FROM dealership_stock

            WHERE vehicle = ? AND dealership NOT IN (?)

        ]], {

            spawnCode,

            locationIds

        })

    else

        MySQL.query.await([[

            DELETE FROM dealership_stock

            WHERE vehicle = ?

        ]], {

            spawnCode

        })

    end

    for _, location in ipairs(vehicleData.locations) do

        MySQL.query.await([[

            INSERT IGNORE INTO dealership_stock

            (vehicle, dealership, price)

            VALUES (?, ?, ?)

        ]], {

            spawnCode,

            location.id,

            vehicleData.price

        })

    end

    if updateAllPrices then

        MySQL.query.await([[

            UPDATE dealership_stock

            SET price = ?

            WHERE vehicle = ?

        ]], {

            vehicleData.price,

            spawnCode

        })

    end

    for _, location in ipairs(vehicleData.locations) do

        Showroom.Server.UpdateVehicleCache(spawnCode, location.id)

    end

    return true

end

function Vehicles.Server.Delete(spawnCode)

    spawnCode = Trim(spawnCode)

    MySQL.query.await(

        "DELETE FROM dealership_stock WHERE vehicle = ?",

        {spawnCode}

    )

    MySQL.query.await(

        "DELETE FROM dealership_sales WHERE vehicle = ?",

        {spawnCode}

    )

    MySQL.query.await(

        "DELETE FROM dealership_orders WHERE vehicle = ?",

        {spawnCode}

    )

    MySQL.query.await(

        "DELETE FROM dealership_dispveh WHERE vehicle = ?",

        {spawnCode}

    )

    MySQL.query.await(

        "DELETE FROM dealership_vehicles WHERE spawn_code = ?",

        {spawnCode}

    )

    Showroom.Server.UpdateVehicleCache(spawnCode)

    return true

end
