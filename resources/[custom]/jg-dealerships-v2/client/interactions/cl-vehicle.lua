Interactions = Interactions or {}

Interactions.Client = Interactions.Client or {}

Interactions.Client.Vehicle = Interactions.Client.Vehicle or {}

local isPlacementActive = false

local KEY_MOVE_UP = 21
local KEY_MOVE_DOWN = 36
local KEY_MOVE_FORWARD = 32
local KEY_MOVE_BACKWARD = 33
local KEY_MOVE_LEFT = 34
local KEY_MOVE_RIGHT = 35
local KEY_ROTATE_LEFT = 241
local KEY_ROTATE_RIGHT = 242
local KEY_CONFIRM = 191
local KEY_CANCEL = 194
local MOVEMENT_DISABLED_KEYS = {30, 31, 22, 23, 140, 44, 36, 21}
local ROTATION_SPEED = 5.0

local MOVEMENT_SPEED = 0.01
local function rotateEntity(entity, currentHeading, rotationDelta)

    local newHeading = (currentHeading + rotationDelta) % 360.0

    SetEntityHeading(entity, newHeading)

    return newHeading

end

local function moveEntity(entity, direction, distance, zoneToCheck)

    local entityCoords = GetEntityCoords(entity)

    local forwardVector = GetEntityForwardVector(entity)

    local rightVector = vector3(-forwardVector.y, forwardVector.x, 0.0)

    local offsetVector = vector3(0.0, 0.0, 0.0)

    if direction == "forward" then

        offsetVector = forwardVector * distance

    elseif direction == "back" then

        offsetVector = forwardVector * -distance

    elseif direction == "right" then

        offsetVector = rightVector * distance

    elseif direction == "left" then

        offsetVector = rightVector * -distance

    elseif direction == "up" then

        offsetVector = vector3(0.0, 0.0, distance)

    elseif direction == "down" then

        offsetVector = vector3(0.0, 0.0, -distance)

    end

    local newCoords = entityCoords + offsetVector

    if zoneToCheck then

        local isInZone = DealershipZones.Client.IsPointInZone(zoneToCheck, newCoords.x, newCoords.y)

        if not isInZone then

            return

        end

    end

    SetEntityCoordsNoOffset(entity, newCoords.x, newCoords.y, newCoords.z, false, false, false)

end

function Interactions.Client.Vehicle.Spawn(coords, model, options)

    options = options or {}

    local colour = options.colour or 0

    local hasCollision = (options.collision ~= nil) and options.collision or true

    local alpha = options.alpha or 255

    local isFrozen = (options.frozen ~= nil) and options.frozen or true

    local isInvincible = (options.invincible ~= nil) and options.invincible or true

    local hasGravity = (options.gravity ~= nil) and options.gravity or false

    local isUndriveable = (options.undriveable ~= nil) and options.undriveable or true

    local isLocked = (options.locked ~= nil) and options.locked or true

    lib.requestModel(model)

    local vehicle = CreateVehicle(

        joaat(model),

        coords.x, coords.y, coords.z,

        coords.w or 0.0,

        true,

        false

    )

    while not DoesEntityExist(vehicle) do

        Wait(0)

    end

    RequestCollisionAtCoord(coords.x, coords.y, coords.z)

    local waitAttempts = 0

    while not HasCollisionLoadedAroundEntity(vehicle) and waitAttempts < 50 do

        RequestCollisionAtCoord(coords.x, coords.y, coords.z)

        Wait(100)

        waitAttempts = waitAttempts + 1

    end

    local minDim, maxDim = GetModelDimensions(GetEntityModel(vehicle))

    local bottomOffset = math.abs(minDim.z)

    local rayHandle = StartShapeTestRay(

        coords.x, coords.y, coords.z + 3.0,

        coords.x, coords.y, coords.z - 3.0,

        1 | 16,
        vehicle,

        7

    )

    local _, hit, hitCoords = GetShapeTestResult(rayHandle)

    if hit and hitCoords and hitCoords.z then

        SetEntityCoordsNoOffset(vehicle, coords.x, coords.y, hitCoords.z + bottomOffset, false, false, false)

    else

        SetVehicleOnGroundProperly(vehicle)

    end

    SetEntityAsMissionEntity(vehicle, true, true)

    SetEntityCollision(vehicle, hasCollision, hasCollision)

    SetEntityAlpha(vehicle, alpha, false)

    FreezeEntityPosition(vehicle, isFrozen)

    SetEntityInvincible(vehicle, isInvincible)

    SetEntityHasGravity(vehicle, hasGravity)

    if isUndriveable then

        SetVehicleUndriveable(vehicle, true)

    end

    if isLocked then

        SetVehicleDoorsLocked(vehicle, 2)

    end

    if colour and type(colour) == "table" and colour.r then

        SetVehicleCustomPrimaryColour(vehicle, colour.r, colour.g, colour.b)

        SetVehicleCustomSecondaryColour(vehicle, colour.r, colour.g, colour.b)

    end

    if options.enableStreaming then

        SetVehicleIsStolen(vehicle, false)

        SetVehicleHasBeenOwnedByPlayer(vehicle, true)

    end

    return {

        entity = vehicle,

        model = model,

        coords = coords,

        options = options

    }

end

function Interactions.Client.Vehicle.StartCreator(model, colour)

    model = model or "adder"

    colour = colour or {r = 0, g = 0, b = 0}

    local placementPromise = promise.new()

    CreateThread(function()

        local waitingForPosition = true

        local userCancelled = false

        Interactions.Client.InstrPrmt.Show(

            "Position yourself where you want to spawn the vehicle",

            {

                {key = "Enter", desc = "Spawn Preview"},

                {key = "ESC", desc = "Cancel"}

            }

        )

        while waitingForPosition do

            Wait(0)

            if IsControlJustPressed(0, KEY_CONFIRM) then

                waitingForPosition = false

            end

            if IsControlJustPressed(0, 200) then
                userCancelled = true

                waitingForPosition = false

            end

        end

        Interactions.Client.InstrPrmt.Hide()

        if userCancelled then

            placementPromise:resolve(nil)

            return

        end

        local playerPed = PlayerPedId()

        local playerCoords = GetEntityCoords(playerPed)

        local playerHeading = GetEntityHeading(playerPed)

        local forwardVector = GetEntityForwardVector(playerPed)

        local spawnOffset = 3.0

        local spawnCoords = vector4(

            playerCoords.x + forwardVector.x * spawnOffset,

            playerCoords.y + forwardVector.y * spawnOffset,

            playerCoords.z,

            playerHeading

        )

        local previewVehicle = Interactions.Client.Vehicle.Spawn(spawnCoords, model, {

            colour = colour,

            collision = true,

            alpha = 200,

            frozen = true,

            invincible = true,

            gravity = false,

            undriveable = true,

            locked = true

        }).entity

        local currentHeading = playerHeading

        local hasCollision = false

        local isConfirmed = false

        local isCancelled = false

        isPlacementActive = true

        Interactions.Client.InstrPrmt.Show(

            "Fine-tune vehicle position",

            {

                {key = "WASD", desc = "Move"},

                {key = "Shift/Ctrl", desc = "Up/Down"},

                {key = "Scroll Wheel", desc = "Rotate"},

                {key = "Enter", desc = "Confirm"},

                {key = "Backspace", desc = "Cancel"}

            },

            "",

            nil

        )

        local lastCollisionState = false

        while isPlacementActive do

            Wait(0)

            for _, key in ipairs(MOVEMENT_DISABLED_KEYS) do

                DisableControlAction(0, key, true)

            end

            if IsControlJustReleased(0, KEY_ROTATE_LEFT) then

                currentHeading = rotateEntity(previewVehicle, currentHeading, ROTATION_SPEED)

            elseif IsControlJustReleased(0, KEY_ROTATE_RIGHT) then

                currentHeading = rotateEntity(previewVehicle, currentHeading, -ROTATION_SPEED)

            end

            if IsDisabledControlPressed(0, KEY_MOVE_UP) then

                moveEntity(previewVehicle, "up", MOVEMENT_SPEED)

            elseif IsDisabledControlPressed(0, KEY_MOVE_DOWN) then

                moveEntity(previewVehicle, "down", MOVEMENT_SPEED)

            end

            if IsControlPressed(0, KEY_MOVE_FORWARD) then

                moveEntity(previewVehicle, "forward", MOVEMENT_SPEED)

            elseif IsControlPressed(0, KEY_MOVE_BACKWARD) then

                moveEntity(previewVehicle, "back", MOVEMENT_SPEED)

            elseif IsControlPressed(0, KEY_MOVE_LEFT) then

                moveEntity(previewVehicle, "left", MOVEMENT_SPEED)

            elseif IsControlPressed(0, KEY_MOVE_RIGHT) then

                moveEntity(previewVehicle, "right", MOVEMENT_SPEED)

            end

            hasCollision = false

            local vehCoords = GetEntityCoords(previewVehicle)

            local minDim, maxDim = GetModelDimensions(GetEntityModel(previewVehicle))

            SetEntityCollision(previewVehicle, false, false)

            local forwardVector = GetEntityForwardVector(previewVehicle)

            local heading = GetEntityHeading(previewVehicle)

            local nearbyVehicles = GetGamePool('CVehicle')

            for _, vehicle in ipairs(nearbyVehicles) do

                if vehicle ~= previewVehicle and DoesEntityExist(vehicle) then

                    if IsEntityTouchingEntity(previewVehicle, vehicle) then

                        hasCollision = true

                        break

                    end

                    local otherCoords = GetEntityCoords(vehicle)

                    local otherMinDim, otherMaxDim = GetModelDimensions(GetEntityModel(vehicle))

                    local dx = math.abs(vehCoords.x - otherCoords.x)

                    local dy = math.abs(vehCoords.y - otherCoords.y)

                    local dz = math.abs(vehCoords.z - otherCoords.z)

                    local xOverlap = dx < ((maxDim.x - minDim.x) + (otherMaxDim.x - otherMinDim.x)) / 2.0 + 0.3

                    local yOverlap = dy < ((maxDim.y - minDim.y) + (otherMaxDim.y - otherMinDim.y)) / 2.0 + 0.3

                    local zOverlap = dz < ((maxDim.z - minDim.z) + (otherMaxDim.z - otherMinDim.z)) / 2.0 + 0.3

                    if xOverlap and yOverlap and zOverlap then

                        hasCollision = true

                        break

                    end

                end

            end

            if not hasCollision then

                local nearbyObjects = GetGamePool('CObject')

                for _, object in ipairs(nearbyObjects) do

                    if DoesEntityExist(object) then

                        if IsEntityTouchingEntity(previewVehicle, object) then

                            hasCollision = true

                            break

                        end

                        local otherCoords = GetEntityCoords(object)

                        local otherMinDim, otherMaxDim = GetModelDimensions(GetEntityModel(object))

                        local dx = math.abs(vehCoords.x - otherCoords.x)

                        local dy = math.abs(vehCoords.y - otherCoords.y)

                        local dz = math.abs(vehCoords.z - otherCoords.z)

                        local xOverlap = dx < ((maxDim.x - minDim.x) + (otherMaxDim.x - otherMinDim.x)) / 2.0 + 0.2

                        local yOverlap = dy < ((maxDim.y - minDim.y) + (otherMaxDim.y - otherMinDim.y)) / 2.0 + 0.2

                        local zOverlap = dz < ((maxDim.z - minDim.z) + (otherMaxDim.z - otherMinDim.z)) / 2.0 + 0.2

                        if xOverlap and yOverlap and zOverlap then

                            hasCollision = true

                            break

                        end

                    end

                end

            end

            SetEntityCollision(previewVehicle, true, true)

            if hasCollision ~= lastCollisionState then

                lastCollisionState = hasCollision

                Interactions.Client.InstrPrmt.Show(

                    "Fine-tune vehicle position",

                    {

                        {key = "WASD", desc = "Move"},

                        {key = "Shift/Ctrl", desc = "Up/Down"},

                        {key = "Scroll Wheel", desc = "Rotate"},

                        {key = "Enter", desc = "Confirm"},

                        {key = "Backspace", desc = "Cancel"}

                    },

                    "",

                    hasCollision and "Warning: Collision detected! Press ENTER to ignore and place anyway." or nil

                )

            end

            if hasCollision then

                SetEntityDrawOutline(previewVehicle, true)

                SetEntityDrawOutlineColor(255, 0, 0, 255)

                SetEntityDrawOutlineShader(1)

            else

                SetEntityDrawOutline(previewVehicle, true)

                SetEntityDrawOutlineColor(0, 255, 0, 255)

                SetEntityDrawOutlineShader(1)

            end

            if IsControlJustPressed(0, KEY_CONFIRM) then

                isConfirmed = true

                isPlacementActive = false

            end

            if IsControlJustPressed(0, KEY_CANCEL) then

                isCancelled = true

                isPlacementActive = false

            end

        end

        local finalCoords = GetEntityCoords(previewVehicle)

        SetEntityDrawOutline(previewVehicle, false)

        if isConfirmed then

            if hasCollision then

                DebugPrint("[VehiclePlacer] Placed with collision warning at vector4(%.2f, %.2f, %.2f, %.2f)",

                    finalCoords.x, finalCoords.y, finalCoords.z, currentHeading)

            else

                DebugPrint("[VehiclePlacer Saved] vector4(%.2f, %.2f, %.2f, %.2f)",

                    finalCoords.x, finalCoords.y, finalCoords.z, currentHeading)

            end

            placementPromise:resolve({

                x = finalCoords.x,

                y = finalCoords.y,

                z = finalCoords.z,

                w = currentHeading

            })

        else

            placementPromise:resolve(nil)

        end

        DeleteEntity(previewVehicle)

        Interactions.Client.InstrPrmt.Hide()

    end)

    return Citizen.Await(placementPromise)

end

RegisterNUICallback("interactions-vehicle-placer", function(data, cb)

    local model = (data and data.vehModel) or "adder"

    local colour = (data and data.vehColour) or {r = 0, g = 0, b = 0}

    SetNuiFocus(false, false)

    local result = Interactions.Client.Vehicle.StartCreator(model, colour)

    cb(result)

    SetNuiFocus(true, true)

end)

function Interactions.Client.Vehicle.Create(coords, model, colour, label, key, onInteract, canInteract)

    model = model or "adder"

    colour = colour or {r = 0, g = 0, b = 0}

    local vehicleData = Interactions.Client.Vehicle.Spawn(coords, model, {

        colour = colour,

        collision = true,

        frozen = true,

        invincible = true,

        gravity = false,

        undriveable = true,

        locked = true,

        enableStreaming = true

    })

    vehicleData.interactionData = {

        label = label,

        key = key,

        onInteract = onInteract,

        distance = 3.0,

        canInteract = canInteract

    }

    if vehicleData.entity and vehicleData.entity ~= 0 and DoesEntityExist(vehicleData.entity) then

        vehicleData.activeInteraction = Interactions.Client.Handler.AddEntityInteraction(

            vehicleData.entity,

            "vehicle",

            label,

            key,

            onInteract,

            3.0,

            canInteract

        )

    end

    return vehicleData

end
