-- Phantom Core - Enhanced Fuel System
-- High-quality fuel system with consumption rates

local fuelStations = {
    { coords = vec3(49.4188, 2778.793, 58.043), price = 2.50 },
    { coords = vec3(263.894, 2606.463, 44.983), price = 2.50 },
    { coords = vec3(1039.958, 2671.134, 39.550), price = 2.50 },
    { coords = vec3(1207.260, 2660.175, 37.899), price = 2.50 },
    { coords = vec3(2539.685, 2594.192, 37.944), price = 2.50 },
    { coords = vec3(2679.858, 3263.946, 55.240), price = 2.50 },
    { coords = vec3(2005.055, 3773.887, 32.403), price = 'regular' },
    { coords = vec3(1687.156, 4929.392, 42.078), price = 'regular' },
    { coords = vec3(1701.314, 6416.028, 32.763), price = 'regular' },
    { coords = vec3(179.857, 6602.839, 31.868), price = 'regular' },
    { coords = vec3(-94.4619, 6419.594, 31.489), price = 'regular' },
    { coords = vec3(-2554.996, 2334.402, 33.078), price = 'regular' },
    { coords = vec3(-1800.375, 803.661, 138.651), price = 'regular' },
    { coords = vec3(-1437.622, -276.747, 46.207), price = 'regular' },
    { coords = vec3(-2096.243, -320.286, 13.168), price = 'regular' },
    { coords = vec3(-724.619, -935.163, 19.213), price = 'regular' },
    { coords = vec3(-519.703, -1211.315, 18.184), price = 'regular' },
    { coords = vec3(-70.2148, -1761.792, 29.534), price = 'regular' },
    { coords = vec3(265.648, -1261.309, 29.292), price = 'regular' },
    { coords = vec3(819.653, -1028.846, 26.403), price = 'regular' },
    { coords = vec3(1208.951, -1402.567, 35.224), price = 'regular' },
    { coords = vec3(1181.381, -330.847, 69.316), price = 'regular' },
    { coords = vec3(620.843, 269.100, 103.089), price = 'regular' },
    { coords = vec3(2581.321, 362.039, 108.468), price = 'regular' },
}

local fuelBlips = {}
local isRefueling = false

-- Create fuel station blips
function CreateFuelBlips()
    for _, station in ipairs(fuelStations) do
        local blip = CreateBlip(station.coords, 361, 1, 0.8, 'Gas Station')
        table.insert(fuelBlips, blip)
    end
end

-- Remove fuel blips
function RemoveFuelBlips()
    for _, blip in ipairs(fuelBlips) do
        RemoveBlip(blip)
    end
    fuelBlips = {}
end

-- Get fuel price
function GetFuelPrice(fuelType)
    return Config.Vehicles.Fuel.Prices[fuelType] or Config.Vehicles.Fuel.Prices.regular
end

-- Refuel vehicle
function RefuelVehicle(vehicle, fuelType)
    if isRefueling then return end
    isRefueling = true
    
    local currentFuel = GetVehicleFuel(vehicle)
    local fuelNeeded = 100.0 - currentFuel
    local pricePerLiter = GetFuelPrice(fuelType)
    local totalPrice = fuelNeeded * pricePerLiter
    
    ShowConfirmDialog({
        title = 'Refuel Vehicle',
        message = 'Refuel to 100% for ' .. FormatMoney(totalPrice) .. '?',
        confirmText = 'Yes',
        cancelText = 'No',
        callback = function(values, confirmed)
            if confirmed then
                -- Check if player has enough money
                -- This would integrate with the economy system
                
                ShowProgressBar({
                    duration = 5000,
                    label = 'Refueling...',
                    canCancel = true
                })
                
                -- Refuel vehicle
                SetVehicleFuel(vehicle, 100.0)
                
                SendNotification({
                    type = 'vehicle',
                    message = 'Vehicle refueled for ' .. FormatMoney(totalPrice)
                })
                
                -- Deduct money
                -- This would integrate with the banking system
            end
            isRefueling = false
        end
    })
end

-- Fuel consumption thread
CreateThread(function()
    CreateFuelBlips()
    
    while true do
        Wait(1000)
        
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        
        if vehicle ~= 0 and DoesEntityExist(vehicle) then
            local fuel = GetVehicleFuel(vehicle)
            
            if fuel > 0 then
                local rpm = GetVehicleCurrentRpm(vehicle)
                local speed = GetEntitySpeed(vehicle)
                
                -- Calculate consumption
                local consumption = Config.Vehicles.Fuel.IdleConsumption
                
                if speed > 0.5 then
                    consumption = Config.Vehicles.Fuel.ConsumptionRate * (1 + rpm * 0.5)
                end
                
                fuel = fuel - consumption
                if fuel < 0 then fuel = 0 end
                
                SetVehicleFuel(vehicle, fuel)
                
                -- Check if out of fuel
                if fuel <= 0 then
                    SetVehicleEngineOn(vehicle, false, true, true)
                end
            end
        end
    end
end)

-- Main thread for fuel stations
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        
        for _, station in ipairs(fuelStations) do
            local distance = #(coords - station.coords)
            
            if distance < 15.0 then
                -- Draw marker
                DrawMarker(36, station.coords, vec3(1.0, 1.0, 1.0), {r = 255, g = 200, b = 0, a = 100})
                
                if distance < 3.0 then
                    Draw3DText(station.coords, '[E] Refuel Vehicle', 0.5, 4)
                    
                    if IsControlJustPressed(0, 38) then -- E key
                        local vehicle = GetVehiclePedIsIn(ped, false)
                        if vehicle ~= 0 then
                            RefuelVehicle(vehicle, station.price)
                        else
                            SendNotification({
                                type = 'error',
                                message = 'You must be in a vehicle'
                            })
                        end
                    end
                end
            end
        end
        
        Wait(0)
    end
end)

-- Export functions
exports('GetFuelPrice', GetFuelPrice)
exports('RefuelVehicle', RefuelVehicle)

DebugPrint('Fuel system loaded')
