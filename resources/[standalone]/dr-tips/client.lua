-- Phantom World Tips System - Client Side

local QBCore = exports['qbx_core']:GetCoreObject()

-- Show tip notification
RegisterNetEvent('dr-tips:client:showTip', function(data)
    local title = data.title
    local tip = data.tip
    local duration = data.duration or 10
    local position = data.position or Config.Position
    
    -- Create the notification UI
    SendNUIMessage({
        action = 'showTip',
        title = title,
        tip = tip,
        duration = duration * 1000,
        position = position,
        backgroundColor = Config.BackgroundColor,
        textColor = Config.TextColor,
        titleColor = Config.TitleColor,
        fontSize = Config.FontSize
    })
end)

-- Initialize NUI
CreateThread(function()
    SetNuiFocus(false, false)
    
    -- Send keepalive to keep NUI loaded
    while true do
        Wait(5000)
        SendNUIMessage({ action = 'keepalive' })
    end
end)

-- NUI callback
RegisterNUICallback('closeTip', function(data, cb)
    cb(1)
end)
