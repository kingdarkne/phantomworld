local serverBootAt = os.time()

local function getServerDisplayName()
    local name = GetConvar('sv_projectName', '')
    if name == '' then name = GetConvar('sv_hostname', '') end
    if name == '' then name = 'Phantom World' end
    return name
end

local function buildStatusPayload()
    return {
        serverName = getServerDisplayName(),
        serverTime = os.date('%a %H:%M'),
        playerCount = #GetPlayers(),
        maxPlayers = GetConvarInt('sv_maxclients', 48),
        bootAt = serverBootAt,
        uptimeSeconds = os.time() - serverBootAt,
    }
end

RegisterNetEvent('phantom_dashboard:requestServerInfo', function()
    TriggerClientEvent('phantom_dashboard:client:serverInfo', source, buildStatusPayload())
end)

--- Export for Discord bot / external tools
exports('GetStatus', function()
    return buildStatusPayload()
end)

exports('GetPlayers', function()
    local list = {}
    for _, src in ipairs(GetPlayers()) do
        local id = tonumber(src)
        local name = GetPlayerName(id) or ('ID ' .. src)
        list[#list + 1] = { id = id, name = name }
    end
    return list
end)

