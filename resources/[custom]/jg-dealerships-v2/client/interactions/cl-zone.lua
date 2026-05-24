Interactions = Interactions or {}

Interactions.Client = Interactions.Client or {}

Interactions.Client.Zone = Interactions.Client.Zone or {}

local KEY_ADD_POINT = 38
local KEY_REMOVE_POINT = 45
local KEY_COMPLETE = 191
local KEY_CANCEL = 194
local ZONE_HEIGHT = 5.0

local isCreatorActive = false

local zonePoints = {}

local function getGroundZ(x, y, z)

    local found, groundZ = GetGroundZFor_3dCoord(x, y, z, false)

    if found then

        return groundZ

    end

    local rayHandle = StartShapeTestRay(

        x, y, z + 10.0,

        x, y, z - 100.0,

        1,
        0,
        0

    )

    local _, hit, hitCoords = GetShapeTestResult(rayHandle)

    if hit then

        return hitCoords.z

    end

    return z

end

local function addPoint()

    local playerPed = PlayerPedId()

    local playerCoords = GetEntityCoords(playerPed)

    local groundZ = getGroundZ(playerCoords.x, playerCoords.y, playerCoords.z)

    local point = {

        x = playerCoords.x,

        y = playerCoords.y,

        z = groundZ + Globals.InteractionZOffset

    }

    table.insert(zonePoints, point)

    DebugPrint(

        string.format(

            "^2[Zone Creator]^7 Point %d added at %.2f, %.2f, %.2f",

            #zonePoints,

            point.x, point.y, point.z

        )

    )

end

local function removeLastPoint()

    if #zonePoints > 0 then

        table.remove(zonePoints)

        DebugPrint(

            string.format(

                "^2[Zone Creator]^7 Point removed. Total points: %d",

                #zonePoints

            )

        )

    else

        DebugPrint("^1[Zone Creator]^7 No points to remove!")

    end

end

local function completeZone()

    if #zonePoints < 3 then

        Framework.Client.Notify(

            string.format(

                "Need at least 3 points to complete zone! (Currently have %d)",

                #zonePoints

            ),

            "error",

            5000

        )

        return nil

    end

    isCreatorActive = false

    return zonePoints

end

local function drawVerticalLine(x, y, z, height, r, g, b, a)

    DrawLine(

        x, y, z,

        x, y, z + height,

        r, g, b, a

    )

end

local function visualizeZone()

    if #zonePoints == 0 then

        return

    end

    local adjustedPoints = {}

    for _, point in ipairs(zonePoints) do

        local adjustedZ = point.z - Globals.InteractionZOffset

        table.insert(adjustedPoints, {

            x = point.x,

            y = point.y,

            z = adjustedZ

        })

    end

    for _, point in ipairs(adjustedPoints) do

        drawVerticalLine(

            point.x, point.y, point.z,

            ZONE_HEIGHT,

            255, 0, 0, 255

        )

    end

    if #adjustedPoints >= 2 then

        Interactions.Client.Zone.DrawVisualization(

            adjustedPoints,

            ZONE_HEIGHT,

            255, 0, 0, 80

        )

    end

end

function Interactions.Client.Zone.DrawVisualization(points, height, r, g, b, a)

    if #points < 2 then

        return

    end

    for i = 1, #points do

        local currentPoint = points[i]

        local nextPoint = points[(i % #points) + 1]

        DrawLine(

            currentPoint.x, currentPoint.y, currentPoint.z,

            nextPoint.x, nextPoint.y, nextPoint.z,

            r, g, b, a

        )

        DrawLine(

            currentPoint.x, currentPoint.y, currentPoint.z + height,

            nextPoint.x, nextPoint.y, nextPoint.z + height,

            r, g, b, a

        )

    end

    if #points >= 3 then

        for i = 1, #points - 2 do

            local p1 = points[1]

            local p2 = points[i + 1]

            local p3 = points[i + 2]

            DrawPoly(

                p1.x, p1.y, p1.z,

                p2.x, p2.y, p2.z,

                p3.x, p3.y, p3.z,

                r, g, b, a

            )

        end

        for i = 1, #points - 2 do

            local p1 = points[1]

            local p2 = points[i + 1]

            local p3 = points[i + 2]

            DrawPoly(

                p1.x, p1.y, p1.z + height,

                p3.x, p3.y, p3.z + height,

                p2.x, p2.y, p2.z + height,

                r, g, b, a

            )

        end

        for i = 1, #points do

            local currentPoint = points[i]

            local nextPoint = points[(i % #points) + 1]

            DrawPoly(

                currentPoint.x, currentPoint.y, currentPoint.z,

                currentPoint.x, currentPoint.y, currentPoint.z + height,

                nextPoint.x, nextPoint.y, nextPoint.z,

                r, g, b, a

            )

            DrawPoly(

                nextPoint.x, nextPoint.y, nextPoint.z,

                currentPoint.x, currentPoint.y, currentPoint.z + height,

                nextPoint.x, nextPoint.y, nextPoint.z + height,

                r, g, b, a

            )

        end

    end

end

function Interactions.Client.Zone.CreatePreview(points, onEnter, onExit)

    CreateThread(function()

        local previewActive = true

        while previewActive do

            Wait(0)

            if points and #points >= 3 then

                Interactions.Client.Zone.DrawVisualization(

                    points,

                    ZONE_HEIGHT,

                    255, 200, 0, 100

                )

            end

        end

    end)

end

function Interactions.Client.Zone.StartCreator()

    zonePoints = {}

    isCreatorActive = true

    local creatorPromise = promise.new()

    CreateThread(function()

        Interactions.Client.InstrPrmt.Show(

            "Zone Creator",

            {

                {key = "E", desc = "Add Point"},

                {key = "R", desc = "Remove Last"},

                {key = "Enter", desc = "Complete"},

                {key = "Backspace", desc = "Cancel"}

            },

            "Move To Create Zone"

        )

        while isCreatorActive do

            Wait(0)

            DisableControlAction(0, KEY_ADD_POINT, true)

            DisableControlAction(0, KEY_REMOVE_POINT, true)

            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 257, true)
            DisableControlAction(0, 263, true)
            DisableControlAction(0, 264, true)
            visualizeZone()

            local playerPed = PlayerPedId()

            local playerCoords = GetEntityCoords(playerPed)

            drawVerticalLine(

                playerCoords.x, playerCoords.y, playerCoords.z - 2.0,

                4.0,

                0, 255, 0, 200

            )

            if IsDisabledControlJustReleased(0, KEY_ADD_POINT) then

                addPoint()

            end

            if IsDisabledControlJustReleased(0, KEY_REMOVE_POINT) then

                removeLastPoint()

            end

            if IsControlJustReleased(0, KEY_COMPLETE) then

                local completedZone = completeZone()

                if completedZone then

                    Interactions.Client.InstrPrmt.Hide()

                    creatorPromise:resolve(completedZone)

                    break

                end

            end

            if IsControlJustReleased(0, KEY_CANCEL) then

                DebugPrint("^1[Zone Creator]^7 Cancelled!")

                Interactions.Client.InstrPrmt.Hide()

                isCreatorActive = false

                creatorPromise:resolve(false)

                break

            end

        end

    end)

    return Citizen.Await(creatorPromise)

end

RegisterNUICallback("interactions-zone-creator", function(data, cb)

    SetNuiFocus(false, false)

    local result = Interactions.Client.Zone.StartCreator()

    cb(result)

    SetNuiFocus(true, true)

end)

function Interactions.Client.Zone.Create(points, label, key, onInteract, canInteract)

    local sumX, sumY, sumZ = 0, 0, 0

    for _, point in ipairs(points) do

        sumX = sumX + point.x

        sumY = sumY + point.y

        sumZ = sumZ + point.z

    end

    local centerPoint = vec3(

        sumX / #points,

        sumY / #points,

        sumZ / #points

    )

    return Interactions.Client.Handler.AddPointInteraction(

        centerPoint,

        10.0,
        label,

        key,

        onInteract,

        points,
        canInteract

    )

end

function Interactions.Client.Zone.Remove(zoneId)

    if not zoneId then

        return

    end

    Interactions.Client.Handler.RemovePointInteraction(zoneId)

end
