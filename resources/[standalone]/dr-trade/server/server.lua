local usingQbx = GetResourceState('qbx_core') == 'started'

local QBCore = not usingQbx and DrGetQBCore() or nil
local useDebug = Config.Debug

local function getQbItem(item)
    if usingQbx then
        local data = exports.ox_inventory:Items(item)
        if data then
            return { label = data.label or item }
        end
        return nil
    end
    return QBCore.Shared.Items[item]
end

local function getPlayer(source)
    if usingQbx then
        return exports.qbx_core:GetPlayer(source)
    end
    return QBCore.Functions.GetPlayer(source)
end

local function getQBItem(item)
    local qbItem = getQbItem(item)
    if qbItem then
        return qbItem
    else
        print('Someone forgot to add the item')
    end
end

local function addItem(item, amount, info, source)
    if Config.Inventory == 'qb' and not usingQbx then
    	local Player = getPlayer(source)
        Player.Functions.AddItem(item, amount, nil, info)
        TriggerClientEvent('inventory:client:ItemBox', source, getQBItem(item), "add")
    elseif Config.Inventory == 'ox' or usingQbx then
        exports.ox_inventory:AddItem(source, item, amount, info)
    end
end

local function removeItem(item, amount, source)
    local Player = getPlayer(source)
    if Config.Inventory == 'qb' and not usingQbx then
        Player.Functions.RemoveItem(item, amount, nil)
        TriggerClientEvent('inventory:client:ItemBox', source, getQBItem(item), "remove")
    elseif Config.Inventory == 'ox' or usingQbx then
        exports.ox_inventory:RemoveItem(source, item, amount, nil, nil)
    end
end

RegisterServerEvent('dr-trade:server:tradeItems', function(trade, modifier)
    local src = source
	local Player = getPlayer(src)

    if Config.UseTokens and trade.tokenValue ~= nil then
        if useDebug then
           print('Doing token trade')
        end
        TriggerEvent('cw-tokens:server:TakeToken', src, trade.tokenValue)
        for i, item in pairs(trade.toItems) do
            local total = item.amount
            if modifier then
                total = item.amount*modifier
            end
            if useDebug then
                print('adding items to pockets (from token trade)')
            end
            addItem(item.name, total,nil, src)
        end
    else
        if trade.fromMoney then
            if useDebug then
                print('Handling a from money trade')
            end
            local moneyType = 'cash'
            if trade.fromMoneyType then
                moneyType = trade.fromMoneyType
            end
            Player.Functions.RemoveMoney(moneyType, trade.fromMoney, 'dr-trades')
        end
        if trade.fromItems then
            for i, item in pairs(trade.fromItems) do
                local total = item.amount
                if modifier then
                    total = item.amount*modifier
                end
                if useDebug then
                   print('removing items from pockets')
                end
                removeItem(item.name, total, src)
            end
        end

        if trade.toMoney then
            if useDebug then
                print('Doing To Money Trade')
            end
            local moneyType = 'cash'
            if trade.toMoneyType then
                moneyType = trade.toMoneyType
            end
            local payout = math.random(trade.toMoney.min, trade.toMoney.max)
            if modifier then
                payout = payout*modifier
            end
            Player.Functions.AddMoney(moneyType, tonumber(payout))
        end

        if trade.toItems then
            for i, item in pairs(trade.toItems) do
                local total = item.amount
                if modifier then
                    total = item.amount*modifier
                end
                if useDebug then
                   print('adding items to pockets')
                end
                addItem(item.name, total, item.info, src)
            end
        end
        if trade.toBills then
            if useDebug then
               print('Doing Dirty Bills Trade')
            end
            local info = {
                worth = math.random(trade.toBills.min, trade.toBills.max)
            }
            addItem('markedbills', math.random(1,2), info, src)
        end
        if trade.toCrypto then
            if useDebug then
                print('Doing Crypto Trade')
             end
            local payout = math.random(trade.toCrypto.min, trade.toCrypto.max)
            Player.Functions.AddMoney('crypto', tonumber(payout))
        end
    end
    TriggerClientEvent('dr-trade:client:freeinventory', src)
end)

if usingQbx and lib and lib.addCommand then
    lib.addCommand('cwdebugtrade', {
        help = 'toggle debug for trade',
        restricted = 'group.admin',
    }, function(source)
        useDebug = not useDebug
        print('debug is now:', useDebug)
        TriggerClientEvent('dr-trade:client:toggleDebug', source, useDebug)
    end)
elseif QBCore and QBCore.Commands and QBCore.Commands.Add then
    QBCore.Commands.Add('cwdebugtrade', 'toggle debug for trade', {}, true, function(source)
        useDebug = not useDebug
        print('debug is now:', useDebug)
        TriggerClientEvent('dr-trade:client:toggleDebug', source, useDebug)
    end, 'dev')
else
    RegisterCommand('cwdebugtrade', function(source)
        if source ~= 0 and not IsPlayerAceAllowed(source, 'group.admin') then return end
        useDebug = not useDebug
        print('debug is now:', useDebug)
        if source ~= 0 then
            TriggerClientEvent('dr-trade:client:toggleDebug', source, useDebug)
        end
    end, false)
end