-- Phantom Core - Server Core
-- Main initialization and core server functions

local isInitialized = false

-- Initialize resource
CreateThread(function()
    Wait(1000)
    
    -- Initialize database tables
    InitializeDatabase()
    
    isInitialized = true
    print('^2[Phantom Core]^7 Server initialized')
end)

-- Initialize database tables
function InitializeDatabase()
    -- Skills table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `phantom_skills` (
            `citizenid` VARCHAR(50) NOT NULL,
            `skill_id` VARCHAR(50) NOT NULL,
            `level` INT DEFAULT 0,
            `xp` INT DEFAULT 0,
            `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`citizenid`, `skill_id`)
        )
    ]])
    
    -- Housing table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `phantom_housing` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `citizenid` VARCHAR(50) NOT NULL,
            `property_id` VARCHAR(50) NOT NULL,
            `property_type` VARCHAR(50) NOT NULL,
            `purchase_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `customization` JSON,
            INDEX `idx_citizenid` (`citizenid`)
        )
    ]])
    
    -- Banking transactions table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `phantom_transactions` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `citizenid` VARCHAR(50) NOT NULL,
            `type` VARCHAR(50) NOT NULL,
            `amount` DECIMAL(15,2) NOT NULL,
            `description` VARCHAR(255),
            `balance_after` DECIMAL(15,2) NOT NULL,
            `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_citizenid` (`citizenid`)
        )
    ]])
    
    -- Shop purchases table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `phantom_purchases` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `citizenid` VARCHAR(50) NOT NULL,
            `shop_id` VARCHAR(50) NOT NULL,
            `items` JSON NOT NULL,
            `total` DECIMAL(15,2) NOT NULL,
            `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_citizenid` (`citizenid`)
        )
    ]])
    
    DebugPrint('Database tables initialized')
end

-- Export functions for other resources
exports('GetPlayerSkills', function(citizenid)
    return GetPlayerSkills(citizenid)
end)

exports('UpdatePlayerSkill', function(citizenid, skillId, xp)
    return UpdatePlayerSkill(citizenid, skillId, xp)
end)

exports('GetPlayerProperties', function(citizenid)
    return GetPlayerProperties(citizenid)
end)

exports('AddTransaction', function(citizenid, type, amount, description, balanceAfter)
    return AddTransaction(citizenid, type, amount, description, balanceAfter)
end)

DebugPrint('Phantom Core server loaded')
