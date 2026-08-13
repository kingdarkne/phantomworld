--- Capture FXServer console errors and forward to Discord via phantom_dashboard alerts/relay.

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
}

local MATCH_PATTERNS = {
    'script error',
    'unknown column',
    'access denied for user',
    'oxmysql',
    'unhandledpromiserejection',
    'attempt to index',
    'attempt to call',
    'nil value',
    'error during',
    "couldn't find resource",
    'failed to load',
    'failed to start',
    'invocation error',
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

local function isErrorLine(lower)
    for i = 1, #MATCH_PATTERNS do
        if lower:find(MATCH_PATTERNS[i], 1, true) then
            return true
        end
    end
    -- generic "error:" but not "0 error"
    if lower:find('error:', 1, true) or lower:find('^%s*%[.*error', 1) then
        return true
    end
    return false
end

local function fingerprint(msg)
    -- collapse numbers / citizenids to reduce spam variants
    local f = msg:lower()
    f = f:gsub('%d+', '#')
    f = f:gsub('%s+', ' ')
    return f:sub(1, 240)
end

local function extractResource(msg)
    local r = msg:match('%[script:([%w%-_]+)%]')
        or msg:match('%[%-?%s*script:([%w%-_]+)%]')
        or msg:match("SCRIPT ERROR:%s*@([%w%-_]+)/")
        or msg:match("SCRIPT ERROR in resource ([%w%-_]+)")
    return r
end

local function severityColor(lower)
    if lower:find('script error', 1, true) or lower:find('unknown column', 1, true) then
        return 15548997 -- red
    end
    if lower:find("couldn't find", 1, true) then
        return 15105570 -- orange
    end
    return 15158332 -- soft red
end

local function reportError(channel, message)
    if not ENABLED then return end
    if not PhantomDashboardEmitError then return end
    if (GetGameTimer() - bootAt) < BOOT_GRACE_MS then return end

    local clean = stripAnsi(tostring(message or '')):gsub('^%s+', ''):gsub('%s+$', '')
    if clean == '' or #clean < 8 then return end

    local lower = clean:lower()
    if shouldIgnore(lower) or not isErrorLine(lower) then return end

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

    -- prune old fingerprints occasionally
    if (now % 50) == 0 then
        for k, v in pairs(recent) do
            if (now - v.at) > (DEBOUNCE_MS * 4) then
                recent[k] = nil
            end
        end
    end

    local resName = extractResource(clean)
    local title = resName and ('FXServer Error — `%s`'):format(resName) or 'FXServer Console Error'
    local body = ('```\n%s\n```'):format(clean:sub(1, MAX_MSG))
    if channel and channel ~= '' then
        body = ('Channel: `%s`\n%s'):format(tostring(channel), body)
    end
    if repeats > 0 then
        body = body .. ('\n_Suppressed **%s** repeat(s) in the last window_'):format(repeats)
    end

    PhantomDashboardEmitError(title, body, severityColor(lower))
end

CreateThread(function()
    Wait(1500)
    if not ENABLED then
        print('[phantom_dashboard] error reporting disabled (phantom_dashboard:errorReporting 0)')
        return
    end

    local ok, err = pcall(function()
        RegisterConsoleListener(function(channel, message)
            -- Some builds pass only message
            if message == nil and type(channel) == 'string' then
                reportError('', channel)
                return
            end
            reportError(channel, message)
        end)
    end)

    if ok then
        print(('[phantom_dashboard] error reporting online (debounce %ss, boot grace %ss)'):format(
            math.floor(DEBOUNCE_MS / 1000),
            math.floor(BOOT_GRACE_MS / 1000)
        ))
    else
        print(('[phantom_dashboard] RegisterConsoleListener unavailable: %s'):format(tostring(err)))
    end
end)

--- Manual report from other resources
exports('ReportError', function(title, message)
    if PhantomDashboardEmitError then
        PhantomDashboardEmitError(title or 'Server Error', message or '', 15548997)
    end
end)

RegisterCommand('phantom_testerror', function(src)
    if src ~= 0 then return end
    PhantomDashboardEmitError(
        'FXServer Error — test',
        '```\nSCRIPT ERROR: @phantom_dashboard/server/errors.lua:0: intentional test error\n```',
        15548997
    )
    print('[phantom_dashboard] sent test error report')
end, true)
