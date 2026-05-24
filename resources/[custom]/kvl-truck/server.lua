ESX = exports["es_extended"]:getSharedObject()


RegisterNetEvent('kvl-truck:shortrangepayment', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    local level = exports.pickle_xp:GetPlayerLevel(source, "Trucker")
    if level == 1 then
        if xPlayer ~= nil then
            exports.pickle_xp:AddPlayerXP(source, 'Trucker', 250)
            xPlayer.addMoney(KVL['Prices']['ShortRangePrices']['SLevel1'])
        end
    elseif level == 2 then
        if xPlayer ~= nil then
            exports.pickle_xp:AddPlayerXP(source, 'Trucker', 500)
            xPlayer.addMoney(KVL['Prices']['ShortRangePrices']['SLevel2'])
        end
    elseif level == 3 then
        if xPlayer ~= nil then
            exports.pickle_xp:AddPlayerXP(source, 'Trucker', 750)
            xPlayer.addMoney(KVL['Prices']['ShortRangePrices']['SLevel3'])
        end
    elseif level == 4 then
        if xPlayer ~= nil then
            exports.pickle_xp:AddPlayerXP(source, 'Trucker', 1000)
            xPlayer.addMoney(KVL['Prices']['ShortRangePrices']['SLevel4'])
        end
    elseif level == 5 then
        if xPlayer ~= nil then
            exports.pickle_xp:AddPlayerXP(source, 'Trucker', 1250)
            xPlayer.addMoney(KVL['Prices']['ShortRangePrices']['SLevel5'])
        end
    elseif level == 6 then
        if xPlayer ~= nil then
            exports.pickle_xp:AddPlayerXP(source, 'Trucker', 1500)
            xPlayer.addMoney(KVL['Prices']['ShortRangePrices']['SLevel6'])
        end
    elseif level == 7 then
        if xPlayer ~= nil then
            exports.pickle_xp:AddPlayerXP(source, 'Trucker', 1750)
            xPlayer.addMoney(KVL['Prices']['ShortRangePrices']['SLevel7'])
        end
    elseif level == 8 then
        if xPlayer ~= nil then
            exports.pickle_xp:AddPlayerXP(source, 'Trucker', 2000)
            xPlayer.addMoney(KVL['Prices']['ShortRangePrices']['SLevel8'])
        end
    elseif level == 9 then
        if xPlayer ~= nil then
            exports.pickle_xp:AddPlayerXP(source, 'Trucker', 2250)
            xPlayer.addMoney(KVL['Prices']['ShortRangePrices']['SLevel9'])
        end
    elseif level == 10 then
        if xPlayer ~= nil then
            exports.pickle_xp:AddPlayerXP(source, 'Trucker', 2500)
            xPlayer.addMoney(KVL['Prices']['ShortRangePrices']['SLevel10'])
        end
    end
end)

RegisterNetEvent('kvl-truck:mediumrangepayment', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    local level = exports.pickle_xp:GetPlayerLevel(source, "Trucker")
    if level == 1 then
        if xPlayer ~= nil then
            exports.pickle_xp:AddPlayerXP(source, 'Trucker', 500)
            xPlayer.addMoney(KVL['Prices']['MediumRangePrices']['SLevel1'])
        end
    elseif level == 2 then
        if xPlayer ~= nil then
            exports.pickle_xp:AddPlayerXP(source, 'Trucker', 750)
            xPlayer.addMoney(KVL['Prices']['MediumRangePrices']['SLevel2'])
        end
    elseif level == 3 then
        if xPlayer ~= nil then
            exports.pickle_xp:AddPlayerXP(source, 'Trucker', 1000)
            xPlayer.addMoney(KVL['Prices']['MediumRangePrices']['SLevel3'])
        end
    elseif level == 4 then
        if xPlayer ~= nil then
            exports.pickle_xp:AddPlayerXP(source, 'Trucker', 1250)
            xPlayer.addMoney(KVL['Prices']['MediumRangePrices']['SLevel4'])
        end
    elseif level == 5 then
        if xPlayer ~= nil then
            exports.pickle_xp:AddPlayerXP(source, 'Trucker', 1500)
            xPlayer.addMoney(KVL['Prices']['MediumRangePrices']['SLevel5'])
        end
    elseif level == 6 then
        if xPlayer ~= nil then
            exports.pickle_xp:AddPlayerXP(source, 'Trucker', 1750)
            xPlayer.addMoney(KVL['Prices']['MediumRangePrices']['SLevel6'])
        end
    elseif level == 7 then
        if xPlayer ~= nil then
            exports.pickle_xp:AddPlayerXP(source, 'Trucker', 2000)
            xPlayer.addMoney(KVL['Prices']['MediumRangePrices']['SLevel7'])
        end
    elseif level == 8 then
        if xPlayer ~= nil then
            exports.pickle_xp:AddPlayerXP(source, 'Trucker', 2250)
            xPlayer.addMoney(KVL['Prices']['MediumRangePrices']['SLevel8'])
        end
    elseif level == 9 then
        if xPlayer ~= nil then
            exports.pickle_xp:AddPlayerXP(source, 'Trucker', 2500)
            xPlayer.addMoney(KVL['Prices']['MediumRangePrices']['SLevel9'])
        end
    elseif level == 10 then
        if xPlayer ~= nil then
            exports.pickle_xp:AddPlayerXP(source, 'Trucker', 2750)
            xPlayer.addMoney(KVL['Prices']['MediumRangePrices']['SLevel10'])
        end
    end
end)

RegisterNetEvent('kvl-truck:longrangepayment', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    local level = exports.pickle_xp:GetPlayerLevel(source, "Trucker")
    if level == 1 then
        if xPlayer ~= nil then
            exports.pickle_xp:AddPlayerXP(source, 'Trucker', 750)
            xPlayer.addMoney(KVL['Prices']['LongRangePrices']['SLevel1'])
        end
    elseif level == 2 then
        if xPlayer ~= nil then
            exports.pickle_xp:AddPlayerXP(source, 'Trucker', 1000)
            xPlayer.addMoney(KVL['Prices']['LongRangePrices']['SLevel2'])
        end
    elseif level == 3 then
        if xPlayer ~= nil then
            exports.pickle_xp:AddPlayerXP(source, 'Trucker', 1250)
            xPlayer.addMoney(KVL['Prices']['LongRangePrices']['SLevel3'])
        end
    elseif level == 4 then
        if xPlayer ~= nil then
            exports.pickle_xp:AddPlayerXP(source, 'Trucker', 1500)
            xPlayer.addMoney(KVL['Prices']['LongRangePrices']['SLevel4'])
        end
    elseif level == 5 then
        if xPlayer ~= nil then
            exports.pickle_xp:AddPlayerXP(source, 'Trucker', 1750)
            xPlayer.addMoney(KVL['Prices']['LongRangePrices']['SLevel5'])
        end
    elseif level == 6 then
        if xPlayer ~= nil then
            exports.pickle_xp:AddPlayerXP(source, 'Trucker', 2000)
            xPlayer.addMoney(KVL['Prices']['LongRangePrices']['SLevel6'])
        end
    elseif level == 7 then
        if xPlayer ~= nil then
            exports.pickle_xp:AddPlayerXP(source, 'Trucker', 2250)
            xPlayer.addMoney(KVL['Prices']['LongRangePrices']['SLevel7'])
        end
    elseif level == 8 then
        if xPlayer ~= nil then
            exports.pickle_xp:AddPlayerXP(source, 'Trucker', 2500)
            xPlayer.addMoney(KVL['Prices']['LongRangePrices']['SLevel8'])
        end
    elseif level == 9 then
        if xPlayer ~= nil then
            exports.pickle_xp:AddPlayerXP(source, 'Trucker', 2750)
            xPlayer.addMoney(KVL['Prices']['LongRangePrices']['SLevel9'])
        end
    elseif level == 10 then
        if xPlayer ~= nil then
            exports.pickle_xp:AddPlayerXP(source, 'Trucker', 3000)
            xPlayer.addMoney(KVL['Prices']['LongRangePrices']['SLevel10'])
        end
    end
end)

RegisterServerEvent('kvl-trucker:addmoney')
AddEventHandler('kvl-trucker:addmoney', function(price)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if xPlayer ~= nil then
        xPlayer.addMoney(price)
    end
end)

RegisterServerEvent('kvl-trucker:removemoney')
AddEventHandler('kvl-trucker:removemoney', function(price)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if xPlayer ~= nil then
        xPlayer.removeMoney(price)
    end
end)

ESX.RegisterServerCallback('kvl-trucker:checkmoney', function(source, cb, price)
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer ~= nil then
        if KVL['Prices']['PaymentMethod'] == 'bank' then
            cb(xPlayer.getAccount("bank").money >= price)
        elseif KVL['Prices']['PaymentMethod'] == 'cash' then
            cb(xPlayer.getAccount("money").money >= price)
        end
    end

end)