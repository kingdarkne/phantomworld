local isTestDriving = false

local currentDealership = nil

local testDriveVehicle = nil

local function EndTestDrive()

    if not isTestDriving or not testDriveVehicle or not currentDealership then

        return false

    end

    isTestDriving = false

    DoScreenFadeOut(500)

    Wait(500)

    local vehiclePlate = Framework.Client.GetPlate(testDriveVehicle)

    if vehiclePlate then

        Framework.Client.VehicleRemoveKeys(vehiclePlate, testDriveVehicle, "testDrive")

    end

    local result = lib.callback.await("jg-dealerships:server:finish-test-drive", false)

    Showroom.Client.Open(currentDealership.id, result.vehicleModel, result.vehicleColour)

    currentDealership = nil

    testDriveVehicle = nil

end

local function MonitorTestDrive()

    CreateThread(function()

        while isTestDriving do

            if not cache.vehicle then

                EndTestDrive()

            end

            SetPlayerCanDoDriveBy(cache.ped, false)

            DisablePlayerFiring(cache.ped, true)

            DisableControlAction(0, 140, true)

            Wait(0)

        end

    end)

end

local function StartTestDrive(dealershipId, vehicleModel, vehicleColor)

    local dealership = Locations.Client.GetLocationById(dealershipId)

    currentDealership = dealership

    if not dealership then

        return false

    end

    if not dealership.enable_test_drive or not dealership.test_drive_coords then

        return false

    end

    local spawnCoords = Utils.Client.ConvertToVec4(dealership.test_drive_coords)

    if not spawnCoords then

        return false

    end

    local playerCoords = GetEntityCoords(cache.ped)

    local vehicleLabel = Framework.Client.GetVehicleLabel(vehicleModel)

    local plate = lib.callback.await("jg-dealerships:server:vehicle-generate-plate", false, Config.TestDrivePlate, false)

    spawnCoords = Utils.Client.FindAvailableSpawnCoords(spawnCoords)

    Showroom.Client.Exit()

    local vehicle = nil

    local vehicleNetId = nil

    local success = false

    if not Config.SpawnVehiclesWithServerSetter then

        local spawnProps = {

            plate = plate,

            colour = vehicleColor

        }

        vehicle = Spawn.Client.Create(0, vehicleModel, plate, spawnCoords, true, spawnProps, "testDrive")

        if not vehicle then

            return false

        end

        vehicleNetId = VehToNet(vehicle)

    end

    local serverResult, serverNetId = lib.callback.await(

        "jg-dealerships:server:start-test-drive",

        false,

        dealershipId,

        spawnCoords,

        vehicleNetId,

        vehicleModel,

        vehicleLabel,

        plate,

        vehicleColor,

        playerCoords

    )

    vehicleNetId = serverNetId

    success = serverResult

    if vehicleNetId then

        local netVeh = NetToVeh(vehicleNetId)

        if netVeh then

            vehicle = netVeh

        end

    end

    if not success then

        if vehicle then

            JGDeleteVehicle(vehicle)

        end

        return false

    end

    if Config.SpawnVehiclesWithServerSetter and not vehicle then

        print("^1[ERROR] There was a problem spawning in your vehicle")

        return false

    end

    isTestDriving = true

    testDriveVehicle = vehicle

    SetNuiFocus(false, false)

    SendNUIMessage({

        type = "testDriveHud",

        time = Config.TestDriveTimeSeconds or 60,

        locale = Locale,

        config = Config

    })

    TriggerEvent("jg-dealerships:client:start-test-drive:config", vehicle, Framework.Client.GetPlate(vehicle))

    DoScreenFadeIn(500)

    CreateThread(function()

        Wait(2500)

        MonitorTestDrive()

    end)

    return true

end

RegisterNUICallback("finish-test-drive", function(data, cb)

    EndTestDrive()

    cb(true)

end)

RegisterNUICallback("start-test-drive", function(data, cb)

    DoScreenFadeOut(500)

    Wait(500)

    local started = StartTestDrive(data.dealershipId, data.vehicle, data.color)

    if not started then

        DoScreenFadeIn(0)

        return cb({ error = true })

    end

    cb(true)

end)

AddEventHandler("onResourceStop", function(resourceName)

    if GetCurrentResourceName() == resourceName then

        if isTestDriving then

            TriggerServerEvent("jg-dealerships:server:exit-bucket")

            if cache.vehicle then

                DeleteEntity(cache.vehicle)

            end

        end

    end

end)
