local function getDiscordId(source)
    for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
        if identifier:sub(1, 8) == 'discord:' then
            return identifier:sub(9)
        end
    end

    return nil
end

local function getDiscordProfile(discordId, cb)
    local token = Settings.DiscordBotToken
    if not discordId or token == '' then
        cb(nil, nil)
        return
    end

    PerformHttpRequest(('https://discord.com/api/v10/users/%s'):format(discordId), function(statusCode, body)
        if statusCode ~= 200 or not body or body == '' then
            cb(nil, nil)
            return
        end

        local ok, data = pcall(json.decode, body)
        if not ok or type(data) ~= 'table' then
            cb(nil, nil)
            return
        end

        local username = data.global_name or data.username
        local avatar = nil

        if data.avatar then
            local extension = data.avatar:sub(1, 2) == 'a_' and 'gif' or 'png'
            avatar = ('https://cdn.discordapp.com/avatars/%s/%s.%s?size=256'):format(discordId, data.avatar, extension)
        end

        cb(username, avatar)
    end, 'GET', '', {
        ['Authorization'] = ('Bot %s'):format(token)
    })
end

AddEventHandler('playerConnecting', function(playerName, _, deferrals)
    local source = source
    local discordId = getDiscordId(source)

    deferrals.defer()
    deferrals.update('Loading profile...')

    getDiscordProfile(discordId, function(discordUsername, discordAvatar)
        local players = #GetPlayers()
        local slots = GetConvarInt('sv_maxclients', 64)
        local rawPing = tonumber(GetPlayerPing(source)) or -1
        local safePing = rawPing > 0 and rawPing or nil

        deferrals.handover({
            name = GetPlayerName(source) or playerName or 'Player',
            ping = safePing,
            players = players,
            slots = slots,
            discord = {
                id = discordId,
                username = discordUsername or 'discord',
                avatar = discordAvatar
            }
        })

        deferrals.done()
    end)
end)
