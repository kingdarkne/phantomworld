--- Live server stats for loading screen (no fake random numbers).

local VERSION = '1.2.0'
local CFX_ID = GetConvar('nc_loadscreen:cfxId', '3m87mo')
local VEHICLE_COUNT = tonumber(GetConvar('nc_loadscreen:vehicleCount', '300')) or 300

local cfxCache = {
    uptimeSeconds = nil,
    hostname = nil,
    lastFetch = 0,
}
local liveDataCache = {
    data = nil,
    updatedAt = 0,
}
local requestLastAt = {}
local LIVE_DATA_CACHE_MS = tonumber(GetConvar('nc_loadscreen:liveDataCacheMs', '3000')) or 3000
local REQUEST_COOLDOWN_MS = tonumber(GetConvar('nc_loadscreen:requestCooldownMs', '5000')) or 5000

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

local function playerDiscordId(src)
    local n = GetNumPlayerIdentifiers(src)
    for i = 0, n - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id:sub(1, 8) == 'discord:' then
            return id:sub(9)
        end
    end
    return nil
end

local function playerLicense(src)
    local license = GetPlayerIdentifierByType(src, 'license')
    if license then return license:gsub('license:', '') end
    local license2 = GetPlayerIdentifierByType(src, 'license2')
    if license2 then return license2:gsub('license2:', '') end
    return nil
end

local function isPlayerStaff(src)
    return IsPlayerAceAllowed(src, 'group.admin')
        or IsPlayerAceAllowed(src, 'admin')
        or IsPlayerAceAllowed(src, 'qbcore.god')
        or IsPlayerAceAllowed(src, 'qbcore.admin')
end

local function rosterMemberOnline(member)
    for _, src in ipairs(GetPlayers()) do
        local pid = tonumber(src)
        if not pid then goto continue end

        if member.discordId and playerDiscordId(pid) == member.discordId then
            return pid
        end

        if member.license and playerLicense(pid) == member.license then
            return pid
        end

        ::continue::
    end
    return nil
end

local function copyBadges(badges)
    if type(badges) ~= 'table' then return {} end
    local out = {}
    for i = 1, #badges do
        out[i] = badges[i]
    end
    return out
end

function BuildStaffList()
    local list = {}
    local matched = {}

    for _, member in ipairs(StaffRoster or {}) do
        local onlineSrc = rosterMemberOnline(member)
        local status = onlineSrc and 'online' or 'offline'
        local displayName = member.name

        if onlineSrc then
            matched[onlineSrc] = true
            local liveName = GetPlayerName(onlineSrc)
            if liveName and liveName ~= '' then
                displayName = liveName
            end
        end

        list[#list + 1] = {
            name = displayName,
            role = member.role,
            roleType = member.roleType or 'mod',
            avatar = member.avatar or 'img/avatars/admin1.png',
            status = status,
            badges = copyBadges(member.badges),
        }
    end

    for _, src in ipairs(GetPlayers()) do
        local pid = tonumber(src)
        if not pid or matched[pid] then goto continue end

        if isPlayerStaff(pid) then
            list[#list + 1] = {
                name = GetPlayerName(pid) or ('Staff ' .. pid),
                role = 'Staff',
                roleType = 'moderator',
                avatar = 'img/avatars/admin3.png',
                status = 'online',
                badges = { 'admin' },
            }
            matched[pid] = true
        end

        ::continue::
    end

    return list
end

local function countStaffOnline(staff)
    local n = 0
    for i = 1, #staff do
        if staff[i].status == 'online' then
            n = n + 1
        end
    end
    return n
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
    local staff = BuildStaffList()
    local staffOnline = countStaffOnline(staff)

    return {
        serverName = getServerDisplayName(),
        serverUptime = formatUptime(getUptimeSeconds()),
        totalActivities = ('%d / %d online'):format(playerCount, maxPlayers),
        availableVehicles = ('%s+ vehicles'):format(FormatNumber(VEHICLE_COUNT)),
        availableJobs = jobs,
        playerCount = playerCount,
        maxPlayers = maxPlayers,
        cfxJoin = ('https://cfx.re/join/%s'):format(CFX_ID),
        staff = staff,
        staffOnline = staffOnline,
        staffOnlineText = staffOnline > 0
            and ('%d staff member%s online now'):format(staffOnline, staffOnline == 1 and '' or 's')
            or 'No staff online right now — Discord support is always open',
    }
end

local function GetCachedLiveServerData()
    local now = GetGameTimer()
    if liveDataCache.data and (now - liveDataCache.updatedAt) < LIVE_DATA_CACHE_MS then
        return liveDataCache.data
    end

    liveDataCache.data = BuildLiveServerData()
    liveDataCache.updatedAt = now
    return liveDataCache.data
end

local function ShouldServeLiveDataRequest(src)
    local key = tostring(src)
    local now = GetGameTimer()
    local last = requestLastAt[key]
    if last and (now - last) < REQUEST_COOLDOWN_MS then
        DebugPrint(('rate-limited live data request from %s'):format(key))
        return false
    end

    requestLastAt[key] = now
    return true
end

RegisterNetEvent('loadingscreen:requestData', function()
    local src = source
    if not ShouldServeLiveDataRequest(src) then return end
    TriggerClientEvent('loadingscreen:receiveData', src, GetCachedLiveServerData())
end)

RegisterNetEvent('loadingscreen:getMaxSlots', function()
    local src = source
    TriggerClientEvent('loadingscreen:receiveMaxSlots', src, GetConvarInt('sv_maxclients', 48))
end)

AddEventHandler('playerDropped', function()
    requestLastAt[tostring(source)] = nil
end)

AddEventHandler('playerConnecting', function(_, _, deferrals)
    deferrals.defer()
    Wait(0)

    local data = GetCachedLiveServerData()
    deferrals.handover({
        serverInfo = data,
        staff = data.staff,
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
