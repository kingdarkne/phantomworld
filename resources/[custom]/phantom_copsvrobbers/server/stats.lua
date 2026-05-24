-- Stats tracking
local playerStats = {}

-- Load stats
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS phantom_cvr_stats (
                id INT AUTO_INCREMENT PRIMARY KEY,
                citizenid VARCHAR(50) NOT NULL UNIQUE,
                matches_played INT DEFAULT 0,
                matches_won INT DEFAULT 0,
                kills INT DEFAULT 0,
                deaths INT DEFAULT 0,
                score INT DEFAULT 0,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            )
        ]])
    end
end)

-- Update stats after match
function UpdatePlayerStats(citizenid, won, kills, deaths)
    MySQL.update([[
        INSERT INTO phantom_cvr_stats (citizenid, matches_played, matches_won, kills, deaths)
        VALUES (?, 1, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
        matches_played = matches_played + 1,
        matches_won = matches_won + ?,
        kills = kills + ?,
        deaths = deaths + ?
    ]], { citizenid, won and 1 or 0, kills or 0, deaths or 0, won and 1 or 0, kills or 0, deaths or 0 })
end
