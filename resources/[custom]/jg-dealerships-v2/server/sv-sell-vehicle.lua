local function CalculateVehicleValue(playerId, dealershipId, plate, model)

    local location = Locations.Server.GetById(dealershipId)

    if not location or not location.enable_sell_vehicle then

        return false

    end

    local playerIdentifier = Framework.Server.GetPlayerIdentifier(playerId)

    local vehicleData = MySQL.single.await(

        string.format([[

            SELECT * FROM %s WHERE plate = ? AND %s = ?

        ]], Framework.VehiclesTable, Framework.PlayerId),

        {plate, playerIdentifier}

    )

    if not vehicleData then

        DebugPrint("The vehicle " .. plate .. " is not owned by player: " .. playerIdentifier .. " (" .. playerId .. ")", "warning")

        Framework.Server.Notify(playerId, Locale.notYourVehicleError, "error")

        return false

    end

    local dbModel = Framework.Server.GetModelColumn(vehicleData)

    if type(dbModel) == "string" then

        dbModel = dbModel:lower()

    end

    model = model:lower()

    if dbModel ~= model then

        if dbModel ~= joaat(model) then

            DebugPrint("[sell-vehicle]: model does not match db: " .. dbModel .. " doesn't match " .. model .. " or " .. joaat(model), "warning")

            Framework.Server.Notify(playerId, Locale.modelDoesNotMatchDb, "error")

            return false

        end

    end

    if vehicleData.financed then

        Framework.Server.Notify(playerId, Locale.vehicleFinancedError, "error")

        return false

    end

    local stockData = MySQL.single.await([[

        SELECT *, stock.price as stock_price FROM dealership_stock stock

        INNER JOIN dealership_vehicles vehicle ON vehicle.spawn_code = stock.vehicle

        WHERE stock.dealership = ? AND vehicle.spawn_code = ?

    ]], {dealershipId, model})

    if not stockData then

        Framework.Server.Notify(playerId, Locale.dealershipDoesntSellVehicle, "error")

        return false

    end

    local sellPercent = location.sell_vehicle_percent or 60

    local vehicleValue = Round(stockData.stock_price * (sellPercent / 100))

    return vehicleValue

end

lib.callback.register("jg-dealerships:server:sell-vehicle-get-value", function(playerId, dealershipId, plate, model)

    local vehicleValue = CalculateVehicleValue(playerId, dealershipId, plate, model)

    if not vehicleValue then

        return false

    end

    local preCheckPassed = SellVehiclePreCheck(dealershipId, plate, model, vehicleValue)

    if not preCheckPassed then

        return false

    end

    return vehicleValue

end)

lib.callback.register("jg-dealerships:server:sell-vehicle", function(playerId, dealershipId, plate, model)

    local vehicleValue = CalculateVehicleValue(playerId, dealershipId, plate, model)

    if not vehicleValue then

        return false

    end

    local location = Locations.Server.GetById(dealershipId)

    if not location then

        return false

    end

    if location.type == "owned" then

        if not DealershipBalance.Server.HasFunds(dealershipId, vehicleValue) then

            Framework.Server.Notify(playerId, Locale.dealershipDoesntSellVehicle, "error")

            return false

        end

        DealershipBalance.Server.Remove(dealershipId, vehicleValue)

        MySQL.update.await(

            "UPDATE dealership_stock SET stock = stock + 1 WHERE dealership = ? AND vehicle = ?",

            {dealershipId, model}

        )

        Showroom.Server.UpdateVehicleCache(model, dealershipId)

    end

    MySQL.query.await(

        string.format("DELETE FROM %s WHERE plate = ?", Framework.VehiclesTable),

        {plate}

    )

    Framework.Server.PlayerAddMoney(playerId, vehicleValue, "bank")

    return true

end)
