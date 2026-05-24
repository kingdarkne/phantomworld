-- Additional notification effects

function ShowEventCountdown(seconds)
    -- Big countdown display
    CreateThread(function()
        local startTime = GetGameTimer()
        while GetGameTimer() - startTime < seconds * 1000 do
            Wait(0)
            local remaining = seconds - math.floor((GetGameTimer() - startTime) / 1000)
            if remaining <= 10 and remaining > 0 then
                DrawTxt(0.5, 0.4, 1.5, tostring(remaining), 4, 255, 255, 255, 255, true)
                DrawTxt(0.5, 0.5, 0.5, 'EVENT STARTING...', 4, 255, 215, 0, 255, true)
            end
        end
    end)
end

function ShowWinnerEffect(winnerName, prize)
    -- Big winner announcement
    CreateThread(function()
        local startTime = GetGameTimer()
        while GetGameTimer() - startTime < 5000 do
            Wait(0)
            DrawTxt(0.5, 0.35, 0.8, '🎉 WINNER! 🎉', 4, 255, 215, 0, 255, true)
            DrawTxt(0.5, 0.42, 1.0, winnerName, 4, 0, 255, 100, 255, true)
            DrawTxt(0.5, 0.5, 0.6, 'WON $' .. prize, 4, 255, 255, 255, 255, true)
        end
    end)

    -- Celebration effects
    StartScreenEffect('HeistCelebPass', 0, false)
    Wait(3000)
    StopScreenEffect('HeistCelebPass')
end
