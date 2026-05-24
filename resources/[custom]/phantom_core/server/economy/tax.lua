-- Phantom Core - Tax System (Server)
-- Server-side tax collection and calculation

-- Calculate and collect taxes (runs daily)
CreateThread(function()
    while true do
        -- Wait 24 hours
        Wait(24 * 60 * 60 * 1000)
        
        -- Collect income tax
        CollectIncomeTax()
        
        -- Collect property tax
        CollectPropertyTax()
        
        print('^2[Phantom Core]^7 Taxes collected')
    end
end)

-- Collect income tax
function CollectIncomeTax()
    local players = MySQL.query.await('SELECT citizenid, money FROM players')
    
    for _, player in ipairs(players) do
        local money = json.decode(player.money)
        local bank = money.bank or 0
        
        if bank > 0 then
            local tax = bank * Config.Economy.Tax.IncomeTaxRate
            local newBank = bank - tax
            
            if newBank > 0 then
                MySQL.query([[
                    UPDATE players 
                    SET money = JSON_SET(money, '$.bank', ?)
                    WHERE citizenid = ?
                ]], { newBank, player.citizenid })
                
                AddTransaction(player.citizenid, 'income_tax', tax, 'Daily Income Tax', newBank)
            end
        end
    end
end

-- Collect property tax
function CollectPropertyTax()
    local properties = MySQL.query.await('SELECT * FROM phantom_housing')
    
    for _, property in ipairs(properties) do
        local propertyType = property.property_type
        local taxRate = Config.Economy.Tax.PropertyTaxRate
        
        -- Get property value from type
        local propertyValue = 0
        for _, propType in ipairs(Config.Mechanics.Housing.PropertyTypes) do
            if propType.name == propertyType then
                propertyValue = propType.price
                break
            end
        end
        
        local tax = propertyValue * taxRate
        local citizenid = property.citizenid
        
        -- Get player bank balance
        local playerData = GetPlayerDataByCitizenId(citizenid)
        if playerData then
            local bank = playerData.money.bank or 0
            
            if bank >= tax then
                local newBank = bank - tax
                MySQL.query([[
                    UPDATE players 
                    SET money = JSON_SET(money, '$.bank', ?)
                    WHERE citizenid = ?
                ]], { newBank, citizenid })
                
                AddTransaction(citizenid, 'property_tax', tax, 'Property Tax: ' .. property.property_id, newBank)
            end
        end
    end
end

-- Get tax history
lib.callback.register('phantom:server:getTaxHistory', function(source)
    local citizenid = GetCitizenId(source)
    
    if not citizenid then return {} end
    
    local transactions = MySQL.query.await([[
        SELECT * FROM phantom_transactions
        WHERE citizenid = ? AND (type = 'income_tax' OR type = 'property_tax' OR type = 'sales_tax')
        ORDER BY timestamp DESC
        LIMIT 20
    ]], { citizenid })
    
    return transactions or {}
end)

function AddTransaction(citizenid, type, amount, description, balanceAfter)
    MySQL.query([[
        INSERT INTO phantom_transactions (citizenid, type, amount, description, balance_after)
        VALUES (?, ?, ?, ?, ?)
    ]], { citizenid, type, amount, description, balanceAfter })
end

DebugPrint('Tax server loaded')
