local OwnerPlayers = {}

local function isOwner(src)
    if not src then return false end
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if Config.OwnerIdentifiers[id] then
            return true
        end
    end
    for _, ace in ipairs(Config.OwnerAces or {}) do
        if IsPlayerAceAllowed(src, ace) then
            return true
        end
    end
    return false
end

local function broadcastOwners()
    local payload = {}
    for src, _ in pairs(OwnerPlayers) do
        local name = GetPlayerName(src) or 'Owner'
        if GetResourceState('qbx_core') == 'started' then
            local ok, Player = pcall(function()
                return exports.qbx_core:GetPlayer(src)
            end)
            if ok and Player and Player.PlayerData and Player.PlayerData.charinfo then
                local c = Player.PlayerData.charinfo
                local full = ((c.firstname or '') .. ' ' .. (c.lastname or '')):gsub('^%s+', ''):gsub('%s+$', '')
                if full ~= '' then name = full end
            end
        end
        payload[#payload + 1] = { id = src, name = name }
    end
    TriggerClientEvent('dr-ownerlabel:client:updateOwners', -1, payload)
end

local function tryMarkOwner(src)
    if not src or OwnerPlayers[src] then return end
    if isOwner(src) then
        OwnerPlayers[src] = true
        broadcastOwners()
    end
end

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    local src = Player and Player.PlayerData and Player.PlayerData.source
    tryMarkOwner(src)
end)

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    tryMarkOwner(source)
end)

AddEventHandler('playerJoining', function()
    local src = source
    SetTimeout(3000, function()
        tryMarkOwner(src)
    end)
end)

AddEventHandler('QBCore:Server:OnPlayerUnload', function(src)
    if OwnerPlayers[src] then
        OwnerPlayers[src] = nil
        broadcastOwners()
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    if OwnerPlayers[src] then
        OwnerPlayers[src] = nil
        broadcastOwners()
    end
end)

RegisterNetEvent('dr-ownerlabel:server:requestOwners', function()
    broadcastOwners()
    tryMarkOwner(source)
end)

-- Refresh owners periodically (ACE can apply after connect)
CreateThread(function()
    while true do
        Wait(15000)
        for _, id in ipairs(GetPlayers()) do
            tryMarkOwner(tonumber(id))
        end
    end
end)
