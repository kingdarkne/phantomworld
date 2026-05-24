Interactions = Interactions or {}

Interactions.Client = Interactions.Client or {}

Interactions.Client.Object = Interactions.Client.Object or {}

local isPlacementActive = false

local ROTATION_SPEED_FAST = 5.0
local ROTATION_SPEED_SLOW = 5.0
local MOVEMENT_SPEED_HORIZONTAL = 0.01

local MOVEMENT_SPEED_VERTICAL = 0.01
local KEY_MOVE_UP = 21
local KEY_MOVE_DOWN = 36
local KEY_MOVE_FORWARD = 32
local KEY_MOVE_BACKWARD = 33
local KEY_MOVE_LEFT = 34
local KEY_MOVE_RIGHT = 35
local KEY_ROTATE_LEFT = 241
local KEY_ROTATE_RIGHT = 242
local KEY_SNAP_GROUND = 47
local KEY_CONFIRM = 191
local KEY_CANCEL = 194
local MOVEMENT_DISABLED_KEYS = {30, 31, 44, 22, 23, 140}

local function rotateEntity(entity, currentHeading, rotationDelta)

    local newHeading = (currentHeading + rotationDelta) % 360.0

    SetEntityHeading(entity, newHeading)

    return newHeading

end

local function moveEntity(entity, direction, distance)

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

    SetEntityCoordsNoOffset(entity, newCoords.x, newCoords.y, newCoords.z, false, false, false)

end

local function snapToGround(object)

    local objectCoords = GetEntityCoords(object)

    local testHeight = objectCoords.z + 10.0

    local foundGround, groundZ = GetGroundZFor_3dCoord(objectCoords.x, objectCoords.y, testHeight, false)

    if foundGround then

        local modelHash = GetEntityModel(object)

        local minDim, maxDim = GetModelDimensions(modelHash)

        return vector3(objectCoords.x, objectCoords.y, groundZ - minDim.z)

    end

    local rayHandle = StartShapeTestRay(

        objectCoords.x, objectCoords.y, objectCoords.z + 10.0,

        objectCoords.x, objectCoords.y, objectCoords.z - 100.0,

        -1,
        object,
        7

    )

    local _, hit, hitCoords = GetShapeTestResult(rayHandle)

    if hit then

        local modelHash = GetEntityModel(object)

        local minDim, maxDim = GetModelDimensions(modelHash)

        return vector3(hitCoords.x, hitCoords.y, hitCoords.z - minDim.z)

    end

    local _, groundZ2 = GetGroundZFor_3dCoord(objectCoords.x, objectCoords.y, objectCoords.z + 1000.0, false)

    if groundZ2 then

        return vector3(objectCoords.x, objectCoords.y, groundZ2)

    end

    return nil

end

function Interactions.Client.Object.Spawn(coords, model, options)

    options = options or {}

    local hasCollision = (options.collision ~= nil) and options.collision or true

    local alpha = options.alpha or 255

    local isFrozen = (options.frozen ~= nil) and options.frozen or true

    local isInvincible = (options.invincible ~= nil) and options.invincible or true

    lib.requestModel(model)

    local object = CreateObject(

        joaat(model),

        coords.x, coords.y, coords.z,

        true,

        false,

        false

    )

    local timeout = GetGameTimer() + 5000

    while not DoesEntityExist(object) do

        if GetGameTimer() > timeout then

            break

        end

        Wait(0)

    end

    if not DoesEntityExist(object) then

        return nil

    end

    SetEntityAsMissionEntity(object, true, true)

    SetEntityHeading(object, coords.w or 0.0)

    SetEntityCollision(object, hasCollision, hasCollision)

    SetEntityAlpha(object, alpha, false)

    FreezeEntityPosition(object, isFrozen)

    SetEntityInvincible(object, isInvincible)

    if options.enableStreaming then

        SetEntityAsNoLongerNeeded(object)

    end

    return {

        entity = object,

        model = model,

        coords = coords,

        options = options

    }

end

function Interactions.Client.Object.SpawnPreview(coords, model)

    return Interactions.Client.Object.Spawn(coords, model, {

        collision = true,

        alpha = 200,

        frozen = true,

        invincible = true

    })

end

local function getGroundZByRaycast(x, y, z)

    local rayHandle = StartShapeTestRay(

        x, y, z + 5.0,

        x, y, z - 100.0,

        1,

        -1,

        7

    )

    local _, hit, hitCoords = GetShapeTestResult(rayHandle)

    if hit and hitCoords then

        return hitCoords.z

    end

    return z
end

function Interactions.Client.Object.StartCreator(model)

    model = model or "prop_barrel_01a"

    local placementPromise = promise.new()

    CreateThread(function()

        local playerPed = PlayerPedId()

        local playerCoords = GetEntityCoords(playerPed)

        local spawnX = playerCoords.x

        local spawnY = playerCoords.y + 2.0

        local groundZ = getGroundZByRaycast(spawnX, spawnY, playerCoords.z)

        local spawnCoords = vector4(spawnX, spawnY, groundZ, 0.0)

        local previewObject = Interactions.Client.Object.Spawn(spawnCoords, model, {

            collision = true,

            alpha = 200,

            frozen = true,

            invincible = true

        }).entity

        if not previewObject or not DoesEntityExist(previewObject) then

            placementPromise:resolve(nil)

            return

        end

        local currentHeading = 0.0

        local isConfirmed = false

        local isCancelled = false

        isPlacementActive = true

        Interactions.Client.InstrPrmt.Show(

            "Fine-tune object position",

            {

                {key = "WASD", desc = "Move"},

                {key = "Scroll", desc = "Rotate"},

                {key = "Shift/Ctrl", desc = "Up/Down"},

                {key = "G", desc = "Snap to Ground"},

                {key = "Enter", desc = "Confirm"},

                {key = "Backspace", desc = "Cancel"}

            },

            "Position Object"

        )

        while isPlacementActive do

            Wait(0)

            for _, key in ipairs(MOVEMENT_DISABLED_KEYS) do

                DisableControlAction(0, key, true)

            end

            if IsControlJustReleased(0, KEY_ROTATE_LEFT) then

                currentHeading = rotateEntity(previewObject, currentHeading, -ROTATION_SPEED_SLOW)

            elseif IsControlJustReleased(0, KEY_ROTATE_RIGHT) then

                currentHeading = rotateEntity(previewObject, currentHeading, ROTATION_SPEED_SLOW)

            end

            if IsControlPressed(0, KEY_MOVE_FORWARD) then

                moveEntity(previewObject, "forward", MOVEMENT_SPEED_HORIZONTAL)

            elseif IsControlPressed(0, KEY_MOVE_BACKWARD) then

                moveEntity(previewObject, "back", MOVEMENT_SPEED_HORIZONTAL)

            end

            if IsControlPressed(0, KEY_MOVE_LEFT) then

                moveEntity(previewObject, "left", MOVEMENT_SPEED_HORIZONTAL)

            elseif IsControlPressed(0, KEY_MOVE_RIGHT) then

                moveEntity(previewObject, "right", MOVEMENT_SPEED_HORIZONTAL)

            end

            if IsControlPressed(0, KEY_MOVE_UP) then

                moveEntity(previewObject, "up", MOVEMENT_SPEED_VERTICAL)

            elseif IsControlPressed(0, KEY_MOVE_DOWN) then

                moveEntity(previewObject, "down", MOVEMENT_SPEED_VERTICAL)

            end

            if IsControlJustReleased(0, KEY_SNAP_GROUND) then

                local groundCoords = snapToGround(previewObject)

                if groundCoords then

                    SetEntityCoordsNoOffset(previewObject, groundCoords.x, groundCoords.y, groundCoords.z, false, false, false)

                    Wait(10)

                    PlaceObjectOnGroundProperly(previewObject)

                else

                    PlaceObjectOnGroundProperly(previewObject)

                end

            end

            Interactions.Client.SetEntityOutline(previewObject, 106, 226, 119, 255)

            if IsControlJustReleased(0, KEY_CONFIRM) then

                local finalCoords = GetEntityCoords(previewObject)

                local finalHeading = GetEntityHeading(previewObject)

                DebugPrint(

                    "[ObjectPlacer Saved] vector4(%.2f, %.2f, %.2f, %.2f)",

                    finalCoords.x, finalCoords.y, finalCoords.z,

                    finalHeading

                )

                DeleteEntity(previewObject)

                Interactions.Client.InstrPrmt.Hide()

                placementPromise:resolve({

                    x = finalCoords.x,

                    y = finalCoords.y,

                    z = finalCoords.z,

                    w = finalHeading

                })

                isPlacementActive = false

            end

            if IsControlJustReleased(0, KEY_CANCEL) then

                DeleteEntity(previewObject)

                Interactions.Client.InstrPrmt.Hide()

                placementPromise:resolve(nil)

                isPlacementActive = false

            end

        end

    end)

    return Citizen.Await(placementPromise)

end

RegisterNUICallback("interactions-object-placer", function(data, cb)

    SetNuiFocus(false, false)

    local result = Interactions.Client.Object.StartCreator(data)

    cb(result)

    SetNuiFocus(true, true)

end)

function Interactions.Client.Object.Create(coords, model, label, key, onInteract, canInteract)

    local objectData = Interactions.Client.Object.Spawn(coords, model, {

        collision = true,

        frozen = true,

        invincible = true,

        enableStreaming = false

    })

    objectData.interactionData = {

        label = label,

        key = key,

        onInteract = onInteract,

        distance = 2.5,

        canInteract = canInteract

    }

    if objectData.entity and objectData.entity ~= 0 and DoesEntityExist(objectData.entity) then

        objectData.activeInteraction = Interactions.Client.Handler.AddEntityInteraction(

            objectData.entity,

            "object",

            label,

            key,

            onInteract,

            2.5,

            canInteract

        )

    end

    return objectData

end
