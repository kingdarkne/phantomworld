local enabled = false

RegisterNetEvent('dr-admincar:toggle', function()
    enabled = not enabled
    local msg = enabled and 'Admin car protection ENABLED' or 'Admin car protection DISABLED'
    lib.notify({ title = 'AdminCar', description = msg, type = enabled and 'success' or 'error' })
end)

CreateThread(function()
    while true do
        Wait(500)
        if enabled then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                local veh = GetVehiclePedIsIn(ped, false)
                if GetPedInVehicleSeat(veh, -1) == ped then
                    -- Make this vehicle extremely hard to destroy while you are driving it
                    SetEntityInvincible(veh, true)
                    SetVehicleCanBreak(veh, false)
                    SetVehicleTyresCanBurst(veh, false)
                    SetDisableVehiclePetrolTankDamage(veh, true)
                    SetDisableVehiclePetrolTankFires(veh, true)
                    SetVehicleEngineCanDegrade(veh, false)
                end
            end
        end
    end
end)

