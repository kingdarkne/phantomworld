local QBCore = exports['qbx_core']:GetCoreObject()

-- Store player data for blips
local playerData = {}

-- Get player job data
function GetPlayerJob(playerId)
    local Player = QBCore.Functions.GetPlayer(playerId)
    if not Player then return 'unknown' end
    
    return Player.PlayerData.job.name
end

-- Get player name
function GetPlayerName(playerId)
    local Player = QBCore.Functions.GetPlayer(playerId)
    if not Player then return 'Unknown' end
    
    return Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
end

-- Get all player data for blips
function GetAllPlayerData()
    local data = {}
    
    for _, playerId in ipairs(GetPlayers()) do
        local id = tonumber(playerId)
        data[id] = {
            name = GetPlayerName(id),
            job = GetPlayerJob(id),
            coords = GetEntityCoords(GetPlayerPed(id))
        }
    end
    
    return data
end

-- Update player data
function UpdatePlayerData(playerId)
    local id = tonumber(playerId)
    playerData[id] = {
        name = GetPlayerName(id),
        job = GetPlayerJob(id),
        coords = GetEntityCoords(GetPlayerPed(id))
    }
end

-- Remove player data
function RemovePlayerData(playerId)
    local id = tonumber(playerId)
    playerData[id] = nil
end

-- Check if player is admin
function IsPlayerAdmin(playerId)
    return QBCore.Functions.HasPermission(playerId, 'admin')
end

-- Send player data to clients
function SendPlayerDataToClients()
    local data = GetAllPlayerData()
    
    for _, playerId in ipairs(GetPlayers()) do
        local id = tonumber(playerId)
        local isAdmin = IsPlayerAdmin(id)
        
        -- Send all player data to admins
        if isAdmin then
            TriggerClientEvent('player-blips:client:UpdateAllPlayers', id, data)
        else
            -- Send only nearby player data to regular players
            local nearbyData = GetNearbyPlayerData(id)
            TriggerClientEvent('player-blips:client:UpdateNearbyPlayers', id, nearbyData)
        end
    end
end

-- Get nearby players
function GetNearbyPlayerData(playerId)
    local nearby = {}
    local playerPed = GetPlayerPed(playerId)
    local playerCoords = GetEntityCoords(playerPed)
    
    for id, data in pairs(playerData) do
        if id ~= playerId then
            local distance = #(playerCoords - data.coords)
            if distance <= 500.0 then -- 500 meters
                nearby[id] = data
            end
        end
    end
    
    return nearby
end

-- Events
RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
    local playerId = Player.PlayerData.source
    UpdatePlayerData(playerId)
end)

RegisterNetEvent('QBCore:Server:OnJobUpdate', function(source, job)
    UpdatePlayerData(source)
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    RemovePlayerData(source)
end)

-- Update loop
CreateThread(function()
    while true do
        SendPlayerDataToClients()
        Wait(5000) -- Update every 5 seconds
    end
end)

-- Commands
QBCore.Commands.Add('playerblips', 'Toggle player blips visibility', {}, false, function(source, args)
    TriggerClientEvent('player-blips:client:ToggleBlips', source)
end)

QBCore.Commands.Add('adminblips', 'Show all player blips (Admin Only)', {}, false, function(source, args)
    if not IsPlayerAdmin(source) then
        TriggerClientEvent('QBCore:Notify', source, 'You don\'t have permission to use this command!', 'error')
        return
    end
    
    local data = GetAllPlayerData()
    TriggerClientEvent('player-blips:client:UpdateAllPlayers', source, data)
    TriggerClientEvent('QBCore:Notify', source, 'Showing all player blips', 'success')
end)

-- Exports
exports('GetAllPlayerData', GetAllPlayerData)
exports('GetNearbyPlayerData', GetNearbyPlayerData)
exports('IsPlayerAdmin', IsPlayerAdmin)
exports('UpdatePlayerData', UpdatePlayerData)
