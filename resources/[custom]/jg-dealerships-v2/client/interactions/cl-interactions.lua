Interactions = Interactions or {}

Interactions.Client = Interactions.Client or {}

local allBlips = {}

local function createBlip(label, coords, sprite, colour, scale)

    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)

    SetBlipSprite(blip, sprite)

    SetBlipColour(blip, colour)

    SetBlipScale(blip, scale + 0.0)

    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName("STRING")

    AddTextComponentString(label)

    EndTextCommandSetBlipName(blip)

    table.insert(allBlips, blip)

    return blip

end

function Interactions.Client.Create(interactions, key, label, onInteract, blipLabel, canInteract)

    local collection = {

        entities = {},

        points = {},

        zones = {},

        blips = {},

        markers = {},

        _cancelled = false,

        _streamingEntitiesReady = false

    }

    local pedsToCreate = {}

    local vehiclesToCreate = {}

    local objectsToCreate = {}

    local shouldSpawnEntities = not canInteract or canInteract

    for _, interaction in ipairs(interactions) do

        local coords = interaction.coords and interaction.coords[1]

        local interactionType = interaction.type

        local hasBlipEnabled = interaction.enableBlip

        if hasBlipEnabled and (shouldSpawnEntities or interactionType == "ped") then

            local blipCoords = nil

            if interactionType == "polyzone" then

                blipCoords = Utils.Client.GetPolygonCenter(interaction.coords)

            elseif coords then

                blipCoords = vec3(coords.x, coords.y, coords.z)

            end

            if blipCoords then

                local blip = createBlip(

                    blipLabel or "Interaction",

                    blipCoords,

                    interaction.blipIconId,

                    interaction.blipColourId,

                    interaction.blipSize

                )

                table.insert(collection.blips, blip)

            end

        end

        if interaction.enableMarker then

            if interactionType == "point" and coords and shouldSpawnEntities then

                local markerCoords = vec3(coords.x, coords.y, coords.z)

                local markerConfig = {

                    id = interaction.markerId,

                    size = interaction.markerSize,

                    color = interaction.markerColor,

                    bobUpAndDown = interaction.markerBobUpAndDown,

                    faceCamera = interaction.markerFaceCamera,

                    rotate = interaction.markerRotate,

                    drawOnEnts = interaction.markerDrawOnEnts

                }

                local markerPoint = lib.points.new({

                    coords = markerCoords,

                    distance = Config.EntityStreamingDistance or 150.0

                })

                function markerPoint:nearby()

                    Utils.Client.DrawMarkerOnFrame(

                        markerConfig.id,

                        markerCoords,

                        markerConfig.size,

                        markerConfig.color,

                        nil, nil,

                        markerConfig.bobUpAndDown,

                        markerConfig.faceCamera,

                        markerConfig.rotate,

                        markerConfig.drawOnEnts

                    )

                end

                table.insert(collection.markers, markerPoint)

            end

        end

        if interactionType == "ped" then

            table.insert(pedsToCreate, {

                coords = coords,

                model = interaction.model,

                pedScenario = interaction.pedScenario,

                text = label,

                key = key,

                callback = onInteract,

                canInteract = canInteract

            })

        elseif interactionType == "vehicle" then

            table.insert(vehiclesToCreate, {

                coords = coords,

                model = interaction.model,

                vehColour = interaction.vehColour,

                text = label,

                key = key,

                callback = onInteract,

                canInteract = canInteract

            })

        elseif interactionType == "object" then

            table.insert(objectsToCreate, {

                coords = coords,

                model = interaction.model,

                text = label,

                key = key,

                callback = onInteract,

                canInteract = canInteract

            })

        elseif interactionType == "point" then

            if coords and shouldSpawnEntities then

                local pointId = Interactions.Client.Point.Create(

                    coords,

                    interaction.distance,

                    label,

                    key,

                    onInteract,

                    canInteract

                )

                table.insert(collection.points, pointId)

            end

        elseif interactionType == "polyzone" then

            local zonePoints = {}

            for _, point in ipairs(interaction.coords) do

                table.insert(zonePoints, vec3(point.x, point.y, point.z))

            end

            if shouldSpawnEntities then

                local zoneId = Interactions.Client.Zone.Create(

                    zonePoints,

                    label,

                    key,

                    onInteract,

                    canInteract

                )

                table.insert(collection.zones, zoneId)

            end

            if interaction.enableMarker and shouldSpawnEntities then

                local centerCoords = Utils.Client.GetPolygonCenter(zonePoints)

                local markerCoords = vec3(centerCoords.x, centerCoords.y, centerCoords.z)

                local markerConfig = {

                    id = interaction.markerId,

                    size = interaction.markerSize,

                    color = interaction.markerColor,

                    bobUpAndDown = interaction.markerBobUpAndDown,

                    faceCamera = interaction.markerFaceCamera,

                    rotate = interaction.markerRotate,

                    drawOnEnts = interaction.markerDrawOnEnts

                }

                local markerPoint = lib.points.new({

                    coords = markerCoords,

                    distance = Config.EntityStreamingDistance or 150.0

                })

                function markerPoint:nearby()

                    Utils.Client.DrawMarkerOnFrame(

                        markerConfig.id,

                        markerCoords,

                        markerConfig.size,

                        markerConfig.color,

                        nil, nil,

                        markerConfig.bobUpAndDown,

                        markerConfig.faceCamera,

                        markerConfig.rotate,

                        markerConfig.drawOnEnts

                    )

                end

                table.insert(collection.markers, markerPoint)

            end

        end

    end

    if #pedsToCreate > 0 or #vehiclesToCreate > 0 or #objectsToCreate > 0 then

        CreateThread(function()

            for _, pedData in ipairs(pedsToCreate) do

                if collection._cancelled then

                    return

                end

                local pedWrapper = Interactions.Client.Ped.Create(

                    pedData.coords,

                    pedData.model,

                    pedData.pedScenario,

                    pedData.text,

                    pedData.key,

                    pedData.callback,

                    pedData.canInteract

                )

                table.insert(collection.entities, {

                    type = "ped",

                    wrapper = pedWrapper,

                    entity = pedWrapper.entity or 0,

                    interactionId = "entity_" .. (pedWrapper.entity or 0)

                })

                Wait(100)
            end

            for _, vehicleData in ipairs(vehiclesToCreate) do

                if collection._cancelled then

                    return

                end

                local vehicleWrapper = Interactions.Client.Vehicle.Create(

                    vehicleData.coords,

                    vehicleData.model,

                    vehicleData.vehColour,

                    vehicleData.text,

                    vehicleData.key,

                    vehicleData.callback,

                    vehicleData.canInteract

                )

                table.insert(collection.entities, {

                    type = "vehicle",

                    wrapper = vehicleWrapper,

                    entity = vehicleWrapper.entity or 0,

                    interactionId = "entity_" .. (vehicleWrapper.entity or 0)

                })

                Wait(100)

            end

            for index, objectData in ipairs(objectsToCreate) do

                if collection._cancelled then

                    return

                end

                local objectWrapper = Interactions.Client.Object.Create(

                    objectData.coords,

                    objectData.model,

                    objectData.text,

                    objectData.key,

                    objectData.callback,

                    objectData.canInteract

                )

                table.insert(collection.entities, {

                    type = "object",

                    wrapper = objectWrapper,

                    entity = objectWrapper.entity or 0,

                    interactionId = "entity_" .. (objectWrapper.entity or 0)

                })

                if index < #objectsToCreate then

                    Wait(100)

                end

            end

            collection._streamingEntitiesReady = true

        end)

    else

        collection._streamingEntitiesReady = true

    end

    return collection

end

function Interactions.Client.Remove(collection)

    if not collection then

        return

    end

    collection._cancelled = true

    if collection.entities then

        for _, entityData in ipairs(collection.entities) do

            local wrapper = entityData.wrapper

            if wrapper then

                wrapper._removed = true

                if wrapper.activeInteraction then

                    Interactions.Client.Handler.RemoveEntityInteraction(wrapper.activeInteraction)

                    wrapper.activeInteraction = nil

                end

                if wrapper.entity and DoesEntityExist(wrapper.entity) then

                    if entityData.type == "ped" then

                        ClearPedTasksImmediately(wrapper.entity)

                    end

                    SetEntityAsMissionEntity(wrapper.entity, false, true)

                    DeleteEntity(wrapper.entity)

                    wrapper.entity = nil

                end

                if wrapper.streamingPoint then

                    wrapper.streamingPoint:remove()

                    wrapper.streamingPoint = nil

                end

            end

        end

    end

    if collection.points then

        for _, pointId in ipairs(collection.points) do

            Interactions.Client.Point.Remove(pointId)

        end

    end

    if collection.zones then

        for _, zoneId in ipairs(collection.zones) do

            Interactions.Client.Zone.Remove(zoneId)

        end

    end

    if collection.blips then

        for _, blip in ipairs(collection.blips) do

            if DoesBlipExist(blip) then

                RemoveBlip(blip)

            end

        end

    end

    if collection.markers then

        for _, marker in ipairs(collection.markers) do

            marker:remove()

        end

    end

end
