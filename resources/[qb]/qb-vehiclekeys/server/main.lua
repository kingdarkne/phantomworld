-----------------------
----   Variables   ----
-----------------------
local QBCore = exports['qbx_core']:GetCoreObject()
local VehicleList = {}

-----------------------
----   Threads     ----
-----------------------

-----------------------
---- Server Events ----
-----------------------

-- Event to give keys. receiver can either be a single id, or a table of ids.
-- Must already have keys to the vehicle, trigger the event from the server, or pass forceGive as true (e.g. admin spawning for another player).
RegisterNetEvent('qb-vehiclekeys:server:GiveVehicleKeys', function(receiver, plate, forceGive)
    local giver = source
    local canGive = forceGive or HasKeys(giver, plate)

    if canGive then
        if not forceGive then
            TriggerClientEvent('QBCore:Notify', giver, Lang:t('notify.vgkeys'), 'success')
        end
        if type(receiver) == 'table' then
            for _, r in ipairs(receiver) do
                GiveKeys(r, plate)
            end
        else
            GiveKeys(receiver, plate)
        end
    else
        TriggerClientEvent('QBCore:Notify', giver, Lang:t('notify.ydhk'), 'error')
    end
end)

RegisterNetEvent('qb-vehiclekeys:server:AcquireVehicleKeys', function(plate)
    local src = source
    GiveKeys(src, plate)
end)

RegisterNetEvent('qb-vehiclekeys:server:breakLockpick', function(itemName)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    if not (itemName == 'lockpick' or itemName == 'advancedlockpick') then return end
    -- QBX uses ox_inventory; qb-inventory is not compatible with qbx_core.
    local removed = false
    if GetResourceState('ox_inventory') == 'started' and exports.ox_inventory and exports.ox_inventory.RemoveItem then
        local ok, res = pcall(exports.ox_inventory.RemoveItem, source, itemName, 1)
        removed = ok and res == true
    end

    if removed then
        -- Optional feedback (no qb-inventory ItemBox UI on QBX)
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Vehicle Keys',
            description = ('%s broke.'):format(itemName),
            type = 'error'
        })
    end
end)

RegisterNetEvent('qb-vehiclekeys:server:setVehLockState', function(vehNetId, state)
    SetVehicleDoorsLocked(NetworkGetEntityFromNetworkId(vehNetId), state)
end)

QBCore.Functions.CreateCallback('qb-vehiclekeys:server:GetVehicleKeys', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    local keysList = {}
    for plate, citizenids in pairs(VehicleList) do
        if citizenids[citizenid] then
            keysList[plate] = true
        end
    end
    cb(keysList)
end)

QBCore.Functions.CreateCallback('qb-vehiclekeys:server:checkPlayerOwned', function(_, cb, plate)
    local playerOwned = false
    if VehicleList[plate] then
        playerOwned = true
    end
    cb(playerOwned)
end)

-----------------------
----   Functions   ----
-----------------------

function GiveKeys(id, plate)
    local Player = QBCore.Functions.GetPlayer(id)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    if not plate then
        if GetVehiclePedIsIn(GetPlayerPed(id), false) ~= 0 then
            plate = QBCore.Shared.Trim(GetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(id), false)))
        else
            return
        end
    end
    if not VehicleList[plate] then VehicleList[plate] = {} end
    VehicleList[plate][citizenid] = true
    TriggerClientEvent('QBCore:Notify', id, Lang:t('notify.vgetkeys'))
    TriggerClientEvent('qb-vehiclekeys:client:AddKeys', id, plate)
end

exports('GiveKeys', GiveKeys)

function RemoveKeys(id, plate)
    local citizenid = QBCore.Functions.GetPlayer(id).PlayerData.citizenid

    if VehicleList[plate] and VehicleList[plate][citizenid] then
        VehicleList[plate][citizenid] = nil
    end

    TriggerClientEvent('qb-vehiclekeys:client:RemoveKeys', id, plate)
end

exports('RemoveKeys', RemoveKeys)

function HasKeys(id, plate)
    local citizenid = QBCore.Functions.GetPlayer(id).PlayerData.citizenid
    if VehicleList[plate] and VehicleList[plate][citizenid] then
        return true
    end
    return false
end

exports('HasKeys', HasKeys)

-- givexp-style: deferred reg + permission in handler + fallback (no add_ace from script)
local givekeysHelp = type(Lang:t('addcom.givekeys')) == 'string' and Lang:t('addcom.givekeys') or 'Give vehicle keys to player (ID optional)'
local givekeysArgName = type(Lang:t('addcom.givekeys_id')) == 'string' and Lang:t('addcom.givekeys_id') or 'id'
local givekeysArgHelp = type(Lang:t('addcom.givekeys_id_help')) == 'string' and Lang:t('addcom.givekeys_id_help') or 'Player server ID'

local function registerVehicleKeyCommands()
    local givekeysHandler = function(source, args)
        args = args or {}
        if not QBCore.Functions.HasPermission(source, 'admin') then
            TriggerClientEvent('QBCore:Notify', source, 'You do not have permission to use this command.', 'error')
            return
        end
        TriggerClientEvent('qb-vehiclekeys:client:GiveKeys', source, args[1] and tonumber(args[1]) or nil)
    end
    local addkeysHandler = function(source, args)
        args = args or {}
        if not QBCore.Functions.HasPermission(source, 'admin') then
            TriggerClientEvent('QBCore:Notify', source, 'You do not have permission to use this command.', 'error')
            return
        end
        local src = source
        if not args[1] or not args[2] then
            TriggerClientEvent('QBCore:Notify', src, Lang:t('notify.fpid'))
            return
        end
        GiveKeys(tonumber(args[1]), args[2])
    end
    local removekeysHandler = function(source, args)
        args = args or {}
        if not QBCore.Functions.HasPermission(source, 'admin') then
            TriggerClientEvent('QBCore:Notify', source, 'You do not have permission to use this command.', 'error')
            return
        end
        local src = source
        if not args[1] or not args[2] then
            TriggerClientEvent('QBCore:Notify', src, Lang:t('notify.fpid'))
            return
        end
        RemoveKeys(tonumber(args[1]), args[2])
    end
    -- RegisterCommand only = no "callback is table" from Commands.Add param order
    RegisterCommand('givekeys', givekeysHandler, false)
    RegisterCommand('addkeys', addkeysHandler, false)
    RegisterCommand('removekeys', removekeysHandler, false)
end
CreateThread(function() Wait(500) registerVehicleKeyCommands() end)
