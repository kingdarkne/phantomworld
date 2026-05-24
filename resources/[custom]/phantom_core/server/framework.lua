-- Phantom Core - QBX/QB server framework helpers

function GetCitizenId(source)
    if Config.Framework == 'qbx' then
        local player = exports.qbx_core:GetPlayer(source)
        return player and player.PlayerData and player.PlayerData.citizenid or nil
    elseif Config.Framework == 'qb' then
        local player = QBCore.Functions.GetPlayer(source)
        return player and player.PlayerData.citizenid or nil
    end
    return nil
end

function GetPlayerDataByCitizenId(citizenid)
    local result = MySQL.query.await('SELECT * FROM players WHERE citizenid = ?', { citizenid })
    if result and result[1] then
        local player = result[1]
        player.money = json.decode(player.money)
        return player
    end
    return nil
end
