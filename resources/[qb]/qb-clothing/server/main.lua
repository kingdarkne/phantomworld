-- QBCore from server/qbx_compat.lua — qb-core export or qbx_core shim

local function normalizeOutfitsForClient(rows)
    if not rows or not rows[1] then return rows end
    for k, v in pairs(rows) do
        local blob = v.skin or v.components
        if type(blob) == 'string' and blob ~= '' then
            local ok, decoded = pcall(json.decode, blob)
            if ok and decoded then
                rows[k].skin = decoded
            end
        end
        rows[k].outfitId = v.outfitId or v.id
    end
    return rows
end

RegisterServerEvent("qb-clothing:saveSkin", function(model, skin)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if model ~= nil and skin ~= nil then
        -- TODO: Update primary key to be citizenid so this can be an insert on duplicate update query
        MySQL.query('DELETE FROM playerskins WHERE citizenid = ?', { Player.PlayerData.citizenid }, function()
            MySQL.insert('INSERT INTO playerskins (citizenid, model, skin, active) VALUES (?, ?, ?, ?)', {
                Player.PlayerData.citizenid,
                model,
                skin,
                1
            })
        end)
    end
end)

RegisterServerEvent("qb-clothes:loadPlayerSkin", function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local result = MySQL.query.await('SELECT * FROM playerskins WHERE citizenid = ? AND active = ?', { Player.PlayerData.citizenid, 1 })
    if result[1] ~= nil then
        TriggerClientEvent("qb-clothes:loadSkin", src, false, result[1].model, result[1].skin)
    else
        TriggerClientEvent("qb-clothes:loadSkin", src, true)
    end
end)

RegisterServerEvent("qb-clothes:saveOutfit", function(outfitName, model, skinData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if model ~= nil and skinData ~= nil then
        -- illenium / Qbox SQL uses components + props; legacy qb-clothing used skin + outfitId
        MySQL.insert('INSERT INTO player_outfits (citizenid, outfitname, model, components, props) VALUES (?, ?, ?, ?, ?)', {
            Player.PlayerData.citizenid,
            outfitName,
            model,
            json.encode(skinData),
            '[]',
        }, function()
            local result = MySQL.query.await('SELECT * FROM player_outfits WHERE citizenid = ?', { Player.PlayerData.citizenid })
            if result[1] ~= nil then
                TriggerClientEvent('qb-clothing:client:reloadOutfits', src, normalizeOutfitsForClient(result))
            else
                TriggerClientEvent('qb-clothing:client:reloadOutfits', src, nil)
            end
        end)
    end
end)

RegisterServerEvent("qb-clothing:server:removeOutfit", function(outfitName, outfitId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local rowId = tonumber(outfitId)
    if not rowId then return end
    MySQL.query('DELETE FROM player_outfits WHERE citizenid = ? AND id = ?', {
        Player.PlayerData.citizenid,
        rowId,
    }, function()
        local result = MySQL.query.await('SELECT * FROM player_outfits WHERE citizenid = ?', { Player.PlayerData.citizenid })
        if result[1] ~= nil then
            TriggerClientEvent('qb-clothing:client:reloadOutfits', src, normalizeOutfitsForClient(result))
        else
            TriggerClientEvent('qb-clothing:client:reloadOutfits', src, nil)
        end
    end)
end)

QBCore.Functions.CreateCallback('qb-clothing:server:getOutfits', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local outfits = {}

    local result = MySQL.query.await('SELECT * FROM player_outfits WHERE citizenid = ?', { Player.PlayerData.citizenid })
    if result and result[1] ~= nil then
        outfits = normalizeOutfitsForClient(result)
    end
    cb(outfits)
end)
