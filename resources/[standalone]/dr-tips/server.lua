-- Phantom World Tips System - Server Side

local QBCore = exports['qbx_core']:GetCoreObject()

-- Send a random tip to a player
local function SendRandomTip(playerId)
    local randomCategory = Config.Tips[math.random(1, #Config.Tips)]
    local randomTip = randomCategory.tips[math.random(1, #randomCategory.tips)]
    
    TriggerClientEvent('dr-tips:client:showTip', playerId, {
        title = randomCategory.title,
        tip = randomTip,
        duration = Config.DisplayDuration,
        position = Config.Position
    })
end

-- Send tip on player join
AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    if Config.EnableOnJoin then
        local playerId = Player and Player.PlayerData and Player.PlayerData.source or source
        if not playerId then return end
        SetTimeout(5000, function()
            SendRandomTip(playerId)
        end)
    end
end)

-- Command to show a tip
QBCore.Commands.Add('tip', 'Show a random tip', {}, false, function(source)
    SendRandomTip(source)
end)

-- Command to show tips for a specific category
QBCore.Commands.Add('tips', 'Show tips for a category', {{name = 'category', help = 'Category (gun_permit, vehicles, jobs, money, legal, health, social, housing, business, emergency)'}}, false, function(source, args)
    local category = args[1]
    
    if not category then
        TriggerClientEvent('QBCore:Notify', source, 'Usage: /tips [category]', 'error')
        local categories = 'Available categories: '
        for _, tipConfig in ipairs(Config.Tips) do
            categories = categories .. tipConfig.category .. ', '
        end
        TriggerClientEvent('QBCore:Notify', source, categories, 'info')
        return
    end
    
    local found = false
    for _, tipConfig in ipairs(Config.Tips) do
        if tipConfig.category == category then
            local randomTip = tipConfig.tips[math.random(1, #tipConfig.tips)]
            TriggerClientEvent('dr-tips:client:showTip', source, {
                title = tipConfig.title,
                tip = randomTip,
                duration = Config.DisplayDuration,
                position = Config.Position
            })
            found = true
            break
        end
    end
    
    if not found then
        TriggerClientEvent('QBCore:Notify', source, 'Category not found', 'error')
    end
end)

-- Periodic tip system
if Config.EnableRandomTips then
    CreateThread(function()
        while true do
            Wait(Config.DisplayInterval * 1000)
            
            -- Send tips to all online players
            local players = QBCore.Functions.GetPlayers()
            for _, playerId in ipairs(players) do
                SendRandomTip(playerId)
            end
        end
    end)
end

-- Export to send specific tip
exports('SendTip', function(playerId, category)
    for _, tipConfig in ipairs(Config.Tips) do
        if tipConfig.category == category then
            local randomTip = tipConfig.tips[math.random(1, #tipConfig.tips)]
            TriggerClientEvent('dr-tips:client:showTip', playerId, {
                title = tipConfig.title,
                tip = randomTip,
                duration = Config.DisplayDuration,
                position = Config.Position
            })
            return true
        end
    end
    return false
end)
