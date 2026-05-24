Interactions = Interactions or {}

Interactions.Client = Interactions.Client or {}

Interactions.Client.Point = Interactions.Client.Point or {}

local KEY_MOVE_UP = 200

local KEY_MOVE_DOWN = 201

local KEY_MOVE_FORWARD = 181

local KEY_MOVE_BACKWARD = 180

local KEY_ROTATE_LEFT = 32

local KEY_ROTATE_RIGHT = 33

local KEY_MOVE_LEFT = 34

local KEY_MOVE_RIGHT = 35

local KEY_CONFIRM = 250

local KEY_CANCEL = 251

local MOVEMENT_DISABLED_KEYS = {30, 31, 44, 22, 23, 140}

local isCreatorActive = false

local currentRadius = 2.0

local radiusBlip = nil

local function moveCoords(coords, direction, distance)

    local playerPed = cache.ped

    local playerHeading = GetEntityHeading(playerPed)

    local headingRad = math.rad(playerHeading)

    local offsetX = 0.0

    local offsetY = 0.0

    local offsetZ = 0.0

    if direction == "forward" then

        offsetX = -math.sin(headingRad) * distance

        offsetY = math.cos(headingRad) * distance

    elseif direction == "back" then

        offsetX = math.sin(headingRad) * distance

        offsetY = -math.cos(headingRad) * distance

    elseif direction == "left" then

        offsetX = -math.cos(headingRad) * distance

        offsetY = -math.sin(headingRad) * distance

    elseif direction == "right" then

        offsetX = math.cos(headingRad) * distance

        offsetY = math.sin(headingRad) * distance

    elseif direction == "up" then

        offsetZ = distance

    elseif direction == "down" then

        offsetZ = -distance

    end

    return vec3(

        coords.x + offsetX,

        coords.y + offsetY,

        coords.z + offsetZ

    )

end

function Interactions.Client.Point.DrawVisualization(x, y, z, radius, r, g, b, a, height)

    height = height or 3.0

    local segments = 32

    for i = 1, segments do

        local angle1 = (i - 1) * (2 * math.pi / segments)

        local angle2 = i * (2 * math.pi / segments)

        local x1 = x + math.cos(angle1) * radius

        local y1 = y + math.sin(angle1) * radius

        local x2 = x + math.cos(angle2) * radius

        local y2 = y + math.sin(angle2) * radius

        DrawPoly(x, y, z, x1, y1, z, x2, y2, z, r, g, b, a)

        DrawPoly(x, y, z, x2, y2, z, x1, y1, z, r, g, b, a)

        DrawPoly(x, y, z + height, x1, y1, z + height, x2, y2, z + height, r, g, b, a)

        DrawPoly(x, y, z + height, x2, y2, z + height, x1, y1, z + height, r, g, b, a)

        DrawPoly(x1, y1, z, x2, y2, z, x1, y1, z + height, r, g, b, a)

        DrawPoly(x2, y2, z, x2, y2, z + height, x1, y1, z + height, r, g, b, a)

    end

end

function Interactions.Client.Point.CreatePreview(coords, distance, onEnter, onExit)

    CreateThread(function()

        local previewActive = true

        while previewActive do

            Wait(0)

            if coords and distance then

                local adjustedZ = coords.z - (Globals.InteractionZOffset or 0)

                Interactions.Client.Point.DrawVisualization(

                    coords.x,

                    coords.y,

                    adjustedZ,

                    distance,

                    255, 200, 0, 100,

                    3.0

                )

            end

        end

    end)

end

function Interactions.Client.Point.StartCreator()

    currentRadius = 2.0

    radiusBlip = nil

    isCreatorActive = true

    local creatorPromise = promise.new()

    CreateThread(function()

        local playerPed = cache.ped

        local playerCoords = GetEntityCoords(playerPed)

        local pointCoords = vec3(playerCoords.x, playerCoords.y, playerCoords.z)

        local movementSpeed = 0.1

        Interactions.Client.InstrPrmt.Show(

            "Point Creator",

            {

                {key = "WASD", desc = "Move"},

                {key = "Shift/Ctrl", desc = "Up/Down"},

                {key = "Scroll Wheel", desc = "Radius"},

                {key = "Enter", desc = "Confirm"},

                {key = "Backspace", desc = "Cancel"}

            },

            "Create Point"

        )

        while isCreatorActive do

            Wait(0)

            for _, key in ipairs(MOVEMENT_DISABLED_KEYS) do

                DisableControlAction(0, key, true)

            end

            DisableControlAction(0, KEY_MOVE_UP, true)

            DisableControlAction(0, KEY_MOVE_DOWN, true)

            if IsDisabledControlPressed(0, 32) then
                pointCoords = moveCoords(pointCoords, "forward", movementSpeed)

            end

            if IsDisabledControlPressed(0, 33) then
                pointCoords = moveCoords(pointCoords, "back", movementSpeed)

            end

            if IsDisabledControlPressed(0, 34) then
                pointCoords = moveCoords(pointCoords, "left", movementSpeed)

            end

            if IsDisabledControlPressed(0, 35) then
                pointCoords = moveCoords(pointCoords, "right", movementSpeed)

            end

            if IsDisabledControlPressed(0, 21) then
                pointCoords = moveCoords(pointCoords, "up", movementSpeed)

            end

            if IsDisabledControlPressed(0, 36) then
                pointCoords = moveCoords(pointCoords, "down", movementSpeed)

            end

            if IsControlJustReleased(0, 241) then
                currentRadius = math.max(0.5, currentRadius - 0.5)

            elseif IsControlJustReleased(0, 242) then
                currentRadius = currentRadius + 0.5

            end

            if not radiusBlip then

                radiusBlip = AddBlipForRadius(pointCoords.x, pointCoords.y, pointCoords.z, currentRadius)

                SetBlipColour(radiusBlip, 1)

                SetBlipAlpha(radiusBlip, 128)

                SetBlipSprite(radiusBlip, 9)

            else

                SetBlipCoords(radiusBlip, pointCoords.x, pointCoords.y, pointCoords.z)

                SetBlipScale(radiusBlip, currentRadius / 5.0)

            end

            local adjustedZ = pointCoords.z - Globals.InteractionZOffset

            Interactions.Client.Point.DrawVisualization(

                pointCoords.x,

                pointCoords.y,

                adjustedZ,

                currentRadius,

                255, 0, 0, 80,

                3.0

            )

            if IsControlJustReleased(0, 191) then
                if radiusBlip then

                    RemoveBlip(radiusBlip)

                    radiusBlip = nil

                end

                Interactions.Client.InstrPrmt.Hide()

                creatorPromise:resolve({

                    coords = {

                        x = pointCoords.x,

                        y = pointCoords.y,

                        z = pointCoords.z

                    },

                    radius = currentRadius

                })

                isCreatorActive = false

            end

            if IsControlJustReleased(0, 194) then
                if radiusBlip then

                    RemoveBlip(radiusBlip)

                    radiusBlip = nil

                end

                Interactions.Client.InstrPrmt.Hide()

                creatorPromise:resolve(nil)

                isCreatorActive = false

            end

        end

    end)

    return Citizen.Await(creatorPromise)

end

RegisterNUICallback("interactions-point-creator", function(data, cb)

    SetNuiFocus(false, false)

    local result = Interactions.Client.Point.StartCreator()

    cb(result)

    SetNuiFocus(true, true)

end)

function Interactions.Client.Point.Create(coords, distance, label, key, callback, canInteract)

    return Interactions.Client.Handler.AddPointInteraction(

        vec3(coords.x, coords.y, coords.z),

        distance,

        label,

        key,

        callback,

        nil,
        canInteract

    )

end

function Interactions.Client.Point.Remove(pointId)

    if not pointId then

        return

    end

    Interactions.Client.Handler.RemovePointInteraction(pointId)

end
