-- Scoreboard system
local scoreboardOpen = false

-- Toggle scoreboard with TAB
CreateThread(function()
    while true do
        Wait(0)
        if inMatch then
            if IsControlJustPressed(0, 199) then -- P pause key, or could use other
                -- scoreboardOpen = not scoreboardOpen
            end
        end
    end
end)

RegisterCommand('scoreboard', function()
    if inMatch then
        -- Would show detailed scoreboard
    end
end)
