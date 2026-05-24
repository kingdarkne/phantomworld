-- Ensure experience table exists so XP saves (run once on start)
CreateThread(function()
    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS experience (
            cid VARCHAR(50) NOT NULL,
            driving INT(11) DEFAULT 0,
            crafting INT(11) DEFAULT 0,
            UNIQUE KEY unique_cid (cid)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
end)

function tablePrintOut(table)
    if type(table) == 'table' then
       local s = '\n{ '
       for k,v in pairs(table) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. tablePrintOut(v) .. ',\n'
       end
       return s .. '}'
    else
       return tostring(table)
    end
 end

-- example how to trigger it

-- print(tablePrintOut(src))

local xplist = {}

-- xplist = {
--     ["crafting"] = 0,
--     ["driving"] = 0,
--     ["hacking"] = 0,
-- }

lib.callback.register("xnlrankbar:server:getxpcb", function(source)
    local player = GetResourceState('qbx_core') == 'started' and exports.qbx_core:GetPlayer(source) or nil
    local citizenid = player and player.PlayerData and player.PlayerData.citizenid or nil
    if not citizenid then
        return { driving = 0, crafting = 0 }
    end

    local result = exports.oxmysql:executeSync('SELECT * FROM experience WHERE cid = ?', { citizenid })
    if result and result[1] then
        return result[1]
    end

    exports.oxmysql:executeSync('INSERT INTO experience (cid, driving, crafting) VALUES (?, ?, ?)', { citizenid, 0, 0 })
    return { driving = 0, crafting = 0 }
end)
    

-- RegisterServerEvent('xnlrankbar:server:getxp')
-- AddEventHandler('xnlrankbar:server:getxp', function(player)
--     local result = exports.oxmysql:executeSync('SELECT cid FROM experience WHERE cid = ?', { player.citizenid })
--     if result[1] == nil then
--         print("new player setting everything to 0")
--         exports.oxmysql:insert('INSERT INTO experience (cid, driving, crafting )VALUES(?,?,?)', {player.citizenid,0,0})
--     end
-- end)

-- RegisterServerEvent('xnlrankbar:server:craftingxp')
-- AddEventHandler('xnlrankbar:server:craftingxp', function(XPAmount,player)
--     exports.oxmysql:update('UPDATE experience SET driving = ? WHERE cid = ?', {XPAmount,player})
-- end)

exports('GetXPReward', function(rewardName)
    local rewards = {
        ['AdminLogin'] = 0,
        ['Kill'] = 10,
        ['Death'] = 0,
    }
    return rewards[rewardName] or 0
end)

-- INT(11) max is 2147483647; clamp to avoid "Out of range value for column 'driving'"
local MAX_DRIVING_XP = 2147483647

-- Upsert: create row if missing so XP always saves (fixes XP not persisting when getxpcb hadn't run yet)
RegisterNetEvent('xnlrankbar:server:setxp', function(XPAmount, citizenid)
    if not citizenid or citizenid == '' then return end
    local xp = tonumber(XPAmount) or 0
    if xp < 0 then xp = 0 end
    if xp > MAX_DRIVING_XP then xp = MAX_DRIVING_XP end
    exports.oxmysql:executeSync(
        'INSERT INTO experience (cid, driving, crafting) VALUES (?, ?, 0) ON DUPLICATE KEY UPDATE driving = ?',
        { citizenid, xp, xp }
    )
end)