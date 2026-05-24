-- Phantom Core - Garage System
-- High-quality garage system with impound and personal garages

local playerGarages = {}
local currentGarage = nil
local garageBlips = {}

-- Garage locations
local garageLocations = {
    { id = 'central', coords = vec3(215.800, -810.057, 30.727), heading = 158.5, name = 'Central Garage' },
    { id = 'paleto', coords = vec3(105.359, 6613.868, 31.397), heading = 225.0, name = 'Paleto Bay Garage' },
    { id = 'sandy', coords = vec3(1737.859, 3710.234, 34.140), heading = 20.0, name = 'Sandy Shores Garage' },
}

-- Create garage blips
function CreateGarageBlips()
    for _, garage in ipairs(garageLocations) do
        local blip = CreateBlip(garage.coords, 357, 3, 0.8, garage.name)
        table.insert(garageBlips, blip)
    end
end

-- Remove garage blips
function RemoveGarageBlips()
    for _, blip in ipairs(garageBlips) do
        RemoveBlip(blip)
    end
    garageBlips = {}
end

-- Open garage menu
function OpenGarage(garageId)
    currentGarage = garageId
    local garage = garageLocations[garageId]
    
    -- Get player vehicles
    local playerVehicles = GetPlayerVehicles()
    local options = {}
    
    if #playerVehicles == 0 then
        table.insert(options, {
            label = 'No vehicles',
            description = 'You don\'t have any vehicles in this garage',
            icon = '🚗',
            disabled = true
        })
    else
        for _, vehicle in ipairs(playerVehicles) do
            table.insert(options, {
                label = vehicle.name,
                description = 'Condition: ' .. vehicle.health .. '% | Fuel: ' .. vehicle.fuel .. '%',
                icon = '🚗',
                args = { type = 'retrieve', vehicleId = vehicle.id }
            })
        end
    end
    
    -- Add store option if in vehicle
    local ped = PlayerPedId()
    local currentVehicle = GetVehiclePedIsIn(ped, false)
    if currentVehicle ~= 0 then
        table.insert(options, {
            label = 'Store Vehicle',
            description = 'Store your current vehicle',
            icon = '🅿️',
            args = { type = 'store', vehicle = currentVehicle }
        })
    end
    
    ShowMenu({
        title = garage.name,
        options = options
    })
end

-- Get player vehicles from server
function GetPlayerVehicles()
    -- This would fetch from the server/database
    -- For now, return empty array
    return {}
end

-- Retrieve vehicle from garage
function RetrieveVehicle(vehicleId)
    local garage = garageLocations[currentGarage]
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    -- Show progress
    ShowProgressBar({
        duration = 2000,
        label = 'Retrieving vehicle...',
        canCancel = false
    })
    
    -- Spawn vehicle at garage location
    -- This would fetch vehicle data from server and spawn it
    
    SendNotification({
        type = 'vehicle',
        message = 'Vehicle retrieved'
    })
    
    CloseMenu()
end

-- Store vehicle in garage
function StoreVehicle(vehicle)
    local ped = PlayerPedId()
    
    -- Show progress
    ShowProgressBar({
        duration = 1500,
        label = 'Storing vehicle...',
        canCancel = false
    })
    
    -- Store vehicle data to server
    -- Delete vehicle from world
    
    SendNotification({
        type = 'vehicle',
        message = 'Vehicle stored'
    })
    
    CloseMenu()
end

-- Open impound menu
function OpenImpound()
    local options = {}
    
    -- Get impounded vehicles
    local impoundedVehicles = GetImpoundedVehicles()
    
    if #impoundedVehicles == 0 then
        table.insert(options, {
            label = 'No impounded vehicles',
            description = 'You don\'t have any vehicles in impound',
            icon = '🚗',
            disabled = true
        })
    else
        for _, vehicle in ipairs(impoundedVehicles) do
            table.insert(options, {
                label = vehicle.name,
                description = 'Impound Fee: ' .. FormatMoney(Config.Vehicles.Garage.ImpoundFee),
                icon = '🚗',
                args = { type = 'claim', vehicleId = vehicle.id }
            })
        end
    end
    
    ShowMenu({
        title = 'Vehicle Impound',
        options = options
    })
end

-- Get impounded vehicles
function GetImpoundedVehicles()
    -- This would fetch from server
    return {}
end

-- Claim vehicle from impound
function ClaimVehicle(vehicleId)
    local impoundLocation = Config.Vehicles.Garage.ImpoundLocations[1]
    
    -- Check if player has enough money
    -- Deduct impound fee
    
    ShowProgressBar({
        duration = 2000,
        label = 'Claiming vehicle...',
        canCancel = false
    })
    
    -- Spawn vehicle at impound location
    
    SendNotification({
        type = 'vehicle',
        message = 'Vehicle claimed for ' .. FormatMoney(Config.Vehicles.Garage.ImpoundFee)
    })
    
    CloseMenu()
end

-- Handle menu selection
RegisterNUICallback('menuItemSelected', function(data, cb)
    if data.args.type == 'retrieve' then
        RetrieveVehicle(data.args.vehicleId)
    elseif data.args.type == 'store' then
        StoreVehicle(data.args.vehicle)
    elseif data.args.type == 'claim' then
        ClaimVehicle(data.args.vehicleId)
    end
    cb({})
end)

-- Main thread for garage zones
CreateThread(function()
    CreateGarageBlips()
    
    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        
        for _, garage in ipairs(garageLocations) do
            local distance = #(coords - garage.coords)
            
            if distance < 5.0 then
                -- Draw marker
                DrawMarker(36, garage.coords, vec3(0.5, 0.5, 0.5), {r = 0, g = 150, b = 255, a = 100})
                
                if distance < 2.0 then
                    Draw3DText(garage.coords, '[E] Open Garage', 0.5, 4)
                    
                    if IsControlJustPressed(0, 38) then -- E key
                        OpenGarage(garage.id)
                    end
                end
            end
        end
        
        -- Impound locations
        for _, impound in ipairs(Config.Vehicles.Garage.ImpoundLocations) do
            local distance = #(coords - impound.coords)
            
            if distance < 5.0 then
                DrawMarker(36, impound.coords, vec3(0.5, 0.5, 0.5), {r = 255, g = 0, b = 0, a = 100})
                
                if distance < 2.0 then
                    Draw3DText(impound.coords, '[E] Open Impound', 0.5, 4)
                    
                    if IsControlJustPressed(0, 38) then -- E key
                        OpenImpound()
                    end
                end
            end
        end
        
        Wait(0)
    end
end)

-- Commands
RegisterCommand('garage', function()
    -- Find nearest garage
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local nearestGarage = nil
    local nearestDistance = 9999.0
    
    for i, garage in ipairs(garageLocations) do
        local distance = #(coords - garage.coords)
        if distance < nearestDistance then
            nearestDistance = distance
            nearestGarage = i
        end
    end
    
    if nearestGarage and nearestDistance < 50.0 then
        OpenGarage(nearestGarage)
    else
        SendNotification({
            type = 'error',
            message = 'No garage nearby'
        })
    end
end)

RegisterCommand('impound', function()
    OpenImpound()
end)

-- Export functions
exports('OpenGarage', OpenGarage)
exports('OpenImpound', OpenImpound)

DebugPrint('Garage system loaded')
