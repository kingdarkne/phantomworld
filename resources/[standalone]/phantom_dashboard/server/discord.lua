local webhook = Config.Discord.Webhook

local function postWebhook(payload)
    if not webhook or webhook == '' then return end
    PerformHttpRequest(webhook, function() end, 'POST', json.encode(payload), {
        ['Content-Type'] = 'application/json',
    })
end

local function playerCount()
    return #GetPlayers()
end

local function shouldAlert()
    return playerCount() >= (Config.Discord.AlertMinPlayers or 0)
end

local function discordIdentifier(src)
    local id = GetPlayerIdentifierByType(src, 'discord')
    if id then
        return id:gsub('discord:', '')
    end
    return nil
end

local function embed(title, description, color)
    return {
        username = 'Phantom Dashboard',
        embeds = {
            {
                title = title,
                description = description,
                color = color or 5814783,
                footer = { text = os.date('%Y-%m-%d %H:%M:%S') },
            },
        },
    }
end

AddEventHandler('phantom_dashboard:discord:serverOnline', function()
    local status = exports[GetCurrentResourceName()]:GetStatus()
    postWebhook(embed(
        '🟢 Server Online',
        ('**%s** is running\nPlayers: **%s/%s**\nTime: %s'):format(
            status.serverName,
            status.playerCount,
            status.maxPlayers,
            status.serverTime
        ),
        5763719
    ))
end)

AddEventHandler('playerConnecting', function()
    -- defer alerts until fully joined
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    if not shouldAlert() then return end
    local src = player.PlayerData.source
    local name = GetPlayerName(src) or 'Unknown'
    local discordId = discordIdentifier(src)
    local mention = discordId and ('<@' .. discordId .. '>') or name
    postWebhook(embed(
        '👤 Player Joined',
        ('**%s** joined (%s/%s players)'):format(name, playerCount(), GetConvarInt('sv_maxclients', 48))
            .. (discordId and ('\nDiscord: ' .. mention) or ''),
        5763719
    ))
end)

AddEventHandler('playerDropped', function(reason)
    if not shouldAlert() then return end
    local src = source
    local name = GetPlayerName(src) or 'Unknown'
    local count = playerCount()
    postWebhook(embed(
        '👋 Player Left',
        ('**%s** disconnected\nReason: %s\n(%s/%s players)'):format(
            name,
            reason or 'unknown',
            count,
            GetConvarInt('sv_maxclients', 48)
        ),
        15548997
    ))
end)

--- Manual alert from other resources
RegisterNetEvent('phantom_dashboard:discord:alert', function(title, message, color)
    if not title or not message then return end
    postWebhook(embed(title, message, color))
end)

exports('SendDiscordAlert', function(title, message, color)
    postWebhook(embed(title, message, color))
end)
