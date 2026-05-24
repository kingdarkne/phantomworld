if not Showroom then

    Showroom = {}

end

if not Showroom.Client then

    Showroom.Client = {}

end

local ROTATION_SPEED = 0.4

local currentDealershipId = nil

local interiorId = nil

local locationData = nil

local camera = nil

local showroomVehicle = nil

local vehicleHeading = 120.0

local baseHeading = 120.0

local colorIndex = 1

local zoomLevel = 1

local isLoadingVehicle = false

local autoRotateEnabled = false

local currentRotation = 0

local function SetVehicleColor(colorData)

    if not showroomVehicle then

        return false

    end

    colorIndex = colorData

    Utils.Client.SetVehicleColourNew(showroomVehicle, colorData)

    return true

end

local function SpawnShowroomVehicle(vehicleModel)

    if not currentDealershipId or not camera then

        return false

    end

    if isLoadingVehicle then

        return false

    end

    isLoadingVehicle = true

    local cameraCoords = locationData.camera_data.coords

    if showroomVehicle then

        DeleteEntity(showroomVehicle)

    end

    local modelHash = ConvertModelToHash(vehicleModel)

    if not IsModelValid(modelHash) then

        DebugPrint("Vehicle does not exist. Please contact an admin! Vehicle: " .. modelHash .. " returned false with IsModelValid", "warning")

        Framework.Client.Notify(Locale.vehicleDoesNotExistContactAdmin, "error")

        isLoadingVehicle = false

        return false

    end

    lib.requestModel(modelHash, 60000)

    showroomVehicle = CreateVehicle(

        modelHash,

        cameraCoords.x + 0.0,

        cameraCoords.y + 0.0,

        cameraCoords.z + 0.0,

        vehicleHeading,

        false,

        false

    )

    SetModelAsNoLongerNeeded(modelHash)

    SetEntityHeading(showroomVehicle, vehicleHeading)

    FreezeEntityPosition(showroomVehicle, true)

    SetEntityCollision(showroomVehicle, false, true)

    SetVehicleDirtLevel(showroomVehicle, 0.0)

    SetVehicleColor(colorIndex)

    local vehicleCoords = GetEntityCoords(showroomVehicle)

    PointCamAtCoord(camera, vehicleCoords.x + 0.0, vehicleCoords.y + 0.0, vehicleCoords.z + 0.0)

    RenderScriptCams(true, true, 1, true, true)

    isLoadingVehicle = false

    return true

end

local function RotateVehicle(rotationAmount)

    if not showroomVehicle then

        return false

    end

    local currentHeading = GetEntityHeading(showroomVehicle)

    vehicleHeading = currentHeading + rotationAmount

    SetEntityHeading(showroomVehicle, vehicleHeading)

    return true

end

local function ChangeCameraZoom()

    if not currentDealershipId or not camera then

        return false

    end

    local zoomLevels = locationData.camera_data.zoomLevels

    local cameraCoords = locationData.camera_data.coords

    zoomLevel = zoomLevel + 1

    if zoomLevel > 4 then

        zoomLevel = 1

    end

    local distance = zoomLevels[zoomLevel]

    local angleRad = math.rad(cameraCoords.w)

    local offsetX = distance * math.sin(angleRad)

    local offsetY = distance * math.cos(angleRad)

    SetCamCoord(

        camera,

        cameraCoords.x + offsetX,

        cameraCoords.y - offsetY,

        cameraCoords.z + (zoomLevels[zoomLevel] / 10) + 1

    )

    return true

end

function Showroom.Client.Open(dealershipId, defaultVehicle, defaultColor)

    if currentDealershipId or Globals.IsTestDriving then

        return false

    end

    currentDealershipId = dealershipId

    if showroomVehicle and DoesEntityExist(showroomVehicle) then

        DeleteEntity(showroomVehicle)

        showroomVehicle = nil

    end

    local playerPed = cache.ped

    local playerCoords = GetEntityCoords(playerPed)

    if IsPedInAnyVehicle(playerPed, true) then

        currentDealershipId = nil

        Framework.Client.Notify(Locale.errorExitVehicle, "error")

        return false

    end

    if not ShowroomPreCheck(dealershipId) then

        DebugPrint("jg-dealerships:client:showroom-pre-check failed", "debug")

        currentDealershipId = nil

        return false

    end

    DoScreenFadeOut(500)

    Wait(500)

    PlayTabletAnim()

    local result = lib.callback.await("jg-dealerships:server:enter-showroom", false, dealershipId, playerCoords)

    if not result then

        currentDealershipId = nil

        DoScreenFadeIn(0)

        return false

    end

    locationData = result.locationData

    local vehicles = result.vehicles

    local financeAllowed = result.financeAllowed

    local societies = result.societies

    local cameraCoords = locationData.camera_data.coords

    local zoomLevels = locationData.camera_data.zoomLevels or {5, 8, 12, 8}

    local interior = GetInteriorAtCoords(cameraCoords.x, cameraCoords.y, cameraCoords.z)

    if interior > 0 then

        PinInteriorInMemory(interior)

        lib.waitFor(function()

            return IsInteriorReady(interior)

        end, nil, 5000)

        interiorId = interior

    end

    local angleRad = math.rad(cameraCoords.w)

    local distance = zoomLevels[1]

    local offsetX = distance * math.sin(angleRad)

    local offsetY = distance * math.cos(angleRad)

    vehicleHeading = cameraCoords.w + 215.0

    baseHeading = vehicleHeading

    camera = CreateCamWithParams(

        "DEFAULT_SCRIPTED_CAMERA",

        cameraCoords.x + offsetX + 0.0,

        cameraCoords.y - offsetY + 0.0,

        cameraCoords.z + 1.5,

        0.0,

        0.0,

        cameraCoords.w + 0.0,

        0.0,

        false,

        0

    )

    SetCamActive(camera, true)

    SetCamFov(camera, 60.0)

    PointCamAtCoord(camera, cameraCoords.x + 0.0, cameraCoords.y + 0.0, cameraCoords.z + 0.0)

    RenderScriptCams(true, true, 1, true, true)

    SetFocusPosAndVel(cameraCoords.x + 0.0, cameraCoords.y + 0.0, cameraCoords.z + 0.0, 0.0, 0.0, 0.0)

    local currencies = lib.callback.await("jg-dealerships:server:get-currencies", false)

    Framework.Client.ToggleHud(false)

    DoScreenFadeIn(500)

    SetNuiFocus(true, true)

    SendNUIMessage({

        type = "showShowroom",

        dealershipId = dealershipId,

        label = locationData.name,

        shopType = locationData.type,

        vehicles = vehicles,

        defaultVehicle = defaultVehicle or false,

        defaultColor = defaultColor,

        colourSelectionType = locationData.colour_selection_type,

        colourOptions = locationData.colour_options,

        categories = locationData.categories,

        playerBalances = GetPlayerBalances(dealershipId),

        paymentMethods = locationData.payment_methods or {"bank", "cash"},

        currencies = currencies,

        societies = societies,

        jgGaragesRunning = GetResourceState("jg-advancedgarages") == "started",

        enablePurchase = locationData.enable_purchase,

        enableTestDrive = locationData.enable_test_drive,

        financeEnabled = locationData.enable_finance and financeAllowed,

        locale = Locale,

        config = Config

    })

    return true

end

function Showroom.Client.Exit()

    if not currentDealershipId then

        return

    end

    local dealershipIdToRefresh = currentDealershipId

    local result = lib.callback.await("jg-dealerships:server:exit-showroom", false, currentDealershipId)

    if not result then

        DebugPrint("jg-dealerships:server:exit-showroom failed", "warning")

        return

    end

    StopTabletAnim()

    Framework.Client.ToggleHud(true)

    if showroomVehicle then

        DeleteEntity(showroomVehicle)

        showroomVehicle = nil

    end

    if camera then

        if IsCamActive(camera) then

            RenderScriptCams(false, false, 0, true, false)

            DestroyCam(camera, true)

        end

    end

    ClearFocus()

    if interiorId then

        UnpinInterior(interiorId)

    end

    camera = nil

    vehicleHeading = 120.0

    colorIndex = 1

    interiorId = nil

    currentDealershipId = nil

    SetTimeout(100, function()

        if Locations and Locations.Client and Locations.Client.RefreshLocationInteractions then

            Locations.Client.RefreshLocationInteractions(dealershipIdToRefresh)

        end

    end)

end

RegisterNUICallback("exit-showroom", function(data, cb)

    DoScreenFadeOut(500)

    Wait(500)

    Showroom.Client.Exit()

    DoScreenFadeIn(500)

    cb(true)

end)

RegisterNUICallback("change-color", function(data, cb)

    SetVehicleColor(data)

    cb(true)

end)

RegisterNUICallback("switch-vehicle", function(data, cb)

    if not SpawnShowroomVehicle(data.spawnCode) then

        return cb({ error = true })

    end

    cb(true)

end)

RegisterNUICallback("veh-left", function(data, cb)

    if not showroomVehicle then

        return cb({ error = true })

    end

    autoRotateEnabled = false

    currentRotation = currentRotation - 10

    if currentRotation < 0 then

        currentRotation = 360 + currentRotation

    end

    vehicleHeading = baseHeading + currentRotation

    SetEntityHeading(showroomVehicle, vehicleHeading)

    cb({ rotation = currentRotation })

end)

RegisterNUICallback("veh-right", function(data, cb)

    if not showroomVehicle then

        return cb({ error = true })

    end

    autoRotateEnabled = false

    currentRotation = currentRotation + 10

    if currentRotation > 360 then

        currentRotation = currentRotation - 360

    end

    vehicleHeading = baseHeading + currentRotation

    SetEntityHeading(showroomVehicle, vehicleHeading)

    cb({ rotation = currentRotation })

end)

RegisterNUICallback("veh-rotate", function(data, cb)

    if not showroomVehicle then

        return cb({ error = true })

    end

    autoRotateEnabled = false

    currentRotation = tonumber(data.rotation) or 0

    vehicleHeading = baseHeading + currentRotation

    SetEntityHeading(showroomVehicle, vehicleHeading)

    cb({ rotation = currentRotation })

end)

RegisterNUICallback("veh-auto-rotate", function(data, cb)

    if not showroomVehicle then

        return cb({ error = true })

    end

    autoRotateEnabled = data.enabled == true

    if autoRotateEnabled then

        CreateThread(function()

            while autoRotateEnabled and showroomVehicle do

                currentRotation = currentRotation + ROTATION_SPEED

                if currentRotation > 360 then

                    currentRotation = currentRotation - 360

                end

                vehicleHeading = baseHeading + currentRotation

                SetEntityHeading(showroomVehicle, vehicleHeading)

                Wait(10)

            end

        end)

    end

    cb({ enabled = autoRotateEnabled, rotation = currentRotation })

end)

RegisterNUICallback("change-cam-view", function(data, cb)

    if not ChangeCameraZoom() then

        return cb({ error = true })

    end

    cb(true)

end)

RegisterNUICallback("get-model-stats", function(data, cb)

    if Config.HideVehicleStats then

        return cb({})

    end

    cb(Framework.Client.GetVehicleStats(data.vehicle))

end)

AddEventHandler("onResourceStop", function(resourceName)

    if GetCurrentResourceName() == resourceName then

        if currentDealershipId then

            if showroomVehicle then

                DeleteEntity(showroomVehicle)

            end

            Framework.Client.ToggleHud(true)

        end

    end

end)
