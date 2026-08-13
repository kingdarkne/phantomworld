--- Critical script-error restart protocol:
--- Discord alert → warn all players → countdown → kick → quit (host brings server back).

local ENABLED = GetConvarInt('phantom_dashboard:errorRestart', 1) == 1
local COUNTDOWN = math.max(15, tonumber(GetConvar('phantom_dashboard:errorRestartSeconds', '60')) or 60)
local COOLDOWN = math.max(120, tonumber(GetConvar('phantom_dashboard:errorRestartCooldownSeconds', '600')) or 600)
local MIN_CRITICAL = math.max(1, tonumber(GetConvar('phantom_dashboard:errorRestartMinCritical', '1')) or 1)
local WINDOW_SEC = math.max(10, tonumber(GetConvar('phantom_dashboard:errorRestartWindowSeconds', '90')) or 90)

local protocolActive = false
local lastRestartAt = 0
local recentCritical = {} ---@type number[]

local function nowSec()
    return os.time()
end

local function ownerPing()
    local owner = GetConvar('phantom_dashboard:ownerDiscordId', '')
    if owner ~= '' then return ('\n<@%s>'):format(owner) end
    return ''
end

local function announce(msg)
    print(('[phantom_dashboard] %s'):format(msg))
    TriggerClientEvent('chat:addMessage', -1, {
        color = { 255, 60, 60 },
        multiline = true,
        args = { 'SYSTEM', msg },
    })
    TriggerClientEvent('phantom_dashboard:client:restartWarn', -1, {
        message = msg,
        seconds = nil,
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

local function discordCritical(title, body)
    if PhantomDashboardEmitError then
        PhantomDashboardEmitError(title, body, 15548997, {
            category = 'critical',
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

local function requestHostRestart()
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
        -- Always quit so Wings/panel can bring a clean process up
        SetTimeout(1500, function()
            ExecuteCommand('quit')
        end)
    end, 'POST', json.encode({
        reason = 'critical_script_error',
        source = 'phantom_dashboard',
        time = os.date('%Y-%m-%d %H:%M:%S'),
    }), headers)
end

function PhantomDashboardStartRestartProtocol(reason, detail)
    if not ENABLED then
        print('[phantom_dashboard] errorRestart disabled — skip restart protocol')
        return false
    end
    if protocolActive then return false end

    local t = nowSec()
    if lastRestartAt > 0 and (t - lastRestartAt) < COOLDOWN then
        print(('[phantom_dashboard] restart cooldown (%ss left)'):format(COOLDOWN - (t - lastRestartAt)))
        discordCritical(
            '⚠️ Critical error (restart skipped — cooldown)',
            ('Reason: `%s`\n%s\n_Restart cooldown active to prevent loops._'):format(
                tostring(reason),
                tostring(detail or '')
            )
        )
        return false
    end

    protocolActive = true
    lastRestartAt = t

    local why = tostring(reason or 'critical script error')
    local extra = tostring(detail or '')

    discordCritical(
        '🚨 CRITICAL — Server restarting',
        table.concat({
            ('**Reason:** `%s`'):format(why),
            extra ~= '' and extra or nil,
            '',
            ('Players are being warned. Restart in **%s seconds**.'):format(COUNTDOWN),
            'They can rejoin once the server is back online.',
            ownerPing(),
        }, '\n')
    )

    announce(('⚠️ CRITICAL SERVER ERROR detected (%s).'):format(why))
    announce(('Server will RESTART in %s seconds. You will be kicked — please rejoin after it is back.'):format(COUNTDOWN))

    CreateThread(function()
        local left = COUNTDOWN
        while left > 0 do
            if left == COUNTDOWN or left == 30 or left == 15 or left == 10 or left <= 5 then
                announce(('⏳ Restart in %s seconds — save up / prepare to rejoin.'):format(left))
                TriggerClientEvent('phantom_dashboard:client:restartWarn', -1, {
                    message = ('Server restarting in %s seconds due to a critical error. You will be kicked — rejoin once fixed.'):format(left),
                    seconds = left,
                })
            end
            Wait(1000)
            left = left - 1
        end

        announce('🔄 Restarting now. Please reconnect in a moment.')
        discordCritical(
            '🔄 Restart executing now',
            ('Kicking players and restarting FXServer.\nReason: `%s`'):format(why)
        )

        Wait(1500)
        kickEveryone('Server restarting due to a critical script error/bug. Please reconnect in a minute once it is back online.')
        Wait(1000)
        requestHostRestart()
    end)

    return true
end

function PhantomDashboardNoteCriticalError(reason, detail)
    if not ENABLED then return end
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
    PhantomDashboardStartRestartProtocol('manual_test', '```\nConsole test of restart protocol\n```')
end, true)

print(('[phantom_dashboard] restart protocol %s (countdown %ss, cooldown %ss, minCritical %s/%ss)'):format(
    ENABLED and 'ENABLED' or 'disabled',
    COUNTDOWN,
    COOLDOWN,
    MIN_CRITICAL,
    WINDOW_SEC
))
