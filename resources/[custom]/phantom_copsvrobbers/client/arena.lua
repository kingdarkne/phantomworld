-- Phantom Cops vs Robbers - Arena/Match Logic
local inMatch = false
local currentTeam = nil
local currentMatchId = nil
local matchHUD = false

-- Match HUD
CreateThread(function()
    while true do
        Wait(0)
        if inMatch then
            DrawMatchHUD()
        end
    end
end)

function DrawMatchHUD()
    -- Team indicator
    local teamColor = currentTeam == 'cops' and { r = 0, g = 100, b = 255 } or { r = 255, g = 50, b = 50 }
    DrawRect(0.15, 0.05, 0.2, 0.06, teamColor.r, teamColor.g, teamColor.b, 180)
    DrawTxt(0.15, 0.04, 0.35, currentTeam:upper(), 4, 255, 255, 255, 255, true)

    -- Score (placeholder - would sync from server)
    DrawTxt(0.15, 0.07, 0.25, 'SCORE: 0', 4, 255, 255, 255, 255, true)

    -- Health bar
    local ped = PlayerPedId()
    local health = GetEntityHealth(ped)
    local maxHealth = GetEntityMaxHealth(ped)
    local healthPct = health / maxHealth
    DrawRect(0.5, 0.95, 0.15, 0.02, 0, 0, 0, 180)
    local r = healthPct < 0.3 and 255 or (healthPct < 0.6 and 255 or 0)
    local g = healthPct < 0.3 and 0 or (healthPct < 0.6 and 255 or 255)
    DrawRect(0.5 - (0.15 * (1 - healthPct) / 2), 0.95, 0.15 * healthPct, 0.02, r, g, 0, 200)
end

RegisterNetEvent('phantom_cvr:client:matchStarted', function(data)
    inMatch = true
    currentTeam = data.team
    currentMatchId = data.matchId
end)

RegisterNetEvent('phantom_cvr:client:matchEnded', function(data)
    inMatch = false
    currentTeam = nil
    currentMatchId = nil
end)

-- Prevent leaving arena area
CreateThread(function()
    while true do
        Wait(5000)
        if inMatch and currentArena then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local dist = #(coords - currentArena.coords)
            if dist > 200.0 then
                -- Teleport back
                SetEntityCoords(ped, currentArena.coords.x, currentArena.coords.y, currentArena.coords.z, false, false, false, false)
                lib.notify({ title = 'Stay in the arena!', type = 'error' })
            end
        end
    end
end)

function DrawTxt(x, y, scale, text, font, r, g, b, a, centered)
    SetTextFont(font)
    SetTextProportional(0)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    if centered then SetTextCentre(1) end
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(x, y)
end
