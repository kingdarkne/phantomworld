--- Owner DMs via Discord Bot API (no Node bot required on restricted hosts).

local ownerDiscordId = GetConvar('phantom_dashboard:ownerDiscordId', '')
local ownerDmChannelId = nil
local tokenValidated = false
local tokenValid = false

local PLACEHOLDER_TOKENS = {
    PASTE_YOUR_BOT_TOKEN_IN_FILE_MANAGER = true,
    YOUR_BOT_TOKEN_FOR_DIRECT_DMS = true,
    paste_your_bot_token_here = true,
    your_bot_token_here = true,
}

local function normalizeBotToken(raw)
    if not raw or raw == '' then return '' end
    local t = raw:gsub('^%s+', ''):gsub('%s+$', '')
    if t:sub(1, 1) == '"' and t:sub(-1) == '"' then
        t = t:sub(2, -2)
    end
    return t
end

local function getBotToken()
    local t = normalizeBotToken(GetConvar('phantom_dashboard:botToken', ''))
    if t == '' or PLACEHOLDER_TOKENS[t] then
        return ''
    end
    return t
end

local function botHeaders(token)
    return {
        ['Content-Type'] = 'application/json',
        ['Authorization'] = 'Bot ' .. token,
    }
end

local function sendToDmChannel(channelId, entry, token)
    local payload = json.encode({
        embeds = {
            {
                title = entry.title or 'Phantom World',
                description = (entry.description or ''):sub(1, 4096),
                color = entry.color or 5814783,
                footer = { text = entry.time or os.date('%Y-%m-%d %H:%M:%S') },
            },
        },
    })
    PerformHttpRequest(
        ('https://discord.com/api/v10/channels/%s/messages'):format(channelId),
        function(statusCode, responseText)
            if statusCode ~= 200 and statusCode ~= 201 then
                print(('[phantom_dashboard] Discord DM send failed HTTP %s: %s'):format(
                    tostring(statusCode),
                    responseText and responseText:sub(1, 200) or ''
                ))
            end
        end,
        'POST',
        payload,
        botHeaders(token)
    )
end

local function logTokenHelp(statusCode, responseText)
    print(('[phantom_dashboard] Discord bot auth failed HTTP %s: %s'):format(
        tostring(statusCode),
        responseText and responseText:sub(1, 120) or ''
    ))
    print('[phantom_dashboard] Fix: File Manager -> /home/container/phantom_dashboard.secrets.cfg')
    print('[phantom_dashboard] Set phantom_dashboard:botToken to your BOT token (Developer Portal -> Bot -> Reset/Copy).')
    print('[phantom_dashboard] Must match the token in discord-bot/.env on your PC. No extra spaces or quotes inside the value.')
    print('[phantom_dashboard] GitHub deploy no longer overwrites this file — paste token on host after pull.')
end

CreateThread(function()
    Wait(2000)
    local token = getBotToken()
    if token == '' then
        print('[phantom_dashboard] botToken missing or placeholder — owner DMs disabled until you set it on the HOST.')
        return
    end
    PerformHttpRequest('https://discord.com/api/v10/users/@me', function(statusCode, responseText)
        tokenValidated = true
        if statusCode == 200 then
            tokenValid = true
            print('[phantom_dashboard] Discord bot token OK (owner DMs enabled)')
        else
            tokenValid = false
            logTokenHelp(statusCode, responseText)
        end
    end, 'GET', '', botHeaders(token))
end)

--- Send alert embed directly to owner DM (works without discord-bot Node process).
function PhantomDashboardDmOwner(entry)
    local token = getBotToken()
    if token == '' or not ownerDiscordId or ownerDiscordId == '' then
        return
    end

    if tokenValidated and not tokenValid then
        return
    end

    if ownerDmChannelId then
        sendToDmChannel(ownerDmChannelId, entry, token)
        return
    end

    PerformHttpRequest(
        ('https://discord.com/api/v10/users/%s/channels'):format(ownerDiscordId),
        function(statusCode, responseText)
            if statusCode ~= 200 or not responseText then
                if statusCode == 401 then
                    tokenValid = false
                    tokenValidated = true
                end
                logTokenHelp(statusCode, responseText)
                return
            end
            local data = json.decode(responseText)
            if not data or not data.id then return end
            ownerDmChannelId = data.id
            sendToDmChannel(ownerDmChannelId, entry, token)
        end,
        'POST',
        '{}',
        botHeaders(token)
    )
end
