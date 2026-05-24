-- Phantom Cops vs Robbers - Server Lobby/Queue
local queues = {}
local matches = {}
local matchCounter = 0

-- Join queue
lib.callback.register('phantom_cvr:server:joinQueue', function(source, arenaId)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return false end

    -- Find arena
    local arena = nil
    for _, a in ipairs(Config.Arenas) do
        if a.id == arenaId then arena = a break end
    end
    if not arena then return false end

    -- Initialize queue
    if not queues[arenaId] then
        queues[arenaId] = {
            players = {},
            arena = arena,
            started = false,
        }
    end

    local queue = queues[arenaId]
    if queue.started then return false end
    if #queue.players >= arena.maxPlayers then return false end

    -- Add to queue
    table.insert(queue.players, {
        source = source,
        citizenid = Player.PlayerData.citizenid,
        name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
    })

    -- Notify other queued players
    for _, p in ipairs(queue.players) do
        TriggerClientEvent('ox_lib:notify', p.source, {
            title = 'Player Joined',
            description = Player.PlayerData.charinfo.firstname .. ' joined the queue (' .. #queue.players .. '/' .. arena.maxPlayers .. ')',
            type = 'info'
        })
    end

    -- Check if enough players to start
    if #queue.players >= arena.minPlayers then
        StartMatchCountdown(arenaId)
    end

    return true
end)

-- Leave queue
RegisterNetEvent('phantom_cvr:server:leaveQueue', function()
    local src = source
    for arenaId, queue in pairs(queues) do
        for i, p in ipairs(queue.players) do
            if p.source == src then
                table.remove(queue.players, i)
                return
            end
        end
    end
end)

-- Start match countdown
function StartMatchCountdown(arenaId)
    local queue = queues[arenaId]
    if not queue or queue.started then return end

    queue.started = true
    local countdown = Config.MatchSettings.lobbyWaitTime

    -- Countdown notifications
    CreateThread(function()
        while countdown > 0 do
            for _, p in ipairs(queue.players) do
                TriggerClientEvent('phantom_cvr:client:matchStarting', p.source, {
                    arenaName = queue.arena.name,
                    countdown = countdown,
                })
            end
            Wait(1000)
            countdown = countdown - 1
        end
        StartMatch(arenaId)
    end)
end

-- Start match
function StartMatch(arenaId)
    local queue = queues[arenaId]
    if not queue then return end

    matchCounter = matchCounter + 1
    local matchId = 'match_' .. matchCounter
    local arena = queue.arena

    -- Assign teams
    local teams = AssignTeams(queue.players)

    matches[matchId] = {
        id = matchId,
        arena = arena,
        players = queue.players,
        teams = teams,
        startTime = os.time(),
        score = { cops = 0, robbers = 0 },
        round = 1,
        active = true,
    }

    -- Spawn players
    for _, player in ipairs(queue.players) do
        local team = teams[player.source]
        local spawn = team == 'cops' and arena.team1Spawn or arena.team2Spawn

        -- Teleport player
        local ped = GetPlayerPed(player.source)
        SetEntityCoords(ped, spawn.x, spawn.y, spawn.z, false, false, false, false)
        SetEntityHeading(ped, GetHeadingFromCoords(spawn, arena.coords))

        -- Give loadout
        local loadoutKey = team == 'cops' and 'cop' or 'robber'
        GiveLoadout(player.source, Config.Loadouts[loadoutKey])

        -- Notify
        TriggerClientEvent('phantom_cvr:client:matchStarted', player.source, {
            arena = arena,
            team = team,
            matchId = matchId,
        })
    end

    -- Clear queue
    queues[arenaId] = nil

    -- Start round timer
    StartRoundTimer(matchId)

    print('^2[Phantom CVR]^7 Match started: ' .. arena.name .. ' (' .. #queue.players .. ' players)')
end

-- Assign teams
function AssignTeams(players)
    local teams = {}
    local shuffled = {}
    for _, p in ipairs(players) do table.insert(shuffled, p) end

    -- Shuffle
    for i = #shuffled, 2, -1 do
        local j = math.random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end

    -- Split
    local half = math.floor(#shuffled / 2)
    for i = 1, #shuffled do
        if i <= half then
            teams[shuffled[i].source] = 'cops'
        else
            teams[shuffled[i].source] = 'robbers'
        end
    end

    return teams
end

-- Give loadout
function GiveLoadout(source, loadout)
    local ped = GetPlayerPed(source)
    -- Remove all weapons
    RemoveAllPedWeapons(ped, true)

    -- Give weapons
    for _, weapon in ipairs(loadout.weapons) do
        local hash = GetHashKey(weapon.name)
        GiveWeaponToPed(ped, hash, weapon.ammo, false, false)
    end

    -- Set skin (optional)
    if loadout.skin then
        -- Would need to handle skin change
    end
end

-- Round timer
function StartRoundTimer(matchId)
    local match = matches[matchId]
    if not match then return end

    CreateThread(function()
        Wait(match.arena.roundTime * 1000)
        EndMatch(matchId, nil) -- Time limit
    end)
end

-- End match
function EndMatch(matchId, winner)
    local match = matches[matchId]
    if not match or not match.active then return end

    match.active = false

    -- Determine winner
    if not winner then
        if match.score.cops > match.score.robbers then
            winner = 'cops'
        elseif match.score.robbers > match.score.cops then
            winner = 'robbers'
        else
            winner = 'draw'
        end
    end

    -- Notify players and give rewards
    for _, player in ipairs(match.players) do
        local team = match.teams[player.source]
        local won = (winner ~= 'draw' and team == winner)

        TriggerClientEvent('phantom_cvr:client:matchEnded', player.source, {
            winner = winner == 'draw' and 'DRAW' or winner:upper(),
            yourScore = match.score[team] or 0,
            won = won,
        })

        -- Give rewards
        local Player = exports.qbx_core:GetPlayer(player.source)
        if Player then
            local reward = won and Config.Rewards.winMoney or Config.Rewards.lossMoney
            Player.Functions.AddMoney('cash', reward, 'cvr-match')
        end
    end

    matches[matchId] = nil
    print('^2[Phantom CVR]^7 Match ended: ' .. match.arena.name .. ' - Winner: ' .. tostring(winner))
end

-- Score update
RegisterNetEvent('phantom_cvr:server:scoreUpdate', function(matchId, team, points)
    local match = matches[matchId]
    if not match or not match.active then return end

    if match.score[team] then
        match.score[team] = match.score[team] + points
    end
end)

-- Helper
function GetHeadingFromCoords(from, to)
    return math.deg(math.atan2(to.y - from.y, to.x - from.x)) + 90.0
end
