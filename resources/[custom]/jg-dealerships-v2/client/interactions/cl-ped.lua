Interactions = Interactions or {}

Interactions.Client = Interactions.Client or {}

Interactions.Client.Ped = Interactions.Client.Ped or {}

local isPlacingPed = false

local KEY_MOUSE_SCROLL_UP = 241
local KEY_MOUSE_SCROLL_DOWN = 242
local KEY_W = 32
local KEY_S = 33
local KEY_A = 34
local KEY_D = 35
local KEY_SHIFT = 21
local KEY_CTRL = 36
local KEY_ENTER = 191
local KEY_BACKSPACE = 194
local ROTATION_KEYS = {30, 31, 22, 23, 140, 44, 36, 21}
local function rotateEntityHeading(entity, currentHeading, deltaHeading)

    local newHeading = (currentHeading + deltaHeading) % 360.0

    SetEntityHeading(entity, newHeading)

    return newHeading

end

local function moveEntity(entity, direction, distance)

    local coords = GetEntityCoords(entity)

    local forward = GetEntityForwardVector(entity)

    local right = vector3(-forward.y, forward.x, 0.0)

    local offset = vector3(0.0, 0.0, 0.0)

    if direction == "forward" then

        offset = forward * distance

    elseif direction == "back" then

        offset = forward * (-distance)

    elseif direction == "right" then

        offset = right * distance

    elseif direction == "left" then

        offset = right * (-distance)

    elseif direction == "up" then

        offset = vector3(0.0, 0.0, distance)

    elseif direction == "down" then

        offset = vector3(0.0, 0.0, -distance)

    end

    local newCoords = coords + offset

    SetEntityCoordsNoOffset(entity, newCoords.x, newCoords.y, newCoords.z, false, false, false)

end

function Interactions.Client.Ped.Spawn(coords, model, scenario, options)

    options = options or {}

    local hasCollision = options.collision ~= false
    local alpha = options.alpha or 255

    local frozen = options.frozen ~= false
    local invincible = options.invincible ~= false
    local blocking = options.blocking ~= false
    local useGroundZ = options.useGroundZ == true
    local spawnZ = coords.z

    if useGroundZ then

        local interiorId = GetInteriorAtCoords(coords.x, coords.y, coords.z)

        local isInInterior = interiorId ~= 0

        if not isInInterior then

            local foundGround, groundZCoord = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 50.0, false)

            if foundGround then

                spawnZ = groundZCoord

            end

        end

    end

    local function spawnPed()

        lib.requestModel(model)

        local ped = CreatePed(

            4,

            joaat(model),

            coords.x, coords.y, spawnZ,

            coords.w or 0.0,

            false,

            false

        )

        local timeout = GetGameTimer() + 5000

        while not DoesEntityExist(ped) and GetGameTimer() < timeout do

            Wait(0)

        end

        if not DoesEntityExist(ped) then

            return nil

        end

        SetEntityAsMissionEntity(ped, true, true)

        SetBlockingOfNonTemporaryEvents(ped, blocking)

        if useGroundZ then

            local pedInteriorId = GetInteriorAtCoords(coords.x, coords.y, coords.z)

            local pedIsInInterior = pedInteriorId ~= 0

            if not pedIsInInterior then

                Wait(50)

                PlaceObjectOnGroundProperly(ped)

                Wait(50)

            end

        end

        if options.alpha and alpha ~= 255 then

            SetEntityAlpha(ped, alpha, false)

        end

        SetEntityCollision(ped, hasCollision, hasCollision)

        FreezeEntityPosition(ped, frozen)

        SetEntityInvincible(ped, invincible)

        if scenario and scenario ~= "" then

            TaskStartScenarioInPlace(ped, scenario, 0, true)

        end

        if options.enableStreaming then

            pcall(function()

                SetEntityDistanceCullingRadius(ped, 20000.0)

            end)

        end

        return ped

    end

    local ped = spawnPed()

    if not ped then

        return {

            success = false,

            entity = nil

        }

    end

    return {

        success = true,

        entity = ped,

        model = model,

        scenario = scenario,

        coords = coords

    }

end

function Interactions.Client.Ped.SpawnPreview(coords, model, scenario)

    return Interactions.Client.Ped.Spawn(

        coords,

        model,

        scenario,

        {

            collision = true,

            alpha = 200,

            frozen = true,

            invincible = true,

            blocking = true

        }

    )

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

function Interactions.Client.Ped.StartCreator(model, scenario, options)

    local playerPed = PlayerPedId()

    local playerCoords = GetEntityCoords(playerPed)

    local playerHeading = GetEntityHeading(playerPed)

    local forward = GetEntityForwardVector(playerPed)

    local spawnX = playerCoords.x + forward.x * 3.0

    local spawnY = playerCoords.y + forward.y * 3.0

    RequestCollisionAtCoord(spawnX, spawnY, playerCoords.z)

    local waitAttempts = 0

    while not HasCollisionLoadedAroundEntity(playerPed) and waitAttempts < 30 do

        RequestCollisionAtCoord(spawnX, spawnY, playerCoords.z)

        Wait(100)

        waitAttempts = waitAttempts + 1

    end

    local rayHandle = StartShapeTestRay(

        spawnX, spawnY, playerCoords.z + 1.0,
        spawnX, spawnY, playerCoords.z - 3.0,
        1,
        playerPed,

        7

    )

    local _, hit, hitCoords = GetShapeTestResult(rayHandle)

    local groundZ = (hit and hitCoords and hitCoords.z) and hitCoords.z or playerCoords.z

    local spawnCoords = vector4(spawnX, spawnY, groundZ, playerHeading)

    local pedData = Interactions.Client.Ped.Spawn(

        spawnCoords,

        model,

        scenario,

        {

            collision = true,

            alpha = 200,

            frozen = true,

            invincible = true,

            blocking = true,

            useGroundZ = false
        }

    )

    if not pedData.success then

        return nil

    end

    local previewPed = pedData.entity

    FreezeEntityPosition(previewPed, true)

    local currentHeading = playerHeading

    local rotationSpeed = 5.0
    local moveSpeed = 0.025

    local verticalMoveSpeed = 0.01
    local verticalDelta = 0.0

    local promise = promise.new()

    isPlacingPed = true

    Interactions.Client.InstrPrmt.Show(

        "Fine-tune ped position",

        {

            {key = "WASD", desc = "Move"},

            {key = "Shift/Ctrl", desc = "Up/Down"},

            {key = "Scroll Wheel", desc = "Rotate"},

            {key = "Enter", desc = "Confirm"},

            {key = "Backspace", desc = "Cancel"}

        }

    )

    CreateThread(function()

        while isPlacingPed do

            Wait(0)

            for _, key in ipairs(ROTATION_KEYS) do

                DisableControlAction(0, key, true)

            end

            if IsControlPressed(0, KEY_W) then

                moveEntity(previewPed, "forward", moveSpeed)

            end

            if IsControlPressed(0, KEY_S) then

                moveEntity(previewPed, "back", moveSpeed)

            end

            if IsControlPressed(0, KEY_A) then

                moveEntity(previewPed, "left", moveSpeed)

            end

            if IsControlPressed(0, KEY_D) then

                moveEntity(previewPed, "right", moveSpeed)

            end

            if IsDisabledControlPressed(0, KEY_SHIFT) then

                moveEntity(previewPed, "up", verticalMoveSpeed)

                verticalDelta = verticalDelta + verticalMoveSpeed

            end

            if IsDisabledControlPressed(0, KEY_CTRL) then

                moveEntity(previewPed, "down", verticalMoveSpeed)

                verticalDelta = verticalDelta - verticalMoveSpeed

            end

            if IsControlJustReleased(0, KEY_MOUSE_SCROLL_UP) then

                currentHeading = rotateEntityHeading(previewPed, currentHeading, rotationSpeed)

            end

            if IsControlJustReleased(0, KEY_MOUSE_SCROLL_DOWN) then

                currentHeading = rotateEntityHeading(previewPed, currentHeading, -rotationSpeed)

            end

            local pedCoords = GetEntityCoords(previewPed)

            Utils.Client.DrawMarkerOnFrame(

                20,
                vec3(pedCoords.x, pedCoords.y, pedCoords.z + 1.2),

                0.5,

                {r = 106, g = 226, b = 119, a = 0.7843137254901961},

                vec3(180, 0, 0)

            )

            if IsControlJustReleased(0, KEY_ENTER) then

                local finalCoords = GetEntityCoords(previewPed)

                local finalZ = groundZ + verticalDelta

                local scenarioText = scenario and (" | scenario: " .. scenario) or ""

                DebugPrint(string.format(

                    "[PedPlacer Saved] vector4(%.2f, %.2f, %.2f, %.2f)%s",

                    finalCoords.x, finalCoords.y, finalZ, currentHeading, scenarioText

                ))

                DeletePed(previewPed)

                Interactions.Client.InstrPrmt.Hide()

                isPlacingPed = false

                promise:resolve({

                    x = finalCoords.x,

                    y = finalCoords.y,

                    z = finalZ,

                    w = currentHeading

                })

                break

            end

            if IsControlJustReleased(0, KEY_BACKSPACE) then

                DeletePed(previewPed)

                Interactions.Client.InstrPrmt.Hide()

                isPlacingPed = false

                promise:resolve(nil)

                break

            end

        end

    end)

    return Citizen.Await(promise)

end

RegisterNUICallback("interactions-ped-placer", function(data, cb)

    local model = data.pedModel

    local scenario = data.pedScenario

    SetNuiFocus(false, false)

    cb(Interactions.Client.Ped.StartCreator(model, scenario))

    SetNuiFocus(true, true)

end)

function Interactions.Client.Ped.Create(coords, model, scenario, label, key, onInteract, canInteract)

    local pedData = Interactions.Client.Ped.Spawn(

        coords,

        model,

        scenario,

        {

            collision = true,

            frozen = true,

            invincible = true,

            blocking = true,

            enableStreaming = true,

            useGroundZ = false
        }

    )

    pedData.interactionData = {

        label = label,

        key = key,

        onInteract = onInteract,

        distance = 2.5,

        canInteract = canInteract

    }

    if pedData.entity and pedData.entity ~= 0 and DoesEntityExist(pedData.entity) then

        pedData.activeInteraction = Interactions.Client.Handler.AddEntityInteraction(

            pedData.entity,

            "ped",

            label,

            key,

            onInteract,

            2.5,

            canInteract

        )

    end

    return pedData

end
