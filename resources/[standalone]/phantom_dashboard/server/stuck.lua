--- Server: stuck / possible bug reports → Discord error pipeline.
--- Auto detections stay quiet (staff log only, no player/owner spam).
--- Manual /reportstuck can notify staff + optional player invite DM.

local lastBySrc = {}
local COOLDOWN = tonumber(GetConvar('phantom_dashboard:stuckCooldownSeconds', '900')) or 900
local AUTO_COOLDOWN = tonumber(GetConvar('phantom_dashboard:stuckAutoCooldownSeconds', '1800')) or 1800

local function playerLabel(src)
    local name = GetPlayerName(src) or ('ID ' .. tostring(src))
    local discord = GetPlayerIdentifierByType(src, 'discord')
    if discord then
        return ('**%s** (<@%s>) `[id:%s]`'):format(name, discord:gsub('discord:', ''), src)
    end
    return ('**%s** `[id:%s]`'):format(name, src)
end

local function formatReport(src, kind, data)
    data = type(data) == 'table' and data or {}
    local c = data.coords or {}
    local lines = {
        ('Player: %s'):format(playerLabel(src)),
        ('Kind: `%s`'):format(kind or 'stuck'),
        ('Reason: `%s`'):format(tostring(data.reason or 'unknown')),
    }
    if data.extra and data.extra ~= '' then
        lines[#lines + 1] = ('Note: %s'):format(data.extra)
    end
    lines[#lines + 1] = ('Coords: `%.2f, %.2f, %.2f`'):format(c.x or 0, c.y or 0, c.z or 0)
    lines[#lines + 1] = ('Street: %s'):format(tostring(data.street or '—'))
    lines[#lines + 1] = ('Flags: vehicle=%s nui=%s pause=%s fade=%s frozen=%s speed=%.2f'):format(
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

local function discordIdOf(src)
    local id = GetPlayerIdentifierByType(src, 'discord')
    if not id then return nil end
    return id:gsub('discord:', '')
end

--- Quiet auto path: staff webhook/channel only — no player DM, no owner DM spam.
local function emitAutoStuck(src, data)
    if not PhantomDashboardEmitError then return end
    local title = ('Player Stuck (auto) — %s'):format(tostring(data and data.reason or 'stuck'))
    PhantomDashboardEmitError(title, formatReport(src, 'auto', data), 15105570, {
        discordId = discordIdOf(src),
        category = 'stuck',
        pingPlayer = false,
        invitePlayer = false,
        dmOwner = false,
    })
end

--- Manual report: notify staff; one help DM to the player.
local function emitPlayerReport(src, data)
    if not PhantomDashboardEmitError then return end
    local did = discordIdOf(src)
    local title = 'Player Stuck / Possible Bug — player_report'
    PhantomDashboardEmitError(title, formatReport(src, 'player_report', data), 15105570, {
        discordId = did,
        category = 'stuck',
        pingPlayer = false,
        invitePlayer = did ~= nil,
        dmOwner = true,
    })

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
        PhantomDashboardEmitError(
            'Admin force-unstuck',
            ('Admin `%s` unstuck player %s'):format(src == 0 and 'console' or playerLabel(src), playerLabel(target)),
            3447003,
            { category = 'stuck', dmOwner = false, invitePlayer = false, pingPlayer = false }
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
