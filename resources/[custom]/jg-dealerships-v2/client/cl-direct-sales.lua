DirectSales = DirectSales or {}

DirectSales.Client = DirectSales.Client or {}

local currentDealershipId = nil
local soldVehicleBlip = nil
local testDriveBlip = nil
local activeTestDriveSessionId = nil
local isTrackingTestDrive = false
local function RemoveSoldVehicleBlip()

    if soldVehicleBlip and DoesBlipExist(soldVehicleBlip) then

        RemoveBlip(soldVehicleBlip)

        soldVehicleBlip = nil

    end

end

local function RemoveTestDriveBlip()

    if testDriveBlip and DoesBlipExist(testDriveBlip) then

        RemoveBlip(testDriveBlip)

        testDriveBlip = nil

    end

end

local function CreateSoldVehicleBlip(coords, label, timeout)

    RemoveSoldVehicleBlip()

    soldVehicleBlip = AddBlipForCoord(coords.x, coords.y, coords.z)

    SetBlipSprite(soldVehicleBlip, 225)

    SetBlipColour(soldVehicleBlip, 2)

    SetBlipScale(soldVehicleBlip, 1.0)

    SetBlipAsShortRange(soldVehicleBlip, false)

    BeginTextCommandSetBlipName("STRING")

    AddTextComponentString(label or "Sold Vehicle Location")

    EndTextCommandSetBlipName(soldVehicleBlip)

    SetBlipRoute(soldVehicleBlip, true)

    SetBlipRouteColour(soldVehicleBlip, 2)

    SetTimeout(timeout or 60000, RemoveSoldVehicleBlip)

end

local function CreateTestDriveBlip(coords)

    RemoveTestDriveBlip()

    testDriveBlip = AddBlipForCoord(coords.x, coords.y, coords.z)

    SetBlipSprite(testDriveBlip, 225)

    SetBlipColour(testDriveBlip, 2)

    SetBlipScale(testDriveBlip, 1.0)

    SetBlipAsShortRange(testDriveBlip, false)

    BeginTextCommandSetBlipName("STRING")

    AddTextComponentString("Test Drive Vehicle")

    EndTextCommandSetBlipName(testDriveBlip)

    SetBlipRoute(testDriveBlip, true)

    SetBlipRouteColour(testDriveBlip, 2)

end

local function StopTrackingTestDrive()

    isTrackingTestDrive = false

    activeTestDriveSessionId = nil

    RemoveTestDriveBlip()

end

local function StartTrackingTestDrive(sessionId)

    if not sessionId then return end

    if isTrackingTestDrive and activeTestDriveSessionId == sessionId then return end

    if isTrackingTestDrive then

        StopTrackingTestDrive()

    end

    isTrackingTestDrive = true

    activeTestDriveSessionId = sessionId

    CreateThread(function()

        while true do

            if not isTrackingTestDrive then break end

            if activeTestDriveSessionId ~= sessionId then break end

            local coords = lib.callback.await("jg-dealerships:server:get-test-drive-vehicle-coords", false, sessionId)

            if not coords then

                StopTrackingTestDrive()

                break

            end

            if testDriveBlip and DoesBlipExist(testDriveBlip) then

                SetBlipCoords(testDriveBlip, coords.x, coords.y, coords.z)

            else

                CreateTestDriveBlip(vector4(coords.x, coords.y, coords.z, 0.0))

            end

            Wait(1000)

        end

    end)

end

local function StartDirectTestDrive(data)

    local success, spawnCoords, vehicleNetId, shouldSpawnOnClient, sessionId, plate = lib.callback.await(

        "jg-dealerships:server:start-direct-test-drive", false,

        currentDealershipId, data.playerId, data.model, data.colour

    )

    if not success then return false end

    print(json.encode(spawnCoords))

    spawnCoords = Utils.Client.FindAvailableSpawnCoords(Utils.Client.ConvertToVec4(spawnCoords))

    if not plate then

        Framework.Client.Notify(Locale.couldNotGetPlateFromServer, "error")

        return false

    end

    local netId = vehicleNetId

    local vehicle = nil

    if shouldSpawnOnClient then

        local vehicleOptions = { plate = plate, colour = data.colour }

        vehicle = Spawn.Client.Create(0, data.model, plate, spawnCoords, false, vehicleOptions, "testDrive")

        if not vehicle then

            Framework.Client.Notify(Locale.couldNotSpawnTestDriveVehicle, "error")

            return false

        end

        netId = VehToNet(vehicle)

        local registered = lib.callback.await("jg-dealerships:server:direct-test-drive-set-vehicle", false, sessionId, netId)

        if not registered then

            DeleteEntity(vehicle)

            Framework.Client.Notify(Locale.couldNotRegisterTestDriveVehicle, "error")

            return false

        end

    else

        if vehicleNetId then

            vehicle = NetToVeh(vehicleNetId)

        end

    end

    activeTestDriveSessionId = sessionId

    CreateTestDriveBlip(spawnCoords)

    return true, spawnCoords, netId, sessionId

end

local function GiveTestDriveKeys()

    if not activeTestDriveSessionId then return false end

    local success = lib.callback.await("jg-dealerships:server:direct-test-drive-give-keys", false, activeTestDriveSessionId)

    return success and true or false

end

local function ShowDirectSaleRequest(uuid, dealerPlayerId, saleData)

    if not saleData or type(saleData) ~= "table" then return false end

    if LocalPlayer.state.isBusy then

        TriggerServerEvent("jg-dealerships:server:notify-other-player", dealerPlayerId, "Customer is in the showroom! Wait for them to come back, and try again", "error")

        return false

    end

    SetNuiFocus(true, true)

    SendNUIMessage({

        type            = "show-direct-sale-request",

        uuid            = uuid,

        dealerPlayerId  = dealerPlayerId,

        dealerName      = saleData.dealerName,

        dealershipId    = saleData.dealershipId,

        dealershipLabel = saleData.dealershipLabel,

        playerBalances  = GetPlayerBalances(saleData.dealershipId),

        paymentMethods  = saleData.paymentMethods or { "bank", "cash" },

        currencies      = saleData.currencies,

        vehicleLabel    = (saleData.vehicle.brand or "") .. " " .. (saleData.vehicle.model or ""),

        vehicleSpawnCode = saleData.vehicle.spawn_code,

        vehicleCategory = saleData.vehicle.category,

        vehiclePrice    = saleData.vehicle.price,

        color           = saleData.colour,

        financed        = saleData.financed,

        downPayment     = saleData.downPayment,

        noOfPayments    = saleData.noOfPayments,

        couponCode      = saleData.couponCode,

        appliedCoupon   = saleData.appliedCoupon,

        config          = Config,

        locale          = Locale,

    })

end

function DirectSales.Client.ShowDirectSaleTablet(dealershipId)

    currentDealershipId = dealershipId

    local saleData = lib.callback.await("jg-dealerships:server:get-direct-sale-data", false, dealershipId)

    if not saleData then return false end

    PlayTabletAnim()

    SetNuiFocus(true, true)

    SendNUIMessage({

        type                = "show-sales-tablet",

        dealershipId        = dealershipId,

        vehicles            = saleData.vehicles,

        nearbyPlayers       = saleData.nearbyPlayers,

        commission          = saleData.commission,

        categories          = saleData.categories,

        enableFinance       = saleData.enableFinance,

        colourSelectionType = saleData.colourSelectionType,

        colourOptions       = saleData.colourOptions,

        myPlayerId          = GetPlayerServerId(PlayerId()),

        employeeName        = saleData.employeeName,

        employeeRole        = saleData.employeeRole,

        dealershipLabel     = saleData.dealershipLabel,

        config              = Config,

        locale              = Locale,

    })

    return true

end

RegisterNUICallback("send-direct-sale-request", function(data, cb)

    local success, uuid = lib.callback.await("jg-dealerships:server:send-direct-sale-request", false, currentDealershipId, data)

    if not success then

        return cb({ error = true })

    end

    cb({ success = true, uuid = uuid })

end)

RegisterNUICallback("accept-direct-sale-request", function(data, cb)

    SetNuiFocus(false, false)

    local success = lib.callback.await(

        "jg-dealerships:server:direct-sale-request-accepted", false,

        data.uuid,

        { paymentMethod = data.paymentMethod, coords = data.coords }

    )

    if not success then

        return cb({ error = true })

    end

    cb(true)

end)

RegisterNUICallback("deny-direct-sale-request", function(data, cb)

    SetNuiFocus(false, false)

    local success = lib.callback.await("jg-dealerships:server:direct-sale-request-denied", false, data)

    if not success then

        return cb({ error = true })

    end

    cb(true)

end)

RegisterNUICallback("cancel-direct-sale-request", function(data, cb)

    local success = lib.callback.await("jg-dealerships:server:cancel-direct-sale-request", false, data)

    if not success then

        return cb({ error = true })

    end

    cb(true)

end)

RegisterNUICallback("start-direct-test-drive", function(data, cb)

    local success, coords, netId, sessionId = StartDirectTestDrive(data)

    if not success then

        return cb({ success = false })

    end

    cb({ success = true, coords = coords, netId = netId, sessionId = sessionId })

end)

RegisterNUICallback("direct-test-drive-give-keys", function(data, cb)

    local success = GiveTestDriveKeys()

    cb({ success = success and true or false })

end)

RegisterNUICallback("cancel-direct-test-drive", function(data, cb)

    if not data.sessionId then

        return cb({ success = false })

    end

    local success = lib.callback.await("jg-dealerships:server:cancel-direct-test-drive", false, data.sessionId)

    if not success then

        return cb({ success = false })

    end

    RemoveTestDriveBlip()

    if activeTestDriveSessionId == data.sessionId then

        activeTestDriveSessionId = nil

    end

    cb({ success = true })

end)

RegisterNUICallback("get-active-test-drives", function(data, cb)

    if not currentDealershipId then

        return cb({ testDrives = {} })

    end

    local testDrives = lib.callback.await("jg-dealerships:server:get-active-test-drives", false, currentDealershipId)

    cb({ testDrives = testDrives or {} })

end)

RegisterNUICallback("end-test-drive-remote", function(data, cb)

    if not data.sessionId then

        return cb({ success = false })

    end

    local success = lib.callback.await("jg-dealerships:server:end-test-drive-remote", false, data.sessionId)

    if not success then

        return cb({ success = false })

    end

    if activeTestDriveSessionId == data.sessionId then

        activeTestDriveSessionId = nil

    end

    StopTrackingTestDrive()

    cb({ success = true })

end)

RegisterNUICallback("track-test-drive-vehicle", function(data, cb)

    if not data.sessionId then

        return cb({ success = false })

    end

    StartTrackingTestDrive(data.sessionId)

    Framework.Client.Notify(Locale.trackingVehicleLocation, "success")

    cb({ success = true, sessionId = data.sessionId })

end)

RegisterNUICallback("stop-tracking-vehicle", function(data, cb)

    StopTrackingTestDrive()

    cb({ success = true })

end)

RegisterNUICallback("get-tracking-state", function(data, cb)

    cb({ isTracking = isTrackingTestDrive, sessionId = activeTestDriveSessionId })

end)

RegisterNetEvent("jg-dealerships:client:show-direct-sale-request")

AddEventHandler("jg-dealerships:client:show-direct-sale-request", function(...)

    ShowDirectSaleRequest(...)

end)

RegisterNetEvent("jg-dealerships:client:direct-sale-response")

AddEventHandler("jg-dealerships:client:direct-sale-response", function(uuid, status, vehicleCoords)

    if status == "accepted" and vehicleCoords then

        CreateSoldVehicleBlip(vehicleCoords)

    end

    SendNUIMessage({

        type         = "direct-sale-response",

        uuid         = uuid,

        status       = status,

        vehicleCoords = vehicleCoords,

    })

end)

RegisterNetEvent("jg-dealerships:client:direct-sale-cancelled")

AddEventHandler("jg-dealerships:client:direct-sale-cancelled", function()

    SetNuiFocus(false, false)

    SendNUIMessage({ type = "direct-sale-cancelled" })

    Framework.Client.Notify(Locale.directSaleCancelled, "error")

end)

RegisterNetEvent("jg-dealerships:client:direct-test-drive-receive-keys")

AddEventHandler("jg-dealerships:client:direct-test-drive-receive-keys", function(netId, plate)

    local vehicle = NetToVeh(netId)

    if not vehicle or not DoesEntityExist(vehicle) then return end

    Framework.Client.VehicleGiveKeys(plate, vehicle, "testDrive")

    Framework.Client.Notify(Locale.testDriveKeysReceived, "success")

end)

RegisterNetEvent("jg-dealerships:client:direct-test-drive-ended")

AddEventHandler("jg-dealerships:client:direct-test-drive-ended", function(plate)

    local currentVehicle = GetVehiclePedIsIn(cache.ped, false)

    if currentVehicle and currentVehicle ~= 0 then

        local currentPlate = GetVehicleNumberPlateText(currentVehicle)

        if currentPlate then

            local cleanCurrent = currentPlate:gsub("%s+", "")

            local cleanTarget  = plate:gsub("%s+", "")

            if cleanCurrent == cleanTarget then

                Framework.Client.VehicleRemoveKeys(plate, currentVehicle, "testDrive")

            end

        end

    end

    Framework.Client.Notify(Locale.testDriveEndedCustomer, "success")

end)

RegisterNetEvent("jg-dealerships:client:direct-test-drive-ended-remote")

AddEventHandler("jg-dealerships:client:direct-test-drive-ended-remote", function(plate, silentEnd)

    local currentVehicle = GetVehiclePedIsIn(cache.ped, false)

    if currentVehicle and currentVehicle ~= 0 then

        local currentPlate = GetVehicleNumberPlateText(currentVehicle)

        if currentPlate then

            local cleanCurrent = currentPlate:gsub("%s+", "")

            local cleanTarget  = plate:gsub("%s+", "")

            if cleanCurrent == cleanTarget then

                Framework.Client.VehicleRemoveKeys(plate, currentVehicle, "testDrive")

            end

        end

    end

    if not silentEnd then

        Framework.Client.Notify(Locale.testDriveEndedByEmployee, "warning")

    end

end)

lib.callback.register("jg-dealerships:client:open-direct-sale-tablet", function()

    local zone = DealershipZones.Client.GetCurrentZone()

    if not zone then

        Framework.Client.Notify(Locale.notInDealershipZone, "error")

        return false

    end

    return DirectSales.Client.ShowDirectSaleTablet(zone)

end)

AddEventHandler("onResourceStop", function(resourceName)

    if GetCurrentResourceName() == resourceName then

        StopTrackingTestDrive()

        RemoveSoldVehicleBlip()

        currentDealershipId = nil

    end

end)
