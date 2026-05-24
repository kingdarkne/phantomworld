-- Phantom Core - Housing System (Server)
-- Server-side housing management

-- Get player properties
lib.callback.register('phantom:server:getPlayerProperties', function(source)
    local citizenid = GetCitizenId(source)
    if not citizenid then return {} end
    
    local properties = MySQL.query.await('SELECT * FROM phantom_housing WHERE citizenid = ?', { citizenid })
    return properties or {}
end)

-- Purchase property
lib.callback.register('phantom:server:purchaseProperty', function(source, propertyId, price)
    local citizenid = GetCitizenId(source)
    if not citizenid then return { success = false, message = 'Player data not found' } end
    
    local playerData = GetPlayerDataByCitizenId(citizenid)
    if not playerData then return { success = false, message = 'Player data not found' } end
    
    -- Check if already owns property
    local existing = MySQL.query.await('SELECT * FROM phantom_housing WHERE citizenid = ? AND property_id = ?', { citizenid, propertyId })
    if existing and #existing > 0 then
        return { success = false, message = 'You already own this property' }
    end
    
    -- Check max properties
    local currentProps = MySQL.query.await('SELECT COUNT(*) as count FROM phantom_housing WHERE citizenid = ?', { citizenid })
    if currentProps[1].count >= Config.Mechanics.Housing.MaxProperties then
        return { success = false, message = 'Max properties reached' }
    end
    
    local bank = playerData.money.bank or 0
    
    if bank < price then
        return { success = false, message = 'Insufficient funds' }
    end
    
    -- Deduct money
    local newBank = bank - price
    MySQL.query([[
        UPDATE players 
        SET money = JSON_SET(money, '$.bank', ?)
        WHERE citizenid = ?
    ]], { newBank, citizenid })
    
    -- Add property
    local propertyType = nil
    for _, propType in ipairs(Config.Mechanics.Housing.PropertyTypes) do
        if string.find(propertyId, string.lower(propType.name)) then
            propertyType = propType.name
            break
        end
    end
    
    if not propertyType then propertyType = 'Apartment' end
    
    MySQL.query([[
        INSERT INTO phantom_housing (citizenid, property_id, property_type, customization)
        VALUES (?, ?, ?, ?)
    ]], { citizenid, propertyId, propertyType, json.encode({}) })
    
    AddTransaction(citizenid, 'property_purchase', price, 'Property: ' .. propertyId, newBank)
    
    TriggerClientEvent('phantom:client:propertyPurchased', source, propertyId)
    
    return { success = true, bank = newBank }
end)

function AddTransaction(citizenid, type, amount, description, balanceAfter)
    MySQL.query([[
        INSERT INTO phantom_transactions (citizenid, type, amount, description, balance_after)
        VALUES (?, ?, ?, ?, ?)
    ]], { citizenid, type, amount, description, balanceAfter })
end

DebugPrint('Housing server loaded')
