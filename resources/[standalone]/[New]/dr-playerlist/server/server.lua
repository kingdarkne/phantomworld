local activePlayers = {}
local disconnectedPlayers = {}
local playerIds = {}
local nextPlayerId = 1

AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    local source = source
    local steamName = GetPlayerName(source)
    local playerId = nextPlayerId
    nextPlayerId = nextPlayerId + 1
    local playerIdentifier = GetPlayerIdentifier(source, 0)
    playerIds[playerIdentifier] = playerId
    local playerInfo = { name = steamName, id = playerId, steamId = playerIdentifier }
    table.insert(activePlayers, playerInfo)
    TriggerClientEvent('dr-playerlist:client:updatePlayers', -1, activePlayers, disconnectedPlayers)
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    local steamName = GetPlayerName(source)
    local playerIdentifier = GetPlayerIdentifier(source, 0)
    local playerId = playerIds[playerIdentifier]
    local playerInfo = { name = steamName, id = playerId, steamId = playerIdentifier }
    table.insert(disconnectedPlayers, playerInfo)
    table.remove(activePlayers, tableIndex(activePlayers, playerId)) 
    TriggerClientEvent('dr-playerlist:client:updatePlayers', -1, activePlayers, disconnectedPlayers)
end)

RegisterNetEvent('dr-playerlist:server:requestUpdate')
AddEventHandler('dr-playerlist:server:requestUpdate', function()
    local source = source
    TriggerClientEvent('dr-playerlist:client:updatePlayers', -1, activePlayers, disconnectedPlayers)
end)

function tableIndex(tbl, value)
    for i, v in ipairs(tbl) do
        if v.id == value then
            return i
        end
    end
    return nil
end