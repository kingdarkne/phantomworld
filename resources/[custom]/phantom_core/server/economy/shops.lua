-- Phantom Core - Shop System (Server)
-- Server-side shop logic

-- Process purchase
lib.callback.register('phantom:server:purchaseItems', function(source, cart, total, shopId)
    local citizenid = GetCitizenId(source)
    
    if not citizenid then return { success = false, message = 'Player data not found' } end
    
    local playerData = GetPlayerDataByCitizenId(citizenid)
    if not playerData then return { success = false, message = 'Player data not found' } end
    
    local cash = playerData.money.cash or 0
    
    if total > cash then
        return { success = false, message = 'Insufficient cash' }
    end
    
    -- Deduct money
    local newCash = cash - total
    
    MySQL.query([[
        UPDATE players 
        SET money = JSON_SET(money, '$.cash', ?)
        WHERE citizenid = ?
    ]], { newCash, citizenid })
    
    -- Add items to inventory (would integrate with ox_inventory)
    for _, item in ipairs(cart) do
        for i = 1, item.quantity do
            -- This would call ox_inventory to add item
            -- exports.ox_inventory:AddItem(source, item.name, 1)
        end
    end
    
    -- Record purchase
    MySQL.query([[
        INSERT INTO phantom_purchases (citizenid, shop_id, items, total)
        VALUES (?, ?, ?, ?)
    ]], { citizenid, shopId, json.encode(cart), total })
    
    TriggerClientEvent('phantom:client:purchaseComplete', source)
    
    return { success = true, cash = newCash }
end)

DebugPrint('Shop server loaded')
