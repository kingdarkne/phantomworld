-- Admin-only event triggers
QBCore = exports['qbx_core']:GetCoreObject()

-- Check if player is admin
QBCore.Functions.CreateCallback('dr_world_events:server:isAdmin', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        cb(false)
        return
    end

    local isAdmin = Player.PlayerData.metadata.isadmin or Player.PlayerData.metadata.admin or
                   IsPlayerAceAllowed(src, 'command.admin') or IsPlayerAceAllowed(src, 'command.easyadmin')
    cb(isAdmin)
end)

-- Trigger earthquake (admin only)
RegisterNetEvent('dr_world_events:triggerEarthquake', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    -- Check if admin (you can adjust this check)
    if not Player or (not Player.PlayerData.metadata.isadmin and not Player.PlayerData.metadata.admin and
       not IsPlayerAceAllowed(src, 'command.admin') and not IsPlayerAceAllowed(src, 'command.easyadmin')) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only admins can trigger events!' })
        return
    end
    
    -- Trigger earthquake effect on all clients
    TriggerClientEvent("dr-Earthquake:Random", -1)
    
    -- Notify all players
    TriggerClientEvent('ox_lib:notify', -1, {
        title = '🌍 EARTHQUAKE!',
        description = 'A massive earthquake is shaking the city!',
        type = 'error',
        duration = 10000
    })
    
    print('[World Events] Earthquake triggered by player ' .. src)
end)

-- Trigger explosion at player location (admin only)
RegisterNetEvent('dr_world_events:triggerExplosion', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player or (not Player.PlayerData.metadata.isadmin and not Player.PlayerData.metadata.admin and
       not IsPlayerAceAllowed(src, 'command.admin') and not IsPlayerAceAllowed(src, 'command.easyadmin')) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only admins can trigger events!' })
        return
    end

    -- Get player coords from client
    TriggerClientEvent('dr_world_events:explodeAtPlayer', src)
end)

-- Trigger lightning storm (admin only)
RegisterNetEvent('dr_world_events:triggerLightning', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player or (not Player.PlayerData.metadata.isadmin and not Player.PlayerData.metadata.admin and
       not IsPlayerAceAllowed(src, 'command.admin') and not IsPlayerAceAllowed(src, 'command.easyadmin')) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only admins can trigger events!' })
        return
    end

    -- Trigger lightning storm on all clients for 1 hour
    TriggerClientEvent('dr_world_events:startLightning', -1)
    TriggerClientEvent('ox_lib:notify', -1, {
        title = '⚡ LIGHTNING STORM!',
        description = 'A severe lightning storm has begun! Seek shelter immediately!',
        type = 'error',
        duration = 10000
    })
    print('[World Events] Lightning storm triggered by player ' .. src)

    -- Stop lightning after 1 hour
    SetTimeout(3600000, function()
        TriggerClientEvent('dr_world_events:stopLightning', -1)
        TriggerClientEvent('ox_lib:notify', -1, {
            title = 'Weather Update',
            description = 'The lightning storm has passed.',
            type = 'inform',
            duration = 8000
        })
    end)
end)

-- Trigger acid rain (admin only)
RegisterNetEvent('dr_world_events:triggerAcidRain', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player or (not Player.PlayerData.metadata.isadmin and not Player.PlayerData.metadata.admin and
       not IsPlayerAceAllowed(src, 'command.admin') and not IsPlayerAceAllowed(src, 'command.easyadmin')) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only admins can trigger events!' })
        return
    end

    -- Trigger acid rain on all clients for 1 hour
    TriggerClientEvent('dr_world_events:startAcidRain', -1)
    TriggerClientEvent('ox_lib:notify', -1, {
        title = '☢️ ACID RAIN ALERT!',
        description = 'Dangerous acid rain is falling! Vehicles will be damaged!',
        type = 'error',
        duration = 10000
    })
    print('[World Events] Acid rain triggered by player ' .. src)

    -- Stop acid rain after 1 hour
    SetTimeout(3600000, function()
        TriggerClientEvent('dr_world_events:stopAcidRain', -1)
        TriggerClientEvent('ox_lib:notify', -1, {
            title = 'Weather Update',
            description = 'The acid rain has stopped.',
            type = 'inform',
            duration = 8000
        })
    end)
end)

-- Heat Wave
RegisterNetEvent('dr_world_events:triggerHeatWave', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player or (not Player.PlayerData.metadata.isadmin and not Player.PlayerData.metadata.admin and
       not IsPlayerAceAllowed(src, 'command.admin') and not IsPlayerAceAllowed(src, 'command.easyadmin')) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only admins can trigger events!' })
        return
    end

    TriggerClientEvent('dr_world_events:startHeatWave', -1)
    TriggerClientEvent('ox_lib:notify', -1, {
        title = '🔥 HEAT WAVE!',
        description = 'Extreme heat! Vehicles may overheat!',
        type = 'error',
        duration = 10000
    })
    print('[World Events] Heat wave triggered by player ' .. src)

    SetTimeout(3600000, function()
        TriggerClientEvent('dr_world_events:stopHeatWave', -1)
        TriggerClientEvent('ox_lib:notify', -1, {
            title = 'Weather Update',
            description = 'The heat wave has passed.',
            type = 'inform',
            duration = 8000
        })
    end)
end)

-- Sandstorm
RegisterNetEvent('dr_world_events:triggerSandstorm', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player or (not Player.PlayerData.metadata.isadmin and not Player.PlayerData.metadata.admin and
       not IsPlayerAceAllowed(src, 'command.admin') and not IsPlayerAceAllowed(src, 'command.easyadmin')) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only admins can trigger events!' })
        return
    end

    TriggerClientEvent('dr_world_events:startSandstorm', -1)
    TriggerClientEvent('ox_lib:notify', -1, {
        title = '🏜️ SANDSTORM!',
        description = 'Severe sandstorm! Low visibility!',
        type = 'error',
        duration = 10000
    })
    print('[World Events] Sandstorm triggered by player ' .. src)

    SetTimeout(3600000, function()
        TriggerClientEvent('dr_world_events:stopSandstorm', -1)
        TriggerClientEvent('ox_lib:notify', -1, {
            title = 'Weather Update',
            description = 'The sandstorm has cleared.',
            type = 'inform',
            duration = 8000
        })
    end)
end)

-- Fog
RegisterNetEvent('dr_world_events:triggerFog', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player or (not Player.PlayerData.metadata.isadmin and not Player.PlayerData.metadata.admin and
       not IsPlayerAceAllowed(src, 'command.admin') and not IsPlayerAceAllowed(src, 'command.easyadmin')) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only admins can trigger events!' })
        return
    end

    TriggerClientEvent('dr_world_events:startFog', -1)
    TriggerClientEvent('ox_lib:notify', -1, {
        title = '🌫️ DENSE FOG!',
        description = 'Visibility extremely low!',
        type = 'error',
        duration = 10000
    })
    print('[World Events] Fog triggered by player ' .. src)

    SetTimeout(3600000, function()
        TriggerClientEvent('dr_world_events:stopFog', -1)
        TriggerClientEvent('ox_lib:notify', -1, {
            title = 'Weather Update',
            description = 'The fog has lifted.',
            type = 'inform',
            duration = 8000
        })
    end)
end)

-- Blackout
RegisterNetEvent('dr_world_events:triggerBlackout', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player or (not Player.PlayerData.metadata.isadmin and not Player.PlayerData.metadata.admin and
       not IsPlayerAceAllowed(src, 'command.admin') and not IsPlayerAceAllowed(src, 'command.easyadmin')) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only admins can trigger events!' })
        return
    end

    TriggerClientEvent('dr_world_events:startBlackout', -1)
    TriggerClientEvent('ox_lib:notify', -1, {
        title = '💡 CITY BLACKOUT!',
        description = 'City-wide power failure! All lights out!',
        type = 'error',
        duration = 10000
    })
    print('[World Events] Blackout triggered by player ' .. src)

    SetTimeout(3600000, function()
        TriggerClientEvent('dr_world_events:stopBlackout', -1)
        TriggerClientEvent('ox_lib:notify', -1, {
            title = 'Power Restored',
            description = 'City power has been restored.',
            type = 'inform',
            duration = 8000
        })
    end)
end)

-- Meteor Shower
RegisterNetEvent('dr_world_events:triggerMeteorShower', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player or (not Player.PlayerData.metadata.isadmin and not Player.PlayerData.metadata.admin and
       not IsPlayerAceAllowed(src, 'command.admin') and not IsPlayerAceAllowed(src, 'command.easyadmin')) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only admins can trigger events!' })
        return
    end

    TriggerClientEvent('dr_world_events:startMeteorShower', -1)
    TriggerClientEvent('ox_lib:notify', -1, {
        title = '☄️ METEOR SHOWER!',
        description = 'Meteors falling from the sky!',
        type = 'error',
        duration = 10000
    })
    print('[World Events] Meteor shower triggered by player ' .. src)

    SetTimeout(3600000, function()
        TriggerClientEvent('dr_world_events:stopMeteorShower', -1)
        TriggerClientEvent('ox_lib:notify', -1, {
            title = 'Weather Update',
            description = 'The meteor shower has ended.',
            type = 'inform',
            duration = 8000
        })
    end)
end)

-- Tornado
RegisterNetEvent('dr_world_events:triggerTornado', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player or (not Player.PlayerData.metadata.isadmin and not Player.PlayerData.metadata.admin and
       not IsPlayerAceAllowed(src, 'command.admin') and not IsPlayerAceAllowed(src, 'command.easyadmin')) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only admins can trigger events!' })
        return
    end

    TriggerClientEvent('dr_world_events:startTornado', -1)
    TriggerClientEvent('ox_lib:notify', -1, {
        title = '🌪️ TORNADO WARNING!',
        description = 'A tornado has touched down! Seek shelter!',
        type = 'error',
        duration = 10000
    })
    print('[World Events] Tornado triggered by player ' .. src)

    SetTimeout(3600000, function()
        TriggerClientEvent('dr_world_events:stopTornado', -1)
        TriggerClientEvent('ox_lib:notify', -1, {
            title = 'Weather Update',
            description = 'The tornado has dissipated.',
            type = 'inform',
            duration = 8000
        })
    end)
end)

-- EMP Blast
RegisterNetEvent('dr_world_events:triggerEMP', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player or (not Player.PlayerData.metadata.isadmin and not Player.PlayerData.metadata.admin and
       not IsPlayerAceAllowed(src, 'command.admin') and not IsPlayerAceAllowed(src, 'command.easyadmin')) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only admins can trigger events!' })
        return
    end

    TriggerClientEvent('dr_world_events:startEMP', -1)
    TriggerClientEvent('ox_lib:notify', -1, {
        title = '⚡ EMP BLAST!',
        description = 'All vehicles disabled temporarily!',
        type = 'error',
        duration = 10000
    })
    print('[World Events] EMP triggered by player ' .. src)

    SetTimeout(300000, function() -- 5 minutes
        TriggerClientEvent('dr_world_events:stopEMP', -1)
        TriggerClientEvent('ox_lib:notify', -1, {
            title = 'Systems Restored',
            description = 'Vehicle systems have been restored.',
            type = 'inform',
            duration = 8000
        })
    end)
end)

-- Gravity Anomaly
RegisterNetEvent('dr_world_events:triggerGravity', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player or (not Player.PlayerData.metadata.isadmin and not Player.PlayerData.metadata.admin and
       not IsPlayerAceAllowed(src, 'command.admin') and not IsPlayerAceAllowed(src, 'command.easyadmin')) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only admins can trigger events!' })
        return
    end

    TriggerClientEvent('dr_world_events:startGravity', -1)
    TriggerClientEvent('ox_lib:notify', -1, {
        title = '🌍 GRAVITY ANOMALY!',
        description = 'Gravity has been reduced! Jump higher!',
        type = 'error',
        duration = 10000
    })
    print('[World Events] Gravity anomaly triggered by player ' .. src)

    SetTimeout(3600000, function()
        TriggerClientEvent('dr_world_events:stopGravity', -1)
        TriggerClientEvent('ox_lib:notify', -1, {
            title = 'Gravity Normalized',
            description = 'Gravity has returned to normal.',
            type = 'inform',
            duration = 8000
        })
    end)
end)

-- Slow Motion
RegisterNetEvent('dr_world_events:triggerSlowMo', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player or (not Player.PlayerData.metadata.isadmin and not Player.PlayerData.metadata.admin and
       not IsPlayerAceAllowed(src, 'command.admin') and not IsPlayerAceAllowed(src, 'command.easyadmin')) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only admins can trigger events!' })
        return
    end

    TriggerClientEvent('dr_world_events:startSlowMo', -1)
    TriggerClientEvent('ox_lib:notify', -1, {
        title = '⏱️ TIME DILATION!',
        description = 'Time has slowed down!',
        type = 'error',
        duration = 10000
    })
    print('[World Events] Slow motion triggered by player ' .. src)

    SetTimeout(300000, function() -- 5 minutes
        TriggerClientEvent('dr_world_events:stopSlowMo', -1)
        TriggerClientEvent('ox_lib:notify', -1, {
            title = 'Time Restored',
            description = 'Time has returned to normal.',
            type = 'inform',
            duration = 8000
        })
    end)
end)

-- High Gravity
RegisterNetEvent('dr_world_events:triggerHighGravity', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player or (not Player.PlayerData.metadata.isadmin and not Player.PlayerData.metadata.admin and
       not IsPlayerAceAllowed(src, 'command.admin') and not IsPlayerAceAllowed(src, 'command.easyadmin')) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only admins can trigger events!' })
        return
    end

    TriggerClientEvent('dr_world_events:startHighGravity', -1)
    TriggerClientEvent('ox_lib:notify', -1, {
        title = '⬇️ HIGH GRAVITY!',
        description = 'Gravity increased! Movement slowed!',
        type = 'error',
        duration = 10000
    })
    print('[World Events] High gravity triggered by player ' .. src)

    SetTimeout(3600000, function()
        TriggerClientEvent('dr_world_events:stopHighGravity', -1)
        TriggerClientEvent('ox_lib:notify', -1, {
            title = 'Gravity Normalized',
            description = 'Gravity has returned to normal.',
            type = 'inform',
            duration = 8000
        })
    end)
end)

-- Vehicle Chaos
RegisterNetEvent('dr_world_events:triggerVehicleChaos', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player or (not Player.PlayerData.metadata.isadmin and not Player.PlayerData.metadata.admin and
       not IsPlayerAceAllowed(src, 'command.admin') and not IsPlayerAceAllowed(src, 'command.easyadmin')) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only admins can trigger events!' })
        return
    end

    TriggerClientEvent('dr_world_events:startVehicleChaos', -1)
    TriggerClientEvent('ox_lib:notify', -1, {
        title = '🚗 VEHICLE CHAOS!',
        description = 'All vehicles are going crazy!',
        type = 'error',
        duration = 10000
    })
    print('[World Events] Vehicle chaos triggered by player ' .. src)

    SetTimeout(300000, function() -- 5 minutes
        TriggerClientEvent('dr_world_events:stopVehicleChaos', -1)
        TriggerClientEvent('ox_lib:notify', -1, {
            title = 'Chaos Ended',
            description = 'Vehicles have returned to normal.',
            type = 'inform',
            duration = 8000
        })
    end)
end)

-- Police Pursuit
RegisterNetEvent('dr_world_events:triggerPolicePursuit', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player or (not Player.PlayerData.metadata.isadmin and not Player.PlayerData.metadata.admin and
       not IsPlayerAceAllowed(src, 'command.admin') and not IsPlayerAceAllowed(src, 'command.easyadmin')) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only admins can trigger events!' })
        return
    end

    TriggerClientEvent('dr_world_events:startPolicePursuit', -1)
    TriggerClientEvent('ox_lib:notify', -1, {
        title = '🚔 MASSIVE POLICE RESPONSE!',
        description = 'Police are swarming the city!',
        type = 'error',
        duration = 10000
    })
    print('[World Events] Police pursuit triggered by player ' .. src)

    SetTimeout(300000, function() -- 5 minutes
        TriggerClientEvent('dr_world_events:stopPolicePursuit', -1)
        TriggerClientEvent('ox_lib:notify', -1, {
            title = 'Pursuit Ended',
            description = 'Police response has ended.',
            type = 'inform',
            duration = 8000
        })
    end)
end)

-- High Gravity
RegisterNetEvent('dr_world_events:triggerHighGravity', function()
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)

        if not Player or (not Player.PlayerData.metadata.isadmin and not Player.PlayerData.metadata.admin and
           not IsPlayerAceAllowed(src, 'command.admin') and not IsPlayerAceAllowed(src, 'command.easyadmin')) then
            TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only admins can trigger events!' })
            return
        end

        TriggerClientEvent('dr_world_events:startHighGravity', -1)
        TriggerClientEvent('ox_lib:notify', -1, {
            title = '⬇️ HIGH GRAVITY!',
            description = 'Gravity increased! Movement slowed!',
            type = 'error',
            duration = 10000
        })
        print('[World Events] High gravity triggered by player ' .. src)

        SetTimeout(3600000, function()
            TriggerClientEvent('dr_world_events:stopHighGravity', -1)
            TriggerClientEvent('ox_lib:notify', -1, {
                title = 'Gravity Normalized',
                description = 'Gravity has returned to normal.',
                type = 'inform',
                duration = 8000
            })
        end)
    end)

    -- Vehicle Chaos
    RegisterNetEvent('dr_world_events:triggerVehicleChaos', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player or (not Player.PlayerData.metadata.isadmin and not Player.PlayerData.metadata.admin and
       not IsPlayerAceAllowed(src, 'command.admin') and not IsPlayerAceAllowed(src, 'command.easyadmin')) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only admins can trigger events!' })
        return
    end

    TriggerClientEvent('dr_world_events:startVehicleChaos', -1)
    TriggerClientEvent('ox_lib:notify', -1, {
        title = '🚗 VEHICLE CHAOS!',
        description = 'All vehicles are going crazy!',
        type = 'error',
        duration = 10000
    })
    print('[World Events] Vehicle chaos triggered by player ' .. src)

    SetTimeout(300000, function() -- 5 minutes
        TriggerClientEvent('dr_world_events:stopVehicleChaos', -1)
        TriggerClientEvent('ox_lib:notify', -1, {
            title = 'Chaos Ended',
            description = 'Vehicles have returned to normal.',
            type = 'inform',
            duration = 8000
        })
    end)
end)

-- Police Pursuit
RegisterNetEvent('dr_world_events:triggerPolicePursuit', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player or (not Player.PlayerData.metadata.isadmin and not Player.PlayerData.metadata.admin and
       not IsPlayerAceAllowed(src, 'command.admin') and not IsPlayerAceAllowed(src, 'command.easyadmin')) then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'Only admins can trigger events!' })
        return
    end

    TriggerClientEvent('dr_world_events:startPolicePursuit', -1)
    TriggerClientEvent('ox_lib:notify', -1, {
        title = '🚔 MASSIVE POLICE RESPONSE!',
        description = 'Police are swarming the city!',
        type = 'error',
        duration = 10000
    })
    print('[World Events] Police pursuit triggered by player ' .. src)

    SetTimeout(300000, function() -- 5 minutes
        TriggerClientEvent('dr_world_events:stopPolicePursuit', -1)
        TriggerClientEvent('ox_lib:notify', -1, {
            title = 'Pursuit Ended',
            description = 'Police response has ended.',
            type = 'inform',
            duration = 8000
        })
    end)
end)

-- Broadcast event to all players
RegisterNetEvent('dr_world_events:broadcast', function(message)
    TriggerClientEvent('dr_world_events:notify', -1, message, 'warning')
end)

-- Automatic event scheduler
local eventTypes = {
    { name = 'lightning', trigger = 'dr_world_events:triggerLightning' },
    { name = 'acidrain', trigger = 'dr_world_events:triggerAcidRain' },
    { name = 'heatwave', trigger = 'dr_world_events:triggerHeatWave' },
    { name = 'sandstorm', trigger = 'dr_world_events:triggerSandstorm' },
    { name = 'fog', trigger = 'dr_world_events:triggerFog' },
    { name = 'blackout', trigger = 'dr_world_events:triggerBlackout' },
    { name = 'meteor', trigger = 'dr_world_events:triggerMeteorShower' },
    { name = 'tornado', trigger = 'dr_world_events:triggerTornado' },
    { name = 'emp', trigger = 'dr_world_events:triggerEMP' },
    { name = 'gravity', trigger = 'dr_world_events:triggerGravity' },
    { name = 'slowmo', trigger = 'dr_world_events:triggerSlowMo' },
    { name = 'highgravity', trigger = 'dr_world_events:triggerHighGravity' },
    { name = 'vehiclechaos', trigger = 'dr_world_events:triggerVehicleChaos' },
    { name = 'police', trigger = 'dr_world_events:triggerPolicePursuit' }
}

    local function scheduleRandomEvent()
    -- Schedule next event in 30 minutes (1800000 ms)
    SetTimeout(1800000, function()
        -- Pick random event
        local randomEvent = eventTypes[math.random(1, #eventTypes)]
        TriggerEvent(randomEvent.trigger)

        -- Schedule next event after current one finishes (1 hour + 30 min wait)
        SetTimeout(5400000, scheduleRandomEvent)
    end)
end

-- Start the scheduler when resource starts
CreateThread(function()
    Wait(5000) -- Wait 5 seconds after server start
    scheduleRandomEvent()
    print('[World Events] Automatic event scheduler started')
end)

-- Admin command to trigger earthquake
QBCore.Commands.Add('triggerearthquake', 'Trigger earthquake event (Admin)', {}, true, function(source)
    TriggerClientEvent("dr-Earthquake:Random", -1)
    TriggerClientEvent('ox_lib:notify', -1, {
        title = '🌍 EARTHQUAKE!',
        description = 'A massive earthquake is shaking the city!',
        type = 'error',
        duration = 10000
    })
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'World Events',
        description = 'Earthquake triggered!',
        type = 'success'
    })
end, 'admin')
