-- Phantom Core - Interaction Menu
-- High-quality 3D target-based interaction menu

local nearbyEntities = {}
local interactionMenuOpen = false

-- Get nearby entities
function GetNearbyEntities()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local entities = {}
    
    -- Get nearby players
    for _, playerId in ipairs(GetActivePlayers()) do
        local targetPed = GetPlayerPed(playerId)
        local targetCoords = GetEntityCoords(targetPed)
        local distance = #(coords - targetCoords)
        
        if distance < Config.Player.Interactions.MaxDistance then
            table.insert(entities, {
                type = 'player',
                id = playerId,
                name = GetPlayerName(playerId),
                ped = targetPed,
                coords = targetCoords,
                distance = distance
            })
        end
    end
    
    -- Get nearby vehicles
    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        local vehicleCoords = GetEntityCoords(vehicle)
        local distance = #(coords - vehicleCoords)
        
        if distance < Config.Player.Interactions.MaxDistance then
            table.insert(entities, {
                type = 'vehicle',
                id = vehicle,
                name = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)),
                coords = vehicleCoords,
                distance = distance
            })
        end
    end
    
    -- Sort by distance
    table.sort(entities, function(a, b)
        return a.distance < b.distance
    end)
    
    return entities
end

-- Get interaction options for entity
function GetInteractionOptions(entity)
    local options = {}
    
    if entity.type == 'player' then
        table.insert(options, {
            label = 'ID: ' .. entity.id,
            description = 'Player ID: ' .. entity.id,
            icon = '👤',
            disabled = true
        })
        table.insert(options, {
            label = 'Trade',
            description = 'Trade items with player',
            icon = '📦'
        })
        table.insert(options, {
            label = 'Give Money',
            description = 'Give money to player',
            icon = '💰'
        })
        table.insert(options, {
            label = 'Invite to Group',
            description = 'Invite to your group',
            icon = '👥'
        })
    elseif entity.type == 'vehicle' then
        table.insert(options, {
            label = entity.name,
            description = 'Vehicle: ' .. entity.name,
            icon = '🚗',
            disabled = true
        })
        table.insert(options, {
            label = 'Enter Vehicle',
            description = 'Enter as driver',
            icon = '🚗'
        })
        table.insert(options, {
            label = 'Enter as Passenger',
            description = 'Enter as passenger',
            icon = '👤'
        })
        table.insert(options, {
            label = 'Check Trunk',
            description = 'Open vehicle trunk',
            icon = '📦'
        })
        table.insert(options, {
            label = 'Lock/Unlock',
            description = 'Toggle vehicle lock',
            icon = '🔒'
        })
    end
    
    return options
end

-- Open interaction menu
function OpenInteractionMenu()
    if interactionMenuOpen then return end
    
    nearbyEntities = GetNearbyEntities()
    
    if #nearbyEntities == 0 then
        SendNotification({
            notificationType = 'info',
            message = 'No nearby entities to interact with'
        })
        return
    end
    
    interactionMenuOpen = true
    local options = {}
    
    for _, entity in ipairs(nearbyEntities) do
        local icon = entity.type == 'player' and '👤' or '🚗'
        table.insert(options, {
            label = entity.name,
            description = string.format('%.1fm away', entity.distance),
            icon = icon,
            args = { type = 'entity', index = _ }
        })
    end
    
    ShowMenu({
        title = 'Nearby Entities',
        options = options
    })
end

-- Open entity interaction menu
function OpenEntityMenu(entityIndex)
    local entity = nearbyEntities[entityIndex]
    if not entity then return end
    
    local options = GetInteractionOptions(entity)
    
    -- Add back button
    table.insert(options, {
        label = '← Back',
        description = 'Return to entity list',
        icon = '⬅️',
        args = { type = 'back' }
    })
    
    ShowMenu({
        title = entity.name,
        options = options
    })
end

-- Handle interaction
function HandleInteraction(entity, option)
    if entity.type == 'player' then
        if option.label == 'Trade' then
            -- Open trade UI
            SendNotification({
                notificationType = 'info',
                message = 'Trade system coming soon'
            })
        elseif option.label == 'Give Money' then
            ShowInputDialog({
                title = 'Give Money',
                inputs = {
                    {
                        type = 'number',
                        label = 'Amount',
                        placeholder = 'Enter amount',
                        required = true
                    }
                },
                callback = function(values, submitted)
                    if submitted and values[1] then
                        -- Give money logic
                        SendNotification({
                            notificationType = 'success',
                            message = 'Gave $' .. values[1] .. ' to player'
                        })
                    end
                end
            })
        elseif option.label == 'Invite to Group' then
            SendNotification({
                notificationType = 'info',
                message = 'Group invite sent'
            })
        end
    elseif entity.type == 'vehicle' then
        local ped = PlayerPedId()
        
        if option.label == 'Enter Vehicle' then
            TaskWarpPedIntoVehicle(ped, entity.id, -1)
        elseif option.label == 'Enter as Passenger' then
            TaskWarpPedIntoVehicle(ped, entity.id, 0)
        elseif option.label == 'Check Trunk' then
            SendNotification({
                notificationType = 'info',
                message = 'Opening trunk...'
            })
        elseif option.label == 'Lock/Unlock' then
            local isLocked = GetVehicleDoorLockStatus(entity.id) == 2
            SetVehicleDoorsLocked(entity.id, isLocked and 1 or 2)
            SendNotification({
                notificationType = 'info',
                message = isLocked and 'Vehicle unlocked' or 'Vehicle locked'
            })
        end
    end
end

-- Handle menu selection
RegisterNUICallback('menuItemSelected', function(data, cb)
    if data.args.type == 'entity' then
        OpenEntityMenu(data.args.index)
    elseif data.args.type == 'back' then
        OpenInteractionMenu()
    else
        local entity = nearbyEntities[data.entityIndex]
        if entity then
            HandleInteraction(entity, data.args)
        end
        CloseMenu()
    end
    
    interactionMenuOpen = false
    cb({})
end)

RegisterNUICallback('menuClosed', function(data, cb)
    interactionMenuOpen = false
    cb({})
end)

-- Register command
RegisterCommand('interact', function()
    OpenInteractionMenu()
end)

-- Key bind to open interaction menu
CreateThread(function()
    while true do
        Wait(0)
        
        if IsControlJustPressed(0, Config.Player.Interactions.Key) then -- E key
            OpenInteractionMenu()
        end
    end
end)

-- Export functions
exports('OpenInteractionMenu', OpenInteractionMenu)
exports('GetNearbyEntities', GetNearbyEntities)

DebugPrint('Interaction system loaded')
