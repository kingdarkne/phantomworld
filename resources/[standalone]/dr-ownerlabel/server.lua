local OwnerPlayers = {}

local function isOwnerIdentifier(src)
    -- Check multiple identifier types, but we primarily care about fivem:****
    -- Fallback: scan all identifiers if needed
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if Config.OwnerIdentifiers[id] then
            return true
        end
    end
    return false
end

local function broadcastOwners()
    -- Build a compact table of owners and their display names
    local payload = {}
    for src, _ in pairs(OwnerPlayers) do
        local Player = exports.qbx_core:GetPlayer(src)
        if Player then
            local charinfo = Player.PlayerData.charinfo or {}
            local firstname = charinfo.firstname or 'Unknown'
            local lastname = charinfo.lastname or ''
            local fullName = (firstname .. ' ' .. lastname):gsub('%s+$', '')
            payload[#payload + 1] = {
                id = src,
                name = fullName,
            }
        end
    end
    TriggerClientEvent('dr-ownerlabel:client:updateOwners', -1, payload)
end

AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    local src = Player.PlayerData.source
    if isOwnerIdentifier(src) then
        OwnerPlayers[src] = true
        broadcastOwners()
    end
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
    local src = source
    broadcastOwners()
end)

