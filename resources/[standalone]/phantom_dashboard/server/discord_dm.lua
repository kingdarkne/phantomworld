--- Owner DMs via Discord Bot API (no Node bot required on restricted hosts).

local botToken = GetConvar('phantom_dashboard:botToken', '')
local ownerDiscordId = GetConvar('phantom_dashboard:ownerDiscordId', '')
local ownerDmChannelId = nil

local function botHeaders()
    return {
        ['Content-Type'] = 'application/json',
        ['Authorization'] = 'Bot ' .. botToken,
    }
end

local function sendToDmChannel(channelId, entry)
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
        botHeaders()
    )
end

--- Send alert embed directly to owner DM (works without discord-bot Node process).
function PhantomDashboardDmOwner(entry)
    if not botToken or botToken == '' or not ownerDiscordId or ownerDiscordId == '' then
        return
    end

    if ownerDmChannelId then
        sendToDmChannel(ownerDmChannelId, entry)
        return
    end

    PerformHttpRequest(
        ('https://discord.com/api/v10/users/%s/channels'):format(ownerDiscordId),
        function(statusCode, responseText)
            if statusCode ~= 200 or not responseText then
                print(('[phantom_dashboard] Discord DM channel open failed HTTP %s: %s'):format(
                    tostring(statusCode),
                    responseText and responseText:sub(1, 200) or ''
                ))
                return
            end
            local data = json.decode(responseText)
            if not data or not data.id then return end
            ownerDmChannelId = data.id
            sendToDmChannel(ownerDmChannelId, entry)
        end,
        'POST',
        '{}',
        botHeaders()
    )
end
