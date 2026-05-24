-- Phantom Core - Banking System (Server)
-- Server-side banking logic

-- Deposit money
lib.callback.register('phantom:server:depositMoney', function(source, amount)
    local citizenid = GetCitizenId(source)
    
    if not citizenid then return false end
    
    -- Get player data
    local playerData = GetPlayerDataByCitizenId(citizenid)
    if not playerData then return false end
    
    local cash = playerData.money.cash or 0
    
    if amount > cash then
        return { success = false, message = 'Insufficient cash' }
    end
    
    if amount <= 0 then
        return { success = false, message = 'Invalid amount' }
    end
    
    -- Update money
    local newCash = cash - amount
    local newBank = (playerData.money.bank or 0) + amount
    
    -- Update in database
    MySQL.query([[
        UPDATE players 
        SET money = JSON_SET(money, '$.cash', ?),
            money = JSON_SET(money, '$.bank', ?)
        WHERE citizenid = ?
    ]], { newCash, newBank, citizenid })
    
    -- Add transaction record
    AddTransaction(citizenid, 'deposit', amount, 'ATM Deposit', newBank)
    
    -- Notify client
    TriggerClientEvent('phantom:client:bankingUpdate', source, newCash, newBank)
    
    return { success = true, cash = newCash, bank = newBank }
end)

-- Withdraw money
lib.callback.register('phantom:server:withdrawMoney', function(source, amount)
    local citizenid = GetCitizenId(source)
    
    if not citizenid then return false end
    
    local playerData = GetPlayerDataByCitizenId(citizenid)
    if not playerData then return false end
    
    local bank = playerData.money.bank or 0
    
    if amount > bank then
        return { success = false, message = 'Insufficient bank balance' }
    end
    
    if amount <= 0 then
        return { success = false, message = 'Invalid amount' }
    end
    
    local newBank = bank - amount
    local newCash = (playerData.money.cash or 0) + amount
    
    MySQL.query([[
        UPDATE players 
        SET money = JSON_SET(money, '$.cash', ?),
            money = JSON_SET(money, '$.bank', ?)
        WHERE citizenid = ?
    ]], { newCash, newBank, citizenid })
    
    AddTransaction(citizenid, 'withdraw', amount, 'ATM Withdrawal', newBank)
    
    TriggerClientEvent('phantom:client:bankingUpdate', source, newCash, newBank)
    
    return { success = true, cash = newCash, bank = newBank }
end)

-- Transfer money
lib.callback.register('phantom:server:transferMoney', function(source, targetPlayerId, amount)
    local citizenid = GetCitizenId(source)
    
    if not citizenid then return false end
    
    local playerData = GetPlayerDataByCitizenId(citizenid)
    if not playerData then return false end
    
    local bank = playerData.money.bank or 0
    
    if amount > bank then
        return { success = false, message = 'Insufficient bank balance' }
    end
    
    if amount <= 0 then
        return { success = false, message = 'Invalid amount' }
    end
    
    -- Get target player
    local targetPlayer = GetPlayerFromId(targetPlayerId)
    if not targetPlayer then
        return { success = false, message = 'Player not found' }
    end
    
    local targetCitizenId = GetCitizenId(targetPlayer)
    if not targetCitizenId then
        return { success = false, message = 'Target player data not found' }
    end
    
    local targetData = GetPlayerDataByCitizenId(targetCitizenId)
    if not targetData then
        return { success = false, message = 'Target player data not found' }
    end
    
    -- Process transfer
    local newBank = bank - amount
    local targetNewBank = (targetData.money.bank or 0) + amount
    
    MySQL.query([[
        UPDATE players 
        SET money = JSON_SET(money, '$.bank', ?)
        WHERE citizenid = ?
    ]], { newBank, citizenid })
    
    MySQL.query([[
        UPDATE players 
        SET money = JSON_SET(money, '$.bank', ?)
        WHERE citizenid = ?
    ]], { targetNewBank, targetCitizenId })
    
    AddTransaction(citizenid, 'transfer', amount, 'Transfer to ' .. targetPlayerId, newBank)
    AddTransaction(targetCitizenId, 'transfer', amount, 'Transfer from ' .. source, targetNewBank)
    
    TriggerClientEvent('phantom:client:bankingUpdate', source, playerData.money.cash, newBank)
    TriggerClientEvent('phantom:client:bankingUpdate', targetPlayer, targetData.money.cash, targetNewBank)
    
    return { success = true, bank = newBank }
end)

-- Get transaction history
lib.callback.register('phantom:server:getTransactionHistory', function(source)
    local citizenid = GetCitizenId(source)
    
    if not citizenid then return {} end
    
    local transactions = MySQL.query.await([[
        SELECT * FROM phantom_transactions
        WHERE citizenid = ?
        ORDER BY timestamp DESC
        LIMIT 20
    ]], { citizenid })
    
    return transactions or {}
end)

-- Add transaction record
function AddTransaction(citizenid, type, amount, description, balanceAfter)
    MySQL.query([[
        INSERT INTO phantom_transactions (citizenid, type, amount, description, balance_after)
        VALUES (?, ?, ?, ?, ?)
    ]], { citizenid, type, amount, description, balanceAfter })
end

-- Calculate and apply interest
CreateThread(function()
    while true do
        -- Wait for interest interval (30 days in seconds)
        Wait(Config.Economy.Banking.InterestInterval * 24 * 60 * 60)
        
        -- Apply interest to all accounts
        local players = MySQL.query.await('SELECT citizenid, money FROM players')
        
        for _, player in ipairs(players) do
            local money = json.decode(player.money)
            local bank = money.bank or 0
            
            if bank > 0 then
                local interest = bank * Config.Economy.Banking.InterestRate
                local newBank = bank + interest
                
                MySQL.query([[
                    UPDATE players 
                    SET money = JSON_SET(money, '$.bank', ?)
                    WHERE citizenid = ?
                ]], { newBank, player.citizenid })
                
                AddTransaction(player.citizenid, 'interest', interest, 'Monthly Interest', newBank)
            end
        end
        
        print('^2[Phantom Core]^7 Interest applied to all bank accounts')
    end
end)

DebugPrint('Banking server loaded')
