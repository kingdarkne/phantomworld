local function getPlayer(src)
    return exports.qbx_core:GetPlayer(src)
end

-- Simple in-memory wanted storage: [citizenid] = { level = n, points = p }
local Wanted = {}

local function RecalcLevel(points)
    if points >= 100 then return 5
    elseif points >= 75 then return 4
    elseif points >= 50 then return 3
    elseif points >= 25 then return 2
    elseif points >= 10 then return 1
    else return 0 end
end

local function GetCitizenIdFromSource(src)
    local Player = getPlayer(src)
    if not Player then return nil end
    return Player.PlayerData.citizenid
end

local function IsProtectedPolice(src)
    local Player = getPlayer(src)
    if not Player then return false end

    local job = Player.PlayerData.job
    if not job then return false end

    return (job.type == 'leo' or job.name == 'police' or job.name == 'lspd' or job.name == 'bcso' or job.name == 'sahp') and job.onduty
end

local function SyncToClient(src)
    local cid = GetCitizenIdFromSource(src)
    if not cid then return end
    local data = Wanted[cid] or { level = 0, points = 0 }
    TriggerClientEvent('dr-wanted:client:update', src, data.level or 0, data.points or 0)
end

-- Public helpers

local function AddWantedPoints(targetSrc, points, reason)
    local cid = GetCitizenIdFromSource(targetSrc)
    if not cid then return end

    local data = Wanted[cid] or { level = 0, points = 0 }
    data.points = math.max(0, (data.points or 0) + points)
    data.level  = RecalcLevel(data.points)
    Wanted[cid] = data

    SyncToClient(targetSrc)

    local msg = ('You gained %d wanted points'):format(points)
    if reason and reason ~= '' then
        msg = msg .. (' (%s)'):format(reason)
    end
    TriggerClientEvent('ox_lib:notify', targetSrc, { title = 'Wanted', description = msg, type = 'error' })
end

local function AddCrimePoints(targetSrc, points, reason)
    targetSrc = tonumber(targetSrc)
    points = tonumber(points) or 0
    if not targetSrc or points <= 0 or not GetPlayerName(targetSrc) or IsProtectedPolice(targetSrc) then return end

    AddWantedPoints(targetSrc, points, reason)
end

local function ClearWanted(targetSrc)
    local cid = GetCitizenIdFromSource(targetSrc)
    if not cid then return end
    Wanted[cid] = { level = 0, points = 0 }
    SyncToClient(targetSrc)
    TriggerClientEvent('ox_lib:notify', targetSrc, { title = 'Wanted', description = 'Your wanted level has been cleared', type = 'success' })
end

-- Expose wanted data to other scripts (MDT, scoreboard, etc.)
exports('GetWantedData', function(src)
    local cid = GetCitizenIdFromSource(src)
    if not cid then
        return { level = 0, points = 0 }
    end
    local data = Wanted[cid] or { level = 0, points = 0 }
    return {
        level = data.level or 0,
        points = data.points or 0
    }
end)

exports('AddWantedPoints', AddWantedPoints)
exports('AddCrimePoints', AddCrimePoints)

lib.callback.register('dr-wanted:getSelf', function(source)
    return exports['dr-wanted']:GetWantedData(source)
end)

-- Also provide an event-based API if someone prefers events over exports
RegisterNetEvent('dr-wanted:server:requestData', function(targetId)
    local src = source
    local t = tonumber(targetId) or src
    if not GetPlayerName(t) then return end
    local data = exports['dr-wanted']:GetWantedData(t)
    TriggerClientEvent('dr-wanted:client:returnData', src, t, data.level, data.points)
end)

-- QBCore player load/unload hooks (payload can be Player object, source number, or nil)

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function(player)
    local src
    if type(player) == 'number' then
        src = player
    elseif type(player) == 'table' and player then
        src = player.source or player.Source or (player.PlayerData and player.PlayerData.source)
    end
    if src and GetPlayerName(src) then
        SyncToClient(src)
    end
end)

AddEventHandler('playerDropped', function()
    -- We deliberately DO NOT clear Wanted here so points persist across reconnects
    -- If you prefer clearing on leave, uncomment the next lines:
    -- local src = source
    -- local cid = GetCitizenIdFromSource(src)
    -- if cid then Wanted[cid] = nil end
end)

-- Commands for police

RegisterCommand('addwanted', function(source, args)
    if source == 0 then return end
    local Player = getPlayer(source)
    if not Player or not Player.PlayerData.job or Player.PlayerData.job.name ~= 'police' then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Wanted', description = 'Police only.', type = 'error' })
        return
    end
    local targetId = tonumber(args[1])
    local points   = tonumber(args[2]) or 0
    if not targetId or points == 0 then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Wanted', description = 'Usage: /addwanted [id] [points] [reason]', type = 'error' })
        return
    end
    if not GetPlayerName(targetId) then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Wanted', description = 'Player not found', type = 'error' })
        return
    end

    local reason = table.concat(args, ' ', 3)
    AddWantedPoints(targetId, points, reason)
end, false)

RegisterCommand('clearwanted', function(source, args)
    if source == 0 then return end
    local Player = getPlayer(source)
    if not Player or not Player.PlayerData.job or Player.PlayerData.job.name ~= 'police' then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Wanted', description = 'Police only.', type = 'error' })
        return
    end
    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Wanted', description = 'Usage: /clearwanted [id]', type = 'error' })
        return
    end
    if not GetPlayerName(targetId) then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Wanted', description = 'Player not found', type = 'error' })
        return
    end

    ClearWanted(targetId)
end, false)

RegisterCommand('wanted', function(source, args)
    if source == 0 then return end
    local Player = getPlayer(source)
    if not Player or not Player.PlayerData.job or Player.PlayerData.job.name ~= 'police' then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Wanted', description = 'Police only.', type = 'error' })
        return
    end
    local targetId = tonumber(args[1]) or source
    if not GetPlayerName(targetId) then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Wanted', description = 'Player not found', type = 'error' })
        return
    end

    local data = exports['dr-wanted']:GetWantedData(targetId)
    local msg = ('Wanted level for %s (ID %d): Level %d, %d points'):format(
        GetPlayerName(targetId),
        targetId,
        data.level or 0,
        data.points or 0
    )
    TriggerClientEvent('chat:addMessage', source, {
        color = { 255, 60, 60 },
        multiline = true,
        args = { 'Wanted', msg }
    })
end, false)

-- Automatic wanted: client tells us about certain actions

RegisterNetEvent('dr-wanted:server:shotsFired', function()
    local src = source
    local Player = getPlayer(src)
    if not Player then return end

    AddCrimePoints(src, 10, 'Discharging a firearm')
end)

RegisterNetEvent('dr-wanted:server:playerHit', function(victimId, isFatal)
    local src = source
    if not GetPlayerName(src) or not GetPlayerName(victimId) then return end

    local Player = getPlayer(src)
    if not Player then return end

    if isFatal then
        AddCrimePoints(src, 25, 'Homicide')
    else
        AddCrimePoints(src, 10, 'Assault with a deadly weapon')
    end
end)

RegisterNetEvent('dr-wanted:server:npcAttack', function(isFatal)
    local src = source
    if isFatal then
        AddCrimePoints(src, 20, 'Assault on a civilian')
    else
        AddCrimePoints(src, 10, 'Assault on a civilian')
    end
end)

