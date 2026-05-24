local QBCore = exports['qbx_core']:GetCoreObject()
local currentHotCar = nil
local lastRotationTime = 0

-- Initialize database table
CreateThread(function()
    exports.oxmysql:executeSync([[
        CREATE TABLE IF NOT EXISTS car_exporter_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(50) NOT NULL,
            vehicle_name VARCHAR(50) NOT NULL,
            price INT NOT NULL,
            is_hot_car BOOLEAN DEFAULT FALSE,
            export_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    
    -- Pick initial hot car
    RotateHotCar()
end)

-- Pick a random hot car
function RotateHotCar()
    if #Config.AllVehicles == 0 then return end
    
    local oldCar = currentHotCar
    local newCar = nil
    
    -- Pick a different car than current
    repeat
        newCar = Config.AllVehicles[math.random(1, #Config.AllVehicles)]
    until newCar ~= oldCar
    
    currentHotCar = newCar
    lastRotationTime = os.time()
    
    -- Notify all players
    local price = Config.VehiclePrices[newCar] or 5000
    local bonusPrice = math.floor(price * Config.HotCarMultiplier)
    
    TriggerClientEvent('ox_lib:notify', -1, {
        title = 'Vehicle Exporter',
        description = 'New Hot Car: ' .. newCar:upper() .. ' - Bonus: $' .. bonusPrice,
        type = 'info',
        duration = 10000
    })
    
    -- Update all clients
    TriggerClientEvent('car_exporter:updateHotCar', -1, currentHotCar)
    
    print('[Car Exporter] Hot car rotated to: ' .. newCar:upper())
end

-- Check for rotation every real hour + periodic announcements
CreateThread(function()
    local lastAnnouncement = 0
    
    while true do
        Wait(60000) -- Check every minute
        
        -- Check if enough real hours have passed (not in-game hours)
        if currentHotCar and (os.time() - lastRotationTime) >= (Config.HotCarRotationHours * 3600) then
            RotateHotCar()
            lastAnnouncement = os.time()
        end
        
        -- Announce every 30 minutes
        if currentHotCar and (os.time() - lastAnnouncement) >= 1800 then
            local timeLeft = (Config.HotCarRotationHours * 3600) - (os.time() - lastRotationTime)
            if timeLeft > 0 then
                local hours = math.floor(timeLeft / 3600)
                local minutes = math.floor((timeLeft % 3600) / 60)
                local timeText = string.format('%dh %02dm', hours, minutes)
                
                TriggerClientEvent('chat:addMessage', -1, {
                    color = {255, 165, 0},
                    multiline = false,
                    args = {'[HOT CAR]', 'Current: ' .. currentHotCar:upper() .. ' | Time Left: ' .. timeText .. ' | Use /hottimer for exact time'}
                })
                lastAnnouncement = os.time()
            end
        end
    end
end)

-- Send current hot car to connecting players
RegisterNetEvent('QBCore:Server:PlayerLoaded', function()
    local src = source
    TriggerClientEvent('car_exporter:updateHotCar', src, currentHotCar)
end)

-- Process vehicle export
RegisterNetEvent('car_exporter:processExport', function(vehName, price, vehNetId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local isHotCar = (vehName == currentHotCar)
    
    -- Add money
    Player.Functions.AddMoney('cash', price)
    
    -- Log to database
    exports.oxmysql:execute([[
        INSERT INTO car_exporter_logs (citizenid, vehicle_name, price, is_hot_car)
        VALUES (?, ?, ?, ?)
    ]], {citizenid, vehName, price, isHotCar})
    
    -- Notify player
    local hotBonusText = isHotCar and ' (HOT CAR BONUS!)' or ''
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Vehicle Exported!',
        description = 'You received $' .. price .. hotBonusText,
        type = 'success'
    })
    
    -- Delete the vehicle on all clients
    TriggerClientEvent('car_exporter:deleteVehicle', -1, vehNetId)
    
    -- If hot car was exported, rotate immediately
    if isHotCar then
        Wait(5000)
        RotateHotCar()
    end
end)

-- Admin command to force rotate hot car
QBCore.Commands.Add('forcerotate', 'Force hot car rotation (Admin)', {}, true, function(source)
    RotateHotCar()
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Car Exporter',
        description = 'Hot car rotated!',
        type = 'success'
    })
end, 'admin')

-- Admin: Set specific vehicle as hot car (for testing)
QBCore.Commands.Add('sethotcar', 'Set a specific vehicle as the hot car (Admin)', {{name = 'vehicle', help = 'Vehicle spawn name (e.g., adder)'}}, true, function(source, args)
    local vehName = args[1] and string.lower(args[1])
    
    if not vehName then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Car Exporter',
            description = 'Usage: /sethotcar [vehicle_name]',
            type = 'error'
        })
        return
    end
    
    if not Config.VehiclePrices[vehName] then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Car Exporter',
            description = 'Vehicle "' .. vehName .. '" not in price list.',
            type = 'error'
        })
        return
    end
    
    currentHotCar = vehName
    lastRotationTime = os.time()
    
    local price = Config.VehiclePrices[vehName] or 5000
    local bonusPrice = math.floor(price * Config.HotCarMultiplier)
    
    TriggerClientEvent('ox_lib:notify', -1, {
        title = 'Vehicle Exporter',
        description = 'New Hot Car: ' .. vehName:upper() .. ' - Bonus: $' .. bonusPrice,
        type = 'info',
        duration = 10000
    })
    
    TriggerClientEvent('car_exporter:updateHotCar', -1, currentHotCar)
    
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Car Exporter',
        description = 'Hot car set to: ' .. vehName:upper(),
        type = 'success'
    })
end, 'admin')

-- Admin: Spawn the current hot car next to you (for testing)
QBCore.Commands.Add('spawnhotcar', 'Spawn the current hot car (Admin)', {}, true, function(source)
    if not currentHotCar then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Car Exporter',
            description = 'No hot car set!',
            type = 'error'
        })
        return
    end
    
    TriggerClientEvent('car_exporter:adminSpawnVehicle', source, currentHotCar)
end, 'admin')

-- Admin: Spawn any vehicle from the price list
QBCore.Commands.Add('spawnexport', 'Spawn an exportable vehicle (Admin)', {{name = 'vehicle', help = 'Vehicle spawn name'}}, true, function(source, args)
    local vehName = args[1] and string.lower(args[1])
    if not vehName or not Config.VehiclePrices[vehName] then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Car Exporter',
            description = 'Usage: /spawnexport [vehicle] - must be in price list',
            type = 'error'
        })
        return
    end
    TriggerClientEvent('car_exporter:adminSpawnVehicle', source, vehName)
end, 'admin')

-- Admin: Reset hot car timer for testing rotations
QBCore.Commands.Add('resettimer', 'Reset hot car timer to trigger rotation soon (Admin)', {{name = 'seconds', help = 'Seconds until rotation (default 30)'}}, true, function(source, args)
    local seconds = tonumber(args[1]) or 30
    -- Set lastRotationTime so timeLeft = seconds
    lastRotationTime = os.time() - (Config.HotCarRotationHours * 3600) + seconds
    
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Car Exporter',
        description = 'Hot car will rotate in ' .. seconds .. ' seconds',
        type = 'success'
    })
end, 'admin')

-- Admin: Give a vehicle (any model) to self or another player with keys
QBCore.Commands.Add('giveveh', 'Spawn a vehicle for self or another player (Admin)', {
    {name = 'vehicle', help = 'Vehicle spawn name (e.g., adder)'},
    {name = 'playerid', help = '(Optional) Target player ID - leave empty for self'}
}, false, function(source, args)
    local vehName = args[1] and string.lower(args[1])
    local targetId = tonumber(args[2])
    
    if not vehName then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Give Vehicle',
            description = 'Usage: /giveveh [vehicle] [playerid]',
            type = 'error'
        })
        return
    end
    
    -- Determine target
    local target = targetId or source
    local isForOther = targetId and targetId ~= source
    
    -- Verify target player exists
    local targetPlayer = QBCore.Functions.GetPlayer(target)
    if not targetPlayer then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Give Vehicle',
            description = 'Target player ID ' .. tostring(target) .. ' is not online.',
            type = 'error'
        })
        return
    end
    
    -- Spawn the vehicle on target's client
    TriggerClientEvent('car_exporter:adminSpawnVehicle', target, vehName)
    
    -- Notify the admin
    if isForOther then
        local targetName = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Vehicle Given',
            description = 'Spawned ' .. vehName:upper() .. ' for ' .. targetName .. ' (ID: ' .. target .. ')',
            type = 'success',
            duration = 6000
        })
        
        -- Notify the target player to store it
        TriggerClientEvent('ox_lib:notify', target, {
            title = 'Vehicle Received',
            description = 'An admin gave you a ' .. vehName:upper() .. '. Take it to a Prepaid Storage / Garage to keep it safe!',
            type = 'warning',
            duration = 12000
        })
    else
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Vehicle Spawned',
            description = vehName:upper() .. ' spawned for you.',
            type = 'success'
        })
    end
end, 'admin')

-- Admin: Give yourself max money for testing
QBCore.Commands.Add('testmoney', 'Give yourself test money (Admin)', {}, true, function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    Player.Functions.AddMoney('cash', 100000)
    Player.Functions.AddMoney('bank', 1000000)
    
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Test Money',
        description = 'Added $100k cash + $1M bank',
        type = 'success'
    })
end, 'admin')

-- Command to check current hot car
QBCore.Commands.Add('hotcar', 'Check current hot car', {}, false, function(source)
    if not currentHotCar then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Car Exporter',
            description = 'No hot car currently set.',
            type = 'info'
        })
        return
    end
    
    local price = Config.VehiclePrices[currentHotCar] or 5000
    local bonusPrice = math.floor(price * Config.HotCarMultiplier)
    
    -- Calculate remaining time
    local timeLeft = (Config.HotCarRotationHours * 3600) - (os.time() - lastRotationTime)
    if timeLeft < 0 then timeLeft = 0 end
    
    local hours = math.floor(timeLeft / 3600)
    local minutes = math.floor((timeLeft % 3600) / 60)
    local timeText = hours .. 'h ' .. minutes .. 'm'
    
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Current Hot Car',
        description = currentHotCar:upper() .. ' - $' .. bonusPrice .. ' - Time Left: ' .. timeText,
        type = 'info',
        duration = 10000
    })
end)

-- Command to check hot car timer
QBCore.Commands.Add('hottimer', 'Check time until hot car rotates', {}, false, function(source)
    if not currentHotCar or lastRotationTime == 0 then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Car Exporter',
            description = 'No hot car timer available.',
            type = 'info'
        })
        return
    end
    
    local timeLeft = (Config.HotCarRotationHours * 3600) - (os.time() - lastRotationTime)
    if timeLeft < 0 then timeLeft = 0 end
    
    local hours = math.floor(timeLeft / 3600)
    local minutes = math.floor((timeLeft % 3600) / 60)
    local seconds = timeLeft % 60
    
    local timeText = string.format('%02d:%02d:%02d', hours, minutes, seconds)
    
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Hot Car Timer',
        description = 'Time remaining: ' .. timeText,
        type = 'info',
        duration = 8000
    })
    
    -- Also send to chat for persistence
    TriggerClientEvent('chat:addMessage', source, {
        color = {255, 165, 0},
        multiline = false,
        args = {'[HOT CAR]', 'Current: ' .. currentHotCar:upper() .. ' | Time Left: ' .. timeText .. ' | Bonus: ' .. (Config.HotCarMultiplier * 100) .. '%'}
    })
end)

-- Get export stats (top exporters)
QBCore.Commands.Add('exporterstats', 'View top vehicle exporters', {}, true, function(source)
    local results = exports.oxmysql:executeSync([[
        SELECT citizenid, vehicle_name, price, is_hot_car, export_time
        FROM car_exporter_logs
        ORDER BY export_time DESC
        LIMIT 10
    ]])
    
    if #results == 0 then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Export Stats',
            description = 'No exports recorded yet.',
            type = 'info'
        })
        return
    end
    
    local statsText = '**Recent Exports:**\n\n'
    for _, row in ipairs(results) do
        local hotMarker = row.is_hot_car == 1 and ' [HOT]' or ''
        statsText = statsText .. row.vehicle_name:upper() .. hotMarker .. ' - $' .. row.price .. '\n'
    end
    
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Export Stats',
        description = statsText,
        type = 'info',
        duration = 15000
    })
end, 'admin')

-- Hot Car Tracking System
local hotCarDrivers = {} -- Track which players are driving hot car

-- Player reports they are/aren't driving hot car
RegisterNetEvent('car_exporter:hotCarStatus', function(isActive, coords)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    
    if isActive then
        hotCarDrivers[src] = {
            name = playerName,
            coords = coords
        }
        
        -- Broadcast to all OTHER players
        TriggerClientEvent('car_exporter:updateHotCarTracker', -1, src, playerName, coords, true)
        
        print('[Car Exporter] ' .. playerName .. ' is now driving the hot car!')
    else
        hotCarDrivers[src] = nil
        -- Broadcast removal to all players
        TriggerClientEvent('car_exporter:updateHotCarTracker', -1, src, playerName, nil, false)
    end
end)

-- Player updates their hot car position
RegisterNetEvent('car_exporter:hotCarUpdate', function(coords)
    local src = source
    if not hotCarDrivers[src] then return end
    
    hotCarDrivers[src].coords = coords
    local playerName = hotCarDrivers[src].name
    
    -- Broadcast updated position to all OTHER players
    TriggerClientEvent('car_exporter:updateHotCarTracker', -1, src, playerName, coords, true)
end)

-- Clean up when player disconnects
AddEventHandler('playerDropped', function()
    local src = source
    if hotCarDrivers[src] then
        local playerName = hotCarDrivers[src].name
        hotCarDrivers[src] = nil
        TriggerClientEvent('car_exporter:updateHotCarTracker', -1, src, playerName, nil, false)
    end
end)
