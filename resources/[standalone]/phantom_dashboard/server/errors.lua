--- Capture FXServer console errors → Discord + optional critical restart protocol.

local ENABLED = GetConvarInt('phantom_dashboard:errorReporting', 1) == 1
local DEBOUNCE_MS = math.max(5, tonumber(GetConvar('phantom_dashboard:errorDebounceSeconds', '45')) or 45) * 1000
local BOOT_GRACE_MS = math.max(0, tonumber(GetConvar('phantom_dashboard:errorBootGraceSeconds', '90')) or 90) * 1000
local MAX_MSG = 1500

local bootAt = GetGameTimer()
local recent = {} ---@type table<string, { at: number, count: number }>

local IGNORE_SUBSTRINGS = {
    'hitch warning',
    'authenticated with cfx',
    'sv_purelevel',
    'version check',
    'easyadmin is outdated',
    'unable to determine current resource version',
    'failed to fetch release information',
    'database server connection established',
    'creating script environments for',
    'started resource ',
    'stopping resource ',
    'restart protocol',
    'error reporting online',
    'phantom_dashboard]',
}

-- Soft errors: Discord only (no restart)
local SOFT_PATTERNS = {
    "couldn't find resource",
    'failed to fetch',
    'unable to determine',
    -- Never let dashboard bugs nuke the whole city (alert only).
    '@phantom_dashboard/',
    'script:phantom_dashboard',
}

-- Critical: Discord + restart protocol
local CRITICAL_PATTERNS = {
    'script error',
    'unknown column',
    'access denied for user',
    'attempt to index',
    'attempt to call',
    'nil value',
    'error during',
    'failed to load script',
    'failed to start resource',
    'invocation error',
    'unhandledpromiserejection',
}

local function stripAnsi(s)
    return (s:gsub('\27%[[0-9;]*m', ''):gsub('\r', ''))
end

local function shouldIgnore(lower)
    for i = 1, #IGNORE_SUBSTRINGS do
        if lower:find(IGNORE_SUBSTRINGS[i], 1, true) then
            return true
        end
    end
    return false
end

local function isSoft(lower)
    for i = 1, #SOFT_PATTERNS do
        if lower:find(SOFT_PATTERNS[i], 1, true) then
            return true
        end
    end
    return false
end

local function isCritical(lower)
    for i = 1, #CRITICAL_PATTERNS do
        if lower:find(CRITICAL_PATTERNS[i], 1, true) then
            return true
        end
    end
    return false
end

local function isErrorLine(lower)
    return isCritical(lower) or isSoft(lower) or lower:find('error:', 1, true) ~= nil
end

local function fingerprint(msg)
    local f = msg:lower()
    f = f:gsub('%d+', '#')
    f = f:gsub('%s+', ' ')
    return f:sub(1, 240)
end

local function extractResource(msg)
    return msg:match('%[script:([%w%-_]+)%]')
        or msg:match("SCRIPT ERROR:%s*@([%w%-_]+)/")
        or msg:match("SCRIPT ERROR in resource ([%w%-_]+)")
end

local function severityColor(critical)
    return critical and 15548997 or 15105570
end

local function reportError(channel, message)
    if not ENABLED then return end
    if not PhantomDashboardEmitError then return end
    if (GetGameTimer() - bootAt) < BOOT_GRACE_MS then return end

    local clean = stripAnsi(tostring(message or '')):gsub('^%s+', ''):gsub('%s+$', '')
    if clean == '' or #clean < 8 then return end

    local lower = clean:lower()
    if shouldIgnore(lower) or not isErrorLine(lower) then return end

    local critical = isCritical(lower) and not isSoft(lower)

    local fp = fingerprint(clean)
    local now = GetGameTimer()
    local prev = recent[fp]
    if prev and (now - prev.at) < DEBOUNCE_MS then
        prev.count = prev.count + 1
        prev.at = now
        return
    end

    local repeats = prev and prev.count or 0
    recent[fp] = { at = now, count = 1 }

    if (now % 50) == 0 then
        for k, v in pairs(recent) do
            if (now - v.at) > (DEBOUNCE_MS * 4) then
                recent[k] = nil
            end
        end
    end

    local resName = extractResource(clean)
    local title = critical
        and (resName and ('CRITICAL Script Error — `%s`'):format(resName) or 'CRITICAL Script Error')
        or (resName and ('FXServer Warning — `%s`'):format(resName) or 'FXServer Console Warning')

    local body = ('```\n%s\n```'):format(clean:sub(1, MAX_MSG))
    if channel and channel ~= '' then
        body = ('Channel: `%s`\n%s'):format(tostring(channel), body)
    end
    if repeats > 0 then
        body = body .. ('\n_Suppressed **%s** repeat(s) in the last window_'):format(repeats)
    end
    if critical then
        body = body .. '\n\n_This is classified as **critical** — restart protocol may start._'
    end

    PhantomDashboardEmitError(title, body, severityColor(critical), {
        category = critical and 'critical' or 'error',
    })

    if critical and PhantomDashboardNoteCriticalError then
        PhantomDashboardNoteCriticalError(
            resName and ('script:' .. resName) or 'script_error',
            body
        )
    end
end

CreateThread(function()
    Wait(2000)
    if not ENABLED then
        print('[phantom_dashboard] error reporting disabled (phantom_dashboard:errorReporting 0)')
        return
    end

    local ok, err = pcall(function()
        RegisterConsoleListener(function(channel, message)
            if message == nil and type(channel) == 'string' then
                reportError('', channel)
                return
            end
            reportError(channel, message)
        end)
    end)

    if ok then
        print(('[phantom_dashboard] full error reporting online (debounce %ss, boot grace %ss)'):format(
            math.floor(DEBOUNCE_MS / 1000),
            math.floor(BOOT_GRACE_MS / 1000)
        ))
    else
        print(('[phantom_dashboard] RegisterConsoleListener unavailable: %s'):format(tostring(err)))
    end
end)

exports('ReportError', function(title, message, critical)
    if PhantomDashboardEmitError then
        PhantomDashboardEmitError(title or 'Server Error', message or '', 15548997, {
            category = critical and 'critical' or 'error',
        })
    end
    if critical and PhantomDashboardNoteCriticalError then
        PhantomDashboardNoteCriticalError(title or 'export', message or '')
    end
end)

RegisterCommand('phantom_testerror', function(src)
    if src ~= 0 then return end
    local body = '```\nSCRIPT ERROR: @phantom_dashboard/server/errors.lua:0: intentional test error\n```'
    PhantomDashboardEmitError('CRITICAL Script Error — test', body, 15548997, { category = 'critical' })
    if PhantomDashboardNoteCriticalError then
        PhantomDashboardNoteCriticalError('test_script_error', body)
    end
    print('[phantom_dashboard] sent critical test error (may start restart protocol)')
end, true)
