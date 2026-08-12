-- Phantom Cops vs Robbers - Lobby/Queue System
local QBCore = exports['qbx_core']:GetCoreObject()
local inQueue = false
local currentArena = nil
local queueTimer = 0

-- Main command
RegisterCommand('cvr', function()
    OpenArenaMenu()
end)

RegisterKeyMapping('cvr', 'Open Cops vs Robbers', 'keyboard', 'END')

-- Open arena selection menu
function OpenArenaMenu()
    local options = {}

    for _, arena in ipairs(Config.Arenas) do
        table.insert(options, {
            title = arena.name,
            description = arena.description .. '\nType: ' .. arena.type:upper() .. ' | Max: ' .. arena.maxPlayers,
            onSelect = function()
                JoinQueue(arena)
            end
        })
    end

    lib.registerContext({ id = 'cvr_arenas', title = '⚔️ Cops vs Robbers', options = options })
    lib.showContext('cvr_arenas')
end

-- Join queue
function JoinQueue(arena)
    if inQueue then
        lib.notify({ title = 'Already in Queue', type = 'error' })
        return
    end

    local success = lib.callback.await('phantom_cvr:server:joinQueue', false, arena.id)
    if success then
        inQueue = true
        currentArena = arena
        queueTimer = Config.MatchSettings.lobbyWaitTime
        lib.notify({ title = 'Joined Queue', description = arena.name .. ' - Waiting for players...', type = 'success', duration = 5000 })
        StartQueueCountdown()
    else
        lib.notify({ title = 'Queue Failed', description = 'Could not join queue', type = 'error' })
    end
end

-- Queue countdown
function StartQueueCountdown()
    CreateThread(function()
        while inQueue and queueTimer > 0 do
            Wait(1000)
            queueTimer = queueTimer - 1
        end
    end)
end

-- Leave queue
RegisterCommand('leavequeue', function()
    if inQueue then
        TriggerServerEvent('phantom_cvr:server:leaveQueue')
        inQueue = false
        currentArena = nil
        lib.notify({ title = 'Left Queue', type = 'info' })
    end
end)

-- Match starting notification
RegisterNetEvent('phantom_cvr:client:matchStarting', function(data)
    inQueue = false
    lib.notify({
        title = 'Match Starting!',
        description = data.arenaName .. ' in ' .. data.countdown .. ' seconds!',
        type = 'success',
        duration = 10000
    })
end)

-- Match started
RegisterNetEvent('phantom_cvr:client:matchStarted', function(data)
    currentArena = data.arena
    lib.notify({
        title = '⚔️ MATCH STARTED!',
        description = 'Team: ' .. data.team:upper(),
        type = 'success',
        duration = 8000
    })
end)

-- Match ended
RegisterNetEvent('phantom_cvr:client:matchEnded', function(data)
    currentArena = nil
    local winnerText = data.winner and (data.winner .. ' WINS!') or 'DRAW'
    lib.notify({
        title = '⚔️ MATCH ENDED',
        description = winnerText .. '\nYour Score: ' .. data.yourScore,
        type = data.won and 'success' or 'info',
        duration = 10000
    })
end)
