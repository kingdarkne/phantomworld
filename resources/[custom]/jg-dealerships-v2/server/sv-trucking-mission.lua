if not TruckingMission then

    TruckingMission = {}

end

local activeMissions = {}

local occupiedPickupLocations = {}

local pendingConfigurations = {}

local configHashSeed = tostring(os.time()) .. tostring(math.random(100000, 999999))

local TruckingServer = TruckingMission.Server or {}

local function CountVehiclesInTransit(orderId)

    local count = 0

    for playerId, mission in pairs(activeMissions) do

        if mission and mission.active and mission.orders then

            for _, order in ipairs(mission.orders) do

                if order.orderId == orderId then

                    count = count + order.quantityToDeliver

                end

            end

        end

    end

    return count

end

function TruckingServer.GetOrderSizeCategory(orderId)

    local sizeCategory = MySQL.scalar.await(

        "SELECT size_category FROM dealership_orders WHERE id = ?",

        {orderId}

    )

    return sizeCategory or "medium"

end

local function GenerateConfigHash(orderIds, trailerType)

    table.sort(orderIds)

    local hashString = configHashSeed .. trailerType

    for _, orderId in ipairs(orderIds) do

        hashString = hashString .. tostring(orderId)

    end

    return GetHashKey(hashString) .. ""

end

local function VerifyConfigHash(orderIds, trailerType, expectedHash)

    return GenerateConfigHash(orderIds, trailerType) == expectedHash

end

local function GetAvailablePickupLocation()

    local availableIndices = {}

    for i = 1, #TruckingConfig.PickupLocations do

        if not occupiedPickupLocations[i] then

            table.insert(availableIndices, i)

        end

    end

    if #availableIndices == 0 then

        return nil, nil

    end

    local selectedIndex = availableIndices[math.random(#availableIndices)]

    local pickupStop = {

        index = selectedIndex,

        location = TruckingConfig.PickupLocations[selectedIndex],

        vehicles = {}

    }

    return pickupStop, selectedIndex

end

local function AddVehiclesToPickupStop(pickupStop, orders)

    for _, order in ipairs(orders) do

        for i = 1, order.quantityToDeliver do

            table.insert(pickupStop.vehicles, {

                orderId = order.orderId,

                model = order.model,

                size = order.size,

                quantity = 1

            })

        end

    end

    return pickupStop

end

local function CalculateDistanceAndTime(dealershipCoords, pickupStop)

    local dealershipVec = vector3(dealershipCoords.x, dealershipCoords.y, dealershipCoords.z)

    local pickupVec = vector3(

        pickupStop.location.coords.x,

        pickupStop.location.coords.y,

        pickupStop.location.coords.z

    )

    local distance = #(dealershipVec - pickupVec)

    distance = distance * 2 * 1.4

    local estimatedTime = math.ceil((distance / 13.9) * 1.3)

    local totalDistance = math.floor(distance)

    return totalDistance, estimatedTime

end

local function ValidatePlayerCanStartMission(playerId, dealershipId)

    if not playerId then

        return false, "Invalid player ID"

    end

    if activeMissions[playerId] then

        return false, "You already have an active mission"

    end

    if not Employees.Server.IsEmployee(playerId, dealershipId, "DELIVER") then

        return false, "You must have delivery permissions to start deliveries"

    end

    return true

end

local function ValidateAndPrepareOrders(orderIds, dealershipId, quantities)

    if #orderIds == 0 then

        return false, "No orders selected", nil

    end

    local validatedOrders = {}

    for _, orderId in ipairs(orderIds) do

        local orderData = MySQL.single.await(

            "SELECT * FROM dealership_orders WHERE id = ? AND dealership = ? AND fulfilled = 0",

            {orderId, dealershipId}

        )

        if not orderData then

            return false, "Order " .. orderId .. " not found or already fulfilled", nil

        end

        local remaining = orderData.quantity - (orderData.delivered or 0)

        local requestedQty = quantities[orderId] or quantities[tostring(orderId)] or remaining

        local inTransit = CountVehiclesInTransit(orderId)

        local available = remaining - inTransit

        if available <= 0 then

            return false, "All remaining vehicles for order " .. orderId .. " are already being delivered", nil

        end

        if requestedQty > available then

            return false, string.format(

                "Order %d: only %d vehicle(s) available to deliver (%d remaining, %d already in transit)",

                orderId, available, remaining, inTransit

            ), nil

        end

        if requestedQty <= 0 then

            return false, "Invalid quantity for order " .. orderId, nil

        end

        local sizeCategory = orderData.size_category or "medium"

        table.insert(validatedOrders, {

            orderId = orderId,

            model = orderData.vehicle,

            quantityToDeliver = requestedQty,

            totalQuantity = orderData.quantity,

            delivered = orderData.delivered or 0,

            size = sizeCategory

        })

    end

    return true, nil, validatedOrders

end

function TruckingServer.GenerateDeliveryConfiguration(playerId, dealershipId, trailerType, orderIds, quantities)

    local isValid, errorMsg = ValidatePlayerCanStartMission(playerId, dealershipId)

    if not isValid then

        return false, errorMsg, nil

    end

    local success, error, orders = ValidateAndPrepareOrders(orderIds, dealershipId, quantities)

    if not success or not orders then

        return false, error, nil

    end

    for _, order in ipairs(orders) do

        if trailerType == "car" and order.size == "large" then

            return false, "Large vehicles require a container trailer", nil

        end

        if trailerType == "container" and order.size ~= "large" then

            return false, "Container trailer is only for large vehicles", nil

        end

    end

    if trailerType == "container" then

        local totalVehicles = 0

        for _, order in ipairs(orders) do

            totalVehicles = totalVehicles + order.quantityToDeliver

        end

        if totalVehicles > 1 then

            return false, "Container trailer can only carry 1 large vehicle", nil

        end

    end

    print(json.encode(orders))

    if trailerType == "car" then

        local maxSlots = 6

        local usedSlots = 0

        for _, order in ipairs(orders) do

            local slotSize = (order.size == "medium") and 1.5 or 1

            usedSlots = usedSlots + (order.quantityToDeliver * slotSize)

        end

        if usedSlots > maxSlots then

            print("car trailer capacity exceeded")

            return false, string.format(

                "Car trailer capacity exceeded! Selected %.1f slots but maximum is %d slots. Small vehicles use 1 slot, medium vehicles use 1.5 slots.",

                usedSlots, maxSlots

            ), nil

        end

    end

    local dealershipLocation = Locations.Server.GetById(dealershipId)

    if not dealershipLocation or not dealershipLocation.trucking_vehicle_coords then

        return false, "[Configuration error] No trucking vehicle coordinates set", nil

    end

    local totalVehicles = 0

    for _, order in ipairs(orders) do

        totalVehicles = totalVehicles + order.quantityToDeliver

    end

    local pickupStop, occupiedIndex = GetAvailablePickupLocation()

    if not pickupStop or not occupiedIndex then

        return false, "No pickup locations available at this time", nil

    end

    pickupStop = AddVehiclesToPickupStop(pickupStop, orders)

    print("^2[Trucking Server] Generated pickup stop with " .. #pickupStop.vehicles .. " vehicles^0")

    for idx, veh in ipairs(pickupStop.vehicles) do

        print("^3[Trucking Server] Vehicle " .. idx .. ": " .. veh.model .. " (Order ID: " .. veh.orderId .. ", Qty: " .. veh.quantity .. ")^0")

    end

    local totalDistance, estimatedTime = CalculateDistanceAndTime(dealershipLocation.trucking_vehicle_coords, pickupStop)

    local configHash = GenerateConfigHash(orderIds, trailerType)

    local maxCapacity = (trailerType == "container") and 1 or 6

    local configuration = {

        trailerType = trailerType,

        pickupStop = pickupStop,

        occupiedIndex = occupiedIndex,

        totalVehicles = totalVehicles,

        maxCapacity = maxCapacity,

        totalDistance = totalDistance,

        estimatedTime = estimatedTime,

        configHash = configHash,

        orders = orders,

        orderIds = orderIds,

        quantities = quantities

    }

    pendingConfigurations[playerId] = configuration

    for pid, config in pairs(pendingConfigurations) do

        if config.timestamp then

            local elapsed = os.time() - config.timestamp

            if elapsed > 300 then

                pendingConfigurations[pid] = nil

            end

        end

    end

    configuration.timestamp = os.time()

    return true, nil, configuration

end

function TruckingServer.SetTruckEntity(playerId, networkId)

    if not activeMissions[playerId] then

        return false

    end

    if not networkId or networkId == 0 then

        return false

    end

    local truckEntity = NetworkGetEntityFromNetworkId(networkId)

    if not truckEntity or truckEntity == 0 then

        return false

    end

    activeMissions[playerId].truck = truckEntity

    return true

end

function TruckingServer.SetCargoEntity(playerId, networkId)

    if not activeMissions[playerId] then

        return false

    end

    if not networkId or networkId == 0 then

        return false

    end

    local cargoEntity = NetworkGetEntityFromNetworkId(networkId)

    if not cargoEntity or cargoEntity == 0 then

        return false

    end

    activeMissions[playerId].cargo = cargoEntity

    return true

end

function TruckingServer.SetMissionStage(playerId, stage)

    if not activeMissions[playerId] then

        return false

    end

    activeMissions[playerId].stage = stage

    return true

end

local function CleanupMissionVehicles(mission, cargoEntity)

    if mission.truck and DoesEntityExist(mission.truck) then

        DeleteEntity(mission.truck)

    end

    if mission.cargo and DoesEntityExist(mission.cargo) then

        DeleteEntity(mission.cargo)

    end

    if cargoEntity and DoesEntityExist(cargoEntity) then

        DeleteEntity(cargoEntity)

    end

end

local function ReleasePickupLocation(mission)

    if mission.pickupStop and mission.pickupStop.index then

        occupiedPickupLocations[mission.pickupStop.index] = nil

    end

end

function TruckingServer.CompleteDelivery(playerId, cargoNetworkId)

    print("^3[Trucking Mission Debug] CompleteDelivery called for player " .. playerId .. "^0")

    local mission = activeMissions[playerId]

    if not mission then

        print("^1[Trucking Mission] Validation failed: No active mission^0")

        return false

    end

    print("^3[Trucking Mission Debug] Mission stage: " .. tostring(mission.stage) .. "^0")

    if mission.stage ~= "at_dropoff" then

        print("^1[Trucking Mission] Validation failed: Wrong stage (expected at_dropoff, got " .. tostring(mission.stage) .. ")^0")

        CleanupMissionVehicles(mission)

        ReleasePickupLocation(mission)

        activeMissions[playerId] = nil

        return false

    end

    local playerPed = GetPlayerPed(playerId)

    if not playerPed or playerPed == 0 then

        print("^1[Trucking Mission] Validation failed: Invalid player ped^0")

        CleanupMissionVehicles(mission)

        ReleasePickupLocation(mission)

        activeMissions[playerId] = nil

        return false

    end

    local playerCoords = GetEntityCoords(playerPed)

    if not playerCoords or not mission.dropoffCoords then

        print("^1[Trucking Mission] Validation failed: Invalid coordinates^0")

        CleanupMissionVehicles(mission)

        ReleasePickupLocation(mission)

        activeMissions[playerId] = nil

        return false

    end

    local playerVec = vector3(playerCoords.x, playerCoords.y, playerCoords.z)

    local dropoffVec = vector3(mission.dropoffCoords.x, mission.dropoffCoords.y, mission.dropoffCoords.z)

    local distance = #(playerVec - dropoffVec)

    print("^3[Trucking Mission Debug] Distance to dropoff: " .. distance .. "m^0")

    if distance > 10.0 then

        print("^1[Trucking Mission] Validation failed: Too far from dropoff (distance: " .. distance .. "m)^0")

        CleanupMissionVehicles(mission)

        ReleasePickupLocation(mission)

        activeMissions[playerId] = nil

        return false

    end

    print("^3[Trucking Mission Debug] Mission truck: " .. tostring(mission.truck) .. "^0")

    if not mission.truck or not DoesEntityExist(mission.truck) then

        print("^1[Trucking Mission] Validation failed: Truck doesn't exist^0")

        CleanupMissionVehicles(mission)

        ReleasePickupLocation(mission)

        activeMissions[playerId] = nil

        return false

    end

    local currentVehicle = GetVehiclePedIsIn(playerPed, false)

    print("^3[Trucking Mission Debug] Current vehicle: " .. tostring(currentVehicle) .. " | Expected: " .. tostring(mission.truck) .. "^0")

    if currentVehicle ~= mission.truck then

        print("^1[Trucking Mission] Validation failed: Player not in mission truck^0")

        CleanupMissionVehicles(mission)

        ReleasePickupLocation(mission)

        activeMissions[playerId] = nil

        return false

    end

    local cargoEntity = nil

    if mission.cargo then

        if not DoesEntityExist(mission.cargo) then

            print("^1[Trucking Mission] Server cargo entity doesn't exist^0")

            CleanupMissionVehicles(mission)

            ReleasePickupLocation(mission)

            activeMissions[playerId] = nil

            return false

        end

        cargoEntity = mission.cargo

    else

        print("^3[Trucking Mission] Cargo spawned on client, using network ID: " .. tostring(cargoNetworkId) .. "^0")

        if not cargoNetworkId then

            print("^1[Trucking Mission] No cargo network ID provided^0")

            CleanupMissionVehicles(mission)

            ReleasePickupLocation(mission)

            activeMissions[playerId] = nil

            return false

        end

        cargoEntity = NetworkGetEntityFromNetworkId(cargoNetworkId)

        if not cargoEntity or cargoEntity == 0 or not DoesEntityExist(cargoEntity) then

            print("^1[Trucking Mission] Failed to get cargo entity from network ID^0")

            CleanupMissionVehicles(mission)

            ReleasePickupLocation(mission)

            activeMissions[playerId] = nil

            return false

        end

        print("^2[Trucking Mission] Got cargo entity from network ID: " .. tostring(cargoEntity) .. "^0")

    end

    local cargoNetId = NetworkGetNetworkIdFromEntity(cargoEntity)

    print("^3[Trucking Mission] Cargo entity network ID: " .. tostring(cargoNetId) .. " | Expected: " .. tostring(cargoNetworkId) .. "^0")

    if not cargoNetId or cargoNetId ~= cargoNetworkId then

        print("^1[Trucking Mission] Cargo network ID mismatch^0")

        CleanupMissionVehicles(mission)

        ReleasePickupLocation(mission)

        activeMissions[playerId] = nil

        return false

    end

    local truckCoords = GetEntityCoords(mission.truck)

    local cargoCoords = GetEntityCoords(cargoEntity)

    local vehicleDistance = #(truckCoords - cargoCoords)

    if vehicleDistance > 15.0 then

        print("^1[Trucking Mission] Truck and cargo too far apart: " .. vehicleDistance .. "m^0")

        CleanupMissionVehicles(mission, cargoEntity)

        ReleasePickupLocation(mission)

        activeMissions[playerId] = nil

        return false

    end

    ReleasePickupLocation(mission)

    CleanupMissionVehicles(mission, cargoEntity)

    local playerIdentifier = Framework.Server.GetPlayerIdentifier(playerId) or nil

    local pickupLocationName = (mission.pickupStop and mission.pickupStop.location and mission.pickupStop.location.name) or "Unknown"

    for _, order in ipairs(mission.orders) do

        local currentDelivered = MySQL.scalar.await(

            "SELECT delivered FROM dealership_orders WHERE id = ?",

            {order.orderId}

        ) or 0

        local newDelivered = currentDelivered + order.quantityToDeliver

        local orderInfo = MySQL.single.await(

            "SELECT quantity FROM dealership_orders WHERE id = ?",

            {order.orderId}

        )

        local isFulfilled = orderInfo and (newDelivered >= orderInfo.quantity)

        MySQL.update.await(

            "UPDATE dealership_orders SET delivered = ?, fulfilled = ?, delivered_by = ?, delivered_at = NOW(), delivery_pickup_location = ? WHERE id = ?",

            {

                newDelivered,

                isFulfilled and 1 or 0,

                playerIdentifier,

                pickupLocationName,

                order.orderId

            }

        )

        local orderCostData = MySQL.single.await(

            "SELECT cost, quantity FROM dealership_orders WHERE id = ?",

            {order.orderId}

        )

        if orderCostData and orderCostData.cost and orderCostData.quantity and orderCostData.quantity > 0 then

            local costPerVehicle = orderCostData.cost / orderCostData.quantity

            local amountToDeduct = costPerVehicle * order.quantityToDeliver

            DealershipBalance.Server.Remove(mission.dealershipId, amountToDeduct)

            print("^2[Trucking Mission] Deducted $" .. amountToDeduct .. " from dealership " .. mission.dealershipId .. " for " .. order.quantityToDeliver .. " vehicle(s) delivered^0")

        end

        local existingStock = MySQL.scalar.await(

            "SELECT stock FROM dealership_stock WHERE vehicle = ? AND dealership = ?",

            {order.model, mission.dealershipId}

        )

        if existingStock then

            MySQL.update.await(

                "UPDATE dealership_stock SET stock = stock + ? WHERE vehicle = ? AND dealership = ?",

                {order.quantityToDeliver, order.model, mission.dealershipId}

            )

        else

            MySQL.insert.await(

                "INSERT INTO dealership_stock (vehicle, dealership, stock, price) SELECT ?, ?, ?, price FROM dealership_vehicles WHERE spawn_code = ?",

                {order.model, mission.dealershipId, order.quantityToDeliver, order.model}

            )

        end

        Showroom.Server.UpdateVehicleCache(order.model, mission.dealershipId)

    end

    activeMissions[playerId] = nil

    return true

end

function TruckingServer.CancelDelivery(playerId)

    if not activeMissions[playerId] then

        return false

    end

    local mission = activeMissions[playerId]

    CleanupMissionVehicles(mission)

    ReleasePickupLocation(mission)

    activeMissions[playerId] = nil

    return true

end

function TruckingServer.GetMissionData(playerId)

    local mission = activeMissions[playerId]

    if not mission then

        return false, "No active mission found", nil

    end

    local dealershipLocation = Locations.Server.GetById(mission.dealershipId)

    if not dealershipLocation or not dealershipLocation.trucking_vehicle_coords then

        return false, "[Configuration error] No trucking vehicle coordinates set", nil

    end

    local missionData = {

        pickupStop = mission.pickupStop,

        dropoffCoords = mission.dropoffCoords,

        truckSpawn = dealershipLocation.trucking_vehicle_coords,

        spawnOnClient = not Config.SpawnVehiclesWithServerSetter,

        trailerType = mission.trailerType,

        orders = mission.orders

    }

    return true, nil, missionData

end

function TruckingServer.SpawnCargoTrailer(playerId)

    local mission = activeMissions[playerId]

    if not mission then

        return false, nil, nil

    end

    if mission.stage ~= "driving_to_pickup" and mission.stage ~= "spawned" then

        return false, nil, nil

    end

    if mission.cargo then

        return false, nil, nil

    end

    if not mission.pickupStop then

        return false, nil, nil

    end

    local spawnCoords = mission.pickupStop.location.coords

    local cargoModel = nil

    local networkId = nil

    local entity = nil

    if mission.trailerType == "container" then

        cargoModel = TruckingConfig.TrailerLargeVehicle

    else

        local configModel = TruckingConfig.TrailerSmallVehicle

        cargoModel = (configModel == "DYNAMIC_TR2") and "tr2" or configModel

    end

    if Config.SpawnVehiclesWithServerSetter then

        local cargoProps = TruckingConfig.CargoProperties or {}

        local success, entityId = Spawn.Server.Create(

            playerId,

            0,

            cargoModel,

            false,

            spawnCoords,

            false,

            cargoProps,

            "truckingMission"

        )

        networkId = entityId

        entity = success

        if not entity or not networkId then

            return false, nil, nil

        end

        mission.cargo = networkId

        FreezeEntityPosition(networkId, true)

    end

    return true, entity, not Config.SpawnVehiclesWithServerSetter

end

function TruckingServer.UnfreezeCargo(playerId)

    local mission = activeMissions[playerId]

    if not mission or not mission.cargo then

        return false

    end

    if DoesEntityExist(mission.cargo) then

        FreezeEntityPosition(mission.cargo, false)

        return true

    end

    return false

end

function TruckingServer.GetPendingConfiguration(playerId)

    return pendingConfigurations[playerId]

end

function TruckingServer.GetActiveMission(playerId)

    return activeMissions[playerId]

end

function TruckingServer.HasActiveDelivery()

    for playerId, mission in pairs(activeMissions) do

        if mission and mission.active then

            return true

        end

    end

    return false

end

function TruckingServer.IsOrderBeingDelivered(orderId)

    local count = CountVehiclesInTransit(orderId)

    return count > 0, count

end

function TruckingServer.GetDeliveryInfoForOrder(orderId)

    local deliveries = {}

    for playerId, mission in pairs(activeMissions) do

        if mission and mission.active and mission.orders then

            for _, order in ipairs(mission.orders) do

                if order.orderId == orderId then

                    local pickupLocationName = (mission.pickupStop and mission.pickupStop.location and mission.pickupStop.location.name) or "Unknown"

                    table.insert(deliveries, {

                        startedAt = mission.startedAt,

                        startedByName = mission.startedByName,

                        pickupLocation = pickupLocationName,

                        quantityBeingDelivered = order.quantityToDeliver

                    })

                end

            end

        end

    end

    if #deliveries == 0 then

        return nil

    end

    table.sort(deliveries, function(a, b)

        return (a.startedAt or 0) < (b.startedAt or 0)

    end)

    local descriptions = {}

    for _, delivery in ipairs(deliveries) do

        if delivery.startedByName then

            table.insert(descriptions, string.format(

                "%dx by %s from %s",

                delivery.quantityBeingDelivered,

                delivery.startedByName,

                delivery.pickupLocation

            ))

        end

    end

    return descriptions

end

function TruckingServer.StartDeliveryMission(playerId, dealershipId, trailerType, orderIds, quantities, configHash)

    local config = pendingConfigurations[playerId]

    if not config then

        return false, "No pending configuration found. Please try again.", nil

    end

    if not VerifyConfigHash(orderIds, trailerType, configHash) then

        pendingConfigurations[playerId] = nil

        return false, "Configuration hash mismatch. Please restart the delivery process.", nil

    end

    local isValid, errorMsg = ValidatePlayerCanStartMission(playerId, dealershipId)

    if not isValid then

        pendingConfigurations[playerId] = nil

        return false, errorMsg, nil

    end

    local success, error, orders = ValidateAndPrepareOrders(orderIds, dealershipId, quantities)

    if not success or not orders then

        pendingConfigurations[playerId] = nil

        return false, error, nil

    end

    local dealershipLocation = Locations.Server.GetById(dealershipId)

    if not dealershipLocation or not dealershipLocation.trucking_vehicle_coords then

        pendingConfigurations[playerId] = nil

        return false, "[Configuration error] No trucking vehicle coordinates set", nil

    end

    occupiedPickupLocations[config.occupiedIndex] = true

    local playerName = GetPlayerName(playerId) or "Unknown"

    activeMissions[playerId] = {

        active = true,

        dealershipId = dealershipId,

        trailerType = trailerType,

        orders = orders,

        pickupStop = config.pickupStop,

        dropoffCoords = dealershipLocation.trucking_vehicle_coords,

        stage = "spawned",

        startedAt = os.time(),

        startedByName = playerName

    }

    pendingConfigurations[playerId] = nil

    return true, nil, activeMissions[playerId]

end

TruckingMission.Server = TruckingServer

lib.callback.register("jg-dealerships:server:start-trucking-mission", function(source, dealershipId, trailerType, orderIds, quantities, configHash)

    local success, error, missionData = TruckingServer.StartDeliveryMission(source, dealershipId, trailerType, orderIds, quantities, configHash)

    if success then

        return {

            success = true,

            data = missionData

        }

    else

        return {

            success = false,

            error = error

        }

    end

end)

lib.callback.register("jg-dealerships:server:complete-trucking-mission", function(source, cargoNetworkId)

    local playerId = source

    local mission = activeMissions[playerId]

    if not mission or not mission.active then

        print("^1[Trucking Mission] No active mission found for player " .. playerId .. "^0")

        return false

    end

    print("^2[Trucking Mission] Completing delivery for player " .. playerId .. "^0")

    print("^3[Trucking Mission] Cargo Network ID received: " .. tostring(cargoNetworkId) .. "^0")

    local success = TruckingServer.CompleteDelivery(playerId, cargoNetworkId)

    print("^2[Trucking Mission] Complete result: " .. tostring(success) .. "^0")

    return success

end)

lib.callback.register("jg-dealerships:server:cancel-trucking-mission", function(source)

    local playerId = source

    TruckingServer.CancelDelivery(playerId)

    return true

end)

lib.callback.register("jg-dealerships:server:set-trucking-stage", function(source, stage)

    local playerId = source

    return TruckingServer.SetMissionStage(playerId, stage)

end)

lib.callback.register("jg-dealerships:server:set-truck-entity", function(source, networkId)

    local playerId = source

    return TruckingServer.SetTruckEntity(playerId, networkId)

end)

lib.callback.register("jg-dealerships:server:set-cargo-entity", function(source, networkId)

    local playerId = source

    return TruckingServer.SetCargoEntity(playerId, networkId)

end)
