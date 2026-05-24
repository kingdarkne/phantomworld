-- Phantom World Fines System - Server Side

local QBCore = exports['qbx_core']:GetCoreObject()

-- Database initialization using oxmysql export
exports['oxmysql']:executeSync([[CREATE TABLE IF NOT EXISTS `player_fines` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) NOT NULL,
    `fine_type` varchar(50) NOT NULL,
    `fine_amount` int(11) NOT NULL,
    `fine_label` varchar(255) NOT NULL,
    `issued_by` varchar(50) DEFAULT NULL,
    `issued_date` timestamp DEFAULT CURRENT_TIMESTAMP,
    `paid` tinyint(1) DEFAULT 0,
    `paid_date` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])

-- Get all fines for a player
QBCore.Commands.Add('getfines', 'Get all fines for a player', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    exports['oxmysql']:fetch('SELECT * FROM player_fines WHERE citizenid = ? AND paid = 0', { citizenid }, function(result)
        if result and #result > 0 then
            local totalFines = 0
            for _, fine in ipairs(result) do
                totalFines = totalFines + fine.fine_amount
            end
            TriggerClientEvent('QBCore:Notify', src, 'You have ' .. #result .. ' unpaid fines totaling $' .. totalFines, 'info')
        else
            TriggerClientEvent('QBCore:Notify', src, 'You have no unpaid fines', 'success')
        end
    end)
end)

-- Pay a fine
QBCore.Commands.Add('payfine', 'Pay a fine by ID', {{name = 'fineid', help = 'Fine ID'}}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    if not args[1] then
        TriggerClientEvent('QBCore:Notify', src, 'Usage: /payfine [fineid]', 'error')
        return
    end
    
    local fineId = tonumber(args[1])
    local citizenid = Player.PlayerData.citizenid
    
    exports['oxmysql']:fetch('SELECT * FROM player_fines WHERE id = ? AND citizenid = ? AND paid = 0', { fineId, citizenid }, function(result)
        if result and #result > 0 then
            local fine = result[1]
            local PlayerMoney = Player.PlayerData.money
            
            -- Check if player can pay
            if PlayerMoney.bank >= fine.fine_amount or PlayerMoney.cash >= fine.fine_amount then
                -- Deduct money (prefer bank)
                if Config.EnableBankPayment and PlayerMoney.bank >= fine.fine_amount then
                    Player.Functions.RemoveMoney('bank', fine.fine_amount, 'fine-payment')
                elseif Config.EnableCashPayment and PlayerMoney.cash >= fine.fine_amount then
                    Player.Functions.RemoveMoney('cash', fine.fine_amount, 'fine-payment')
                else
                    TriggerClientEvent('QBCore:Notify', src, 'You don\'t have enough money to pay this fine', 'error')
                    return
                end
                
                -- Mark as paid
                exports['oxmysql']:execute('UPDATE player_fines SET paid = 1, paid_date = NOW() WHERE id = ?', { fineId })
                TriggerClientEvent('QBCore:Notify', src, 'You paid fine #' .. fineId .. ' for $' .. fine.fine_amount, 'success')
            else
                TriggerClientEvent('QBCore:Notify', src, 'You don\'t have enough money to pay this fine', 'error')
            end
        else
            TriggerClientEvent('QBCore:Notify', src, 'Fine not found or already paid', 'error')
        end
    end)
end)

-- Pay all fines
QBCore.Commands.Add('payallfines', 'Pay all your fines', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    exports['oxmysql']:fetch('SELECT * FROM player_fines WHERE citizenid = ? AND paid = 0', { citizenid }, function(result)
        if result and #result > 0 then
            local totalFines = 0
            for _, fine in ipairs(result) do
                totalFines = totalFines + fine.fine_amount
            end
            
            local PlayerMoney = Player.PlayerData.money
            
            -- Check if player can pay
            if PlayerMoney.bank >= totalFines or PlayerMoney.cash >= totalFines then
                -- Deduct money
                if Config.EnableBankPayment and PlayerMoney.bank >= totalFines then
                    Player.Functions.RemoveMoney('bank', totalFines, 'fines-payment')
                elseif Config.EnableCashPayment and PlayerMoney.cash >= totalFines then
                    Player.Functions.RemoveMoney('cash', totalFines, 'fines-payment')
                else
                    TriggerClientEvent('QBCore:Notify', src, 'You don\'t have enough money to pay all fines', 'error')
                    return
                end
                
                -- Mark all as paid
                exports['oxmysql']:execute('UPDATE player_fines SET paid = 1, paid_date = NOW() WHERE citizenid = ? AND paid = 0', { citizenid })
                TriggerClientEvent('QBCore:Notify', src, 'You paid all fines totaling $' .. totalFines, 'success')
            else
                TriggerClientEvent('QBCore:Notify', src, 'You don\'t have enough money to pay all fines', 'error')
            end
        else
            TriggerClientEvent('QBCore:Notify', src, 'You have no unpaid fines', 'success')
        end
    end)
end, 'admin')

-- Police command to issue fine
QBCore.Commands.Add('issuefine', 'Issue a fine to a player', {{name = 'id', help = 'Player ID'}, {name = 'fine', help = 'Fine type'}}, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local targetId = tonumber(args[1])
    local fineType = args[2]
    
    if not targetId or not fineType then
        TriggerClientEvent('QBCore:Notify', src, 'Usage: /issuefine [playerid] [finetype]', 'error')
        return
    end
    
    local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not TargetPlayer then
        TriggerClientEvent('QBCore:Notify', src, 'Player not found', 'error')
        return
    end
    
    local fineConfig = Config.Fines[fineType]
    if not fineConfig then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid fine type', 'error')
        return
    end
    
    local fineAmount
    local fineLabel
    
    if fineConfig.fines then
        -- Speeding fine with tiers
        fineAmount = fineConfig.fines[#fineConfig.fines].fine -- Default to highest
        fineLabel = fineConfig.label
    else
        fineAmount = fineConfig.fine
        fineLabel = fineConfig.label
    end
    
    -- Ensure fine is within limits
    fineAmount = math.max(Config.MinFineAmount, math.min(fineAmount, Config.MaxFineAmount))
    
    local citizenid = TargetPlayer.PlayerData.citizenid
    local issuedBy = Player.PlayerData.citizenid
    
    -- Insert fine into database
    exports['oxmysql']:execute('INSERT INTO player_fines (citizenid, fine_type, fine_amount, fine_label, issued_by) VALUES (?, ?, ?, ?, ?)', 
        { citizenid, fineType, fineAmount, fineLabel, issuedBy })
    
    TriggerClientEvent('QBCore:Notify', src, 'Issued fine to player ' .. targetId .. ' for $' .. fineAmount, 'success')
    TriggerClientEvent('QBCore:Notify', targetId, 'You have been issued a fine: ' .. fineLabel .. ' - $' .. fineAmount, 'error')
end, 'admin')

-- List available fine types
QBCore.Commands.Add('finetypes', 'List all available fine types', {}, true, function(source, args)
    local src = source
    local fineTypes = "Available Fine Types:\n"
    
    for fineType, config in pairs(Config.Fines) do
        fineTypes = fineTypes .. "- " .. fineType .. " (" .. config.label .. ")\n"
    end
    
    TriggerClientEvent('QBCore:Notify', src, fineTypes, 'info')
end, 'admin')

-- Export function to get player fines
exports('GetPlayerFines', function(citizenid)
    local fines = {}
    exports['oxmysql']:fetch('SELECT * FROM player_fines WHERE citizenid = ? AND paid = 0', { citizenid }, function(result)
        if result then
            fines = result
        end
    end)
    return fines
end)

-- Export function to issue fine
exports('IssueFine', function(citizenid, fineType, issuedBy)
    local fineConfig = Config.Fines[fineType]
    if not fineConfig then return false end
    
    local fineAmount = fineConfig.fines and fineConfig.fines[#fineConfig.fines].fine or fineConfig.fine
    local fineLabel = fineConfig.label
    
    fineAmount = math.max(Config.MinFineAmount, math.min(fineAmount, Config.MaxFineAmount))
    
    exports['oxmysql']:execute('INSERT INTO player_fines (citizenid, fine_type, fine_amount, fine_label, issued_by) VALUES (?, ?, ?, ?, ?)', 
        { citizenid, fineType, fineAmount, fineLabel, issuedBy })
    
    return true
end)
