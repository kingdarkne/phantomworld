-- Phantom Core - Housing System (Server)
-- Server-side housing management
local Properties = {
    apt_vinewood = { type = 'Apartment', price = 100000 },
    house_richman = { type = 'House', price = 500000 },
    mansion_vinewood = { type = 'Mansion', price = 2000000 },
}

local function purchaseProperty(source, propertyId)
    local citizenid = GetCitizenId(source)
    if not citizenid then return { success = false, message = 'Player data not found' } end

    local property = Properties[propertyId]
    if not property then
        return { success = false, message = 'Invalid property' }
    end

    local price = property.price

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
    
    MySQL.query([[
        INSERT INTO phantom_housing (citizenid, property_id, property_type, customization)
        VALUES (?, ?, ?, ?)
    ]], { citizenid, propertyId, property.type, json.encode({}) })
    
    AddTransaction(citizenid, 'property_purchase', price, 'Property: ' .. propertyId, newBank)
    
    TriggerClientEvent('phantom:client:propertyPurchased', source, propertyId)
    
    return { success = true, bank = newBank }
end

-- Get player properties
lib.callback.register('phantom:server:getPlayerProperties', function(source)
    local citizenid = GetCitizenId(source)
    if not citizenid then return {} end

    local properties = MySQL.query.await('SELECT * FROM phantom_housing WHERE citizenid = ?', { citizenid })
    return properties or {}
end)

-- Purchase property
RegisterNetEvent('phantom:server:purchaseProperty', function(propertyId)
    purchaseProperty(source, propertyId)
end)

lib.callback.register('phantom:server:purchaseProperty', function(source, propertyId)
    return purchaseProperty(source, propertyId)
end)

function AddTransaction(citizenid, type, amount, description, balanceAfter)
    MySQL.query([[
        INSERT INTO phantom_transactions (citizenid, type, amount, description, balance_after)
        VALUES (?, ?, ?, ?, ?)
    ]], { citizenid, type, amount, description, balanceAfter })
end

DebugPrint('Housing server loaded')
