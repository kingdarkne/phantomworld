local isPreviewActive = false

local previewEnabled = true

local previewEntities = {}

local previewBlips = {}

local lastLocationId = nil

local lastInteractionType = nil

local isInExplorationMode = false

local isNuiFocusActive = false

local KEY_EXPLORATION_TOGGLE = 200

local function cleanupPreviews(locationId, interactionType, interactions)

    if not isPreviewActive then

        return

    end

    isPreviewActive = false

    isInExplorationMode = false

    previewEnabled = true

    for _, entityData in ipairs(previewEntities) do

        local entityType = entityData.type

        if entityType == "ped" or entityType == "vehicle" or entityType == "object" then

            if entityData.entity then

                if DoesEntityExist(entityData.entity) then

                    SetEntityAsMissionEntity(entityData.entity, false, true)

                    if entityType == "ped" then

                        ClearPedTasksImmediately(entityData.entity)

                    end

                    DeleteEntity(entityData.entity)

                end

            end

        end

    end

    for _, blip in ipairs(previewBlips) do

        if DoesBlipExist(blip) then

            RemoveBlip(blip)

        end

    end

    previewEntities = {}

    previewBlips = {}

    if lastInteractionType and lastLocationId then

        if locationId and interactionType then

            if interactions then

                Locations.Client.RecreateInteractionTypeFromData(locationId, interactionType, interactions)

            else

                Locations.Client.RecreateInteractionType(locationId, interactionType)

            end

            lastInteractionType = nil

            lastLocationId = nil

        end

    end

end

local function startPreview(interactions, highlightingMode, optionalLocationId, keepInteractionsEnabled)

    if isInExplorationMode then

        return

    end

    isInExplorationMode = true

    previewEnabled = (keepInteractionsEnabled ~= false)

    if #previewEntities > 0 then

        for _, entityData in ipairs(previewEntities) do

            local entityType = entityData.type

            if entityType == "ped" or entityType == "vehicle" or entityType == "object" then

                if entityData.entity then

                    if DoesEntityExist(entityData.entity) then

                        SetEntityAsMissionEntity(entityData.entity, false, true)

                        if entityType == "ped" then

                            ClearPedTasksImmediately(entityData.entity)

                        end

                        DeleteEntity(entityData.entity)

                    end

                end

            end

        end

    end

    isPreviewActive = true

    previewEntities = {}

    previewBlips = {}

    for _, interaction in ipairs(interactions) do

        local coords = interaction.coords and interaction.coords[1]

        local interactionType = interaction.type

        if interactionType == "ped" and coords then

            local pedData = Interactions.Client.Ped.SpawnPreview(coords, interaction.model, interaction.pedScenario)

            local pedEntity = pedData.entity or 0

            if pedEntity ~= 0 then

                table.insert(previewEntities, {

                    type = "ped",

                    entity = pedEntity

                })

            end

        elseif interactionType == "vehicle" and coords then

            local vehicleData = Interactions.Client.Vehicle.SpawnPreview(coords, interaction.model, interaction.vehColour)

            local vehicleEntity = vehicleData.entity or 0

            if vehicleEntity ~= 0 then

                table.insert(previewEntities, {

                    type = "vehicle",

                    entity = vehicleEntity

                })

            end

        elseif interactionType == "object" and coords then

            local objectData = Interactions.Client.Object.SpawnPreview(coords, interaction.model)

            local objectEntity = objectData.entity or 0

            if objectEntity ~= 0 then

                table.insert(previewEntities, {

                    type = "object",

                    entity = objectEntity

                })

            end

        elseif interactionType == "blip" and coords then

            local blipData = Interactions.Client.Blip.CreatePreview(coords, interaction.blipSprite, interaction.blipColour)

            local blip = blipData.blip

            if blip and blip ~= 0 then

                table.insert(previewBlips, blip)

            end

        elseif interactionType == "textUI" and coords then

            Interactions.Client.TextUI.CreatePreview(coords, interaction.message, interaction.variant)

        elseif interactionType == "zone" then

            local zonePoints = interaction.coords

            Interactions.Client.Zone.CreatePreview(zonePoints, interaction.onEnter, interaction.onExit)

        elseif interactionType == "point" then

            local pointCoords = interaction.coords

            Interactions.Client.Point.CreatePreview(pointCoords, interaction.distance, interaction.onEnter, interaction.onExit)

        end

    end

    if optionalLocationId then

        lastLocationId = optionalLocationId

        lastInteractionType = highlightingMode

    end

    if highlightingMode then

        CreateThread(function()

            while isPreviewActive do

                Wait(0)

                for index, entityData in ipairs(previewEntities) do

                    if not entityData.highlightHidden then

                        local entity = entityData.entity

                        if entity and DoesEntityExist(entity) then

                            local entityCoords = GetEntityCoords(entity)

                            DrawMarker(

                                2,
                                entityCoords.x, entityCoords.y, entityCoords.z + 2.0,

                                0.0, 0.0, 0.0,
                                0.0, 180.0, 0.0,
                                0.5, 0.5, 0.5,
                                255, 200, 0, 200,
                                false,
                                true,
                                2,
                                false, nil, nil, false

                            )

                            local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(

                                entityCoords.x, entityCoords.y, entityCoords.z + 2.5

                            )

                            if onScreen then

                                SetTextScale(0.4, 0.4)

                                SetTextFont(4)

                                SetTextProportional(true)

                                SetTextColour(255, 255, 255, 255)

                                SetTextOutline()

                                SetTextCentre(true)

                                BeginTextCommandDisplayText("STRING")

                                AddTextComponentSubstringPlayerName(tostring(index))

                                EndTextCommandDisplayText(screenX, screenY)

                            end

                        end

                    end

                end

            end

        end)

    end

end

RegisterNUICallback("preview-location-interactions", function(data, cb)

    local locationId = data.locationId

    local interactions = data.interactions

    local highlightingMode = data.interactionType

    local keepEnabled = data.keepInteractionsEnabled

    startPreview(interactions, highlightingMode, locationId, keepEnabled)

    cb("ok")

end)

RegisterNUICallback("cancel-highlighting-preview", function(data, cb)

    cleanupPreviews(nil, nil, nil)

    cb("ok")

end)

RegisterNUICallback("toggle-all-interaction-highlights", function(data, cb)

    previewEnabled = (data.enabled ~= false)

    cb("ok")

end)

RegisterNUICallback("toggle-single-interaction-highlight", function(data, cb)

    local index = data.index + 1
    if previewEntities[index] then

        previewEntities[index].highlightHidden = not data.enabled

    end

    cb("ok")

end)

RegisterNUICallback("set-nui-focus", function(data, cb)

    SetNuiFocus(data.hasFocus, data.hasCursor)

    isNuiFocusActive = not data.hasFocus

    if isNuiFocusActive then

        CreateThread(function()

            while isNuiFocusActive do

                DisableControlAction(0, KEY_EXPLORATION_TOGGLE, true)

                if IsDisabledControlJustReleased(0, KEY_EXPLORATION_TOGGLE) then

                    SendNUIMessage({

                        action = "toggle-exploration-mode"

                    })

                    isNuiFocusActive = false

                end

                Wait(0)

            end

        end)

    end

    cb("ok")

end)

RegisterNUICallback("stop-preview-location-interactions", function(data, cb)

    local locationId = data.locationId

    local interactionType = data.interactionType

    local interactions = data.interactions

    local skipRecreate = data.skipRecreate

    if skipRecreate then

        cleanupPreviews(nil, nil, nil)

    else

        cleanupPreviews(locationId, interactionType, interactions)

    end

    cb("ok")

end)

RegisterNUICallback("restore-location-interactions", function(data, cb)

    local locationId = data.locationId

    if isPreviewActive then

        isPreviewActive = false

        isInExplorationMode = false

        previewEnabled = true

        for _, entityData in ipairs(previewEntities) do

            local entityType = entityData.type

            if entityType == "ped" or entityType == "vehicle" or entityType == "object" then

                if entityData.entity and DoesEntityExist(entityData.entity) then

                    SetEntityAsMissionEntity(entityData.entity, false, true)

                    if entityType == "ped" then

                        ClearPedTasksImmediately(entityData.entity)

                    end

                    DeleteEntity(entityData.entity)

                end

            end

        end

        for _, blip in ipairs(previewBlips) do

            if DoesBlipExist(blip) then

                RemoveBlip(blip)

            end

        end

        previewEntities = {}

        previewBlips = {}

    end

    if lastInteractionType and lastLocationId then

        if lastLocationId == locationId then

            Locations.Client.RecreateInteractionType(locationId, lastInteractionType)

            lastInteractionType = nil

            lastLocationId = nil

        end

    end

    cb("ok")

end)

AddEventHandler("onResourceStop", function(resourceName)

    if GetCurrentResourceName() == resourceName then

        cleanupPreviews()

    end

end)
