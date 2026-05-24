-- qb-vehiclekeys usage
-- replace the function LockpickDoor() in qb-vehicle keys with the following snippet

-- helper used below to handle the lockpick result using qb-vehiclekeys logic
local function lockpickFinish(success, vehicle)
    if not vehicle or vehicle == 0 then return end

    local vehNetId = NetworkGetNetworkIdFromEntity(vehicle)
    local plate = QBCore.Functions.GetPlate(vehicle)

    if success then
        -- unlock the vehicle door and give keys
        TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', vehNetId, 1)
        TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
        if QBCore and QBCore.Functions and QBCore.Functions.Notify then
            QBCore.Functions.Notify('You successfully lockpicked the vehicle.', 'success')
        end
    else
        -- optional: notify failure
        if QBCore and QBCore.Functions and QBCore.Functions.Notify then
            QBCore.Functions.Notify('You failed to lockpick the vehicle.', 'error')
        end
    end
end

function LockpickDoor()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local vehicle = QBCore.Functions.GetClosestVehicle(pos)
    if vehicle ~= nil and vehicle ~= 0 then
        local vehpos = GetEntityCoords(vehicle)
        if #(pos - vehpos) < 2.5 then
            local vehLockStatus = GetVehicleDoorLockStatus(vehicle)
            if vehLockStatus > 0 then
                -- Call the new lockpicking minigame function
                exports["cure-lockpick"]:OpenLockpickMinigame(function(success)
                    if success then
                        print("Lockpicking success!")
                        lockpickFinish(true, vehicle)
                    else
                        print("Lockpicking failed!")
                        lockpickFinish(false, vehicle)
                    end
                end, vehicle) -- Pass the vehicle as a parameter
            end
        end
    end
end

-- to make game shorter / faster adjust the time from the OpenDevice function in client.lua
-- see below example for time adjustment

function OpenDevice(successCallback, target, time)
    SetNuiFocus(true, true)
    time = 50  -- Change to suit your needs 
    SendNUIMessage({type = "open", target = target, time = time})
end