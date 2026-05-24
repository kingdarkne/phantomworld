local menuOpen = false
local QBCore = exports['qbx_core']:GetCoreObject()
local playerLoaded = false
local loadTime = 0

-- Track when player is fully loaded
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerLoaded = true
    loadTime = GetGameTimer()

    -- Clear any lingering visual effects
    ClearTimecycleModifier()
    ClearAllBrokenGlass()
    ClearAllHelpMessages()
    ClearFloatingHelp()
    ClearGpsFlags()
    ClearPedTasks(PlayerPedId())
    SetBlackout(false)
    SetArtificialLightsState(false)
    SetWeatherTypePersist('CLEAR')
    SetWeatherTypeNow('CLEAR')
    SetWeatherTypeNowPersist('CLEAR')
    SetGravityLevel(1.0)
    SetTimeScale(1.0)
    NetworkOverrideClockTime(12, 0, 0)
    print('[World Events] Cleared all effects on player load')
end)

-- Clear effects on resource start
CreateThread(function()
    Wait(2000)
    ClearTimecycleModifier()
    ClearAllBrokenGlass()
    ClearAllHelpMessages()
    ClearFloatingHelp()
    ClearGpsFlags()
    SetBlackout(false)
    SetArtificialLightsState(false)
    SetWeatherTypePersist('CLEAR')
    SetWeatherTypeNow('CLEAR')
    SetWeatherTypeNowPersist('CLEAR')
    SetGravityLevel(1.0)
    SetTimeScale(1.0)
    NetworkOverrideClockTime(12, 0, 0)
    print('[World Events] Cleared all effects on resource start')
end)

-- Periodically clear effects to prevent lingering
CreateThread(function()
    while true do
        Wait(30000) -- Every 30 seconds
        if not fogActive and not blackoutActive and not sandstormActive then
            ClearTimecycleModifier()
            SetBlackout(false)
            SetArtificialLightsState(false)
        end
    end
end)

-- Check if player is admin
local function isAdmin(Player)
    if not Player then return false end
    return Player.metadata['isadmin'] or Player.metadata['admin'] or
           IsPlayerAceAllowed(Player.source, 'command.admin') or
           IsPlayerAceAllowed(Player.source, 'command.easyadmin')
end

local function openMenu()
    if menuOpen then
        -- If already open, close first then reopen
        closeMenu()
        Wait(100)
    end

    -- Ensure clean state
    SetNuiFocus(false, false)
    Wait(50)

    menuOpen = true

    -- Send to NUI first
    SendNUIMessage({ action = 'open', isAdmin = true })

    -- Then set focus after short delay
    Wait(100)
    SetNuiFocus(true, true)
end

local function closeMenu()
    if not menuOpen then return end
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterNUICallback('close', function(_, cb)
    closeMenu()
    cb('ok')
end)

RegisterNUICallback('triggerEvent', function(data, cb)
    local eventType = data.event

    -- Check if player is admin before triggering
    QBCore.Functions.TriggerCallback('dr_world_events:server:isAdmin', function(isAdmin)
        if isAdmin then
            if eventType == 'earthquake' then
                TriggerServerEvent('dr_world_events:triggerEarthquake')
                lib.notify({ title = 'World Events', description = 'Triggering earthquake...', type = 'info' })
            elseif eventType == 'explosion' then
                TriggerServerEvent('dr_world_events:triggerExplosion')
                lib.notify({ title = 'World Events', description = 'Explosion triggered at your location!', type = 'warning' })
            elseif eventType == 'lightning' then
                TriggerServerEvent('dr_world_events:triggerLightning')
                lib.notify({ title = 'World Events', description = 'Triggering lightning storm...', type = 'info' })
            elseif eventType == 'acidrain' then
                TriggerServerEvent('dr_world_events:triggerAcidRain')
                lib.notify({ title = 'World Events', description = 'Triggering acid rain...', type = 'info' })
            elseif eventType == 'heatwave' then
                TriggerServerEvent('dr_world_events:triggerHeatWave')
                lib.notify({ title = 'World Events', description = 'Triggering heat wave...', type = 'info' })
            elseif eventType == 'sandstorm' then
                TriggerServerEvent('dr_world_events:triggerSandstorm')
                lib.notify({ title = 'World Events', description = 'Triggering sandstorm...', type = 'info' })
            elseif eventType == 'fog' then
                TriggerServerEvent('dr_world_events:triggerFog')
                lib.notify({ title = 'World Events', description = 'Triggering fog...', type = 'info' })
            elseif eventType == 'blackout' then
                TriggerServerEvent('dr_world_events:triggerBlackout')
                lib.notify({ title = 'World Events', description = 'Triggering blackout...', type = 'info' })
            elseif eventType == 'meteor' then
                TriggerServerEvent('dr_world_events:triggerMeteorShower')
                lib.notify({ title = 'World Events', description = 'Triggering meteor shower...', type = 'info' })
            elseif eventType == 'tornado' then
                TriggerServerEvent('dr_world_events:triggerTornado')
                lib.notify({ title = 'World Events', description = 'Triggering tornado...', type = 'info' })
            elseif eventType == 'emp' then
                TriggerServerEvent('dr_world_events:triggerEMP')
                lib.notify({ title = 'World Events', description = 'Triggering EMP blast...', type = 'info' })
            elseif eventType == 'gravity' then
                TriggerServerEvent('dr_world_events:triggerGravity')
                lib.notify({ title = 'World Events', description = 'Triggering gravity anomaly...', type = 'info' })
            elseif eventType == 'slowmo' then
                TriggerServerEvent('dr_world_events:triggerSlowMo')
                lib.notify({ title = 'World Events', description = 'Triggering slow motion...', type = 'info' })
            elseif eventType == 'highgravity' then
                TriggerServerEvent('dr_world_events:triggerHighGravity')
                lib.notify({ title = 'World Events', description = 'Triggering high gravity...', type = 'info' })
            elseif eventType == 'vehiclechaos' then
                TriggerServerEvent('dr_world_events:triggerVehicleChaos')
                lib.notify({ title = 'World Events', description = 'Triggering vehicle chaos...', type = 'info' })
            elseif eventType == 'police' then
                TriggerServerEvent('dr_world_events:triggerPolicePursuit')
                lib.notify({ title = 'World Events', description = 'Triggering police pursuit...', type = 'info' })
            end
        else
            lib.notify({ title = 'Access Denied', description = 'Only admins can trigger events', type = 'error' })
        end
    end)
    cb('ok')
end)

RegisterCommand('worldevents', function()
    openMenu()
end, false)

-- Reset command in case menu gets stuck
RegisterCommand('resetworldevents', function()
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    Wait(500)
    lib.notify({ title = 'World Events', description = 'Menu reset. Use /worldevents to reopen', type = 'info' })
end, false)

RegisterKeyMapping('worldevents', 'Open World Events Panel', 'keyboard', 'F8')

-- Close menu with ESC
CreateThread(function()
    while true do
        Wait(0)
        if menuOpen and IsControlJustPressed(0, 200) then -- 200 is ESC
            closeMenu()
        end
    end
end)

-- Listen for event notifications
RegisterNetEvent('dr_world_events:notify', function(message, type)
    lib.notify({ title = 'World Event', description = message, type = type or 'info', duration = 8000 })
end)

-- Trigger explosion at player location
RegisterNetEvent('dr_world_events:explodeAtPlayer', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    -- Multiple explosions for dramatic effect
    for i = 1, 5 do
        local offsetX = math.random(-20, 20)
        local offsetY = math.random(-20, 20)
        AddExplosion(coords.x + offsetX, coords.y + offsetY, coords.z, 59, 100.0, true, false, 1.0)
        Wait(100)
    end

    -- Strong camera shake
    ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 5.0)

    -- Screen flash
    SetFlash(0, 0, 1000, 5000, 1000)

    -- Timecycle modifier for earthquake effect
    SetTimecycleModifier('BeastIntro01')
    SetTimecycleModifierStrength(0.5)

    -- Damage and ragdoll nearby NPCs
    local nearbyPeds = GetGamePool('CPed')
    for _, npc in ipairs(nearbyPeds) do
        local npcCoords = GetEntityCoords(npc)
        local distance = #(coords - npcCoords)
        if distance < 50.0 and npc ~= ped then
            ApplyDamageToPed(npc, 100, true)
            SetPedToRagdoll(npc, 2000, 2000, 0, false, false, false)
            -- Make NPCs flee
            TaskSmartFleeCoord(npc, coords, 100.0, -1, false, false)
        end
    end

    -- Clear effects after delay
    SetTimeout(5000, function()
        ClearTimecycleModifier()
        StopGameplayCamShaking(true)
    end)
end)

-- Lightning storm effects
local lightningActive = false
local lightningThread = nil

RegisterNetEvent('dr_world_events:startLightning', function()
    if lightningActive then return end
    lightningActive = true

    -- Play alarm sound
    PlaySoundFrontend(-1, "Boss_Message_Orange", "GTAO_Boss_Goons_FM_Soundset", true)

    lightningThread = CreateThread(function()
        while lightningActive do
            Wait(math.random(2000, 8000)) -- Random interval between strikes

            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            -- Create lightning strike near player
            local strikeX = coords.x + math.random(-100, 100)
            local strikeY = coords.y + math.random(-100, 100)
            local strikeZ = coords.z + math.random(50, 100)

            -- Add explosion for lightning effect
            AddExplosion(strikeX, strikeY, strikeZ, 38, 5.0, true, false, 1.0)

            -- Flash screen brighter
            SetFlash(0, 0, 1000, 5000, 1000)

            -- Strong camera shake
            ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 2.0)

            -- Play thunder sound
            PlaySoundFrontend(-1, "Thunder", "WeatherDropsSounds", true)

            -- Damage nearby NPCs
            local nearbyPeds = GetGamePool('CPed')
            for _, npc in ipairs(nearbyPeds) do
                local npcCoords = GetEntityCoords(npc)
                local distance = #(vector3(strikeX, strikeY, strikeZ) - npcCoords)
                if distance < 30.0 and npc ~= ped then
                    ApplyDamageToPed(npc, 50, true)
                    SetPedToRagdoll(npc, 1000, 1000, 0, false, false, false)
                end
            end

            -- Remove light after delay
            SetTimeout(1000, function()
                RemoveLight(light)
            end)

            -- Wait between strikes
            Wait(500)
        end
    end)

    lib.notify({ title = 'Lightning Storm', description = 'Seek shelter!', type = 'error', duration = 8000 })
end)

RegisterNetEvent('dr_world_events:stopLightning', function()
    lightningActive = false
    if lightningThread then
        lightningThread = nil
    end
    lib.notify({ title = 'Weather Update', description = 'Lightning storm has passed', type = 'inform', duration = 5000 })
end)

-- Acid rain effects
local acidRainActive = false
local acidRainThread = nil

RegisterNetEvent('dr_world_events:startAcidRain', function()
    if acidRainActive then return end
    acidRainActive = true

    -- Play alarm sound
    PlaySoundFrontend(-1, "Boss_Message_Orange", "GTAO_Boss_Goons_FM_Soundset", true)

    -- Set weather to rain
    SetWeatherTypePersist('THUNDER')
    SetWeatherTypeNow('THUNDER')
    SetWeatherTypeNowPersist('THUNDER')

    acidRainThread = CreateThread(function()
        while acidRainActive do
            Wait(1000)

            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)

            -- Damage vehicles if player is in one
            if vehicle ~= 0 and DoesEntityExist(vehicle) then
                local health = GetEntityHealth(vehicle)
                if health > 200 then

            -- Damage nearby NPCs
            local nearbyPeds = GetGamePool('CPed')
            for _, npc in ipairs(nearbyPeds) do
                if npc ~= ped then
                    local npcHealth = GetEntityHealth(npc)
                    if npcHealth > 100 then
                        SetEntityHealth(npc, npcHealth - 3)
                    end
                end
            end
                    SetEntityHealth(vehicle, health - 5) -- Slowly damage vehicle
                end
            end

            -- Small chance to damage player if on foot
            if vehicle == 0 then
                if math.random(1, 100) <= 5 then -- 5% chance per second
                    local playerHealth = GetEntityHealth(ped)
                    if playerHealth > 100 then
                        SetEntityHealth(ped, playerHealth - 5)
                    end
                end
            end
        end
    end)

    lib.notify({ title = 'Acid Rain', description = 'Dangerous conditions! Vehicles will be damaged!', type = 'error', duration = 8000 })
end)

RegisterNetEvent('dr_world_events:stopAcidRain', function()
    acidRainActive = false
    if acidRainThread then
        acidRainThread = nil
    end
    
    ClearTimecycleModifier()
    SetWeatherTypePersist('CLEAR')
    SetWeatherTypeNow('CLEAR')
    SetWeatherTypeNowPersist('CLEAR')
    lib.notify({ title = 'Weather Update', description = 'Acid rain has stopped', type = 'inform', duration = 5000 })
end)

-- Heat Wave
local heatWaveActive = false
local heatWaveThread = nil

RegisterNetEvent('dr_world_events:startHeatWave', function()
    if heatWaveActive then return end
    heatWaveActive = true
    PlaySoundFrontend(-1, "Boss_Message_Orange", "GTAO_Boss_Goons_FM_Soundset", true)
    
    -- Add heat wave visual effect
    SetTimecycleModifier('casino_main_floor_seist')
    SetTimecycleModifierStrength(0.3)
    
    SetWeatherTypePersist('CLEAR')
    SetWeatherTypeNow('CLEAR')
    SetWeatherTypeNowPersist('CLEAR')

    heatWaveThread = CreateThread(function()
        while heatWaveActive do
            Wait(1000)
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            
            -- Vehicle engine damage
            if vehicle ~= 0 and DoesEntityExist(vehicle) then
                if GetIsVehicleEngineRunning(vehicle) then
                    local health = GetVehicleEngineHealth(vehicle)
                    if health > 200 then
                        SetVehicleEngineHealth(vehicle, health - 2)
                    end
                end
            end
        end
    end)

    lib.notify({ title = 'Heat Wave', description = 'Extreme temperatures! Stay hydrated!', type = 'error', duration = 8000 })
end)

RegisterNetEvent('dr_world_events:stopHeatWave', function()
    heatWaveActive = false
    if heatWaveThread then heatWaveThread = nil end
    ClearTimecycleModifier()
    lib.notify({ title = 'Weather Update', description = 'Heat wave has passed', type = 'inform', duration = 5000 })
end)

-- Sandstorm
local sandstormActive = false
local sandstormThread = nil

RegisterNetEvent('dr_world_events:startSandstorm', function()
    if sandstormActive then return end
    sandstormActive = true
    PlaySoundFrontend(-1, "Boss_Message_Orange", "GTAO_Boss_Goons_FM_Soundset", true)

    SetWeatherTypePersist('XMAS')
    SetWeatherTypeNow('XMAS')
    SetWeatherTypeNowPersist('XMAS')

    sandstormThread = CreateThread(function()
        while sandstormActive do
            Wait(100)
            -- Reduced visibility effect
            SetArtificialLightsState(true)
        end
    end)

    lib.notify({ title = 'Sandstorm', description = 'Visibility severely reduced!', type = 'error', duration = 8000 })
end)

RegisterNetEvent('dr_world_events:stopSandstorm', function()
    sandstormActive = false
    if sandstormThread then sandstormThread = nil end
    SetArtificialLightsState(false)
    SetWeatherTypePersist('CLEAR')
    SetWeatherTypeNow('CLEAR')
    SetWeatherTypeNowPersist('CLEAR')
    lib.notify({ title = 'Weather Update', description = 'Sandstorm has cleared', type = 'inform', duration = 5000 })
end)

-- Fog
local fogActive = false

RegisterNetEvent('dr_world_events:startFog', function()
    if fogActive then return end
    fogActive = true
    PlaySoundFrontend(-1, "Boss_Message_Orange", "GTAO_Boss_Goons_FM_Soundset", true)

    SetTimecycleModifier('halloween')
    SetTimecycleModifierStrength(0.8)

    lib.notify({ title = 'Dense Fog', description = 'Visibility extremely low!', type = 'error', duration = 8000 })
end)

RegisterNetEvent('dr_world_events:stopFog', function()
    fogActive = false
    ClearTimecycleModifier()
    lib.notify({ title = 'Weather Update', description = 'Fog has lifted', type = 'inform', duration = 5000 })
end)

-- Blackout
local blackoutActive = false

RegisterNetEvent('dr_world_events:startBlackout', function()
    if blackoutActive then return end
    blackoutActive = true
    PlaySoundFrontend(-1, "Boss_Message_Orange", "GTAO_Boss_Goons_FM_Soundset", true)

    SetArtificialLightsState(true)
    SetBlackout(true)

    lib.notify({ title = 'Blackout', description = 'City-wide power failure!', type = 'error', duration = 8000 })
end)

RegisterNetEvent('dr_world_events:stopBlackout', function()
    blackoutActive = false
    SetArtificialLightsState(false)
    SetBlackout(false)
    lib.notify({ title = 'Power Restored', description = 'City power has been restored', type = 'inform', duration = 5000 })
end)

-- Meteor Shower
local meteorShowerActive = false
local meteorThread = nil

RegisterNetEvent('dr_world_events:startMeteorShower', function()
    if meteorShowerActive then return end
    meteorShowerActive = true
    PlaySoundFrontend(-1, "Boss_Message_Orange", "GTAO_Boss_Goons_FM_Soundset", true)

    meteorThread = CreateThread(function()
        while meteorShowerActive do
            Wait(math.random(3000, 8000))
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local strikeX = coords.x + math.random(-200, 200)
            local strikeY = coords.y + math.random(-200, 200)
            local strikeZ = coords.z + math.random(100, 200)
            AddExplosion(strikeX, strikeY, strikeZ, 59, 50.0, true, false, 1.0)
            SetFlash(0, 0, 500, 3000, 500)
            ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 0.8)
        end
    end)

    lib.notify({ title = 'Meteor Shower', description = 'Meteors falling from the sky!', type = 'error', duration = 8000 })
end)

RegisterNetEvent('dr_world_events:stopMeteorShower', function()
    meteorShowerActive = false
    if meteorThread then meteorThread = nil end
    lib.notify({ title = 'Weather Update', description = 'Meteor shower has ended', type = 'inform', duration = 5000 })
end)

-- Tornado
local tornadoActive = false
local tornadoThread = nil

RegisterNetEvent('dr_world_events:startTornado', function()
    if tornadoActive then return end
    tornadoActive = true
    PlaySoundFrontend(-1, "Boss_Message_Orange", "GTAO_Boss_Goons_FM_Soundset", true)

    tornadoThread = CreateThread(function()
        while tornadoActive do
            Wait(100)
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local vehicle = GetVehiclePedIsIn(ped, false)
            
            -- Pull effect
            if vehicle ~= 0 then
                ApplyForceToEntity(vehicle, 1, 0.0, 0.0, 5.0, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
            end
        end
    end)

    lib.notify({ title = 'Tornado', description = 'Seek shelter immediately!', type = 'error', duration = 8000 })
end)

RegisterNetEvent('dr_world_events:stopTornado', function()
    tornadoActive = false
    if tornadoThread then tornadoThread = nil end
    lib.notify({ title = 'Weather Update', description = 'Tornado has dissipated', type = 'inform', duration = 5000 })
end)

-- EMP
local empActive = false
local empThread = nil

RegisterNetEvent('dr_world_events:startEMP', function()
    if empActive then return end
    empActive = true
    PlaySoundFrontend(-1, "Boss_Message_Orange", "GTAO_Boss_Goons_FM_Soundset", true)

    empThread = CreateThread(function()
        while empActive do
            Wait(100)
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            if vehicle ~= 0 then
                SetVehicleEngineOn(vehicle, false, true, true)
            end
        end
    end)

    lib.notify({ title = 'EMP Blast', description = 'All vehicles disabled!', type = 'error', duration = 8000 })
end)

RegisterNetEvent('dr_world_events:stopEMP', function()
    empActive = false
    if empThread then empThread = nil end
    lib.notify({ title = 'Systems Restored', description = 'Vehicle systems restored', type = 'inform', duration = 5000 })
end)

-- Gravity Anomaly (Low Gravity)
local gravityActive = false

RegisterNetEvent('dr_world_events:startGravity', function()
    if gravityActive then return end
    gravityActive = true
    PlaySoundFrontend(-1, "Boss_Message_Orange", "GTAO_Boss_Goons_FM_Soundset", true)
    SetGravityLevel(0.3)
    lib.notify({ title = 'Gravity Anomaly', description = 'Gravity reduced!', type = 'error', duration = 8000 })
end)

RegisterNetEvent('dr_world_events:stopGravity', function()
    gravityActive = false
    SetGravityLevel(1.0)
    lib.notify({ title = 'Gravity Normalized', description = 'Gravity returned to normal', type = 'inform', duration = 5000 })
end)

-- Slow Motion
local slowMoActive = false

RegisterNetEvent('dr_world_events:startSlowMo', function()
    if slowMoActive then return end
    slowMoActive = true
    PlaySoundFrontend(-1, "Boss_Message_Orange", "GTAO_Boss_Goons_FM_Soundset", true)
    SetTimeScale(0.5)
    lib.notify({ title = 'Time Dilation', description = 'Time has slowed!', type = 'error', duration = 8000 })
end)

RegisterNetEvent('dr_world_events:stopSlowMo', function()
    slowMoActive = false
    SetTimeScale(1.0)
    lib.notify({ title = 'Time Restored', description = 'Time returned to normal', type = 'inform', duration = 5000 })
end)

-- High Gravity
local highGravityActive = false

RegisterNetEvent('dr_world_events:startHighGravity', function()
    if highGravityActive then return end
    highGravityActive = true
    PlaySoundFrontend(-1, "Boss_Message_Orange", "GTAO_Boss_Goons_FM_Soundset", true)
    SetGravityLevel(2.0)
    lib.notify({ title = 'High Gravity', description = 'Gravity increased!', type = 'error', duration = 8000 })
end)

RegisterNetEvent('dr_world_events:stopHighGravity', function()
    highGravityActive = false
    SetGravityLevel(1.0)
    lib.notify({ title = 'Gravity Normalized', description = 'Gravity returned to normal', type = 'inform', duration = 5000 })
end)

-- Vehicle Chaos
local vehicleChaosActive = false
local chaosThread = nil

RegisterNetEvent('dr_world_events:startVehicleChaos', function()
    if vehicleChaosActive then return end
    vehicleChaosActive = true
    PlaySoundFrontend(-1, "Boss_Message_Orange", "GTAO_Boss_Goons_FM_Soundset", true)

    chaosThread = CreateThread(function()
        while vehicleChaosActive do
            Wait(500)
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            if vehicle ~= 0 then
                local randomAction = math.random(1, 3)
                if randomAction == 1 then
                    SetVehicleForwardSpeed(vehicle, GetVehicleForwardSpeed(vehicle) + 10)
                elseif randomAction == 2 then
                    SetVehicleSteeringAngle(vehicle, math.random(-1, 1))
                elseif randomAction == 3 then
                    SetVehicleHorn(vehicle, true)
                    Wait(200)
                    SetVehicleHorn(vehicle, false)
                end
            end
        end
    end)

    lib.notify({ title = 'Vehicle Chaos', description = 'Vehicles going crazy!', type = 'error', duration = 8000 })
end)

RegisterNetEvent('dr_world_events:stopVehicleChaos', function()
    vehicleChaosActive = false
    if chaosThread then chaosThread = nil end
    lib.notify({ title = 'Chaos Ended', description = 'Vehicles returned to normal', type = 'inform', duration = 5000 })
end)

-- Police Pursuit
local policePursuitActive = false

RegisterNetEvent('dr_world_events:startPolicePursuit', function()
    if policePursuitActive then return end
    policePursuitActive = true
    PlaySoundFrontend(-1, "Boss_Message_Orange", "GTAO_Boss_Goons_FM_Soundset", true)
    
    -- Set player wanted level
    SetPlayerWantedLevel(PlayerId(), 5, false)
    SetPlayerWantedLevelNow(PlayerId(), 5)
    
    lib.notify({ title = 'Police Pursuit', description = 'Massive police response!', type = 'error', duration = 8000 })
end)

RegisterNetEvent('dr_world_events:stopPolicePursuit', function()
    policePursuitActive = false
    ClearPlayerWantedLevel(PlayerId())
    lib.notify({ title = 'Pursuit Ended', description = 'Police response ended', type = 'inform', duration = 5000 })
end)
