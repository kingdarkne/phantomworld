local config = require 'config.server'

---Gets Citizen Id based on source
---@param source number ID of player
---@return string? citizenid The player CitizenID, nil otherwise.
local function getCitizenId(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    return player.PlayerData.citizenid
end

lib.callback.register('qbx_vehiclekeys:server:findKeys', function(source, netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if PolstangDenyKeyGrant(source, vehicle) then return false end
    if math.random() <= GetVehicleConfig(vehicle).findKeysChance then
        GiveKeys(source, vehicle)
        return true
    end
end)

-- Add callback for giving keys to vehicle owners
lib.callback.register('qbx_vehiclekeys:server:giveKeys', function(source, netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not vehicle then return false end
    
    local citizenId = getCitizenId(source)
    if not citizenId then return false end
    
    local owner = Entity(vehicle).state.owner
    if owner and citizenId == owner then
        GiveKeys(source, vehicle, true) -- Skip notification for owner
        return true
    end
    
    return false
end)

lib.callback.register('qbx_vehiclekeys:server:carjack', function(source, netId, weaponTypeGroup)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if PolstangDenyKeyGrant(source, vehicle) then return false end
    local chance = config.carjackChance[weaponTypeGroup] or 0.5
    if math.random() <= chance then
        GiveKeys(source, vehicle)
        TriggerEvent('qb-vehiclekeys:server:setVehLockState', netId, 1)
        return true
    end
end)

RegisterNetEvent('qbx_vehiclekeys:server:playerEnteredVehicleWithEngineOn', function(netId)
    local src = source
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not GetIsVehicleEngineRunning(vehicle) then return end
    if PolstangDenyKeyGrant(src, vehicle) then return end
    GiveKeys(src, vehicle)
end)

---TODO: secure this event
RegisterNetEvent('qbx_vehiclekeys:server:tookKeys', function(netId)
    local src = source
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if PolstangDenyKeyGrant(src, vehicle) then return end
    GiveKeys(src, vehicle)
end)

---TODO: secure this event
RegisterNetEvent('qbx_vehiclekeys:server:hotwiredVehicle', function(netId)
    local src = source
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if PolstangDenyKeyGrant(src, vehicle) then return end
    GiveKeys(src, vehicle)
end)

RegisterNetEvent('qb-vehiclekeys:server:breakLockpick', function(itemName)
    if not (itemName == 'lockpick' or itemName == 'advancedlockpick') then return end
    exports.ox_inventory:RemoveItem(source, itemName, 1)
end)

RegisterNetEvent('qb-vehiclekeys:server:setVehLockState', function(vehNetId, state)
	local vehicleEntity = NetworkGetEntityFromNetworkId(vehNetId)
	if type(state) ~= 'number' or not DoesEntityExist(vehicleEntity) then return end
    local vehicleConfig = GetVehicleConfig(vehicleEntity)
    if vehicleConfig.noLock or vehicleConfig.shared then return end
    Entity(vehicleEntity).state:set('doorslockstate', state, true)
end)
