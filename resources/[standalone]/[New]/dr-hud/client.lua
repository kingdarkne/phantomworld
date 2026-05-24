local usingQbx = GetResourceState('qbx_core') == 'started'

local function getPlayerData()
    if usingQbx then
        return exports.qbx_core:GetPlayerData()
    end
    return nil
end

local function isPlayerLoggedIn()
    return LocalPlayer and LocalPlayer.state and LocalPlayer.state.isLoggedIn == true
end

-- Simple convar toggles (setr in server.cfg)
-- setr drhud:showRank 0
-- setr drhud:showJob  0
local SHOW_RANK = GetConvarInt('drhud:showRank', 1) == 1
local SHOW_JOB = GetConvarInt('drhud:showJob', 1) == 1

local function getRankFromMeta(meta)
    meta = meta or {}
    return meta.rankxp_level or meta.rank or meta.xp or 0
end

local ServerInfo = {
    serverName = GetConvar('sv_projectName', 'Server'),
    serverTime = '',
}

local VoiceInfo = {
    talking = false,
    proximity = { distance = nil, mode = nil },
}

local hudVisible = false
local function setHudVisible(visible)
    visible = visible == true
    if hudVisible == visible then return end
    hudVisible = visible
    SendNUIMessage({ action = 'setVisible', visible = visible })
end

RegisterNetEvent('dr-hud:serverInfo', function(info)
    if type(info) ~= 'table' then return end
    if info.serverName then ServerInfo.serverName = info.serverName end
    if info.serverTime then ServerInfo.serverTime = info.serverTime end
    -- push immediately so UI updates without waiting for money refresh
    if not isPlayerLoggedIn() then return end
    SendNUIMessage({
        action = 'updateServerInfo',
        serverName = ServerInfo.serverName,
        serverTime = ServerInfo.serverTime,
        playerId = GetPlayerServerId(PlayerId()),
    })
end)

local function requestServerInfo()
    TriggerServerEvent('dr-hud:requestServerInfo')
end

local function sendHudConfig()
    if not isPlayerLoggedIn() then return end
    SendNUIMessage({
        action = 'hudConfig',
        showRank = SHOW_RANK,
        showJob = SHOW_JOB,
    })
end

local function sendVoiceUpdate()
    if not isPlayerLoggedIn() then return end
    SendNUIMessage({
        action = 'voiceUpdate',
        talking = VoiceInfo.talking,
        proximity = VoiceInfo.proximity,
    })
end

local function sendHudUpdate()
    if not isPlayerLoggedIn() then return end
    local PlayerData = getPlayerData()
    if not PlayerData or not PlayerData.money then return end

    local cash = PlayerData.money.cash or 0
    local bank = PlayerData.money.bank or 0
    local meta = PlayerData.metadata or {}
    local rank = getRankFromMeta(meta)
    local job = (PlayerData.job and PlayerData.job.label) or 'Unemployed'
    local gang = 'No Gang'
    if type(PlayerData.gang) == 'table' and PlayerData.gang.label then
        gang = PlayerData.gang.label
    elseif type(PlayerData.gangs) == 'table' and type(PlayerData.gang) == 'table' and PlayerData.gang.name and PlayerData.gangs[PlayerData.gang.name] then
        gang = PlayerData.gangs[PlayerData.gang.name].label or gang
    end
    local name = PlayerData.name
    if PlayerData.charinfo and PlayerData.charinfo.firstname then
        name = (PlayerData.charinfo.firstname or '') .. ' ' .. (PlayerData.charinfo.lastname or '')
    end

    local coords = GetEntityCoords(PlayerPedId())
    local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = GetStreetNameFromHashKey(streetHash) or 'Unknown'

    SendNUIMessage({
        action = 'updateHUD',
        cash = cash,
        bank = bank,
        rank = SHOW_RANK and rank or nil,
        job = SHOW_JOB and job or nil,
        playerId = GetPlayerServerId(PlayerId()),
        serverName = ServerInfo.serverName,
        serverTime = ServerInfo.serverTime,
        playerName = name or 'Player',
        playerGang = gang,
        playerStreet = street,
    })
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000)
    setHudVisible(true)
    requestServerInfo()
    sendHudConfig()
    sendHudUpdate()
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function()
    sendHudUpdate()
end)

-- Voice widget (pma-voice if present, otherwise fallback to mumble proximity)
CreateThread(function()
    local lastTalking = nil
    local lastProxKey = nil

    while true do
        local talking = (MumbleIsPlayerTalking(PlayerId()) == 1)

        local prox = LocalPlayer.state.proximity
        local proxDistance = nil
        local proxMode = nil
        if type(prox) == 'table' then
            proxDistance = prox.distance
            proxMode = prox.mode
        end
        if proxDistance == nil then
            proxDistance = MumbleGetTalkerProximity()
        end

        local proxKey = tostring(proxMode or '') .. ':' .. tostring(proxDistance or '')

        if lastTalking ~= talking or lastProxKey ~= proxKey then
            lastTalking = talking
            lastProxKey = proxKey
            VoiceInfo.talking = talking
            VoiceInfo.proximity = { distance = proxDistance, mode = proxMode }
            sendVoiceUpdate()
        end

        Wait(200)
    end
end)

-- Periodic refresh as a fallback
CreateThread(function()
    while true do
        if isPlayerLoggedIn() then
            if not hudVisible then
                setHudVisible(true)
                sendHudConfig()
            end
            requestServerInfo()
            sendHudUpdate()
            Wait(2000)
        else
            setHudVisible(false)
            Wait(1000)
        end
    end
end)

