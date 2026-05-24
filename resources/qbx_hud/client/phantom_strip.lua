--[[
  Phantom bottom-right strip: server name, time, ID, rank, job, voice (Qbox player data).
  Hides while pause menu or any NUI menu has focus (inventory, phone, ox_lib, etc.).
]]

local function isOtherMenuOpen()
    return IsPauseMenuActive() or IsNuiFocused()
end

local SHOW_RANK = GetConvarInt('qbx_hud:showRank', 1) == 1
local SHOW_JOB = GetConvarInt('qbx_hud:showJob', 1) == 1

local function getRankFromMeta(meta)
    meta = meta or {}
    return meta.rankxp_level or meta.rank or meta.xp or 0
end

local function sendPhantomInfo()
    if not LocalPlayer.state.isLoggedIn then return end
    if isOtherMenuOpen() then return end
    local pd = QBX.PlayerData
    if not pd or not pd.money then return end

    local meta = pd.metadata or {}
    local rank = getRankFromMeta(meta)
    local job = (pd.job and pd.job.label) or 'Unemployed'
    local gang = '—'
    if type(pd.gang) == 'table' and pd.gang.label then
        gang = pd.gang.label
    end

    local name = pd.name
    if pd.charinfo and pd.charinfo.firstname then
        name = (pd.charinfo.firstname or '') .. ' ' .. (pd.charinfo.lastname or '')
    end

    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = GetStreetNameFromHashKey(streetHash) or 'Unknown'

    SendNUIMessage({
        action = 'phantomInfo',
        visible = true,
        showRank = SHOW_RANK,
        showJob = SHOW_JOB,
        rank = rank,
        job = job,
        gang = gang,
        playerName = (name and name:gsub('^%s+', ''):gsub('%s+$', '')) or 'Player',
        playerStreet = street,
        playerId = cache.serverId,
        cash = pd.money.cash or 0,
        bank = pd.money.bank or 0,
    })
end

RegisterNetEvent('qbx_hud:client:serverInfo', function(info)
    if type(info) ~= 'table' then return end
    SendNUIMessage({
        action = 'phantomInfo',
        serverName = info.serverName,
        serverTime = info.serverTime,
    })
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000)
    TriggerServerEvent('qbx_hud:requestServerInfo')
    sendPhantomInfo()
    local pd = QBX.PlayerData
    if pd and pd.money then
        SendNUIMessage({ action = 'showconstant', cash = pd.money.cash, bank = pd.money.bank })
    end
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function()
    sendPhantomInfo()
end)

RegisterNetEvent('hud:client:OnMoneyChange', function()
    sendPhantomInfo()
end)

RegisterNetEvent('hud:client:ShowAccounts', function()
    sendPhantomInfo()
end)

CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn then
            TriggerServerEvent('qbx_hud:requestServerInfo')
            Wait(30000)
        else
            Wait(5000)
        end
    end
end)

CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn then
            sendPhantomInfo()
            Wait(1500)
        else
            SendNUIMessage({ action = 'phantomInfo', visible = false })
            SendNUIMessage({ action = 'topRightStack', visible = false })
            Wait(1000)
        end
    end
end)

--- Hide strip immediately when a menu opens; show again when menus close.
CreateThread(function()
    local wasBlocked = false
    while true do
        local blocked = LocalPlayer.state.isLoggedIn and isOtherMenuOpen()
        if blocked ~= wasBlocked then
            wasBlocked = blocked
            if blocked then
                SendNUIMessage({ action = 'phantomInfo', visible = false })
                SendNUIMessage({ action = 'topRightStack', visible = false })
            else
                SendNUIMessage({ action = 'topRightStack', visible = true })
                sendPhantomInfo()
            end
        end
        Wait(100)
    end
end)

CreateThread(function()
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
                local label = mode and (tostring(mode) .. (dist and (' · ' .. math.floor(dist)) .. 'm' or '')) or 'VOICE'
                SendNUIMessage({
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
