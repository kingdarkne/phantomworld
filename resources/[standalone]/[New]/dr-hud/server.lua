local function getServerName()
    local name = GetConvar('sv_projectName', '')
    if name == '' then name = GetConvar('sv_hostname', '') end
    if name == '' then name = 'Server' end
    return name
end

RegisterNetEvent('dr-hud:requestServerInfo', function()
    local src = source
    TriggerClientEvent('dr-hud:serverInfo', src, {
        serverName = getServerName(),
        serverTime = os.date('%A %H:%M'),
    })
end)

