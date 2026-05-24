-- Admin Auto Keys - Client side (v2 - simplified)
-- Removed aggressive door-lock manipulation that caused cars to stay locked.
-- Only handles giving keys.

local lastVehicle = 0
local lastKeyAttempt = 0
local isAdminCached = nil
local lastAdminCheck = 0

local function checkAdmin()
    local now = GetGameTimer()
    if isAdminCached ~= nil and (now - lastAdminCheck) < 30000 then
        return isAdminCached
    end
    isAdminCached = lib.callback.await('admin_auto_keys:isAdmin', false) or false
    lastAdminCheck = now
    return isAdminCached
end

local function hasKeys(vehicle)
    local ok, result = pcall(function()
        return exports.qbx_vehiclekeys:HasKeys(vehicle)
    end)
    if ok then return result end
    return false
end

CreateThread(function()
    Wait(5000)
    while true do
        Wait(1000)

        local ped = PlayerPedId()
        if not IsPedInAnyVehicle(ped, false) then
            lastVehicle = 0
            goto continue
        end

        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle == 0 or not DoesEntityExist(vehicle) then goto continue end
        if vehicle == lastVehicle then goto continue end
        if GetPedInVehicleSeat(vehicle, -1) ~= ped then goto continue end

        lastVehicle = vehicle

        if GetGameTimer() - lastKeyAttempt < 1500 then goto continue end
        lastKeyAttempt = GetGameTimer()

        local netId = NetworkGetNetworkIdFromEntity(vehicle)
        if not netId or netId == 0 then goto continue end

        if hasKeys(vehicle) then goto continue end

        local isAdmin = checkAdmin()
        local adminSpawned = Entity(vehicle).state.adminSpawned

        if isAdmin then
            -- Admin entering: silently grant keys + mark for future drivers
            TriggerServerEvent('admin_auto_keys:requestKeys', netId, true)
        elseif adminSpawned then
            -- Player entering an admin-flagged car: get keys + storage alert
            TriggerServerEvent('admin_auto_keys:requestKeys', netId, false)
            lib.notify({
                title = 'Vehicle Received',
                description = 'An admin gave you this vehicle. Take it to a Prepaid Storage / Garage to keep it!',
                type = 'warning',
                duration = 12000
            })
        end

        ::continue::
    end
end)

-- /givekeys [playerId] - admin command: give keys + flag the NEAREST vehicle for target player
RegisterCommand('givekeys', function(_, args)
    if not checkAdmin() then
        lib.notify({ title = 'Admin Auto Keys', description = 'You are not an admin.', type = 'error' })
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        lib.notify({ title = 'Usage', description = '/givekeys [playerId]', type = 'inform' })
        return
    end

    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 then
        -- Find nearest vehicle within 10m
        local closest, closestDist = 0, 10.0
        local vehicles = GetGamePool('CVehicle')
        for _, v in ipairs(vehicles) do
            local dist = #(GetEntityCoords(v) - pedCoords)
            if dist < closestDist then
                closest, closestDist = v, dist
            end
        end
        vehicle = closest
    end

    if vehicle == 0 or not DoesEntityExist(vehicle) then
        lib.notify({ title = 'Admin Auto Keys', description = 'No vehicle found nearby (must be within 10m).', type = 'error' })
        return
    end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    TriggerServerEvent('admin_auto_keys:giveToPlayer', netId, targetId)
    lib.notify({ title = 'Admin Auto Keys', description = ('Gave vehicle keys to player ID %d'):format(targetId), type = 'success' })
end, false)

TriggerEvent('chat:addSuggestion', '/givekeys', 'Give keys + storage alert for nearest vehicle to a player', {
    { name = 'playerId', help = 'Target player server ID' }
})
