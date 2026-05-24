-- Vehicle Calling Menu - Client
-- Integrated with qbx_core/ox_inventory

local QBCore = exports['qbx_core']:GetCoreObject()
local isOpen = false
local vehicles = {}

-- Get player's owned vehicles
local function GetOwnedVehicles()
    local ownedVehicles = {}
    
    if Config.Integration.useQBXGarages then
        -- Try to get vehicles from qbx_garages
        local result = lib.callback.await('qbx_garages:server:getPlayerVehicles', false)
        if result then
            for _, vehicle in ipairs(result) do
                table.insert(ownedVehicles, {
                    id = vehicle.id,
                    model = vehicle.model,
                    plate = vehicle.plate,
                    name = vehicle.name or vehicle.model,
                    type = 'owned',
                    stored = vehicle.stored or true,
                    garage = vehicle.garage,
                })
            end
        end
    end
    
    -- Fallback: Try to get from player data
    local PlayerData = QBCore.Functions.GetPlayerData()
    if PlayerData and PlayerData.metadata and PlayerData.metadata.vehicles then
        for _, vehicle in ipairs(PlayerData.metadata.vehicles) do
            table.insert(ownedVehicles, {
                id = vehicle.id,
                model = vehicle.model,
                plate = vehicle.plate,
                name = vehicle.name or vehicle.model,
                type = 'owned',
                stored = vehicle.stored or true,
                garage = vehicle.garage,
            })
        end
    end
    
    return ownedVehicles
end

-- Get rented vehicles
local function GetRentedVehicles()
    local rentedVehicles = {}
    
    local PlayerData = QBCore.Functions.GetPlayerData()
    if PlayerData and PlayerData.metadata and PlayerData.metadata.rentals then
        for _, vehicle in ipairs(PlayerData.metadata.rentals) do
            table.insert(rentedVehicles, {
                id = vehicle.id,
                model = vehicle.model,
                plate = vehicle.plate,
                name = vehicle.name or vehicle.model,
                type = 'rented',
                expiry = vehicle.expiry,
            })
        end
    end
    
    return rentedVehicles
end

-- Get job vehicles
local function GetJobVehicles()
    local jobVehicles = {}
    
    local PlayerData = QBCore.Functions.GetPlayerData()
    local job = PlayerData.job and PlayerData.job.name
    local jobGrade = PlayerData.job and PlayerData.job.grade
    
    -- ND Police jobs (lspd / sahp / bcso) -- Legacy 2023 vehicle pack
    if job == 'lspd' or job == 'sahp' or job == 'bcso' then
        table.insert(jobVehicles, { model = 'lspd1',  name = '2020 FPIU (SUV)',       type = 'job' })
        table.insert(jobVehicles, { model = 'lspd2',  name = '2013 FPIU (SUV)',       type = 'job' })
        table.insert(jobVehicles, { model = 'lspd3',  name = '2016 Ram (Truck)',       type = 'job' })
        table.insert(jobVehicles, { model = 'lspd4',  name = '2018 Tahoe (SUV)',       type = 'job' })
        table.insert(jobVehicles, { model = 'lspd5',  name = '2014 Tahoe (SUV)',       type = 'job' })
        table.insert(jobVehicles, { model = 'lspd6',  name = 'Durango (SUV)',         type = 'job' })
        table.insert(jobVehicles, { model = 'lspd7',  name = '2018 F-150 (Truck)',     type = 'job' })
        table.insert(jobVehicles, { model = 'lspd8',  name = '2010 Charger',           type = 'job' })
        table.insert(jobVehicles, { model = 'lspd9',  name = '2018 Charger',           type = 'job' })
        table.insert(jobVehicles, { model = 'lspd10', name = '2014 Charger',           type = 'job' })
        table.insert(jobVehicles, { model = 'lspd11', name = '2010 Impala',            type = 'job' })
        table.insert(jobVehicles, { model = 'lspd12', name = '2011 CVPI',            type = 'job' })
        table.insert(jobVehicles, { model = 'lspd13', name = '2018 Taurus',          type = 'job' })
        table.insert(jobVehicles, { model = 'lspd14', name = '2022 Tahoe (SUV)',       type = 'job' })
        table.insert(jobVehicles, { model = 'lspd15', name = '2022 Silverado (Truck)', type = 'job' })
        table.insert(jobVehicles, { model = 'lspd16', name = 'Gator (Offroad)',        type = 'job' })
        table.insert(jobVehicles, { model = 'lspd17', name = 'Mustang (Sport)',        type = 'job' })
        table.insert(jobVehicles, { model = 'lspd18', name = 'Camaro (Sport)',         type = 'job' })
        table.insert(jobVehicles, { model = 'lspd19', name = 'Demon (Muscle)',         type = 'job' })
        table.insert(jobVehicles, { model = 'lspd20', name = '2022 Charger (RT)',      type = 'job' })
        table.insert(jobVehicles, { model = 'lspd21', name = 'Audi RS5 (Sport)',       type = 'job' })
        table.insert(jobVehicles, { model = 'lspd22', name = '2016 Explorer (SUV)',    type = 'job' })
    elseif job == 'lsfd' then
        table.insert(jobVehicles, { model = 'ambulance', name = 'Ambulance', type = 'job' })
        table.insert(jobVehicles, { model = 'emsswift', name = 'EMS Swift', type = 'job' })
        table.insert(jobVehicles, { model = 'firetruk', name = 'Fire Truck', type = 'job' })
    elseif job == 'mechanic' then
        table.insert(jobVehicles, { model = 'towtruck', name = 'Tow Truck', type = 'job' })
        table.insert(jobVehicles, { model = 'flatbed', name = 'Flatbed', type = 'job' })
    end
    
    return jobVehicles
end

-- Open vehicle menu
local function OpenVehicleMenu()
    if isOpen then return end
    
    isOpen = true
    
    -- Get all vehicles
    local owned = GetOwnedVehicles()
    local rented = GetRentedVehicles()
    local job = GetJobVehicles()
    
    vehicles = {
        personal = owned,
        rented = rented,
        job = job,
    }
    
    -- Send to NUI
    SendNUIMessage({
        action = 'open',
        categories = Config.Categories,
        vehicles = vehicles,
        config = Config.UI,
    })
    
    -- Set NUI focus
    SetNuiFocus(true, true)
    
    print('^2[Vehicle Caller]^7 Menu opened')
end

-- Close vehicle menu
local function CloseVehicleMenu()
    if not isOpen then return end
    
    isOpen = false
    
    -- Send to NUI
    SendNUIMessage({
        action = 'close',
    })
    
    -- Release NUI focus
    SetNuiFocus(false, false)
    
    print('^2[Vehicle Caller]^7 Menu closed')
end

-- Spawn vehicle
local function SpawnVehicle(vehicleData)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    -- Find spawn position
    local spawnCoords = nil
    local spawnHeading = GetEntityHeading(ped)
    
    -- Check for nearby spawn point
    for i = 0, 10 do
        local testCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 8.0 + i, 0.0)
        local clear = not IsAnyVehicleNearPoint(testCoords.x, testCoords.y, testCoords.z, 3.0)
        
        if clear then
            spawnCoords = testCoords
            break
        end
    end
    
    if not spawnCoords then
        spawnCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 10.0, 0.0)
    end
    
    -- Request vehicle model
    local modelHash = GetHashKey(vehicleData.model)
    RequestModel(modelHash)
    
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(modelHash) then
        lib.notify({
            title = 'Error',
            description = 'Vehicle model failed to load',
            type = 'error'
        })
        return
    end
    
    -- Create vehicle
    local vehicle = CreateVehicle(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnHeading, true, false)
    
    if vehicle == 0 then
        lib.notify({
            title = 'Error',
            description = 'Failed to spawn vehicle',
            type = 'error'
        })
        return
    end
    
    -- Set vehicle properties
    SetVehicleFuelLevel(vehicle, 100.0)
    SetVehicleEngineOn(vehicle, true, true, false)
    
    -- Set plate if provided
    if vehicleData.plate then
        SetVehicleNumberPlateText(vehicle, vehicleData.plate)
    end
    
    -- Spawn player in vehicle if configured
    if Config.Spawn.spawnInVehicle then
        TaskWarpPedIntoVehicle(ped, vehicle, -1)
    end
    
    -- Give keys if using qbx_vehiclekeys
    if Config.Integration.useQBXVehicleKeys then
        TriggerServerEvent('qbx_vehiclekeys:server:AddKeys', GetVehicleNumberPlateText(vehicle))
    end
    
    -- Notify server
    TriggerServerEvent('vehicle_caller:server:vehicleSpawned', vehicleData)
    
    lib.notify({
        title = 'Vehicle Spawned',
        description = vehicleData.name or vehicleData.model,
        type = 'success'
    })
    
    print('^2[Vehicle Caller]^7 Spawned: ' .. (vehicleData.name or vehicleData.model))
end

-- Handle key press
CreateThread(function()
    while true do
        Wait(0)
        
        if Config.Menu.enabled then
            if IsControlJustPressed(0, GetHashKey(Config.Menu.openKey)) then
                if isOpen then
                    CloseVehicleMenu()
                else
                    OpenVehicleMenu()
                end
            end
        end
    end
end)

-- NUI Callbacks
RegisterNUICallback('spawnVehicle', function(data, cb)
    SpawnVehicle(data.vehicle)
    CloseVehicleMenu()
    cb({})
end)

RegisterNUICallback('close', function(data, cb)
    CloseVehicleMenu()
    cb({})
end)

-- Exports
exports('OpenVehicleMenu', OpenVehicleMenu)
exports('CloseVehicleMenu', CloseVehicleMenu)

-- Command to open menu
RegisterCommand(Config.Menu.command, function()
    if isOpen then
        CloseVehicleMenu()
    else
        OpenVehicleMenu()
    end
end, false)

-- Key mapping
RegisterKeyMapping('vehicles', 'Toggle Vehicle Menu', 'keyboard', Config.Menu.openKey)

-- Initialize
CreateThread(function()
    Wait(1000)
    print('^2[Vehicle Caller]^7 Resource loaded - Press ' .. Config.Menu.openKey .. ' to open vehicle menu')
end)
