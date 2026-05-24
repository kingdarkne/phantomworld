-- Phantom Garage - Main Client
local QBCore = exports['qbx_core']:GetCoreObject()
local inGarage = false
local currentGarage = nil
local garageVehicles = {}
local spawnedGarageVehicles = {}
local garageBlips = {}

-- Initialize
CreateThread(function()
    Wait(2000)
    CreateGarageBlips()
    print('^2[Phantom Garage]^7 Client initialized')
end)

-- Create garage blips
function CreateGarageBlips()
    for _, location in ipairs(Config.GarageLocations) do
        local garageType = nil
        for _, gt in ipairs(Config.GarageTypes) do
            if gt.id == location.type then
                garageType = gt
                break
            end
        end
        if garageType then
            local blip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
            SetBlipSprite(blip, garageType.blip.sprite)
            SetBlipColour(blip, garageType.blip.color)
            SetBlipScale(blip, 0.8)
            SetBlipAsShortRange(blip, true)
            SetBlipDisplay(blip, 4)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(garageType.name .. ' - ' .. location.label)
            EndTextCommandSetBlipName(blip)
            table.insert(garageBlips, blip)
        end
    end
end

-- Check proximity to garages
CreateThread(function()
    while true do
        Wait(1000)
        if not inGarage then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            currentGarage = nil

            for _, location in ipairs(Config.GarageLocations) do
                local dist = #(coords - location.coords)
                if dist < 15.0 then
                    currentGarage = location
                    break
                end
            end
        end
    end
end)

-- Draw markers and interact
CreateThread(function()
    while true do
        Wait(0)
        if currentGarage and not inGarage then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local dist = #(coords - currentGarage.coords)

            -- Draw marker
            if dist < 20.0 then
                DrawMarker(36, currentGarage.coords.x, currentGarage.coords.y, currentGarage.coords.z + 0.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0, 150, 255, 200, false, false, 2, true, nil, nil, false)
            end

            if dist < 2.0 then
                -- Get garage type info
                local gType = nil
                for _, gt in ipairs(Config.GarageTypes) do
                    if gt.id == currentGarage.type then
                        gType = gt
                        break
                    end
                end

                Draw3DText(currentGarage.coords + vec3(0, 0, 1.0), '~b~[E]~w~ Enter Garage\n' .. currentGarage.label .. ' (' .. gType.name .. ')', 0.4, 4)

                if IsControlJustPressed(0, 38) then -- E key
                    EnterGarage(currentGarage)
                end
            end
        end
    end
end)

-- Enter garage
function EnterGarage(location)
    local garageType = nil
    for _, gt in ipairs(Config.GarageTypes) do
        if gt.id == location.type then
            garageType = gt
            break
        end
    end
    if not garageType then return end

    -- Get player's vehicles for this garage
    local vehicles = lib.callback.await('phantom_garage:server:getGarageVehicles', false, location.type)
    garageVehicles = vehicles or {}

    -- Get interior config
    local interior = Config.Interiors[garageType.interior]
    if not interior then
        lib.notify({ title = 'Error', description = 'Garage interior not found', type = 'error' })
        return
    end

    -- Fade out
    DoScreenFadeOut(500)
    Wait(500)

    -- Teleport to garage interior
    SetEntityCoords(PlayerPedId(), interior.spawnCoords.x, interior.spawnCoords.y, interior.spawnCoords.z, false, false, false, false)
    SetEntityHeading(PlayerPedId(), interior.spawnCoords.w)

    -- Request IPL
    if interior.ipl then
        RequestIpl(interior.ipl)
    end

    -- Spawn stored vehicles
    SpawnGarageVehicles(garageVehicles, interior.vehicleOffsets)

    inGarage = true
    currentGarage = location

    -- Show garage UI
    SendNUIMessage({
        action = 'openGarage',
        garageName = location.label,
        garageType = garageType.name,
        slots = garageType.slots,
        vehicles = garageVehicles,
    })
    SetNuiFocus(true, true)

    DoScreenFadeIn(500)
end

-- Exit garage
function ExitGarage()
    if not inGarage or not currentGarage then return end

    DoScreenFadeOut(500)
    Wait(500)

    -- Delete spawned vehicles
    for _, veh in ipairs(spawnedGarageVehicles) do
        if DoesEntityExist(veh) then
            DeleteVehicle(veh)
        end
    end
    spawnedGarageVehicles = {}

    -- Remove IPL
    local garageType = nil
    for _, gt in ipairs(Config.GarageTypes) do
        if gt.id == currentGarage.type then
            garageType = gt
            break
        end
    end
    if garageType then
        local interior = Config.Interiors[garageType.interior]
        if interior and interior.ipl then
            RemoveIpl(interior.ipl)
        end
    end

    -- Teleport back to garage entrance
    SetEntityCoords(PlayerPedId(), currentGarage.coords.x, currentGarage.coords.y, currentGarage.coords.z, false, false, false, false)
    SetEntityHeading(PlayerPedId(), 0.0)

    inGarage = false
    SetNuiFocus(false, false)

    DoScreenFadeIn(500)
end

-- Spawn vehicles in garage
function SpawnGarageVehicles(vehicles, offsets)
    for i, vehicle in ipairs(vehicles) do
        if i <= #offsets then
            local offset = offsets[i]
            local hash = GetHashKey(vehicle.model)
            RequestModel(hash)
            while not HasModelLoaded(hash) do Wait(10) end

            local veh = CreateVehicle(hash, offset.x, offset.y, offset.z, offset.w, false, false)
            SetModelAsNoLongerNeeded(hash)
            SetEntityAsMissionEntity(veh, true, true)
            FreezeEntityPosition(veh, true)
            SetVehicleDoorsLocked(veh, 2)

            -- Apply stored mods
            if vehicle.mods then
                ApplyVehicleMods(veh, vehicle.mods)
            end

            -- Apply stored colors
            if vehicle.colors then
                SetVehicleColours(veh, vehicle.colors.primary, vehicle.colors.secondary)
                if vehicle.colors.pearlescent then
                    SetVehicleExtraColours(veh, vehicle.colors.pearlescent, vehicle.colors.wheelColor)
                end
            end

            table.insert(spawnedGarageVehicles, veh)
        end
    end
end

-- Apply vehicle mods
function ApplyVehicleMods(vehicle, mods)
    if not mods then return end
    SetVehicleModKit(vehicle, 0)
    for modType, modIndex in pairs(mods) do
        if tonumber(modType) then
            SetVehicleMod(vehicle, tonumber(modType), modIndex, false)
        end
    end
    if mods.plate then
        SetVehicleNumberPlateText(vehicle, mods.plate)
    end
end

-- NUI Callbacks
RegisterNUICallback('closeGarage', function(data, cb)
    ExitGarage()
    cb({})
end)

RegisterNUICallback('selectVehicle', function(data, cb)
    -- Highlight vehicle in garage
    local index = data.index
    if index and spawnedGarageVehicles[index] and DoesEntityExist(spawnedGarageVehicles[index]) then
        local veh = spawnedGarageVehicles[index]
        -- Camera focus on vehicle (simplified)
    end
    cb({})
end)

RegisterNUICallback('driveVehicle', function(data, cb)
    local index = data.index
    if not index or not garageVehicles[index] then cb({ success = false }) return end

    local vehicleData = garageVehicles[index]
    ExitGarage()

    Wait(1000)

    -- Spawn vehicle at garage entrance
    local hash = GetHashKey(vehicleData.model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local veh = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, false)
    SetModelAsNoLongerNeeded(hash)

    TaskWarpPedIntoVehicle(ped, veh, -1)

    -- Apply mods
    if vehicleData.mods then
        ApplyVehicleMods(veh, vehicleData.mods)
    end
    if vehicleData.colors then
        SetVehicleColours(veh, vehicleData.colors.primary, vehicleData.colors.secondary)
    end

    SetVehicleNumberPlateText(veh, vehicleData.plate or vehicleData.model:upper())
    SetVehicleDoorsLocked(veh, 0)

    TriggerServerEvent('phantom_garage:server:vehicleTakenOut', vehicleData.id)

    cb({ success = true })
end)

RegisterNUICallback('storeVehicle', function(data, cb)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)

    if veh == 0 then
        cb({ success = false, message = 'Not in a vehicle' })
        return
    end

    -- Get vehicle data
    local model = GetEntityModel(veh)
    local modelName = GetDisplayNameFromVehicleModel(model):lower()
    local plate = GetVehicleNumberPlateText(veh)
    local primary, secondary = GetVehicleColours(veh)
    local pearlescent, wheelColor = GetVehicleExtraColours(veh)

    -- Get mods
    local mods = {}
    for i = 0, 48 do
        local mod = GetVehicleMod(veh, i)
        if mod ~= -1 then
            mods[i] = mod
        end
    end

    local vehicleData = {
        model = modelName,
        plate = plate,
        mods = mods,
        colors = {
            primary = primary,
            secondary = secondary,
            pearlescent = pearlescent,
            wheelColor = wheelColor,
        },
        fuel = GetVehicleFuelLevel(veh),
        garageType = currentGarage.type,
        garageLabel = currentGarage.label,
    }

    local result = lib.callback.await('phantom_garage:server:storeVehicle', false, vehicleData)
    if result.success then
        -- Delete current vehicle
        SetEntityAsMissionEntity(veh, true, true)
        DeleteVehicle(veh)

        lib.notify({ title = 'Vehicle Stored', description = modelName:upper() .. ' stored in garage', type = 'success' })
    else
        lib.notify({ title = 'Storage Failed', description = result.message or 'Could not store vehicle', type = 'error' })
    end

    cb(result)
end)

RegisterNUICallback('sellVehicle', function(data, cb)
    local index = data.index
    if not index or not garageVehicles[index] then cb({ success = false }) return end

    local vehicle = garageVehicles[index]
    local confirm = lib.alertDialog({
        header = 'Sell Vehicle',
        content = 'Sell ' .. vehicle.model:upper() .. ' for $' .. (vehicle.sellPrice or 0) .. '?',
        cancel = true,
    })

    if confirm == 'confirm' then
        local result = lib.callback.await('phantom_garage:server:sellVehicle', false, vehicle.id)
        if result.success then
            lib.notify({ title = 'Vehicle Sold', description = '+$' .. result.price, type = 'success' })
            -- Refresh
            ExitGarage()
            Wait(1000)
            EnterGarage(currentGarage)
        else
            lib.notify({ title = 'Sale Failed', description = result.message, type = 'error' })
        end
        cb(result)
    else
        cb({ success = false })
    end
end)

-- Purchase garage
RegisterNUICallback('buyGarage', function(data, cb)
    local result = lib.callback.await('phantom_garage:server:buyGarage', false, data.garageType, data.locationIndex)
    if result.success then
        lib.notify({ title = 'Garage Purchased!', description = 'You own a new garage!', type = 'success' })
    else
        lib.notify({ title = 'Purchase Failed', description = result.message, type = 'error' })
    end
    cb(result)
end)

-- Buy garage command
RegisterCommand('buygarage', function()
    OpenGarageStore()
end)

function OpenGarageStore()
    local options = {}
    for _, gt in ipairs(Config.GarageTypes) do
        table.insert(options, {
            title = gt.name,
            description = gt.slots .. ' slots - $' .. gt.price,
            onSelect = function()
                -- Show available locations
                ShowGarageLocations(gt)
            end
        })
    end

    lib.registerContext({ id = 'garage_store', title = '🏢 Buy Garage', options = options })
    lib.showContext('garage_store')
end

function ShowGarageLocations(garageType)
    local options = {}
    for i, loc in ipairs(Config.GarageLocations) do
        if loc.type == garageType.id then
            table.insert(options, {
                title = loc.label,
                description = 'Price: $' .. garageType.price,
                onSelect = function()
                    local result = lib.callback.await('phantom_garage:server:buyGarage', false, garageType.id, i)
                    if result.success then
                        lib.notify({ title = 'Garage Purchased!', description = loc.label .. ' is yours!', type = 'success' })
                    else
                        lib.notify({ title = 'Purchase Failed', description = result.message, type = 'error' })
                    end
                end
            })
        end
    end

    lib.registerContext({ id = 'garage_locations', title = 'Select Location', options = options })
    lib.showContext('garage_locations')
end

-- 3D Text helper
function Draw3DText(coords, text, scale, font)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if onScreen then
        SetTextScale(scale, scale)
        SetTextFont(font)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry('STRING')
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

print('^2[Phantom Garage]^7 Client loaded')
