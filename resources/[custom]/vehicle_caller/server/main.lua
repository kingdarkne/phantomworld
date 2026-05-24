-- Vehicle Calling Menu - Server
-- Handles vehicle spawning logic and database interactions

print('^2[Vehicle Caller]^7 Server loaded')

-- Vehicle spawned event
RegisterNetEvent('vehicle_caller:server:vehicleSpawned', function(vehicleData)
    local src = source
    print('^2[Vehicle Caller]^7 Player ' .. src .. ' spawned vehicle: ' .. (vehicleData.name or vehicleData.model))
    
    -- Here you can add database logging or other server-side logic
    -- For example, update vehicle status in database
end)
