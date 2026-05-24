-- Phantom Events - Server Main
local activeEvents = {}
local playerEventData = {}

-- Check if player is admin
function IsAdmin(source)
    if Config.AdminPerms.acePermission and IsPlayerAceAllowed(source, Config.AdminPerms.acePermission) then
        return true
    end

    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return false end

    for _, cid in ipairs(Config.AdminPerms.citizenids) do
        if Player.PlayerData.citizenid == cid then
            return true
        end
    end

    return false
end

-- Start event
RegisterNetEvent('phantom_events:server:startEvent', function(eventType, options)
    local src = source
    if not IsAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'No Permission', description = 'Owner only!', type = 'error' })
        return
    end

    if activeEvents[eventType] then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Event Already Active', type = 'error' })
        return
    end

    local eventConfig = Config.Events[eventType]
    if not eventConfig or not eventConfig.enabled then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Event Disabled', type = 'error' })
        return
    end

    local eventData = {
        type = eventType,
        name = eventConfig.name,
        description = eventConfig.description,
        startTime = os.time(),
        duration = options.duration or eventConfig.defaultDuration,
        options = options,
        starter = src,
        active = true,
    }

    activeEvents[eventType] = eventData

    -- Broadcast to all players
    TriggerClientEvent('phantom_events:client:eventStarted', -1, {
        type = eventType,
        name = eventConfig.name,
        description = eventConfig.description,
        duration = eventData.duration,
        colors = eventConfig.colors,
        options = options,
    })

    -- Log
    print('^2[Phantom Events]^7 ' .. eventConfig.name .. ' started by ' .. GetPlayerName(src))

    -- Auto-end timer
    CreateThread(function()
        Wait(eventData.duration * 1000)
        EndEvent(eventType)
    end)
end)

-- End event
function EndEvent(eventType)
    local event = activeEvents[eventType]
    if not event then return end

    event.active = false
    activeEvents[eventType] = nil

    TriggerClientEvent('phantom_events:client:eventEnded', -1, {
        type = eventType,
        name = event.name,
    })

    print('^3[Phantom Events]^7 ' .. event.name .. ' ended')
end

-- Stop event (admin)
RegisterNetEvent('phantom_events:server:stopEvent', function(eventType)
    local src = source
    if not IsAdmin(src) then return end
    EndEvent(eventType)
    TriggerClientEvent('ox_lib:notify', src, { title = 'Event Stopped', description = eventType, type = 'success' })
end)

-- Is admin check for client
lib.callback.register('phantom_events:server:isAdmin', function(source)
    return IsAdmin(source)
end)

-- Get active events
lib.callback.register('phantom_events:server:getActiveEvents', function(source)
    local events = {}
    for type, event in pairs(activeEvents) do
        if event.active then
            table.insert(events, {
                type = type,
                name = event.name,
                timeRemaining = event.duration - (os.time() - event.startTime),
            })
        end
    end
    return events
end)

-- Check if event is active
function IsEventActive(eventType)
    return activeEvents[eventType] ~= nil
end

-- Get event multiplier (for integrations)
function GetEventMultiplier(eventType)
    if activeEvents[eventType] then
        return Config.Events[eventType].multiplier or 1.0
    end
    return 1.0
end

-- Export for other resources
exports('IsEventActive', IsEventActive)
exports('GetEventMultiplier', GetEventMultiplier)

-- DB Init
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS phantom_events_log (
                id INT AUTO_INCREMENT PRIMARY KEY,
                event_type VARCHAR(50),
                event_name VARCHAR(100),
                started_by VARCHAR(50),
                duration INT,
                participants INT DEFAULT 0,
                total_payout INT DEFAULT 0,
                started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ]])
        print('^2[Phantom Events]^7 Server loaded')
    end
end)

-- Commands
RegisterCommand('eventmenu', function(source)
    if IsAdmin(source) then
        TriggerClientEvent('phantom_events:client:openAdminPanel', source)
    else
        TriggerClientEvent('ox_lib:notify', source, { title = 'No Permission', type = 'error' })
    end
end)

RegisterCommand('events', function(source)
    TriggerClientEvent('phantom_events:client:openEventsMenu', source)
end)
