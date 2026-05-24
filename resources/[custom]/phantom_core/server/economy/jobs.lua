-- Phantom Core - Job Payout System (Server)
-- Server-side job payout logic

-- Process job payout
lib.callback.register('phantom:server:jobPayout', function(source, jobName, minutes, amount)
    local citizenid = GetCitizenId(source)
    
    if not citizenid then return { success = false, message = 'Player data not found' } end
    
    local playerData = GetPlayerDataByCitizenId(citizenid)
    if not playerData then return { success = false, message = 'Player data not found' } end
    
    -- Add money to bank
    local bank = playerData.money.bank or 0
    local newBank = bank + amount
    
    MySQL.query([[
        UPDATE players 
        SET money = JSON_SET(money, '$.bank', ?)
        WHERE citizenid = ?
    ]], { newBank, citizenid })
    
    AddTransaction(citizenid, 'job_payout', amount, 'Job: ' .. jobName .. ' (' .. minutes .. ' min)', newBank)
    
    TriggerClientEvent('phantom:client:jobPayout', source, amount)
    
    return { success = true, bank = newBank }
end)

function AddTransaction(citizenid, type, amount, description, balanceAfter)
    MySQL.query([[
        INSERT INTO phantom_transactions (citizenid, type, amount, description, balance_after)
        VALUES (?, ?, ?, ?, ?)
    ]], { citizenid, type, amount, description, balanceAfter })
end

DebugPrint('Job payout server loaded')
