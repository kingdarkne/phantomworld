--- Restart protocol: critical errors + scheduled hourly restarts.
--- Discord alert → warn players → countdown → kick → host restart.

local ERROR_RESTART = GetConvarInt('phantom_dashboard:errorRestart', 1) == 1
local COUNTDOWN = math.max(15, tonumber(GetConvar('phantom_dashboard:errorRestartSeconds', '60')) or 60)
local COOLDOWN = math.max(120, tonumber(GetConvar('phantom_dashboard:errorRestartCooldownSeconds', '600')) or 600)
local MIN_CRITICAL = math.max(1, tonumber(GetConvar('phantom_dashboard:errorRestartMinCritical', '1')) or 1)
local WINDOW_SEC = math.max(10, tonumber(GetConvar('phantom_dashboard:errorRestartWindowSeconds', '90')) or 90)

local HOURLY = GetConvarInt('phantom_dashboard:hourlyRestart', 1) == 1
local HOURLY_EVERY = math.max(300, tonumber(GetConvar('phantom_dashboard:hourlyRestartSeconds', '3600')) or 3600)
local HOURLY_WARN = math.max(30, tonumber(GetConvar('phantom_dashboard:hourlyRestartWarnSeconds', '300')) or 300)

local protocolActive = false
local lastRestartAt = 0
local recentCritical = {} ---@type number[]
local bootAt = os.time()

local function nowSec()
    return os.time()
end

local function ownerPing()
    local owner = GetConvar('phantom_dashboard:ownerDiscordId', '')
    if owner ~= '' then return ('\n<@%s>'):format(owner) end
    return ''
end

local function announce(msg, seconds)
    print(('[phantom_dashboard] %s'):format(msg))
    TriggerClientEvent('chat:addMessage', -1, {
        color = { 255, 60, 60 },
        multiline = true,
        args = { 'SYSTEM', msg },
    })
    TriggerClientEvent('phantom_dashboard:client:restartWarn', -1, {
        message = msg,
        seconds = seconds,
    })
    if GetResourceState('ox_lib') == 'started' then
        TriggerClientEvent('ox_lib:notify', -1, {
            title = 'Server Warning',
            description = msg,
            type = 'error',
            duration = 10000,
        })
    end
end

local function discordAlert(title, body, category)
    if PhantomDashboardEmitError then
        PhantomDashboardEmitError(title, body, 15548997, {
            category = category or 'critical',
            pingPlayer = false,
            invitePlayer = false,
        })
    end
end

local function kickEveryone(reason)
    for _, id in ipairs(GetPlayers()) do
        DropPlayer(id, reason)
    end
end

local function requestHostRestart(reason)
    local botRelay = GetConvar('phantom_dashboard:botRelayUrl', '')
    local token = GetConvar('phantom_dashboard:apiToken', '')
    if botRelay == '' then
        print('[phantom_dashboard] no botRelayUrl — using quit; ensure panel auto-restarts the process')
        ExecuteCommand('quit')
        return
    end

    local base = botRelay:gsub('/events%s*$', ''):gsub('/errors%s*$', '')
    local url = base .. '/server/restart'
    local headers = { ['Content-Type'] = 'application/json' }
    if token ~= '' then
        headers['Authorization'] = 'Bearer ' .. token
        headers['X-Phantom-Token'] = token
    end

    PerformHttpRequest(url, function(statusCode, responseText)
        print(('[phantom_dashboard] host restart request HTTP %s %s'):format(
            tostring(statusCode),
            responseText and responseText:sub(1, 120) or ''
        ))
        SetTimeout(1500, function()
            ExecuteCommand('quit')
        end)
    end, 'POST', json.encode({
        reason = reason or 'restart',
        source = 'phantom_dashboard',
        time = os.date('%Y-%m-%d %H:%M:%S'),
    }), headers)
end

--- opts: countdown, skipCooldown, scheduled, kickReason, discordTitle
function PhantomDashboardStartRestartProtocol(reason, detail, opts)
    opts = type(opts) == 'table' and opts or {}
    local scheduled = opts.scheduled == true
    local countdown = math.max(15, tonumber(opts.countdown) or COUNTDOWN)
    local kickReason = opts.kickReason
        or (scheduled
            and 'Scheduled hourly server restart. Please reconnect — the server will be back shortly.'
            or 'Server restarting due to a critical script error/bug. Please reconnect in a minute once it is back online.')

    if not scheduled and not ERROR_RESTART then
        print('[phantom_dashboard] errorRestart disabled — skip restart protocol')
        return false
    end
    if protocolActive then return false end

    local t = nowSec()
    if not opts.skipCooldown and lastRestartAt > 0 and (t - lastRestartAt) < COOLDOWN then
        print(('[phantom_dashboard] restart cooldown (%ss left)'):format(COOLDOWN - (t - lastRestartAt)))
        if not scheduled then
            discordAlert(
                '⚠️ Critical error (restart skipped — cooldown)',
                ('Reason: `%s`\n%s\n_Restart cooldown active to prevent loops._'):format(
                    tostring(reason),
                    tostring(detail or '')
                ),
                'critical'
            )
        end
        return false
    end

    protocolActive = true
    lastRestartAt = t

    local why = tostring(reason or 'restart')
    local extra = tostring(detail or '')
    local title = opts.discordTitle
        or (scheduled and '⏰ Scheduled hourly restart' or '🚨 CRITICAL — Server restarting')

    discordAlert(
        title,
        table.concat({
            ('**Reason:** `%s`'):format(why),
            extra ~= '' and extra or nil,
            '',
            ('Players are being warned. Restart in **%s seconds**.'):format(countdown),
            'They can rejoin once the server is back online.',
            ownerPing(),
        }, '\n'),
        scheduled and 'scheduled_restart' or 'critical'
    )

    if scheduled then
        announce(('⏰ Scheduled server restart in %s seconds. You will be kicked — please rejoin after it is back.'):format(countdown), countdown)
    else
        announce(('⚠️ CRITICAL SERVER ERROR detected (%s).'):format(why))
        announce(('Server will RESTART in %s seconds. You will be kicked — please rejoin after it is back.'):format(countdown), countdown)
    end

    CreateThread(function()
        local left = countdown
        while left > 0 do
            local shouldAnnounce = left == countdown
                or left == 600 or left == 300 or left == 180 or left == 120
                or left == 60 or left == 30 or left == 15 or left == 10
                or left <= 5
            if shouldAnnounce then
                announce(('⏳ Restart in %s seconds — prepare to rejoin.'):format(left), left)
                TriggerClientEvent('phantom_dashboard:client:restartWarn', -1, {
                    message = scheduled
                        and ('Scheduled restart in %s seconds. You will be kicked — rejoin when the server is back.'):format(left)
                        or ('Server restarting in %s seconds due to a critical error. You will be kicked — rejoin once fixed.'):format(left),
                    seconds = left,
                })
            end
            Wait(1000)
            left = left - 1
        end

        announce('🔄 Restarting now. Please reconnect in a moment.')
        discordAlert(
            '🔄 Restart executing now',
            ('Kicking players and restarting FXServer.\nReason: `%s`'):format(why),
            scheduled and 'scheduled_restart' or 'critical'
        )

        Wait(1500)
        kickEveryone(kickReason)
        Wait(1000)
        requestHostRestart(scheduled and 'hourly_scheduled' or 'critical_script_error')
    end)

    return true
end

function PhantomDashboardNoteCriticalError(reason, detail)
    if not ERROR_RESTART then return end
    local t = nowSec()
    recentCritical[#recentCritical + 1] = t
    local kept = {}
    for i = 1, #recentCritical do
        if (t - recentCritical[i]) <= WINDOW_SEC then
            kept[#kept + 1] = recentCritical[i]
        end
    end
    recentCritical = kept

    if #recentCritical >= MIN_CRITICAL then
        PhantomDashboardStartRestartProtocol(reason, detail)
        recentCritical = {}
    end
end

exports('StartRestartProtocol', PhantomDashboardStartRestartProtocol)
exports('NoteCriticalError', PhantomDashboardNoteCriticalError)

RegisterCommand('phantom_testrestart', function(src)
    if src ~= 0 then return end
    PhantomDashboardStartRestartProtocol('manual_test', '```\nConsole test of restart protocol\n```', {
        countdown = 20,
        skipCooldown = true,
    })
end, true)

RegisterCommand('phantom_testhourly', function(src)
    if src ~= 0 then return end
    PhantomDashboardStartRestartProtocol('hourly_test', 'Manual test of hourly restart warning', {
        scheduled = true,
        countdown = 20,
        skipCooldown = true,
        discordTitle = '⏰ Hourly restart (test)',
    })
end, true)

-- Hourly (or interval) scheduled restart
CreateThread(function()
    if not HOURLY then
        print('[phantom_dashboard] hourly restart disabled')
        return
    end

    -- Wait until warn window before the interval ends
    local waitSec = math.max(60, HOURLY_EVERY - HOURLY_WARN)
    print(('[phantom_dashboard] hourly restart ENABLED every %ss (warn %ss before)'):format(
        HOURLY_EVERY, HOURLY_WARN
    ))

    while true do
        local elapsed = nowSec() - bootAt
        local nextAt = bootAt
        while nextAt <= nowSec() do
            nextAt = nextAt + HOURLY_EVERY
        end
        local sleepSec = (nextAt - HOURLY_WARN) - nowSec()
        if sleepSec < 1 then sleepSec = 1 end

        print(('[phantom_dashboard] next hourly restart at %s (sleep %ss until warn)'):format(
            os.date('%H:%M:%S', nextAt),
            sleepSec
        ))
        Wait(sleepSec * 1000)

        if protocolActive then
            -- Critical restart already running; wait for next cycle
            Wait(5000)
        else
            PhantomDashboardStartRestartProtocol('scheduled_hourly', ('Automatic restart every %s seconds'):format(HOURLY_EVERY), {
                scheduled = true,
                countdown = HOURLY_WARN,
                skipCooldown = true,
                discordTitle = '⏰ Scheduled hourly server restart',
            })
            -- After starting protocol, wait past the restart so we don't double-fire
            Wait((HOURLY_WARN + 30) * 1000)
            -- If we're somehow still alive (restart failed), bump bootAt so next cycle is fresh
            if not protocolActive then
                bootAt = nowSec()
            end
        end
    end
end)

print(('[phantom_dashboard] restart protocol error=%s (countdown %ss) hourly=%s (%ss / warn %ss)'):format(
    ERROR_RESTART and 'on' or 'off',
    COUNTDOWN,
    HOURLY and 'on' or 'off',
    HOURLY_EVERY,
    HOURLY_WARN
))
