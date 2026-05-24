-- Admin Auto Keys - Server side (v2)

local QBCore = exports['qbx_core']:GetCoreObject()

local ADMIN_GROUPS = { 'admin', 'god', 'superadmin' }

local function isAdmin(src)
    if not src or src == 0 then return false end
    if IsPlayerAceAllowed(src, 'command') then return true end
    for _, group in ipairs(ADMIN_GROUPS) do
        if IsPlayerAceAllowed(src, group) then return true end
        local ok, has = pcall(QBCore.Functions.HasPermission, src, group)
        if ok and has then return true end
    end
    return false
end

lib.callback.register('admin_auto_keys:isAdmin', function(source)
    return isAdmin(source)
end)

local function giveKeysToPlayer(targetSrc, vehicle)
    local ok = pcall(function()
        exports.qbx_vehiclekeys:GiveKeys(targetSrc, vehicle)
    end)
    if not ok then
        lib.callback('qbx_vehiclekeys:server:giveKeys', targetSrc, function() end, NetworkGetNetworkIdFromEntity(vehicle))
    end
end

-- Auto self-claim when admin or flagged-vehicle player enters
RegisterNetEvent('admin_auto_keys:requestKeys', function(netId, markAsAdminSpawned)
    local src = source
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not vehicle or vehicle == 0 then return end

    if markAsAdminSpawned and isAdmin(src) then
        Entity(vehicle).state:set('adminSpawned', true, true)
    end

    if not isAdmin(src) then
        if not Entity(vehicle).state.adminSpawned then return end
    end

    giveKeysToPlayer(src, vehicle)

    if not isAdmin(src) then
        Entity(vehicle).state:set('adminSpawned', false, true)
    end
end)

-- Admin uses /givekeys [playerid] - give keys + alert + storage hint to target
RegisterNetEvent('admin_auto_keys:giveToPlayer', function(netId, targetId)
    local src = source
    if not isAdmin(src) then return end

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not vehicle or vehicle == 0 then return end

    targetId = tonumber(targetId)
    if not targetId then return end
    if not GetPlayerName(targetId) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Admin Auto Keys',
            description = 'Target player not online: ID ' .. tostring(targetId),
            type = 'error'
        })
        return
    end

    -- Flag vehicle so target gets the storage alert when they enter
    Entity(vehicle).state:set('adminSpawned', true, true)

    -- Give keys directly so they can drive immediately
    giveKeysToPlayer(targetId, vehicle)

    TriggerClientEvent('ox_lib:notify', targetId, {
        title = 'Vehicle Received',
        description = 'An admin gave you a vehicle nearby. Take it to a Prepaid Storage / Garage to keep it!',
        type = 'warning',
        duration = 15000
    })
end)
