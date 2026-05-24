-- Phantom World Fines System - Client Side

local QBCore = exports['qbx_core']:GetCoreObject()

-- Initialize player
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    -- Check for unpaid fines on player load
    TriggerServerEvent('dr-fines:server:checkFines')
end)

-- Check fines command
RegisterCommand('checkfines', function()
    TriggerServerEvent('dr-fines:server:getFines')
end)

-- Open fines menu
RegisterCommand('finesmenu', function()
    -- This would open a UI menu for viewing and paying fines
    -- For now, we'll use chat commands
    TriggerServerEvent('dr-fines:server:getFines')
end)

-- Notify when fine is issued
RegisterNetEvent('dr-fines:client:notifyFine', function(fineLabel, fineAmount)
    if Config.EnableNotifications then
        QBCore:Notify('You have been issued a fine: ' .. fineLabel .. ' - $' .. fineAmount, 'error')
    end
end)

-- Notify when fine is paid
RegisterNetEvent('dr-fines:client:notifyPaid', function(fineId, fineAmount)
    if Config.EnableNotifications then
        QBCore:Notify('Fine #' .. fineId .. ' paid successfully - $' .. fineAmount, 'success')
    end
end)

-- Notify when all fines are paid
RegisterNetEvent('dr-fines:client:notifyAllPaid', function(totalAmount)
    if Config.EnableNotifications then
        QBCore:Notify('All fines paid successfully - Total: $' .. totalAmount, 'success')
    end
end)

-- Fine payment reminder (runs every 30 minutes)
CreateThread(function()
    while true do
        Wait(1800000) -- 30 minutes
        TriggerServerEvent('dr-fines:server:getFines')
    end
end)
