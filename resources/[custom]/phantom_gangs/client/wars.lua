-- Gang war client effects
local warActive = false
local warTimer = 0
local warScore = { us = 0, them = 0 }

-- War HUD
CreateThread(function()
    while true do
        Wait(0)
        if warActive then
            DrawWarHUD()
        end
    end
end)

function DrawWarHUD()
    -- Background
    DrawRect(0.5, 0.05, 0.25, 0.06, 0, 0, 0, 180)

    -- Title
    DrawTxt(0.5, 0.03, 0.35, '⚔️ GANG WAR', 4, 255, 50, 50, 255, true)

    -- Score
    DrawTxt(0.5, 0.055, 0.3, warScore.us .. ' - ' .. warScore.them, 4, 255, 255, 255, 255, true)

    -- Timer
    local mins = math.floor(warTimer / 60)
    local secs = warTimer % 60
    DrawTxt(0.65, 0.04, 0.25, string.format('%02d:%02d', mins, secs), 4, 255, 100, 100, 255, true)
end

RegisterNetEvent('phantom_gangs:client:warStarted', function(data)
    warActive = true
    warTimer = Config.WarSettings.duration
    warScore = { us = 0, them = 0 }

    CreateThread(function()
        while warActive and warTimer > 0 do
            Wait(1000)
            warTimer = warTimer - 1
        end
    end)
end)

RegisterNetEvent('phantom_gangs:client:warEnded', function(data)
    warActive = false
end)

RegisterNetEvent('phantom_gangs:client:warScoreUpdate', function(score)
    warScore = score
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
