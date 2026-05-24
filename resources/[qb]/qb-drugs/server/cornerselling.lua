local StolenDrugs = {}

local function getAvailableDrugs(source)
    local AvailableDrugs = {}
    local Player = QBCore.Functions.GetPlayer(source)

    if not Player then return nil end

    for k in pairs(Config.DrugsPrice) do
        local item = Player.Functions.GetItemByName(k)

        if item then
            AvailableDrugs[#AvailableDrugs + 1] = {
                item = item.name,
                amount = item.amount,
                label = QBCore.Shared.Items[item.name]['label']
            }
        end
    end
    return table.type(AvailableDrugs) ~= 'empty' and AvailableDrugs or nil
end

QBCore.Functions.CreateCallback('qb-drugs:server:cornerselling:getAvailableDrugs', function(source, cb)
    cb(getAvailableDrugs(source))
end)

RegisterNetEvent('qb-drugs:server:giveStealItems', function(drugType, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or StolenDrugs == {} then return end
    for k, v in pairs(StolenDrugs) do
        if drugType == v.item and amount == v.amount then
            exports['qb-inventory']:AddItem(src, drugType, amount, false, false, 'qb-drugs:server:giveStealItems')
            table.remove(StolenDrugs, k)
        end
    end
end)

RegisterNetEvent('qb-drugs:server:sellCornerDrugs', function(drugType, amount, price)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local availableDrugs = getAvailableDrugs(src)
    
    if not availableDrugs or not Player then return end
    
    local item = availableDrugs[drugType].item
    local hasItem = Player.Functions.GetItemByName(item)
    
    if hasItem and hasItem.amount >= amount then
        -- Notify the player that the offer was accepted
        TriggerClientEvent('QBCore:Notify', src, Lang:t('success.offer_accepted'), 'success')
        
        -- Remove the drug item from the player's inventory
        Player.Functions.RemoveItem(item, amount, false, 'qb-drugs:server:sellCornerDrugs')
        
        -- Add black money to the player's inventory
        Player.Functions.AddItem('black_money', price)
        
        -- Show item box animation for removing the item
        TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[item], 'remove')
        
        -- Refresh the player's available drugs
        TriggerClientEvent('qb-drugs:client:refreshAvailableDrugs', src, getAvailableDrugs(src))
    else
        -- Restart the corner selling process if the player doesn't have enough items
        TriggerClientEvent('qb-drugs:client:cornerselling', src)
    end
end)



RegisterNetEvent('qb-drugs:server:robCornerDrugs', function(drugType, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local availableDrugs = getAvailableDrugs(src)
    if not availableDrugs or not Player then return end
    local item = availableDrugs[drugType].item
    exports['qb-inventory']:RemoveItem(src, item, amount, false, 'qb-drugs:server:robCornerDrugs')
    table.insert(StolenDrugs, { item = item, amount = amount })
    TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[item], 'remove')
    TriggerClientEvent('qb-drugs:client:refreshAvailableDrugs', src, getAvailableDrugs(src))
end)
