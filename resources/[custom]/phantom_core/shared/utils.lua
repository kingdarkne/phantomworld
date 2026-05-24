-- Shared utility functions for Phantom Core

-- Get player data based on framework
function GetPlayerData()
    if Config.Framework == 'qbx' then
        if QBX and QBX.PlayerData and QBX.PlayerData.citizenid then
            return QBX.PlayerData
        end
        return exports.qbx_core:GetPlayerData()
    elseif Config.Framework == 'qb' then
        return QBCore.Functions.GetPlayerData()
    end
    return nil
end

-- Check if player is logged in
function IsPlayerLoggedIn()
    local playerData = GetPlayerData()
    if Config.Framework == 'qbx' then
        return playerData and playerData.charinfo ~= nil
    elseif Config.Framework == 'qb' then
        return QBCore.Functions.GetPlayerData().loggedin
    end
    return false
end

-- Format currency
function FormatMoney(amount)
    return '$' .. tostring(math.floor(amount)):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

-- Format time
function FormatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    
    if hours > 0 then
        return string.format('%02d:%02d:%02d', hours, minutes, secs)
    else
        return string.format('%02d:%02d', minutes, secs)
    end
end

-- Get distance between two vectors
function GetDistance(coord1, coord2)
    return #(coord1 - coord2)
end

-- Round number
function Round(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Clamp number
function Clamp(num, min, max)
    return math.min(math.max(num, min), max)
end

-- Lerp between two values
function Lerp(a, b, t)
    return a + (b - a) * t
end

-- Check if table contains value
function TableContains(table, value)
    for _, v in pairs(table) do
        if v == value then return true end
    end
    return false
end

-- Get table length
function TableLength(table)
    local count = 0
    for _ in pairs(table) do count = count + 1 end
    return count
end

-- Deep copy table
function DeepCopy(table)
    local copy = {}
    for key, value in pairs(table) do
        if type(value) == 'table' then
            copy[key] = DeepCopy(value)
        else
            copy[key] = value
        end
    end
    return copy
end

-- Debug print
function DebugPrint(message)
    if Config.Debug then
        print('^3[Phantom Core Debug]^7 ' .. tostring(message))
    end
end

-- Send notification to player
function Notify(message, type, duration)
    type = type or 'info'
    duration = duration or Config.UI.Notifications.DefaultDuration
    
    SendNUIMessage({
        action = 'notification',
        message = message,
        type = type,
        duration = duration
    })
end

-- Show progress bar
function Progress(options)
    options = options or {}
    options.duration = options.duration or Config.UI.Progress.DefaultDuration
    options.label = options.label or 'Processing...'
    options.canCancel = options.canCancel ~= nil and options.canCancel or Config.UI.Progress.CanCancel
    
    return lib.progressBar({
        duration = options.duration,
        label = options.label,
        useWhileDead = false,
        canCancel = options.canCancel,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = false,
        },
        anim = options.anim or {
            dict = 'missheistdockssetup1clipboard@base',
            clip = 'base'
        }
    })
end

-- Show menu
function ShowMenu(options)
    return lib.showMenu(options.id or 'phantom_menu', {
        title = options.title or 'Menu',
        position = options.position or 'top-right',
        options = options.options or {}
    })
end

-- Show dialog
function ShowDialog(options)
    return lib.inputDialog(options.title or 'Input', options.inputs or {})
end

-- Get vehicle in front
function GetVehicleInFront(distance)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    
    local rayHandle = StartShapeTestRay(coords, coords + (forward * distance), 2, ped, 0)
    local _, _, _, _, entity = GetShapeTestResult(rayHandle)
    
    if entity ~= 0 and IsEntityAVehicle(entity) then
        return entity
    end
    return nil
end

-- Get nearest player
function GetNearestPlayer(distance)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local nearestPlayer = nil
    local nearestDistance = distance
    
    for _, player in ipairs(GetActivePlayers()) do
        local targetPed = GetPlayerPed(player)
        local targetCoords = GetEntityCoords(targetPed)
        local dist = #(coords - targetCoords)
        
        if dist < nearestDistance then
            nearestDistance = dist
            nearestPlayer = player
        end
    end
    
    return nearestPlayer, nearestDistance
end

-- Get nearest vehicle
function GetNearestVehicle(distance)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local nearestVehicle = nil
    local nearestDistance = distance
    
    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        local vehicleCoords = GetEntityCoords(vehicle)
        local dist = #(coords - vehicleCoords)
        
        if dist < nearestDistance then
            nearestDistance = dist
            nearestVehicle = vehicle
        end
    end
    
    return nearestVehicle, nearestDistance
end

-- Play animation
function PlayAnimation(animDict, animName, duration, flags)
    local ped = PlayerPedId()
    flags = flags or 49
    
    RequestAnimDict(animDict)
    local timeout = 0
    while not HasAnimDictLoaded(animDict) and timeout < 50 do
        Wait(10)
        timeout = timeout + 1
    end
    
    if HasAnimDictLoaded(animDict) then
        TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, duration or -1, flags, 0, false, false, false)
        return true
    end
    return false
end

-- Clear animation
function ClearAnimation(ped)
    ped = ped or PlayerPedId()
    ClearPedTasks(ped)
    ClearPedSecondaryTask(ped)
end

-- Spawn vehicle
function SpawnVehicle(model, coords, heading)
    local hash = GetHashKey(model)
    
    if not IsModelInCdimage(hash) then
        return nil, 'Invalid vehicle model'
    end
    
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 50 do
        Wait(10)
        timeout = timeout + 1
    end
    
    if HasModelLoaded(hash) then
        local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, heading or 0.0, true, false)
        SetModelAsNoLongerNeeded(hash)
        SetVehicleOnGroundProperly(vehicle)
        return vehicle
    end
    
    return nil, 'Failed to load vehicle model'
end

-- Delete vehicle
function DeleteVehicle(vehicle)
    if DoesEntityExist(vehicle) then
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)
        return true
    end
    return false
end

-- Get vehicle fuel level
function GetVehicleFuel(vehicle)
    if DoesEntityExist(vehicle) then
        return GetVehicleFuelLevel(vehicle) or 100.0
    end
    return 100.0
end

-- Set vehicle fuel level
function SetVehicleFuel(vehicle, level)
    if DoesEntityExist(vehicle) then
        SetVehicleFuelLevel(vehicle, level)
    end
end

-- Get vehicle health percentage
function GetVehicleHealth(vehicle)
    if DoesEntityExist(vehicle) then
        local health = GetVehicleEngineHealth(vehicle)
        return math.floor((health / 1000) * 100)
    end
    return 100
end

-- Blip utilities
function CreateBlip(coords, sprite, color, scale, label)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, color)
    SetBlipScale(blip, scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(label)
    EndTextCommandSetBlipName(blip)
    return blip
end

function RemoveBlip(blip)
    if DoesBlipExist(blip) then
        RemoveBlip(blip)
    end
end

-- Draw 3D text
function Draw3DText(coords, text, scale, font)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    
    SetTextScale(scale, scale)
    SetTextFont(font or 4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
    
    local factor = (string.len(text)) / 370
    DrawRect(_x, _y + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 68)
end

-- Draw marker
local _DrawMarker = DrawMarker
function DrawMarker(type, coords, size, color)
    _DrawMarker(type, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, size.x, size.y, size.z, color.r, color.g, color.b, color.a, false, false, 2, false, nil, nil, false)
end
