-- Phantom Core - Client Core
-- Main initialization and core client functions

local isInitialized = false

-- Initialize resource
CreateThread(function()
    Wait(1000)
    
    if not IsPlayerLoggedIn() then
        while not IsPlayerLoggedIn() do
            Wait(500)
        end
    end
    
    isInitialized = true
    DebugPrint('Phantom Core initialized')
    
    -- Register NUI callbacks
    RegisterNUICallback('closeMenu', function(data, cb)
        SetNuiFocus(false, false)
        cb({})
    end)
    
    RegisterNUICallback('getPlayers', function(data, cb)
        local players = {}
        for _, playerId in ipairs(GetActivePlayers()) do
            local ped = GetPlayerPed(playerId)
            local name = GetPlayerName(playerId)
            table.insert(players, {
                id = playerId,
                name = name,
                ped = ped
            })
        end
        cb(players)
    end)
end)

-- Export functions for other resources
exports('Notify', function(message, type, duration)
    Notify(message, type, duration)
end)

exports('Progress', function(options)
    return Progress(options)
end)

exports('ShowMenu', function(options)
    return ShowMenu(options)
end)

exports('ShowDialog', function(options)
    return ShowDialog(options)
end)

exports('GetPlayerData', GetPlayerData)
exports('IsPlayerLoggedIn', IsPlayerLoggedIn)
exports('FormatMoney', FormatMoney)
exports('FormatTime', FormatTime)

DebugPrint('Phantom Core client loaded')
