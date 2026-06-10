--[[
  Phantom Dashboard — compact info strip (bottom-left, above minimap).
  Works alongside tuff-hud; hides when pause menu or NUI has focus.
]]

local function isMenuBlocking()
    return IsPauseMenuActive() or IsNuiFocused()
end

local SHOW_RANK = GetConvarInt('qbx_hud:showRank', Config.ShowRank and 1 or 0) == 1
local SHOW_JOB = GetConvarInt('qbx_hud:showJob', Config.ShowJob and 1 or 0) == 1

local function getRankFromMeta(meta)
    meta = meta or {}
    return meta.rankxp_level or meta.rank or meta.xp or 0
end

local function sendDashboard(payload)
    payload.action = 'phantomDashboard'
    SendNUIMessage(payload)
end

local function pushPlayerInfo()
    if not LocalPlayer.state.isLoggedIn then return end
    if isMenuBlocking() then return end

    local pd = QBX.PlayerData
    if not pd or not pd.money then return end

    local meta = pd.metadata or {}
    local name = pd.name
    if pd.charinfo and pd.charinfo.firstname then
        name = (pd.charinfo.firstname or '') .. ' ' .. (pd.charinfo.lastname or '')
    end

    local gang = '—'
    if Config.ShowGang and type(pd.gang) == 'table' and pd.gang.label then
        gang = pd.gang.label
    end

    local street = '—'
    if Config.ShowStreet then
        local coords = GetEntityCoords(cache.ped)
        local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        street = GetStreetNameFromHashKey(streetHash) or 'Unknown'
    end

    sendDashboard({
        visible = true,
        showRank = SHOW_RANK,
        showJob = SHOW_JOB,
        showGang = Config.ShowGang,
        showStreet = Config.ShowStreet,
        showMoney = Config.ShowMoney,
        showVoice = Config.ShowVoice,
        rank = getRankFromMeta(meta),
        job = (pd.job and pd.job.label) or 'Unemployed',
        gang = gang,
        playerName = (name and name:gsub('^%s+', ''):gsub('%s+$', '')) or 'Player',
        street = street,
        playerId = cache.serverId,
        cash = pd.money.cash or 0,
        bank = pd.money.bank or 0,
    })
end

RegisterNetEvent('phantom_dashboard:client:serverInfo', function(info)
    if type(info) ~= 'table' then return end
    sendDashboard({
        serverName = info.serverName,
        serverTime = info.serverTime,
        playerCount = info.playerCount,
        maxPlayers = info.maxPlayers,
    })
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000)
    TriggerServerEvent('phantom_dashboard:requestServerInfo')
    pushPlayerInfo()
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function()
    pushPlayerInfo()
end)

RegisterNetEvent('hud:client:OnMoneyChange', function()
    pushPlayerInfo()
end)

RegisterNetEvent('hud:client:ShowAccounts', function()
    pushPlayerInfo()
end)

CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn then
            TriggerServerEvent('phantom_dashboard:requestServerInfo')
            Wait(30000)
        else
            Wait(5000)
        end
    end
end)

CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn then
            pushPlayerInfo()
            Wait(1500)
        else
            sendDashboard({ visible = false })
            Wait(1000)
        end
    end
end)

CreateThread(function()
    local wasBlocked = false
    while true do
        local blocked = LocalPlayer.state.isLoggedIn and isMenuBlocking()
        if blocked ~= wasBlocked then
            wasBlocked = blocked
            if blocked then
                sendDashboard({ visible = false })
            else
                pushPlayerInfo()
            end
        end
        Wait(100)
    end
end)

CreateThread(function()
    if not Config.ShowVoice then return end
    local lastTalking, lastKey
    while true do
        if LocalPlayer.state.isLoggedIn then
            local talking = NetworkIsPlayerTalking(cache.playerId)
            local prox = LocalPlayer.state.proximity
            local dist, mode = nil, nil
            if type(prox) == 'table' then
                dist = prox.distance
                mode = prox.mode
            end
            if dist == nil then dist = MumbleGetTalkerProximity() end
            local key = tostring(talking) .. ':' .. tostring(mode) .. ':' .. tostring(dist)
            if lastTalking ~= talking or lastKey ~= key then
                lastTalking = talking
                lastKey = key
                local label = mode and (tostring(mode) .. (dist and (' · ' .. math.floor(dist)) .. 'm' or '')) or 'Voice'
                sendDashboard({
                    action = 'phantomVoice',
                    talking = talking,
                    voiceLabel = label,
                })
            end
            Wait(200)
        else
            Wait(500)
        end
    end
end)
