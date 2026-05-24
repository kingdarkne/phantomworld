if not TruckingMission then

    TruckingMission = {}

end

if not TruckingMission.Client then

    TruckingMission.Client = {}

end

local missionActive = false

local truckEntity = nil

local trailerEntity = nil

local cargoEntity = nil

local cargoVehicles = {}

local pickupBlip = nil

local dropoffBlip = nil

local isSpawningVehicles = false

local spawnOnClient = false

local missionData = nil

local currentStage = nil

local pickupLocation = nil

local dropoffLocation = nil

local truckNetId = nil

local trailerNetId = nil

local function CleanupTruck()

    if truckEntity and DoesEntityExist(truckEntity) then

        local plate = GetVehicleNumberPlateText(truckEntity)

        if plate then

            Framework.Client.VehicleRemoveKeys(plate, truckEntity, "truckingMission")

        end

        DeleteEntity(truckEntity)

    end

    truckEntity = nil

end

local function CleanupCargoVehicles()

    for _, vehicle in pairs(cargoVehicles) do

        if DoesEntityExist(vehicle) then

            DetachEntity(vehicle, false, false)

            DeleteEntity(vehicle)

        end

    end

    cargoVehicles = {}

    if cargoEntity and DoesEntityExist(cargoEntity) then

        DeleteEntity(cargoEntity)

    end

    cargoEntity = nil

end

local function CleanupBlips()

    if pickupBlip and DoesBlipExist(pickupBlip) then

        RemoveBlip(pickupBlip)

        pickupBlip = nil

    end

    if dropoffBlip and DoesBlipExist(dropoffBlip) then

        RemoveBlip(dropoffBlip)

        dropoffBlip = nil

    end

end

local function IsMissionVehicle(entity)

    if not entity or entity == 0 or not DoesEntityExist(entity) then

        return false

    end

    if isSpawningVehicles then

        if entity == cargoEntity then

            return true

        end

    end

    if pickupLocation then

        for _, vehicle in pairs(cargoVehicles) do

            if entity == vehicle then

                return true

            end

        end

    end

    return false

end

function TruckingMission.Client.Start(dealershipId, trailerType, orderIds, quantities, configHash)

    if missionActive then

        return false, "Mission already active"

    end

    local result = lib.callback.await(

        "jg-dealerships:server:start-trucking-mission",

        false,

        dealershipId,

        trailerType,

        orderIds,

        quantities,

        configHash

    )

    if not result or not result.success then

        return false, result.error or "Failed to start mission"

    end

    missionData = result.data

    missionActive = true

    currentStage = "spawned"

    if missionData.pickupStop then

        pickupLocation = missionData.pickupStop.location

    end

    if missionData.dropoffCoords then

        dropoffLocation = missionData.dropoffCoords

    end

    if pickupLocation and pickupLocation.coords then

        local blipConfig = TruckingConfig.Blips.pickup

        pickupBlip = AddBlipForCoord(pickupLocation.coords.x, pickupLocation.coords.y, pickupLocation.coords.z)

        SetBlipSprite(pickupBlip, blipConfig.sprite)

        SetBlipColour(pickupBlip, blipConfig.color)

        SetBlipScale(pickupBlip, blipConfig.scale)

        SetBlipRoute(pickupBlip, false)
        BeginTextCommandSetBlipName("STRING")

        AddTextComponentSubstringPlayerName(blipConfig.label)

        EndTextCommandSetBlipName(pickupBlip)

    end

    if missionData.dropoffCoords then

        CreateThread(function()

            local spawnCoords = missionData.dropoffCoords

            local truckModel = GetHashKey(TruckingConfig.TruckModel or "hauler")

            lib.requestModel(truckModel, 10000)

            local truck = CreateVehicle(truckModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w or 0.0, true, false)

            SetVehicleOnGroundProperly(truck)

            SetEntityAsMissionEntity(truck, true, true)

            SetVehicleHasBeenOwnedByPlayer(truck, true)

            local plate = GetVehicleNumberPlateText(truck)

            Framework.Client.VehicleGiveKeys(plate, truck, "truckingMission")

            truckEntity = truck

            truckNetId = NetworkGetNetworkIdFromEntity(truck)

            lib.callback.await("jg-dealerships:server:set-truck-entity", false, truckNetId)

            SetModelAsNoLongerNeeded(truckModel)

            if not dropoffBlip then

                local blipConfig = TruckingConfig.Blips.spawn

                dropoffBlip = AddBlipForCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z)

                SetBlipSprite(dropoffBlip, blipConfig.sprite)

                SetBlipColour(dropoffBlip, blipConfig.color)

                SetBlipScale(dropoffBlip, blipConfig.scale)

                SetBlipRoute(dropoffBlip, true)

                BeginTextCommandSetBlipName("STRING")

                AddTextComponentSubstringPlayerName(blipConfig.label)

                EndTextCommandSetBlipName(dropoffBlip)

            end

            CreateThread(function()

                while missionActive and currentStage == "spawned" and DoesEntityExist(truck) do

                    Wait(0)

                    local truckCoords = GetEntityCoords(truck)

                    local markerConfig = TruckingConfig.Markers.spawn

                    DrawMarker(

                        markerConfig.type,

                        truckCoords.x, truckCoords.y, truckCoords.z + 2.0,

                        0.0, 0.0, 0.0,

                        0.0, 0.0, 0.0,

                        markerConfig.size, markerConfig.size, markerConfig.size,

                        markerConfig.color.r, markerConfig.color.g, markerConfig.color.b, markerConfig.color.a,

                        markerConfig.bobUpAndDown,

                        markerConfig.faceCamera,

                        2,

                        markerConfig.rotate,

                        nil,

                        nil,

                        false

                    )

                end

            end)

            Interactions.Client.InstrPrmt.Show(

                "Get in the truck at the marked location to start your delivery",

                {

                    {key = "E", desc = "Dismiss"}

                },

                ""

            )

            CreateThread(function()

                while missionActive and currentStage == "spawned" do

                    Wait(100)

                    local ped = PlayerPedId()

                    local vehicle = GetVehiclePedIsIn(ped, false)

                    if IsControlJustPressed(0, 38) then
                        Interactions.Client.InstrPrmt.Hide()

                    end

                    if vehicle and vehicle == truck and GetPedInVehicleSeat(truck, -1) == ped then

                        Interactions.Client.InstrPrmt.Hide()

                        currentStage = "driving_to_pickup"

                        Wait(100)
                        if dropoffBlip and DoesBlipExist(dropoffBlip) then

                            RemoveBlip(dropoffBlip)

                            dropoffBlip = nil

                        end

                        Framework.Client.Notify("Drive to the pickup location to collect the trailer", "info")

                        Interactions.Client.InstrPrmt.Show(

                            "Drive to the pickup location to collect the trailer",

                            {

                                {key = "E", desc = "Dismiss"}

                            },

                            ""

                        )

                        if pickupBlip and DoesBlipExist(pickupBlip) then

                            SetBlipRoute(pickupBlip, true)

                            SetBlipRouteColour(pickupBlip, 5)

                        end

                        TruckingMission.Client.StartPickupCheck()

                        break

                    end

                end

            end)

        end)

    end

    return true, "Mission started successfully"

end

function TruckingMission.Client.Complete()

    if not missionActive then

        return false

    end

    local result = lib.callback.await("jg-dealerships:server:complete-trucking-mission", false, trailerNetId)

    CleanupTruck()

    CleanupCargoVehicles()

    CleanupBlips()

    missionActive = false

    missionData = nil

    currentStage = nil

    pickupLocation = nil

    dropoffLocation = nil

    return result or false

end

function TruckingMission.Client.Cancel()

    if not missionActive then

        return false

    end

    lib.callback.await("jg-dealerships:server:cancel-trucking-mission", false)

    CleanupTruck()

    CleanupCargoVehicles()

    CleanupBlips()

    missionActive = false

    missionData = nil

    currentStage = nil

    pickupLocation = nil

    dropoffLocation = nil

    return true

end

function TruckingMission.Client.GetStatus()

    return {

        active = missionActive,

        stage = currentStage,

        data = missionData

    }

end

function TruckingMission.Client.SetTruck(networkId)

    if not networkId then

        return false

    end

    local entity = NetworkGetEntityFromNetworkId(networkId)

    if entity and entity ~= 0 then

        truckEntity = entity

        truckNetId = networkId

        return true

    end

    return false

end

function TruckingMission.Client.SetTrailer(networkId)

    if not networkId then

        return false

    end

    local entity = NetworkGetEntityFromNetworkId(networkId)

    if entity and entity ~= 0 then

        trailerEntity = entity

        trailerNetId = networkId

        return true

    end

    return false

end

function TruckingMission.Client.StartPickupCheck()

    if not pickupLocation or not pickupLocation.coords then

        return

    end

    local trailerSpawned = false

    local dismissKeyPressed = false

    CreateThread(function()

        while missionActive and currentStage == "driving_to_pickup" do

            Wait(0)

            if IsControlJustPressed(0, 38) then
                Interactions.Client.InstrPrmt.Hide()

                dismissKeyPressed = true

                break

            end

        end

    end)

    CreateThread(function()

        while missionActive and currentStage == "driving_to_pickup" do

            Wait(1000)

            local ped = PlayerPedId()

            local vehicle = GetVehiclePedIsIn(ped, false)

            if vehicle == truckEntity then

                local truckCoords = GetEntityCoords(truckEntity)

                local pickupCoords = pickupLocation.coords

                local distance = #(truckCoords - vector3(pickupCoords.x, pickupCoords.y, pickupCoords.z))

                if distance < 200.0 and not trailerSpawned then

                    trailerSpawned = true

                    currentStage = "at_pickup"

                    Interactions.Client.InstrPrmt.Hide()

                    CreateThread(function()

                        local trailerModel = GetHashKey(missionData.trailerType == "small" and TruckingConfig.TrailerSmallVehicle or TruckingConfig.TrailerLargeVehicle)

                        lib.requestModel(trailerModel, 10000)

                        local groundZ = pickupCoords.z

                        local foundGround, zCoord = GetGroundZFor_3dCoord(pickupCoords.x, pickupCoords.y, pickupCoords.z + 100.0, false)

                        if foundGround then

                            groundZ = zCoord

                        end

                        local trailer = CreateVehicle(trailerModel, pickupCoords.x, pickupCoords.y, groundZ + 1.0, pickupCoords.w or 0.0, true, false)

                        Wait(100)
                        SetVehicleOnGroundProperly(trailer)

                        SetEntityAsMissionEntity(trailer, true, true)

                        trailerEntity = trailer

                        trailerNetId = NetworkGetNetworkIdFromEntity(trailer)

                        lib.callback.await("jg-dealerships:server:set-cargo-entity", false, trailerNetId)

                        SetModelAsNoLongerNeeded(trailerModel)

                        if missionData.pickupStop and missionData.pickupStop.vehicles then

                            isSpawningVehicles = true

                            cargoVehicles = {}

                            print("^2[Trucking Mission] Spawning " .. #missionData.pickupStop.vehicles .. " vehicles on trailer^0")

                            for idx, veh in ipairs(missionData.pickupStop.vehicles) do

                                print("^3[Trucking Mission] Vehicle " .. idx .. ": " .. veh.model .. " (Order ID: " .. veh.orderId .. ")^0")

                            end

                            local trailerCoords = GetEntityCoords(trailer)

                            local trailerHeading = GetEntityHeading(trailer)

                            local trailerForward = GetEntityForwardVector(trailer)

                            local tr2Positions = {

                                {x = 0.0, y = 4.2, z = 0.7},
                                {x = 0.0, y = -3.8, z = 0.9},
                                {x = 0.0, y = 4.2, z = 2.8},
                                {x = 0.0, y = -3.6, z = 3.0},
                            }

                            for i, vehicleData in ipairs(missionData.pickupStop.vehicles) do

                                if i > 4 then

                                    print("^1[Trucking Mission] Warning: TR2 trailer can only hold 4 vehicles, skipping vehicle " .. i .. "^0")

                                    break

                                end

                                local vehicleModel = GetHashKey(vehicleData.model)

                                lib.requestModel(vehicleModel, 10000)

                                local position = tr2Positions[i]

                                local vehicle = CreateVehicle(vehicleModel, trailerCoords.x, trailerCoords.y, trailerCoords.z + 2.0, trailerHeading, true, false)

                                Wait(50)
                                SetEntityAsMissionEntity(vehicle, true, true)

                                SetVehicleEngineOn(vehicle, false, true, true)

                                SetVehicleDoorsLocked(vehicle, 2)
                                AttachEntityToEntity(

                                    vehicle,
                                    trailer,
                                    0,
                                    position.x,
                                    position.y,
                                    position.z,
                                    0.0,
                                    0.0,
                                    0.0,
                                    false,
                                    false,
                                    true,
                                    false,
                                    2,
                                    true
                                )

                                SetEntityInvincible(vehicle, true)

                                SetVehicleUndriveable(vehicle, true)

                                FreezeEntityPosition(vehicle, false)
                                print("^2[Trucking Mission] Attached vehicle " .. i .. " (" .. vehicleData.model .. ") at position: x=" .. position.x .. ", y=" .. position.y .. ", z=" .. position.z .. "^0")

                                table.insert(cargoVehicles, vehicle)

                                SetModelAsNoLongerNeeded(vehicleModel)

                            end

                            isSpawningVehicles = false

                        end

                        Interactions.Client.InstrPrmt.Show(

                            "Drive under the trailer to attach it",

                            {

                                {key = "E", desc = "Dismiss"}

                            },

                            ""

                        )

                        currentStage = "attaching_trailer"

                        TruckingMission.Client.StartTrailerAttachCheck()

                    end)

                    break

                end

                if distance < 50.0 then

                    local markerConfig = TruckingConfig.Markers.pickup

                    DrawMarker(

                        markerConfig.type,

                        pickupCoords.x, pickupCoords.y, pickupCoords.z - 1.0,

                        0.0, 0.0, 0.0,

                        0.0, 0.0, 0.0,

                        markerConfig.size, markerConfig.size, markerConfig.size,

                        markerConfig.color.r, markerConfig.color.g, markerConfig.color.b, markerConfig.color.a,

                        markerConfig.bobUpAndDown,

                        markerConfig.faceCamera,

                        2,

                        markerConfig.rotate,

                        nil,

                        nil,

                        false

                    )

                end

            end

        end

    end)

end

function TruckingMission.Client.StartTrailerAttachCheck()

    if not trailerEntity then

        return

    end

    local attachPromptShown = true

    local dismissKeyPressed = false

    CreateThread(function()

        while missionActive and currentStage == "attaching_trailer" do

            Wait(0)

            if IsControlJustPressed(0, 38) then
                Interactions.Client.InstrPrmt.Hide()

                dismissKeyPressed = true

                attachPromptShown = false

                break

            end

        end

    end)

    CreateThread(function()

        while missionActive and currentStage == "attaching_trailer" do

            Wait(500)

            local ped = PlayerPedId()

            local vehicle = GetVehiclePedIsIn(ped, false)

            if vehicle == truckEntity then

                local isAttached = IsVehicleAttachedToTrailer(truckEntity)

                print("^3[Trucking Mission Debug] Checking attachment... IsAttached: " .. tostring(isAttached) .. " | Truck: " .. tostring(truckEntity) .. " | Trailer: " .. tostring(trailerEntity) .. "^0")

                if isAttached then

                    print("^2[Trucking Mission] TRAILER ATTACHED! Transitioning to dropoff stage...^0")

                    Interactions.Client.InstrPrmt.Hide()

                    currentStage = "driving_to_dropoff"

                    if pickupBlip and DoesBlipExist(pickupBlip) then

                        print("^2[Trucking Mission] Removing pickup blip^0")

                        RemoveBlip(pickupBlip)

                        pickupBlip = nil

                    else

                        print("^1[Trucking Mission] Pickup blip already removed or doesn't exist^0")

                    end

                    Wait(100)

                    Interactions.Client.InstrPrmt.Show(

                        "Drive to the delivery location",

                        {

                            {key = "E", desc = "Dismiss"}

                        },

                        ""

                    )

                    print("^2[Trucking Mission] Calling SetStage with dropoff location: " .. tostring(dropoffLocation) .. "^0")

                    if dropoffLocation then

                        print("^2[Trucking Mission] Dropoff coords: " .. dropoffLocation.x .. ", " .. dropoffLocation.y .. ", " .. dropoffLocation.z .. "^0")

                    end

                    TruckingMission.Client.SetStage("driving_to_dropoff")

                    TruckingMission.Client.StartDropoffCheck()

                    break

                end

            end

        end

    end)

end

function TruckingMission.Client.StartDropoffCheck()

    if not dropoffLocation then

        return

    end

    local dismissKeyPressed = false

    local atDropoffPromptShown = false

    CreateThread(function()

        while missionActive and currentStage == "driving_to_dropoff" do

            Wait(0)

            if IsControlJustPressed(0, 38) and not atDropoffPromptShown then
                Interactions.Client.InstrPrmt.Hide()

                dismissKeyPressed = true

                break

            end

        end

    end)

    CreateThread(function()

        while missionActive and (currentStage == "driving_to_dropoff" or currentStage == "at_dropoff") do

            Wait(0)

            local ped = PlayerPedId()

            local vehicle = GetVehiclePedIsIn(ped, false)

            if vehicle == truckEntity then

                local truckCoords = GetEntityCoords(truckEntity)

                local dropoffCoords = dropoffLocation

                local distance = #(truckCoords - vector3(dropoffCoords.x, dropoffCoords.y, dropoffCoords.z))

                if distance < 50.0 then

                    local markerConfig = TruckingConfig.Markers.dropoff or TruckingConfig.Markers.pickup

                    DrawMarker(

                        markerConfig.type,

                        dropoffCoords.x, dropoffCoords.y, dropoffCoords.z - 1.0,

                        0.0, 0.0, 0.0,

                        0.0, 0.0, 0.0,

                        markerConfig.size, markerConfig.size, markerConfig.size,

                        markerConfig.color.r, markerConfig.color.g, markerConfig.color.b, markerConfig.color.a,

                        markerConfig.bobUpAndDown,

                        markerConfig.faceCamera,

                        2,

                        markerConfig.rotate,

                        nil,

                        nil,

                        false

                    )

                    if distance < 10.0 then

                        if not atDropoffPromptShown then

                            print("^2[Trucking Mission] Arrived at dropoff! Distance: " .. distance .. "^0")

                            Interactions.Client.InstrPrmt.Hide()

                            Interactions.Client.InstrPrmt.Show(

                                "Complete the delivery",

                                {

                                    {key = "E", desc = "Deliver Cargo"}

                                },

                                ""

                            )

                            atDropoffPromptShown = true

                            currentStage = "at_dropoff"

                            lib.callback.await("jg-dealerships:server:set-trucking-stage", false, "at_dropoff")

                        end

                        if IsControlJustPressed(0, 38) then
                            print("^3[Trucking Mission Debug] E key pressed at dropoff!^0")

                            if trailerEntity and DoesEntityExist(trailerEntity) then

                                local isAttached = IsVehicleAttachedToTrailer(truckEntity)

                                print("^3[Trucking Mission Debug] E pressed at dropoff. IsAttached: " .. tostring(isAttached) .. "^0")

                                if not isAttached then

                                    Framework.Client.Notify("You need to attach the trailer to complete the delivery!", "error")

                                else

                                    Interactions.Client.InstrPrmt.Hide()

                                    print("^2[Trucking Mission] Completing delivery...^0")

                                    print("^3[Trucking Mission Debug] trailerNetId value: " .. tostring(trailerNetId) .. "^0")

                                    print("^3[Trucking Mission Debug] trailerEntity value: " .. tostring(trailerEntity) .. "^0")

                                    Framework.Client.Notify("Completing delivery...", "info")

                                    local success = TruckingMission.Client.Complete()

                                    print("^2[Trucking Mission] Complete result: " .. tostring(success) .. "^0")

                                    if success then

                                        Framework.Client.Notify("Delivery completed successfully!", "success")

                                    else

                                        Framework.Client.Notify("Failed to complete delivery", "error")

                                    end

                                end

                            else

                                Framework.Client.Notify("Trailer not found!", "error")

                            end

                        end

                    end

                end

            end

        end

    end)

end

function TruckingMission.Client.SetStage(stage)

    currentStage = stage

    if stage == "driving_to_dropoff" then

        if dropoffLocation then

            if dropoffBlip and DoesBlipExist(dropoffBlip) then

                RemoveBlip(dropoffBlip)

                dropoffBlip = nil

            end

            local blipConfig = TruckingConfig.Blips.dropoff

            dropoffBlip = AddBlipForCoord(dropoffLocation.x, dropoffLocation.y, dropoffLocation.z)

            SetBlipSprite(dropoffBlip, blipConfig.sprite)

            SetBlipColour(dropoffBlip, blipConfig.color)

            SetBlipScale(dropoffBlip, blipConfig.scale)

            SetBlipRoute(dropoffBlip, true)

            SetBlipRouteColour(dropoffBlip, blipConfig.color)

            BeginTextCommandSetBlipName("STRING")

            AddTextComponentSubstringPlayerName(blipConfig.label)

            EndTextCommandSetBlipName(dropoffBlip)

            print("^2[Trucking Mission] Dropoff blip created at: " .. dropoffLocation.x .. ", " .. dropoffLocation.y .. ", " .. dropoffLocation.z .. "^0")

        else

            print("^1[Trucking Mission] ERROR: dropoffLocation is nil!^0")

        end

    elseif stage == "at_dropoff" then

    end

    return true

end

RegisterNUICallback("trucking:start", function(data, cb)

    local success, msg = TruckingMission.Client.Start(

        data.dealershipId,

        data.trailerType,

        data.orderIds,

        data.quantities,

        data.configHash

    )

    cb({ success = success, message = msg })

end)

RegisterNUICallback("trucking:complete", function(data, cb)

    local result = TruckingMission.Client.Complete()

    cb({ success = result })

end)

RegisterNUICallback("trucking:cancel", function(data, cb)

    local result = TruckingMission.Client.Cancel()

    cb({ success = result })

end)

AddEventHandler("onResourceStop", function(resourceName)

    if GetCurrentResourceName() == resourceName then

        if missionActive then

            TruckingMission.Client.Cancel()

        end

    end

end)

exports('IsMissionVehicle', IsMissionVehicle)
