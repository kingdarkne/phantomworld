--- Server: stuck / possible bug reports → Discord error pipeline.

local lastBySrc = {}
local COOLDOWN = tonumber(GetConvar('phantom_dashboard:stuckCooldownSeconds', '180')) or 180

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

local function allowed(src)
    local now = os.time()
    local prev = lastBySrc[src]
    if prev and (now - prev) < COOLDOWN then
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

local function emitStuck(src, kind, data)
    if not PhantomDashboardEmitError then return end
    local title = ('Player Stuck / Possible Bug — %s'):format(kind or 'stuck')
    local did = discordIdOf(src)
    PhantomDashboardEmitError(title, formatReport(src, kind, data), 15105570, {
        discordId = did,
        category = 'stuck',
        pingPlayer = did ~= nil,
        invitePlayer = true,
    })

    if did then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Phantom Assist',
            description = 'Staff were notified. Check your Discord DMs for an invite so we can help.',
            type = 'inform',
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Phantom Assist',
            description = 'Link Discord in FiveM settings, then join discord.gg/phantomworld for help.',
            type = 'inform',
        })
    end
end

RegisterNetEvent('phantom_dashboard:stuck:auto', function(data)
    local src = source
    if not allowed(src) then return end
    emitStuck(src, 'auto', data)
end)

RegisterNetEvent('phantom_dashboard:stuck:report', function(data)
    local src = source
    if not allowed(src) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Phantom Assist',
            description = 'Report cooldown — try again shortly.',
            type = 'error',
        })
        return
    end
    emitStuck(src, 'player_report', data)
end)

RegisterNetEvent('phantom_dashboard:stuck:unstuckUsed', function(data)
    local src = source
    -- Lighter touch: log unstuck usage less often (separate cooldown bucket)
    local key = ('u:%s'):format(src)
    local now = os.time()
    if lastBySrc[key] and (now - lastBySrc[key]) < COOLDOWN then return end
    lastBySrc[key] = now
    -- Only Discord-notify unstuck if it followed an auto/manual stuck context with odd flags
    data = type(data) == 'table' and data or {}
    if data.faded or data.nuiFocused or data.frozen or (data.reason == 'manual_unstuck') then
        -- soft info via error pipeline so staff sees patterns
        if PhantomDashboardEmitError then
            PhantomDashboardEmitError(
                'Player used /unstuck',
                formatReport(src, 'unstuck', data),
                15844367
            )
        end
    end
end)

--- Admin: force unstuck on a player
RegisterCommand('forceunstuck', function(src, args)
    if src ~= 0 then
        -- require ace if used in-game
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
            3447003
        )
    end
end, true)

AddEventHandler('playerDropped', function()
    local src = source
    lastBySrc[src] = nil
    lastBySrc[('u:%s'):format(src)] = nil
end)
