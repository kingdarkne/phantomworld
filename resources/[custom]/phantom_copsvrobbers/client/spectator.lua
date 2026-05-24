-- Spectator mode for dead players
local spectating = false
local spectateTarget = nil

RegisterNetEvent('phantom_cvr:client:startSpectate', function()
    if not Config.MatchSettings.spectatorEnabled then return end
    spectating = true

    -- Find alive player to spectate
    local players = GetActivePlayers()
    for _, player in ipairs(players) do
        local ped = GetPlayerPed(player)
        if IsEntityDead(ped) == false then
            spectateTarget = player
            NetworkSetInSpectatorMode(true, ped)
            break
        end
    end

    lib.notify({ title = 'Spectator Mode', description = 'Use [A]/[D] to switch players', type = 'info', duration = 5000 })
end)

-- Cycle spectate targets
CreateThread(function()
    while true do
        Wait(0)
        if spectating then
            if IsControlJustPressed(0, 34) then -- A - previous
                -- Cycle backwards
            elseif IsControlJustPressed(0, 35) then -- D - next
                -- Cycle forward
            end
        end
    end
end)

RegisterNetEvent('phantom_cvr:client:stopSpectate', function()
    spectating = false
    spectateTarget = nil
    NetworkSetInSpectatorMode(false, nil)
end)
