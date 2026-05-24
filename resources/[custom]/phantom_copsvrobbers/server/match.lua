-- Match management (core in lobby.lua)
-- Additional match logic

-- Player death in match
AddEventHandler('onPlayerDeath', function(data)
    local victim = source
    if data.killerServerId then
        local killer = data.killerServerId
        -- Award kill in active match
        for matchId, match in pairs(matches) do
            if match.active then
                for _, player in ipairs(match.players) do
                    if player.source == victim then
                        local victimTeam = match.teams[victim]
                        local killerTeam = match.teams[killer]
                        if victimTeam and killerTeam and victimTeam ~= killerTeam then
                            match.score[killerTeam] = (match.score[killerTeam] or 0) + Config.Rewards.killXP
                            -- Notify
                            TriggerClientEvent('phantom_cvr:client:scoreUpdate', -1, {
                                team = killerTeam,
                                score = match.score[killerTeam]
                            })
                        end

                        -- Start spectator
                        TriggerClientEvent('phantom_cvr:client:startSpectate', victim)
                        break
                    end
                end
            end
        end
    end
end)

-- Respawn timer
RegisterNetEvent('phantom_cvr:server:requestRespawn', function()
    for matchId, match in pairs(matches) do
        if match.active then
            for _, player in ipairs(match.players) do
                if player.source == source then
                    -- Respawn at team spawn
                    local team = match.teams[source]
                    local spawn = team == 'cops' and match.arena.team1Spawn or match.arena.team2Spawn
                    local ped = GetPlayerPed(source)
                    SetEntityCoords(ped, spawn.x, spawn.y, spawn.z, false, false, false, false)
                    -- Restore loadout
                    local loadoutKey = team == 'cops' and 'cop' or 'robber'
                    GiveLoadout(source, Config.Loadouts[loadoutKey])
                    TriggerClientEvent('phantom_cvr:client:stopSpectate', source)
                    return
                end
            end
        end
    end
end)
