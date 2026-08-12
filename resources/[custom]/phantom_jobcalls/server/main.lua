local QBCore

CreateThread(function()
    while GetResourceState('qbx_core') ~= 'started' do
        Wait(100)
    end
    QBCore = exports['qbx_core']:GetCoreObject()
end)

RegisterNetEvent('phantom_jobcalls:complete', function(contactId, payout)
    local src = source
    if not QBCore then return end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    payout = tonumber(payout) or 0
    if payout < 0 or payout > 10000 then return end
    Player.Functions.AddMoney('cash', payout, 'phantom-jobcall')
end)

AddEventHandler('phantom_jobcalls:enableContracts', function(_src)
    -- reserved for future duty toggles
end)

CreateThread(function()
    if not Config.Enabled then return end
    while true do
        local waitMs = math.random(Config.MinIntervalMs, Config.MaxIntervalMs)
        Wait(waitMs)
        local ok, players = pcall(function()
            return exports.qbx_core:GetQBPlayers()
        end)
        if ok and type(players) == 'table' then
            for _, Player in pairs(players) do
                if Player and Player.PlayerData and Player.PlayerData.source then
                    local allow = true
                    if Config.RequireContractsMeta then
                        allow = Player.PlayerData.metadata and Player.PlayerData.metadata.phantom_contracts == true
                    end
                    if allow and math.random(1, 100) <= 55 then
                        local contact = Config.Contacts[math.random(#Config.Contacts)]
                        TriggerClientEvent('phantom_jobcalls:incoming', Player.PlayerData.source, {
                            id = contact.id,
                            name = contact.name,
                            title = contact.title,
                            type = contact.type,
                            blurb = contact.blurb,
                            payout = contact.payout,
                            ringSeconds = Config.RingSeconds,
                        })
                    end
                end
            end
        end
    end
end)
