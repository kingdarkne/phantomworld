-- Phantom Gangs - War System
local activeWars = {}
local warCooldowns = {}

-- Declare war
RegisterNetEvent('phantom_gangs:server:declareWar', function(attackerId, defenderId)
    local src = source

    if activeWars[attackerId] or activeWars[defenderId] then
        TriggerClientEvent('ox_lib:notify', src, { title = 'War in Progress', description = 'One of the gangs is already in a war', type = 'error' })
        return
    end

    if warCooldowns[attackerId] and warCooldowns[attackerId] > os.time() then
        TriggerClientEvent('ox_lib:notify', src, { title = 'War Cooldown', description = 'Your gang must wait before declaring another war', type = 'error' })
        return
    end

    local attacker = gangs[attackerId]
    local defender = gangs[defenderId]
    if not attacker or not defender then return end

    -- Check min members
    local attackerOnline = 0
    local defenderOnline = 0
    local players = GetPlayers()

    for _, playerId in ipairs(players) do
        local p = exports.qbx_core:GetPlayer(tonumber(playerId))
        if p then
            local pGang = GetPlayerGangId(p.PlayerData.citizenid)
            if pGang == attackerId then attackerOnline = attackerOnline + 1 end
            if pGang == defenderId then defenderOnline = defenderOnline + 1 end
        end
    end

    if attackerOnline < Config.WarSettings.minMembers or defenderOnline < Config.WarSettings.minMembers then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Not Enough Members', description = 'Need at least ' .. Config.WarSettings.minMembers .. ' members online on each side', type = 'error' })
        return
    end

    -- Start war
    local warId = attackerId .. '_vs_' .. defenderId .. '_' .. os.time()
    activeWars[attackerId] = warId
    activeWars[defenderId] = warId

    local warData = {
        id = warId,
        attacker = attackerId,
        defender = defenderId,
        attackerName = attacker.name,
        defenderName = defender.name,
        startTime = os.time(),
        score = { attacker = 0, defender = 0 },
        kills = {},
        captures = {},
    }

    -- Notify all gang members
    for _, playerId in ipairs(players) do
        local p = exports.qbx_core:GetPlayer(tonumber(playerId))
        if p then
            local pGang = GetPlayerGangId(p.PlayerData.citizenid)
            if pGang == attackerId or pGang == defenderId then
                TriggerClientEvent('phantom_gangs:client:warStarted', tonumber(playerId), {
                    attacker = attacker.name,
                    defender = defender.name,
                    warId = warId,
                })
            end
        end
    end

    -- End war timer
    CreateThread(function()
        Wait(Config.WarSettings.duration * 1000)
        EndWar(warId)
    end)

    print('^1[Phantom Gangs]^7 WAR: ' .. attacker.name .. ' vs ' .. defender.name)
end)

-- End war
function EndWar(warId)
    for gangId, wId in pairs(activeWars) do
        if wId == warId then
            activeWars[gangId] = nil
        end
    end

    -- Find war data (simplified - in real implementation store in table)
    -- For now just notify it's over
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        TriggerClientEvent('phantom_gangs:client:warEnded', tonumber(playerId), {
            winner = nil,
            score = '0 - 0',
        })
    end

    warCooldowns[gangId] = os.time() + Config.WarSettings.cooldown
end

-- War kill tracking
RegisterNetEvent('phantom_gangs:server:warKill', function(victimId)
    local src = source
    local killerPlayer = exports.qbx_core:GetPlayer(src)
    local victimPlayer = exports.qbx_core:GetPlayer(victimId)
    if not killerPlayer or not victimPlayer then return end

    local killerGang = GetPlayerGangId(killerPlayer.PlayerData.citizenid)
    local victimGang = GetPlayerGangId(victimPlayer.PlayerData.citizenid)
    if not killerGang or not victimGang then return end
    if killerGang == victimGang then return end

    -- Check if in war
    if activeWars[killerGang] and activeWars[killerGang] == activeWars[victimGang] then
        -- Award points
        -- Simplified - broadcast score update
        TriggerClientEvent('phantom_gangs:client:warScoreUpdate', -1, {
            killer = killerGang,
            victim = victimGang,
        })
    end
end)

-- Player death handler
AddEventHandler('onPlayerDeath', function(data)
    local victim = source
    if data.killerServerId then
        TriggerEvent('phantom_gangs:server:warKill', victim)
    end
end)
