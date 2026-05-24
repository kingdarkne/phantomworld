local testDriveSessions = {}

local directTestDriveSessions = {}

if not DirectTestDrive then

    DirectTestDrive = {}

end

if not DirectTestDrive.Server then

    DirectTestDrive.Server = {}

end

function DirectTestDrive.Server.GetActiveTestDrives(dealershipId)

    local activeTestDrives = {}

    for _, session in pairs(directTestDriveSessions) do

        if session.dealershipId == dealershipId then

            table.insert(activeTestDrives, session)

        end

    end

    return activeTestDrives

end

function DirectTestDrive.Server.GetSession(identifier)

    return directTestDriveSessions[identifier]

end

local function GetTestDriveCoords(dealership)

    if dealership.test_drive_coords then

        return dealership.test_drive_coords

    end

    if dealership.purchase_vehicle_coords then

        return dealership.purchase_vehicle_coords

    end

    return nil

end

local function DeleteTestDriveVehicle(session)

    if not session then

        return

    end

    local vehicle = session.vehicleEntity

    if not vehicle and session.vehicleNetId then

        vehicle = NetworkGetEntityFromNetworkId(session.vehicleNetId)

    end

    if not vehicle or not DoesEntityExist(vehicle) then

        return

    end

    for seatIndex = -1, 5 do

        local ped = GetPedInVehicleSeat(vehicle, seatIndex)

        if ped and ped ~= 0 then

            TaskLeaveVehicle(ped, vehicle, 0)

        end

    end

    SetTimeout(500, function()

        if DoesEntityExist(vehicle) then

            SetVehicleDoorsLocked(vehicle, 2)

            JGDeleteVehicle(vehicle)

        end

    end)

end

lib.callback.register("jg-dealerships:server:start-test-drive", function(source, dealershipId, spawnCoords, vehicleNetId, vehicleModel, vehicleLabel, plate, vehicleColor, playerCoords)

    local vehicleEntity = vehicleNetId and NetworkGetEntityFromNetworkId(vehicleNetId) or nil

    local identifier = Framework.Server.GetPlayerIdentifier(source)

    if not identifier then

        return false

    end

    if Config.SpawnVehiclesWithServerSetter then

        local spawnInsideVehicle = not Config.DoNotSpawnInsideVehicle

        local spawnProps = {

            plate = plate,

            colour = vehicleColor

        }

        vehicleNetId, vehicleEntity = Spawn.Server.Create(source, 0, vehicleModel, plate, spawnCoords, spawnInsideVehicle, spawnProps, "testDrive")

    end

    if not vehicleEntity or vehicleEntity == 0 or not vehicleNetId then

        Framework.Server.Notify(source, Locale.couldNotSpawnVehicle, "error")

        return false

    end

    local originalBucket = 0

    local useRoutingBucket = not Config.TestDriveNotInBucket

    if useRoutingBucket then

        if Config.ReturnToPreviousRoutingBucket then

            originalBucket = GetPlayerRoutingBucket(source)

        end

    end

    if useRoutingBucket then

        local bucket = math.random(100, 999)

        SetPlayerRoutingBucket(source, bucket)

        SetEntityRoutingBucket(vehicleEntity, bucket)

    end

    testDriveSessions[identifier] = {

        dealershipId = dealershipId,

        originalBucket = originalBucket,

        originalCoords = playerCoords,

        vehicleNetId = vehicleNetId,

        vehicleModel = vehicleModel,

        vehicleColour = vehicleColor

    }

    SendWebhook(source, Webhooks.TestDrive, "New Test Drive", "success", {

        {key = "Vehicle", value = vehicleLabel},

        {key = "Dealership", value = dealershipId},

        {key = "Plate", value = plate}

    })

    return true, vehicleNetId

end)

lib.callback.register("jg-dealerships:server:finish-test-drive", function(source)

    local identifier = Framework.Server.GetPlayerIdentifier(source)

    if not identifier then

        DebugPrint("jg-dealerships:server:finish-test-drive: no identifier found for player " .. source, "warning")

        return false

    end

    local session = testDriveSessions[identifier]

    if not session then

        DebugPrint("jg-dealerships:server:finish-test-drive: no test drive session found for player " .. source, "warning")

        return false

    end

    local vehicle = NetworkGetEntityFromNetworkId(session.vehicleNetId)

    SetEntityVelocity(vehicle, 0, 0, 0)

    for seatIndex = -1, 5 do

        local ped = GetPedInVehicleSeat(vehicle, seatIndex)

        if ped then

            TaskLeaveVehicle(ped, vehicle, 0)

        end

    end

    SetVehicleDoorsLocked(vehicle, 2)

    local playerPed = GetPlayerPed(source)

    local originalCoords = session.originalCoords

    JGDeleteVehicle(vehicle)

    SetEntityCoords(playerPed, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false, false)

    Wait(500)

    if not Config.TestDriveNotInBucket then

        SetPlayerRoutingBucket(source, session.originalBucket)

    end

    testDriveSessions[identifier] = nil

    return session

end)

lib.callback.register("jg-dealerships:server:start-direct-test-drive", function(source, dealershipId, customerPlayerId, vehicleModel, vehicleColor)

    local identifier = Framework.Server.GetPlayerIdentifier(source)

    if not identifier then

        return false

    end

    if not Employees.Server.IsEmployee(source, dealershipId, "SELL") then

        Framework.Server.Notify(source, Locale.employeePermissionsError, "error")

        return false

    end

    local activeCount = 0

    for _, session in pairs(directTestDriveSessions) do

        if session.dealershipId == dealershipId then

            activeCount = activeCount + 1

        end

    end

    local maxTestDrives = Config.DealershipMaxActiveTestDrives or 5

    if activeCount >= maxTestDrives then

        Framework.Server.Notify(source, Locale.maxTestDrivesReached, "error")

        return false

    end

    local dealership = Locations.Server.GetById(dealershipId)

    if not dealership then

        return false

    end

    local spawnCoords = GetTestDriveCoords(dealership)

    if not spawnCoords then

        Framework.Server.Notify(source, Locale.noTestDriveSpawnCoords, "error")

        return false

    end

    local plate = Framework.Server.VehicleGeneratePlate(Config.TestDrivePlate or "TEST0000", false)

    if not plate then

        Framework.Server.Notify(source, Locale.couldNotGeneratePlate, "error")

        return false

    end

    local vehicleLabel = vehicleModel

    if Framework.Server.GetVehicleLabel then

        vehicleLabel = Framework.Server.GetVehicleLabel(vehicleModel) or vehicleModel

    end

    local sellerInfo = Framework.Server.GetPlayerInfo(source)

    local customerInfo = Framework.Server.GetPlayerInfo(customerPlayerId)

    local sessionId = Utils.Server.GenerateUuid()

    local sessionData = {

        id = sessionId,

        dealershipId = dealershipId,

        sellerPlayerId = source,

        sellerName = (sellerInfo and sellerInfo.name) or "Unknown",

        customerPlayerId = customerPlayerId,

        customerName = (customerInfo and customerInfo.name) or "Unknown",

        vehicleModel = vehicleModel,

        vehicleLabel = vehicleLabel,

        plate = plate,

        coords = spawnCoords,

        colour = vehicleColor,

        startTime = os.time()

    }

    local vehicleNetId = nil

    local vehicleEntity = nil

    if Config.SpawnVehiclesWithServerSetter then

        local spawnProps = {

            plate = plate,

            colour = vehicleColor

        }

        vehicleNetId, vehicleEntity = Spawn.Server.Create(source, 0, vehicleModel, plate, spawnCoords, false, spawnProps, "testDrive")

        if not vehicleEntity or vehicleEntity == 0 or not vehicleNetId then

            Framework.Server.Notify(source, Locale.couldNotSpawnTestDriveVehicle, "error")

            return false

        end

        sessionData.vehicleNetId = vehicleNetId

        sessionData.vehicleEntity = vehicleEntity

    end

    directTestDriveSessions[sessionId] = sessionData

    SendWebhook(source, Webhooks.TestDrive, "New Direct Sale Test Drive", "success", {

        {key = "Vehicle", value = vehicleLabel},

        {key = "Dealership", value = dealershipId},

        {key = "Plate", value = plate},

        {key = "Customer ID", value = tostring(customerPlayerId)}

    })

    return true, spawnCoords, vehicleNetId, not Config.SpawnVehiclesWithServerSetter, sessionId, plate

end)

lib.callback.register("jg-dealerships:server:direct-test-drive-give-keys", function(source, sessionId)

    if not sessionId then

        return false

    end

    local session = directTestDriveSessions[sessionId]

    if not session then

        return false

    end

    if not session.vehicleNetId then

        return false

    end

    if session.sellerPlayerId ~= source then

        return false

    end

    TriggerClientEvent("jg-dealerships:client:direct-test-drive-receive-keys", session.customerPlayerId, session.vehicleNetId, session.plate)

    TriggerClientEvent("jg-dealerships:client:direct-test-drive-receive-keys", source, session.vehicleNetId, session.plate)

    return true

end)

lib.callback.register("jg-dealerships:server:cancel-direct-test-drive", function(source, sessionId)

    if not sessionId then

        return false

    end

    local session = directTestDriveSessions[sessionId]

    if not session then

        return false

    end

    if not Employees.Server.IsEmployee(source, session.dealershipId, "SELL") then

        return false

    end

    local plate = session.plate

    DeleteTestDriveVehicle(session)

    TriggerClientEvent("jg-dealerships:client:direct-test-drive-ended", session.customerPlayerId, plate)

    directTestDriveSessions[sessionId] = nil

    return true, plate

end)

lib.callback.register("jg-dealerships:server:direct-test-drive-set-vehicle", function(source, sessionId, vehicleNetId)

    if not sessionId then

        return false

    end

    local session = directTestDriveSessions[sessionId]

    if not session then

        return false

    end

    if session.sellerPlayerId ~= source then

        return false

    end

    if not vehicleNetId or vehicleNetId == 0 then

        return false

    end

    local vehicleEntity = NetworkGetEntityFromNetworkId(vehicleNetId)

    if not vehicleEntity or vehicleEntity == 0 then

        return false

    end

    session.vehicleNetId = vehicleNetId

    session.vehicleEntity = vehicleEntity

    return true

end)

lib.callback.register("jg-dealerships:server:get-active-test-drives", function(source, dealershipId)

    if not Employees.Server.IsEmployee(source, dealershipId, "SELL") then

        return {}

    end

    local activeTestDrives = {}

    for _, session in pairs(directTestDriveSessions) do

        if session.dealershipId == dealershipId then

            table.insert(activeTestDrives, {

                id = session.id,

                sellerPlayerId = session.sellerPlayerId,

                sellerName = session.sellerName,

                customerName = session.customerName,

                vehicleLabel = session.vehicleLabel,

                vehicleModel = session.vehicleModel,

                plate = session.plate,

                startTime = session.startTime,

                vehicleNetId = session.vehicleNetId

            })

        end

    end

    return activeTestDrives

end)

lib.callback.register("jg-dealerships:server:end-test-drive-remote", function(source, sessionId)

    if not sessionId then

        return false

    end

    local session = directTestDriveSessions[sessionId]

    if not session then

        return false

    end

    if not Employees.Server.IsEmployee(source, session.dealershipId, "SELL") then

        Framework.Server.Notify(source, Locale.employeePermissionsError, "error")

        return false

    end

    local plate = session.plate

    DeleteTestDriveVehicle(session)

    local isSellerEnding = (source == session.sellerPlayerId)

    TriggerClientEvent("jg-dealerships:client:direct-test-drive-ended-remote", session.sellerPlayerId, plate, isSellerEnding)

    TriggerClientEvent("jg-dealerships:client:direct-test-drive-ended-remote", session.customerPlayerId, plate, false)

    directTestDriveSessions[sessionId] = nil

    return true

end)

lib.callback.register("jg-dealerships:server:track-test-drive-vehicle", function(source, sessionId)

    if not sessionId then

        return false

    end

    local session = directTestDriveSessions[sessionId]

    if not session then

        return false

    end

    if not Employees.Server.IsEmployee(source, session.dealershipId, "SELL") then

        Framework.Server.Notify(source, Locale.employeePermissionsError, "error")

        return false

    end

    if not session.vehicleNetId then

        return false

    end

    local vehicle = NetworkGetEntityFromNetworkId(session.vehicleNetId)

    if not vehicle or not DoesEntityExist(vehicle) then

        return false

    end

    local coords = GetEntityCoords(vehicle)

    return true, coords

end)

lib.callback.register("jg-dealerships:server:get-test-drive-vehicle-coords", function(source, sessionId)

    if not sessionId then

        return nil

    end

    local session = directTestDriveSessions[sessionId]

    if not session then

        return nil

    end

    if not session.vehicleNetId then

        return nil

    end

    local vehicle = NetworkGetEntityFromNetworkId(session.vehicleNetId)

    if not vehicle or not DoesEntityExist(vehicle) then

        return nil

    end

    return GetEntityCoords(vehicle)

end)

lib.callback.register("jg-dealerships:server:get-direct-test-drive-status", function(source)

    for _, session in pairs(directTestDriveSessions) do

        if session.sellerPlayerId == source then

            return true, {

                id = session.id,

                dealershipId = session.dealershipId,

                customerPlayerId = session.customerPlayerId,

                vehicleNetId = session.vehicleNetId,

                vehicleModel = session.vehicleModel,

                plate = session.plate,

                coords = session.coords

            }

        end

    end

    return false

end)

RegisterNetEvent("jg-dealerships:server:exit-bucket", function()

    local src = source

    SetPlayerRoutingBucket(src, 0)

    print(string.format("Restart: emergency player %s breakout to bucket 0", src))

end)

AddEventHandler("playerDropped", function()

    local src = source

    for sessionId, session in pairs(directTestDriveSessions) do

        if session.sellerPlayerId == src then

            DeleteTestDriveVehicle(session)

            if GetPlayerPing(tostring(session.customerPlayerId)) > 0 then

                TriggerClientEvent("jg-dealerships:client:direct-test-drive-ended", session.customerPlayerId, session.plate)

            end

            directTestDriveSessions[sessionId] = nil

        end

    end

end)

AddEventHandler("onResourceStop", function(resourceName)

    if GetCurrentResourceName() ~= resourceName then

        return

    end

    for _, session in pairs(directTestDriveSessions) do

        DeleteTestDriveVehicle(session)

        if GetPlayerPing(tostring(session.sellerPlayerId)) > 0 then

            TriggerClientEvent("jg-dealerships:client:direct-test-drive-ended", session.sellerPlayerId, session.plate)

        end

        if GetPlayerPing(tostring(session.customerPlayerId)) > 0 then

            TriggerClientEvent("jg-dealerships:client:direct-test-drive-ended", session.customerPlayerId, session.plate)

        end

    end

    directTestDriveSessions = {}

end)
