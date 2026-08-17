--- Server: stuck / possible bug reports → Discord error pipeline.
--- Auto detections stay quiet (staff log only, no player/owner spam).
--- Manual /reportstuck can notify staff + optional player invite DM.

local lastBySrc = {}
local COOLDOWN = tonumber(GetConvar('phantom_dashboard:stuckCooldownSeconds', '900')) or 900
local AUTO_COOLDOWN = tonumber(GetConvar('phantom_dashboard:stuckAutoCooldownSeconds', '1800')) or 1800

local function idType(src, kind)
    local id = GetPlayerIdentifierByType(src, kind)
    if not id or id == '' then return nil end
    return id
end

local function discordIdOf(src)
    local id = idType(src, 'discord')
    if not id then return nil end
    return id:gsub('discord:', '')
end

local function citizenIdOf(src)
    -- Qbox / QBCore character id when available
    local ok, player = pcall(function()
        if GetResourceState('qbx_core') == 'started' then
            return exports.qbx_core:GetPlayer(src)
        end
        if GetResourceState('qb-core') == 'started' then
            return exports['qb-core']:GetCoreObject().Functions.GetPlayer(src)
        end
        return nil
    end)
    if not ok or not player then return nil end
    local cid = player.PlayerData and player.PlayerData.citizenid
    return cid and tostring(cid) or nil
end

local function collectIdentifiers(src)
    local out = {
        license = idType(src, 'license'),
        license2 = idType(src, 'license2'),
        fivem = idType(src, 'fivem'),
        steam = idType(src, 'steam'),
        xbl = idType(src, 'xbl'),
        live = idType(src, 'live'),
        discord = idType(src, 'discord'),
    }
    return out
end

local function playerLabel(src)
    local name = GetPlayerName(src) or ('ID ' .. tostring(src))
    local discord = discordIdOf(src)
    if discord then
        return ('**%s** (<@%s>) `[serverId:%s]`'):format(name, discord, src)
    end
    return ('**%s** `[serverId:%s]` _(Discord not linked)_'):format(name, src)
end

local function formatIdentity(src)
    local name = GetPlayerName(src) or ('ID ' .. tostring(src))
    local did = discordIdOf(src)
    local ids = collectIdentifiers(src)
    local cid = citizenIdOf(src)
    local lines = {
        '**Identity**',
        ('• CFX / FiveM name: **%s**'):format(name),
        ('• Server ID: `%s`'):format(src),
    }
    if cid then
        lines[#lines + 1] = ('• Citizen ID: `%s`'):format(cid)
    end
    if did then
        lines[#lines + 1] = ('• Discord: linked — <@%s> (`%s`)'):format(did, did)
        lines[#lines + 1] = '• Discord guild: _Rex will check membership when posting_'
    else
        lines[#lines + 1] = '• Discord: **NOT LINKED** in FiveM (cannot ping / DM)'
    end
    if ids.license then lines[#lines + 1] = ('• License: `%s`'):format(ids.license) end
    if ids.license2 then lines[#lines + 1] = ('• License2: `%s`'):format(ids.license2) end
    if ids.fivem then lines[#lines + 1] = ('• CFX ID: `%s`'):format(ids.fivem) end
    if ids.steam then lines[#lines + 1] = ('• Steam: `%s`'):format(ids.steam) end
    return table.concat(lines, '\n'), {
        playerName = name,
        serverId = tonumber(src),
        citizenId = cid,
        discordId = did,
        identifiers = ids,
    }
end

local function formatReport(src, kind, data)
    data = type(data) == 'table' and data or {}
    local c = data.coords or {}
    local identityBlock = formatIdentity(src)
    local lines = {
        identityBlock,
        '',
        ('**Report**'),
        ('• Kind: `%s`'):format(kind or 'stuck'),
        ('• Reason: `%s`'):format(tostring(data.reason or 'unknown')),
    }
    if data.extra and data.extra ~= '' then
        lines[#lines + 1] = ('• Note: %s'):format(data.extra)
    end
    lines[#lines + 1] = ('• Coords: `%.2f, %.2f, %.2f`'):format(c.x or 0, c.y or 0, c.z or 0)
    lines[#lines + 1] = ('• Street: %s'):format(tostring(data.street or '—'))
    lines[#lines + 1] = ('• Flags: vehicle=%s nui=%s pause=%s fade=%s frozen=%s speed=%.2f'):format(
        tostring(data.inVehicle == true),
        tostring(data.nuiFocused == true),
        tostring(data.pause == true),
        tostring(data.faded == true),
        tostring(data.frozen == true),
        tonumber(data.speed) or 0.0
    )
    lines[#lines + 1] = '_Players can run `/unstuck` — investigate if reports repeat._'
    return table.concat(lines, '\n')
end

local function stuckOpts(src, extra)
    local _, meta = formatIdentity(src)
    local opts = {
        discordId = meta.discordId,
        category = 'stuck',
        playerName = meta.playerName,
        serverId = meta.serverId,
        citizenId = meta.citizenId,
        identifiers = meta.identifiers,
    }
    for k, v in pairs(extra or {}) do
        opts[k] = v
    end
    return opts
end

local function allowed(src, seconds)
    local now = os.time()
    local prev = lastBySrc[src]
    local need = seconds or COOLDOWN
    if prev and (now - prev) < need then
        return false
    end
    lastBySrc[src] = now
    return true
end

--- Quiet auto path: staff webhook/channel only — no player DM, no owner DM spam.
local function emitAutoStuck(src, data)
    if not PhantomDashboardEmitError then
        print('[phantom_dashboard] stuck auto skipped — PhantomDashboardEmitError missing (alerts.lua outdated)')
        return
    end
    local reason = tostring(data and data.reason or 'stuck')
    local name = GetPlayerName(src) or ('ID ' .. tostring(src))
    local title = ('Player Stuck (auto) — %s [%s]'):format(name, reason)
    PhantomDashboardEmitError(title, formatReport(src, 'auto', data), 15105570, stuckOpts(src, {
        pingPlayer = true,
        invitePlayer = false,
        dmOwner = false,
    }))
end

--- Manual report: notify staff; one help DM to the player.
local function emitPlayerReport(src, data)
    if not PhantomDashboardEmitError then
        print('[phantom_dashboard] stuck report skipped — PhantomDashboardEmitError missing (alerts.lua outdated)')
        return
    end
    local did = discordIdOf(src)
    local name = GetPlayerName(src) or ('ID ' .. tostring(src))
    local title = ('Player Stuck / Bug — %s [serverId %s]'):format(name, src)
    PhantomDashboardEmitError(title, formatReport(src, 'player_report', data), 15105570, stuckOpts(src, {
        pingPlayer = true,
        invitePlayer = did ~= nil,
        dmOwner = true,
    }))

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Phantom Assist',
        description = did
            and 'Staff were notified. Check Discord if we send a help invite.'
            or 'Staff were notified. Link Discord in FiveM settings for faster help.',
        type = 'inform',
    })
end

RegisterNetEvent('phantom_dashboard:stuck:auto', function(data)
    local src = source
    if not allowed(('auto:%s'):format(src), AUTO_COOLDOWN) then return end
    emitAutoStuck(src, data)
end)

RegisterNetEvent('phantom_dashboard:stuck:report', function(data)
    local src = source
    if not allowed(('report:%s'):format(src), COOLDOWN) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Phantom Assist',
            description = 'Report cooldown — try again shortly.',
            type = 'error',
        })
        return
    end
    emitPlayerReport(src, data)
end)

--- Kept for backwards compatibility; client no longer fires this on every /unstuck.
RegisterNetEvent('phantom_dashboard:stuck:unstuckUsed', function(data)
    -- Intentionally no Discord emit — /unstuck is a local self-help tool.
end)

RegisterCommand('forceunstuck', function(src, args)
    if src ~= 0 then
        if not IsPlayerAceAllowed(src, 'command.forceunstuck') and not IsPlayerAceAllowed(src, 'admin') then
            return
        end
    end
    local target = tonumber(args[1] or '')
    if not target then
        if src == 0 then print('usage: forceunstuck <serverId>') end
        return
    end
    TriggerClientEvent('phantom_dashboard:stuck:forceUnstuck', target)
    if PhantomDashboardEmitError then
        local name = GetPlayerName(target) or ('ID ' .. tostring(target))
        PhantomDashboardEmitError(
            ('Admin force-unstuck — %s'):format(name),
            ('Admin `%s` unstuck player %s\n\n%s'):format(
                src == 0 and 'console' or playerLabel(src),
                playerLabel(target),
                select(1, formatIdentity(target))
            ),
            3447003,
            stuckOpts(target, { dmOwner = false, invitePlayer = false, pingPlayer = false })
        )
    end
end, true)

AddEventHandler('playerDropped', function()
    local src = source
    lastBySrc[src] = nil
    lastBySrc[('auto:%s'):format(src)] = nil
    lastBySrc[('report:%s'):format(src)] = nil
    lastBySrc[('u:%s'):format(src)] = nil
end)
