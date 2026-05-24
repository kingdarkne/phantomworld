-- Vehicle Damage Multiplier System
-- Makes vehicles more durable by reducing damage

local damageMultipliers = {
    engine = 0.02,       -- 2% of normal engine damage
    body = 0.02,         -- 2% of normal body damage
    petrol = 0.02,       -- 2% of normal petrol tank damage
    collision = 0.05,    -- 5% of normal collision damage
    weapon = 0.1,        -- 10% of normal weapon damage
    deformation = 0.02   -- 2% of visual deformation
}

-- Apply damage multipliers when resource starts
CreateThread(function()
    while true do
        Wait(100)
        
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        
        if vehicle ~= 0 and DoesEntityExist(vehicle) then
            -- Reduce engine damage
            SetVehicleEngineHealth(vehicle, GetVehicleEngineHealth(vehicle) + (1000 - GetVehicleEngineHealth(vehicle)) * (1 - damageMultipliers.engine) * 0.01)
            
            -- Reduce body damage
            SetVehicleBodyHealth(vehicle, GetVehicleBodyHealth(vehicle) + (1000 - GetVehicleBodyHealth(vehicle)) * (1 - damageMultipliers.body) * 0.01)
            
            -- Reduce petrol tank damage
            SetVehiclePetrolTankHealth(vehicle, GetVehiclePetrolTankHealth(vehicle) + (1000 - GetVehiclePetrolTankHealth(vehicle)) * (1 - damageMultipliers.petrol) * 0.01)
        end
    end
end)

-- Reduce damage from collisions
CreateThread(function()
    while true do
        Wait(1000)
        
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        
        if vehicle ~= 0 and DoesEntityExist(vehicle) then
            -- Apply damage reduction for recent collisions
            if HasEntityBeenDamagedByAnyVehicle(vehicle) then
                local currentHealth = GetVehicleBodyHealth(vehicle)
                if currentHealth < 1000 then
                    SetVehicleBodyHealth(vehicle, currentHealth + 50 * damageMultipliers.collision)
                end
            end
        end
    end
end)

-- Prevent instant vehicle explosion
CreateThread(function()
    while true do
        Wait(500)
        
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        
        if vehicle ~= 0 and DoesEntityExist(vehicle) then
            local petrolHealth = GetVehiclePetrolTankHealth(vehicle)
            
            -- If petrol tank is critically low, boost it to prevent explosion
            if petrolHealth < 200 then
                SetVehiclePetrolTankHealth(vehicle, 300)
            end
        end
    end
end)

print('[dr-vehdamage] Vehicle damage multipliers loaded - Vehicles are now more durable')
