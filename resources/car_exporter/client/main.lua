local QBCore = exports['qbx_core']:GetCoreObject()
local isNearExportZone = false
local exportZone = nil
local currentHotCar = nil
local exportCooldown = 0
local hotCarBlip = nil -- For tracking other players in hot car
local isInHotCar = false
local lastHotCarUpdate = 0
local hotCarMarkerBlip = nil -- GPS blip to hot car location
local spawnedHotCarEntity = nil -- Track spawned hot car entity

-- Chat suggestions (autocomplete for / commands)
CreateThread(function()
    -- Player commands
    TriggerEvent('chat:addSuggestion', '/hotcar', 'Check the current hot car and bonus price')
    TriggerEvent('chat:addSuggestion', '/hottimer', 'See exact countdown until hot car rotates')
    
    -- Admin commands
    TriggerEvent('chat:addSuggestion', '/giveveh', '[Admin] Spawn vehicle for self or another player', {
        { name = 'vehicle', help = 'Vehicle spawn name (e.g., adder, zentorno)' },
        { name = 'playerid', help = '(Optional) Target player ID - empty for self' }
    })
    TriggerEvent('chat:addSuggestion', '/spawnhotcar', '[Admin] Spawn the current hot car next to you')
    TriggerEvent('chat:addSuggestion', '/spawnexport', '[Admin] Spawn an exportable vehicle', {
        { name = 'vehicle', help = 'Vehicle spawn name from price list' }
    })
    TriggerEvent('chat:addSuggestion', '/sethotcar', '[Admin] Force a specific vehicle as hot car', {
        { name = 'vehicle', help = 'Vehicle spawn name' }
    })
    TriggerEvent('chat:addSuggestion', '/forcerotate', '[Admin] Rotate hot car to a new random vehicle')
    TriggerEvent('chat:addSuggestion', '/resettimer', '[Admin] Reset hot car rotation timer', {
        { name = 'seconds', help = 'Seconds until rotation (default 30)' }
    })
    TriggerEvent('chat:addSuggestion', '/testmoney', '[Admin] Give yourself $100k cash + $1M bank')
    TriggerEvent('chat:addSuggestion', '/exporterstats', '[Admin] View recent vehicle exports')
end)

-- Create blip
CreateThread(function()
    if Config.Blip.enabled then
        local blip = AddBlipForCoord(Config.ExportLocation.x, Config.ExportLocation.y, Config.ExportLocation.z)
        SetBlipSprite(blip, Config.Blip.sprite)
        SetBlipColour(blip, Config.Blip.color)
        SetBlipScale(blip, Config.Blip.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(Config.Blip.label)
        EndTextCommandSetBlipName(blip)
    end
end)

-- Spawn export ped
CreateThread(function()
    local model = Config.ExportPedModel
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(1) end
    
    local ped = CreatePed(4, GetHashKey(model), Config.ExportLocation.x, Config.ExportLocation.y, Config.ExportLocation.z - 1.0, Config.ExportHeading, false, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetPedDiesWhenInjured(ped, false)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    SetPedCanBeTargetted(ped, false)
    
    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'export_vehicle',
            icon = 'fa-solid fa-car',
            label = 'Export Vehicle',
            onSelect = function()
                TryExportVehicle()
            end
        },
        {
            name = 'check_hot_car',
            icon = 'fa-solid fa-fire',
            label = 'Check Hot Car',
            onSelect = function()
                CheckHotCar()
            end
        }
    })
end)

-- Get current hot car from server
RegisterNetEvent('car_exporter:updateHotCar', function(vehName)
    currentHotCar = vehName
end)

-- Check hot car info
function CheckHotCar()
    if not currentHotCar then
        lib.notify({ title = 'Vehicle Exporter', description = 'No hot car currently set. Check back soon!', type = 'info' })
        return
    end
    
    local price = Config.VehiclePrices[currentHotCar] or 5000
    local bonusPrice = math.floor(price * Config.HotCarMultiplier)
    
    lib.alertDialog({
        header = 'Current Hot Car',
        content = '**Vehicle:** ' .. currentHotCar:upper() .. '\n\n**Base Price:** $' .. price .. '\n\n**Hot Car Bonus Price:** $' .. bonusPrice .. ' (' .. (Config.HotCarMultiplier * 100) .. '% bonus)',
        centered = true,
        cancel = false
    })
end

-- Try to export the vehicle
function TryExportVehicle()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Check cooldown
    if GetGameTimer() < exportCooldown then
        local remaining = math.ceil((exportCooldown - GetGameTimer()) / 1000 / 60)
        lib.notify({ title = 'Vehicle Exporter', description = 'Export on cooldown. Wait ' .. remaining .. ' minutes.', type = 'error' })
        return
    end
    
    -- Check if in vehicle
    if not IsPedInAnyVehicle(playerPed, false) then
        lib.notify({ title = 'Vehicle Exporter', description = 'You need to be in a vehicle to export!', type = 'error' })
        return
    end
    
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    local vehicleCoords = GetEntityCoords(vehicle)
    local dist = #(playerCoords - Config.ExportLocation)
    
    if dist > Config.ExportDistance then
        lib.notify({ title = 'Vehicle Exporter', description = 'Drive closer to the export zone!', type = 'error' })
        return
    end
    
    -- Get vehicle info
    local model = GetEntityModel(vehicle)
    local displayName = GetDisplayNameFromVehicleModel(model)
    local vehName = string.lower(displayName)
    local vehicleHealth = GetVehicleBodyHealth(vehicle)
    
    -- Check vehicle health
    if vehicleHealth < Config.MinVehicleHealth then
        lib.notify({ title = 'Vehicle Exporter', description = 'This vehicle is too damaged! Repair it first.', type = 'error' })
        return
    end
    
    -- Check if vehicle is in our price list
    local basePrice = Config.VehiclePrices[vehName]
    if not basePrice then
        lib.notify({ title = 'Vehicle Exporter', description = 'We don\'t want this type of vehicle.', type = 'error' })
        return
    end
    
    -- Calculate final price
    local isHotCar = (vehName == currentHotCar)
    local finalPrice = basePrice
    if isHotCar then
        finalPrice = math.floor(basePrice * Config.HotCarMultiplier)
    end
    
    -- Apply health damage penalty
    local healthPercent = vehicleHealth / 1000
    finalPrice = math.floor(finalPrice * healthPercent)
    
    -- Confirm export
    local hotText = isHotCar and ' (HOT CAR BONUS!)' or ''
    local confirm = lib.alertDialog({
        header = 'Export Vehicle?',
        content = '**Vehicle:** ' .. displayName:upper() .. hotText .. '\n\n**Condition:** ' .. math.floor(healthPercent * 100) .. '%\n\n**Offer:** $' .. finalPrice,
        centered = true,
        cancel = true
    })
    
    if confirm ~= 'confirm' then return end
    
    -- Eject player from vehicle
    TaskLeaveVehicle(playerPed, vehicle, 0)
    Wait(2000)
    
    -- Delete vehicle and pay player
    local vehNetId = NetworkGetNetworkIdFromEntity(vehicle)
    TriggerServerEvent('car_exporter:processExport', vehName, finalPrice, vehNetId)
    
    exportCooldown = GetGameTimer() + (Config.ExportCooldown * 1000)
end

-- Draw 3D text for zone + green arrow above hot car
CreateThread(function()
    while true do
        local sleep = 1000
        local playerCoords = GetEntityCoords(PlayerPedId())
        local dist = #(playerCoords - Config.ExportLocation)
        
        if dist < 20.0 then
            sleep = 0
            if dist < 10.0 then
                DrawMarker(1, Config.ExportLocation.x, Config.ExportLocation.y, Config.ExportLocation.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 5.0, 5.0, 1.0, 255, 165, 0, 100, false, true, 2, false, nil, nil, false)
                
                if dist < 5.0 and not IsPedInAnyVehicle(PlayerPedId(), false) then
                    DrawText3D(Config.ExportLocation.x, Config.ExportLocation.y, Config.ExportLocation.z + 1.0, '~y~Vehicle Exporter~w~\nTalk to the dealer')
                end
            end
        end
        
        -- Green arrow above hot car if spawned and close
        if spawnedHotCarEntity and DoesEntityExist(spawnedHotCarEntity) then
            local vehCoords = GetEntityCoords(spawnedHotCarEntity)
            local vehDist = #(playerCoords - vehCoords)
            
            if vehDist < 50.0 then
                sleep = 0
                -- Draw green arrow marker above the car
                DrawMarker(42, vehCoords.x, vehCoords.y, vehCoords.z + 2.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 1.5, 0, 255, 0, 150, false, true, 2, false, nil, nil, false)
                
                if vehDist < 15.0 then
                    DrawText3D(vehCoords.x, vehCoords.y, vehCoords.z + 3.5, '~g~HOT CAR~w~\nDrive to docks!')
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- Helper function for 3D text
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry('STRING')
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- Hot Car Tracking System
-- Check if local player is driving hot car
CreateThread(function()
    while true do
        Wait(1000)
        
        if not currentHotCar then
            if isInHotCar then
                isInHotCar = false
                TriggerServerEvent('car_exporter:hotCarStatus', false)
                lib.notify({ title = 'Hot Car', description = 'You are no longer in the hot car.', type = 'info' })
            end
            goto continue
        end
        
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        if IsPedInAnyVehicle(playerPed, false) then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            if GetPedInVehicleSeat(vehicle, -1) == playerPed then
                local model = GetEntityModel(vehicle)
                local displayName = GetDisplayNameFromVehicleModel(model)
                local vehName = string.lower(displayName)
                
                if vehName == currentHotCar then
                    if not isInHotCar then
                        isInHotCar = true
                        -- Red flashing screen effect
                        CreateThread(function()
                            for i = 1, 6 do
                                SetFlash(0, 0, 100, 255, 255, 0, 0, 100)
                                Wait(150)
                            end
                        end)
                        -- Prominent notification
                        lib.notify({ title = '🔥 HOT CAR ALERT! 🔥', description = 'You are driving the HOT CAR! Everyone can see you! DRIVE TO THE DOCKS NOW!', type = 'error', duration = 12000 })
                        -- Also show alert dialog
                        lib.alertDialog({
                            header = '🔥 HOT CAR! 🔥',
                            content = 'You are in the HOT CAR!\n\nEveryone on the server can see you on the map!\n\n**DRIVE TO THE DOCKS NOW TO EXPORT IT!**',
                            centered = true,
                            cancel = false
                        })
                        TriggerServerEvent('car_exporter:hotCarStatus', true, playerCoords)
                    elseif GetGameTimer() - lastHotCarUpdate > 2000 then
                        -- Update position every 2 seconds
                        lastHotCarUpdate = GetGameTimer()
                        TriggerServerEvent('car_exporter:hotCarUpdate', playerCoords)
                    end
                else
                    if isInHotCar then
                        isInHotCar = false
                        TriggerServerEvent('car_exporter:hotCarStatus', false)
                    end
                end
            else
                if isInHotCar then
                    isInHotCar = false
                    TriggerServerEvent('car_exporter:hotCarStatus', false)
                end
            end
        else
            if isInHotCar then
                isInHotCar = false
                TriggerServerEvent('car_exporter:hotCarStatus', false)
            end
        end
        
        ::continue::
    end
end)

-- Show other players driving hot car on map
RegisterNetEvent('car_exporter:updateHotCarTracker', function(playerId, playerName, coords, isActive)
    local myId = GetPlayerServerId(PlayerId())
    
    -- Don't show our own blip
    if playerId == myId then return end
    
    -- Remove old blip if exists
    if hotCarBlip then
        RemoveBlip(hotCarBlip)
        hotCarBlip = nil
    end
    
    if isActive and coords then
        -- Create new blip at player position
        hotCarBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(hotCarBlip, 523) -- 523 = personal vehicle icon
        SetBlipColour(hotCarBlip, 1) -- Red color
        SetBlipScale(hotCarBlip, 1.2)
        SetBlipFlashes(hotCarBlip, true)
        SetBlipFlashInterval(hotCarBlip, 500)
        SetBlipAsShortRange(hotCarBlip, false)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName('HOT CAR: ' .. playerName)
        EndTextCommandSetBlipName(hotCarBlip)
        
        lib.notify({ title = 'Hot Car Spotted!', description = playerName .. ' is driving the hot car! Get them!', type = 'warning', duration = 5000 })
    end
end)

-- Admin: Spawn vehicle for testing
RegisterNetEvent('car_exporter:adminSpawnVehicle', function(vehName)
    local model = GetHashKey(vehName)
    RequestModel(model)
    
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 100 do
        Wait(50)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(model) then
        lib.notify({ title = 'Spawn Error', description = 'Failed to load model: ' .. vehName, type = 'error' })
        return
    end
    
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    
    local vehicle = CreateVehicle(model, coords.x + 3.0, coords.y, coords.z, heading, true, false)
    local plate = 'TEST' .. math.random(100, 999)
    SetVehicleNumberPlateText(vehicle, plate)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehicleDoorsLocked(vehicle, 1)
    SetVehicleDoorsLockedForAllPlayers(vehicle, false)
    SetVehicleEngineOn(vehicle, true, true, false)
    
    -- Give the spawning player keys (qbx_vehiclekeys uses lib.callback)
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    lib.callback('qbx_vehiclekeys:server:giveKeys', false, function() end, netId)
    
    SetModelAsNoLongerNeeded(model)
    
    -- Track if this is the hot car
    if vehName == currentHotCar then
        spawnedHotCarEntity = vehicle
        -- Add GPS blip to the hot car
        if hotCarMarkerBlip then RemoveBlip(hotCarMarkerBlip) end
        hotCarMarkerBlip = AddBlipForEntity(vehicle)
        SetBlipSprite(hotCarMarkerBlip, 523)
        SetBlipColour(hotCarMarkerBlip, 5) -- Green color
        SetBlipScale(hotCarMarkerBlip, 1.3)
        SetBlipFlashes(hotCarMarkerBlip, true)
        SetBlipFlashInterval(hotCarMarkerBlip, 300)
        SetBlipRoute(hotCarMarkerBlip, true)
        SetBlipRouteColour(hotCarMarkerBlip, 5)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName('YOUR HOT CAR')
        EndTextCommandSetBlipName(hotCarMarkerBlip)
        
        lib.notify({ title = 'HOT CAR SPAWNED!', description = vehName:upper() .. ' spawned! GPS route set. Drive to docks!', type = 'warning', duration = 10000 })
    else
        lib.notify({ title = 'Vehicle Spawned', description = vehName:upper() .. ' spawned & unlocked', type = 'success' })
    end
    
    -- GPS blip to hot car
    if hotCarMarkerBlip then
        RemoveBlip(hotCarMarkerBlip)
        hotCarMarkerBlip = nil
    end
    
    spawnedHotCarEntity = nil
    
    -- Clear 
end)

-- Delete vehicle after successful export
RegisterNetEvent('car_exporter:deleteVehicle', function(vehNetId)
    local vehicle = NetworkGetEntityFromNetworkId(vehNetId)
    if DoesEntityExist(vehicle) then
        DeleteEntity(vehicle)
    end
    
    -- Clear hot car blip if we were tracking it
    if hotCarBlip then
        RemoveBlip(hotCarBlip)
        hotCarBlip = nil
    end
    
    -- Clear our hot car status
    if isInHotCar then
        isInHotCar = false
        TriggerServerEvent('car_exporter:hotCarStatus', false)
    end
end)
