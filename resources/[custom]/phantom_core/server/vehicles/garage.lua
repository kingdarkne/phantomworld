-- Phantom Core - Garage System (Server)
-- Server-side garage management

-- Get player vehicles
lib.callback.register('phantom:server:getPlayerVehicles', function(source)
    local citizenid = GetCitizenId(source)
    if not citizenid then return {} end
    
    -- This would query your vehicles table
    -- For now, return empty array
    return {}
end)

-- Store vehicle
lib.callback.register('phantom:server:storeVehicle', function(source, vehicleData)
    local citizenid = GetCitizenId(source)
    if not citizenid then return { success = false } end
    
    -- Store vehicle data to database
    -- This would integrate with your vehicle system
    
    return { success = true }
end)

-- Retrieve vehicle
lib.callback.register('phantom:server:retrieveVehicle', function(source, vehicleId)
    local citizenid = GetCitizenId(source)
    if not citizenid then return { success = false } end
    
    -- Get vehicle data and spawn it
    -- This would integrate with your vehicle system
    
    return { success = true }
end)

DebugPrint('Garage server loaded')
