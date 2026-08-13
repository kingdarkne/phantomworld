--- Server event hub: Discord webhook + bot relay for owner DMs.

local RESOURCE = GetCurrentResourceName()
local eventLog = {}
local MAX_EVENTS = 250

local webhook = Config.Discord.Webhook
local botRelay = GetConvar('phantom_dashboard:botRelayUrl', '')
local botToken = GetConvar('phantom_dashboard:botToken', '')
local relayToken = Config.Discord.ApiToken

local function directOwnerDmEnabled()
    if not botToken or botToken == '' then return false end
    if botToken == 'PASTE_YOUR_BOT_TOKEN_IN_FILE_MANAGER' then return false end
    return true
end

--- Node relay only when no botToken (relay must run on same machine as FXServer).
local function shouldUseBotRelay()
    if not botRelay or botRelay == '' then return false end
    return not directOwnerDmEnabled()
end
local alertAll = GetConvarInt('phantom_dashboard:alertAllEvents', 1) == 1
local ownerDiscordId = GetConvar('phantom_dashboard:ownerDiscordId', '')

local IGNORE_RESOURCE_ALERTS = {
    [RESOURCE] = true,
    monitor = true,
    sessionmanager = true,
    hardcap = true,
}

--- After FXServer boot, skip noisy per-resource alerts until grace ends.
local bootAtMs = 0
local BOOT_GRACE_MS = tonumber(GetConvar('phantom_dashboard:bootGraceSeconds', '120')) * 1000

local function pastBootGrace()
    if bootAtMs == 0 then return true end
    return (GetGameTimer() - bootAtMs) >= BOOT_GRACE_MS
end

local function playerCount()
    return #GetPlayers()
end

local function shouldAlert()
    return alertAll and playerCount() >= (Config.Discord.AlertMinPlayers or 0)
end

local function discordIdentifier(src)
    local id = GetPlayerIdentifierByType(src, 'discord')
    if id then return id:gsub('discord:', '') end
    return nil
end

local function playerLabel(src)
    local name = GetPlayerName(src) or ('ID ' .. tostring(src))
    local discordId = discordIdentifier(src)
    if discordId then
        return ('**%s** (<@%s>)'):format(name, discordId)
    end
    return ('**%s**'):format(name)
end

local function pushLog(entry)
    eventLog[#eventLog + 1] = entry
    if #eventLog > MAX_EVENTS then
        table.remove(eventLog, 1)
    end
end

local function embedPayload(title, description, color)
    local body = description or ''
    if ownerDiscordId ~= '' then
        body = body .. '\n\n<@' .. ownerDiscordId .. '>'
    end
    return {
        username = 'Phantom World',
        embeds = {
            {
                title = title,
                description = body,
                color = color or 5814783,
                footer = { text = os.date('%Y-%m-%d %H:%M:%S') },
            },
        },
    }
end

local function postWebhook(payload)
    if not webhook or webhook == '' then
        print('[phantom_dashboard] webhook not set — add phantom_dashboard.secrets.cfg on the HOST')
        return
    end
    PerformHttpRequest(webhook, function(statusCode, responseText)
        if statusCode ~= 200 and statusCode ~= 204 then
            print(('[phantom_dashboard] webhook failed HTTP %s: %s'):format(
                tostring(statusCode),
                responseText and responseText:sub(1, 200) or 'no body'
            ))
        end
    end, 'POST', json.encode(payload), {
        ['Content-Type'] = 'application/json',
    })
end

local function postBotRelay(entry)
    if not shouldUseBotRelay() then return end
    local headers = { ['Content-Type'] = 'application/json' }
    if relayToken and relayToken ~= '' then
        headers['Authorization'] = 'Bearer ' .. relayToken
        headers['X-Phantom-Token'] = relayToken
    end
    PerformHttpRequest(botRelay, function(statusCode, responseText)
        if statusCode == 0 or (statusCode and statusCode >= 300) then
            print(('[phantom_dashboard] bot relay failed (%s). Run discord-bot ON THE GAME HOST, or set phantom_dashboard:botToken for direct DMs.'):format(
                tostring(statusCode)
            ))
            if responseText then
                print(('[phantom_dashboard] relay response: %s'):format(responseText:sub(1, 120)))
            end
        end
    end, 'POST', json.encode(entry), headers)
end

local function postBotRelayWithRetries(entry, attempts)
    postBotRelay(entry)
    if attempts <= 1 then return end
    CreateThread(function()
        for i = 2, attempts do
            Wait(10000)
            postBotRelay(entry)
        end
    end)
end

local errorWebhook = GetConvar('phantom_dashboard:errorWebhook', '')

local function postErrorWebhook(payload)
    local url = (errorWebhook and errorWebhook ~= '') and errorWebhook or webhook
    if not url or url == '' then
        print('[phantom_dashboard] no webhook for errors — set phantom_dashboard:webhook or :errorWebhook')
        return
    end
    PerformHttpRequest(url, function(statusCode, responseText)
        if statusCode ~= 200 and statusCode ~= 204 then
            print(('[phantom_dashboard] error webhook failed HTTP %s: %s'):format(
                tostring(statusCode),
                responseText and responseText:sub(1, 200) or 'no body'
            ))
        end
    end, 'POST', json.encode(payload), {
        ['Content-Type'] = 'application/json',
    })
end

--- Public emit for other resources
function PhantomDashboardEmit(category, title, description, color)
    if not alertAll then return end

    local entry = {
        category = category or 'info',
        title = title or 'Alert',
        description = description or '',
        color = color or 5814783,
        time = os.date('%Y-%m-%d %H:%M:%S'),
        timestamp = os.time(),
        players = playerCount(),
        maxPlayers = GetConvarInt('sv_maxclients', 48),
    }

    pushLog(entry)
    postWebhook(embedPayload(title, description, color))
    PhantomDashboardDmOwner(entry)
    postBotRelay(entry)
end

--- Always-on path for SCRIPT ERROR / console failures (ignores alertAll / min players).
function PhantomDashboardEmitError(title, description, color)
    local entry = {
        category = 'error',
        title = title or 'FXServer Error',
        description = description or '',
        color = color or 15548997,
        time = os.date('%Y-%m-%d %H:%M:%S'),
        timestamp = os.time(),
        players = playerCount(),
        maxPlayers = GetConvarInt('sv_maxclients', 48),
    }

    pushLog(entry)
    postErrorWebhook(embedPayload(entry.title, entry.description, entry.color))
    PhantomDashboardDmOwner(entry)
    -- Prefer relay so the Discord bot can route to #errors / errorLogs webhook
    if botRelay and botRelay ~= '' then
        local headers = { ['Content-Type'] = 'application/json' }
        if relayToken and relayToken ~= '' then
            headers['Authorization'] = 'Bearer ' .. relayToken
            headers['X-Phantom-Token'] = relayToken
        end
        PerformHttpRequest(botRelay, function(statusCode, responseText)
            if statusCode == 0 or (statusCode and statusCode >= 300) then
                print(('[phantom_dashboard] error relay failed (%s)'):format(tostring(statusCode)))
                if responseText then
                    print(('[phantom_dashboard] relay response: %s'):format(responseText:sub(1, 120)))
                end
            end
        end, 'POST', json.encode(entry), headers)
    end
end

exports('EmitError', function(title, message, color)
    PhantomDashboardEmitError(title, message, color)
end)

--- Lifecycle alerts: always webhook; retry bot relay (bot may start after FXServer).
function PhantomDashboardEmitLifecycle(category, title, description, color)
    if not alertAll then return end

    local entry = {
        category = category or 'lifecycle',
        title = title or 'Alert',
        description = description or '',
        color = color or 5814783,
        time = os.date('%Y-%m-%d %H:%M:%S'),
        timestamp = os.time(),
        players = playerCount(),
        maxPlayers = GetConvarInt('sv_maxclients', 48),
    }

    pushLog(entry)
    postWebhook(embedPayload(title, description, color))
    PhantomDashboardDmOwner(entry)
    postBotRelayWithRetries(entry, 6)
end

exports('EmitAlert', function(title, message, color)
    PhantomDashboardEmit('export', title, message, color)
end)

exports('GetRecentEvents', function()
    return eventLog
end)

-- Server lifecycle
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= RESOURCE then return end
    bootAtMs = GetGameTimer()
    if Config.Discord.PostStartup then
        local status = exports[RESOURCE]:GetStatus()
        PhantomDashboardEmitLifecycle(
            'server',
            '🟢 FXServer / Phantom Dashboard Online',
            ('**%s** started on the **game host**\nPlayers: **%s/%s**\nOwner DMs: %s'):format(
                status.serverName,
                status.playerCount,
                status.maxPlayers,
                directOwnerDmEnabled() and 'direct (botToken)' or (shouldUseBotRelay() and ('relay ' .. botRelay) or 'webhook only')
            ),
            5763719
        )
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if IGNORE_RESOURCE_ALERTS[resourceName] then return end
    if not shouldAlert() or not pastBootGrace() then return end
    PhantomDashboardEmit(
        'resource',
        '📦 Resource Started',
        ('`%s`'):format(resourceName),
        3447003
    )
end)

AddEventHandler('onResourceStop', function(resourceName)
    if IGNORE_RESOURCE_ALERTS[resourceName] then return end
    if not shouldAlert() or not pastBootGrace() then return end
    PhantomDashboardEmit(
        'resource',
        '📦 Resource Stopped',
        ('`%s`'):format(resourceName),
        15158332
    )
end)

AddEventHandler('playerConnecting', function(name, _setKickReason, _deferrals)
    if not shouldAlert() then return end
    PhantomDashboardEmit(
        'connect',
        '🔗 Player Connecting',
        ('**%s** is connecting (%s/%s)'):format(
            name or 'Unknown',
            playerCount(),
            GetConvarInt('sv_maxclients', 48)
        ),
        3447003
    )
end)

AddEventHandler('playerJoining', function()
    if not shouldAlert() then return end
    local src = source
    PhantomDashboardEmit(
        'join',
        '👋 Player Joining',
        playerLabel(src) .. ('\nSession loading (%s/%s)'):format(
            playerCount(),
            GetConvarInt('sv_maxclients', 48)
        ),
        5763719
    )
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    if not shouldAlert() then return end
    local src = player.PlayerData.source
    local char = player.PlayerData.charinfo
    local job = player.PlayerData.job and player.PlayerData.job.label or 'Unknown'
    local extra = ''
    if char then
        extra = ('\nCharacter: %s %s'):format(char.firstname or '', char.lastname or '')
    end
    PhantomDashboardEmit(
        'loaded',
        '✅ Player Loaded',
        playerLabel(src) .. extra .. ('\nJob: %s (%s/%s online)'):format(
            job,
            playerCount(),
            GetConvarInt('sv_maxclients', 48)
        ),
        5763719
    )
end)

AddEventHandler('playerDropped', function(reason)
    if not shouldAlert() then return end
    local src = source
    PhantomDashboardEmit(
        'leave',
        '👋 Player Left',
        playerLabel(src) .. ('\nReason: %s\n(%s/%s online)'):format(
            reason or 'unknown',
            playerCount(),
            GetConvarInt('sv_maxclients', 48)
        ),
        15548997
    )
end)

-- Combat / medical
AddEventHandler('baseevents:onPlayerDied', function(killedBy, pos)
    if not shouldAlert() then return end
    local src = source
    PhantomDashboardEmit(
        'death',
        '💀 Player Died',
        playerLabel(src) .. ('\nCause type: %s'):format(tostring(killedBy)),
        15158332
    )
end)

AddEventHandler('baseevents:onPlayerKilled', function(killerId, data)
    if not shouldAlert() then return end
    local victim = source
    local killerName = killerId and GetPlayerName(killerId) or 'Unknown'
    PhantomDashboardEmit(
        'kill',
        '⚔️ Player Killed',
        ('Victim: %s\nKiller: **%s** (ID %s)'):format(
            playerLabel(victim),
            killerName,
            tostring(killerId)
        ),
        15158332
    )
end)

RegisterNetEvent('hospital:server:SetDeathStatus', function(isDead)
    if not shouldAlert() then return end
    local src = source
    PhantomDashboardEmit(
        'medical',
        isDead and '🏥 Player Down' or '🏥 Player Revived',
        playerLabel(src),
        isDead and 15158332 or 5763719
    )
end)

RegisterNetEvent('qbx_medical:server:playerDied', function()
    if not shouldAlert() then return end
    PhantomDashboardEmit('medical', '💀 Medical: Player Died', playerLabel(source), 15158332)
end)

-- txAdmin
AddEventHandler('txAdmin:events:serverShuttingDown', function()
    PhantomDashboardEmitLifecycle('txadmin', '🔴 FXServer Shutting Down', 'txAdmin shutdown / server restart', 15158332)
end)

AddEventHandler('txAdmin:events:scheduledRestart', function(eventData)
    local msg = 'Scheduled restart'
    if eventData and eventData.secondsRemaining then
        msg = ('Scheduled restart in **%s** seconds'):format(eventData.secondsRemaining)
    end
    PhantomDashboardEmit('txadmin', '⏱️ txAdmin Restart', msg, 16776960)
end)

AddEventHandler('txAdmin:events:healedPlayer', function(eventData)
    local target = eventData and eventData.id
    PhantomDashboardEmit(
        'txadmin',
        '💚 txAdmin Heal',
        target and playerLabel(target) or 'A player was healed via txAdmin',
        5763719
    )
end)

-- Manual / resource bridge (legacy event)
RegisterNetEvent('phantom_dashboard:discord:alert', function(title, message, color)
    PhantomDashboardEmit('manual', title, message, color)
end)

AddEventHandler('phantom_dashboard:discord:serverOnline', function()
    -- handled on resource start
end)
