--- Live server stats for loading screen (no fake random numbers).

local VERSION = '1.1.0'
local CFX_ID = GetConvar('nc_loadscreen:cfxId', '3m87mo')
local VEHICLE_COUNT = tonumber(GetConvar('nc_loadscreen:vehicleCount', '300')) or 300

local cfxCache = {
    uptimeSeconds = nil,
    hostname = nil,
    lastFetch = 0,
}

local function DebugPrint(...)
    if GetConvarInt('nc_loadscreen:debug', 0) == 1 then
        print('[nc-loadingscreen]', ...)
    end
end

local function FormatNumber(number)
    local formatted = tostring(number)
    local k
    while true do
        formatted, k = string.gsub(formatted, '^(-?%d+)(%d%d%d)', '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

local function formatUptime(seconds)
    seconds = math.max(0, math.floor(seconds or 0))
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    if days > 0 then
        return ('%d days %dh online'):format(days, hours)
    end
    if hours > 0 then
        return ('%dh %dm online'):format(hours, mins)
    end
    if mins > 0 then
        return ('%d min online'):format(mins)
    end
    return 'Just started'
end

local function getServerDisplayName()
    local name = GetConvar('sv_projectName', '')
    if name == '' then name = GetConvar('sv_hostname', '') end
    if name == '' then name = 'Phantom World' end
    return name
end

local function countJobs()
    if GetResourceState('qbx_core') ~= 'started' then
        return tonumber(GetConvar('nc_loadscreen:jobCount', '0')) or 0
    end

    local ok, jobs = pcall(function()
        return exports.qbx_core:GetJobs()
    end)

    if not ok or type(jobs) ~= 'table' then
        return tonumber(GetConvar('nc_loadscreen:jobCount', '0')) or 0
    end

    local count = 0
    for _ in pairs(jobs) do
        count = count + 1
    end
    return count
end

local function fetchCfxListing()
    if not CFX_ID or CFX_ID == '' then return end

    PerformHttpRequest(
        ('https://servers-frontend.fivem.net/api/servers/single/%s'):format(CFX_ID),
        function(statusCode, body)
            if statusCode ~= 200 or not body then return end
            local decoded = json.decode(body)
            local data = decoded and decoded.Data
            if not data then return end

            if data.uptime then
                cfxCache.uptimeSeconds = tonumber(data.uptime)
            end
            if data.hostname then
                cfxCache.hostname = data.hostname
            end
            cfxCache.lastFetch = os.time()
            DebugPrint('CFX listing refreshed uptime=' .. tostring(cfxCache.uptimeSeconds))
        end,
        'GET'
    )
end

local function getUptimeSeconds()
    if cfxCache.uptimeSeconds and (os.time() - cfxCache.lastFetch) < 120 then
        local elapsed = os.time() - cfxCache.lastFetch
        return cfxCache.uptimeSeconds + elapsed
    end

    if GetResourceState('phantom_dashboard') == 'started' then
        local ok, status = pcall(function()
            return exports.phantom_dashboard:GetStatus()
        end)
        if ok and status and status.bootAt then
            return os.time() - tonumber(status.bootAt)
        end
    end

    return math.floor(GetGameTimer() / 1000)
end

function BuildLiveServerData()
    local maxPlayers = GetConvarInt('sv_maxclients', 48)
    local playerCount = #GetPlayers()
    local jobCount = countJobs()
    local jobs = jobCount > 0 and ('%d jobs'):format(jobCount) or 'Loading jobs...'

    return {
        serverName = getServerDisplayName(),
        serverUptime = formatUptime(getUptimeSeconds()),
        totalActivities = ('%d / %d online'):format(playerCount, maxPlayers),
        availableVehicles = ('%s+ vehicles'):format(FormatNumber(VEHICLE_COUNT)),
        availableJobs = jobs,
        playerCount = playerCount,
        maxPlayers = maxPlayers,
        cfxJoin = ('https://cfx.re/join/%s'):format(CFX_ID),
    }
end

RegisterNetEvent('loadingscreen:requestData', function()
    local src = source
    TriggerClientEvent('loadingscreen:receiveData', src, BuildLiveServerData())
end)

RegisterNetEvent('loadingscreen:getMaxSlots', function()
    local src = source
    TriggerClientEvent('loadingscreen:receiveMaxSlots', src, GetConvarInt('sv_maxclients', 48))
end)

AddEventHandler('playerConnecting', function(_, _, deferrals)
    deferrals.defer()
    Wait(0)

    local data = BuildLiveServerData()
    deferrals.handover({
        serverInfo = data,
        maxSlots = data.maxPlayers,
        serverName = data.serverName,
    })

    deferrals.done()
end)

CreateThread(function()
    fetchCfxListing()
    while true do
        Wait(60000)
        fetchCfxListing()
    end
end)

print(('^2[nc-loadingscreen]^7 Live stats enabled (CFX %s) | v%s'):format(CFX_ID, VERSION))
