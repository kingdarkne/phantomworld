local usingQbx = GetResourceState('qbx_core') == 'started'
local QBCore = nil
local useDebug = Config.Debug
local rep = nil

local function notify(msg, nType)
    if usingQbx and lib and lib.notify then
        lib.notify({ description = msg, type = nType == 'error' and 'error' or 'inform' })
        return
    end
    QBCore.Functions.Notify(msg, nType)
end

local function getPlayerData()
    if usingQbx then
        return exports.qbx_core:GetPlayerData()
    end
    return QBCore.Functions.GetPlayerData()
end

local function triggerServerCallback(name, cb, ...)
    local args = { ... }
    if usingQbx and lib and lib.callback then
        local ok, result, value = pcall(function()
            return lib.callback.await(name, false, table.unpack(args))
        end)
        if ok and type(cb) == 'function' then
            cb(result, value)
        elseif type(cb) == 'function' then
            cb({}, nil)
        end
        return
    end
    QBCore.Functions.TriggerCallback(name, cb, ...)
end

local function PoliceCall()
    if Config.PoliceCallChance >= math.random(1, 100) then
        TriggerServerEvent('police:server:policeAlert', 'Suspicous activity')
    end
end


local function hasItem(item, amount)
    if usingQbx then
        local fromItem = exports.ox_inventory:Search('count', item)
        if fromItem < amount then return false end
        return true
    elseif Config.Inventory == 'qb' then
        return QBCore.Functions.HasItem(item, amount)
    elseif Config.Inventory == 'ox' then
        local fromItem = exports.ox_inventory:Search('count', item)
        if fromItem < amount then return false end
        return true
    end
end

local function attemptTrade(trade, modifier)
    TriggerEvent('animations:client:EmoteCommandStart', {"argue2"})
    if trade.type == 'illegal' then
        PoliceCall()
    end

    if usingQbx and lib and lib.progressBar then
        local ok = lib.progressBar({
            duration = 2000,
            label = 'Discussing trade',
            useWhileDead = false,
            canCancel = false,
            disable = {
                move = true,
                car = true,
                combat = true,
                mouse = false,
            },
        })
        if not ok then
            TriggerEvent('animations:client:EmoteCommandStart', {"damn"})
            notify('You do not have the required items on you.' , 'error')
            return
        end
        -- continue in shared done flow below
    else
        QBCore.Functions.Progressbar("item_check", 'Discussing trade', 2000, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
            }, {
            }, {}, {}, function() end, function() end)
    end

    do -- Done flow
            if useDebug then
               print('Tokens: ', Config.UseTokens)
               print('Token value: ', trade.tokenValue)
            end
            if Config.UseTokens and trade.tokenValue ~= nil then
                if useDebug then
                print('Doing token trade')
                end
                local tokens = nil
                local tokenName = trade.tokenValue
                triggerServerCallback('cw-tokens:server:PlayerHasToken', function(result, value)
                    tokens = result
                    if tokens[tokenName] ~= nil then
                        if useDebug then
                        print('found a token with '..tokenName)
                        end
                        TriggerEvent('animations:client:EmoteCommandStart', {"c"})
                        TriggerServerEvent('dr-trade:server:tradeItems', trade, modifier)
                    else
                        TriggerEvent('animations:client:EmoteCommandStart', {"damn"})
                        notify('You do not have the right token on you.' , 'error')
                    end
                end)
            else
                if useDebug then
                   print('Trade was initiated - calling server side')
                end
                TriggerEvent('animations:client:EmoteCommandStart', {"c"})
                TriggerServerEvent('dr-trade:server:tradeItems', trade, modifier)
            end
        end
end

RegisterNetEvent('dr-trade:client:attemptTrade', function(data, modifier)
    local tradeName = data.tradeName
    local trade = Config.Trades[tradeName]
    if useDebug then
        print('trade name: ', tradeName)
    end

    if trade then
        local amountOfItemsPlayerHas = 0
        if trade.fromItems then
            if useDebug then
               print('amount of From items:', #trade.fromItems)
            end
            for i,item in pairs(trade.fromItems) do
                local total = item.amount
                if modifier then
                    total = item.amount*modifier
                end
                if hasItem(item.name , total) then
                    if useDebug then
                       print('Player has '..total..' '..item.name)
                    end
                    amountOfItemsPlayerHas = amountOfItemsPlayerHas + 1
                else
                    if useDebug then
                       print('Player doesnt have '..total..' '..item.name)
                    end
                    local itemLabel = item.name
                    if QBCore and QBCore.Shared and QBCore.Shared.Items and QBCore.Shared.Items[item.name] then
                        itemLabel = QBCore.Shared.Items[item.name].label
                    end
                    TriggerEvent('animations:client:EmoteCommandStart', {"shrug"})
                    notify('You do not have enough '..itemLabel.. ' on you.' , 'error')
                end
            end

            if useDebug then
               print('amountOfItemsPlayerHas', amountOfItemsPlayerHas, 'amount of from items:', #trade.fromItems )
            end

            if (amountOfItemsPlayerHas == #trade.fromItems) then
                local Player = getPlayerData()

                attemptTrade(trade, modifier)
            end
        else
            if useDebug then
                print('Handling a cash trade without items')
                print('Amount: ', trade.fromMoney)
            end
            local Player = getPlayerData()
            if Player.money[trade.fromMoneyType] >= trade.fromMoney then
                attemptTrade(trade)
            else
                notify('You do not have enough '..trade.fromMoneyType.. ' on you.' , 'error')
            end
        end
    else
        TriggerEvent('animations:client:EmoteCommandStart', {"damn"})
        notify('Trade doesnt exist', 'error')
    end
end)

RegisterNetEvent('dr-trade:client:toggleDebug', function(debug)
   print('Setting debug to',debug)
   useDebug = debug
end)

function getTrade(tradeName)
    if Config.Trades[tradeName] then
        return Config.Trades[tradeName]
    else
        return nil
    end
end

RegisterNetEvent('dr-trade:client:freeinventory', function()
    LocalPlayer.state.invBusy = false
end)