RegisterCommand("jomidar", function()
    print("jomidarontop")
    exports["skillchecks"]:startSameGame(100000000, 11, 8)
end)

RegisterCommand('minigame', function(source, args, rawCommand)
    local NotifySt = args[1]

    if NotifySt == '1' then
        exports['skillchecks']:startAlphabetGame(1000000, 5)
    elseif NotifySt == '2' then
        exports['skillchecks']:startDirectionGame(1000000, 2, 5, 7)
    elseif NotifySt == '3' then
        exports['skillchecks']:startFlipGame(1000000, 5)
    elseif NotifySt == '4' then
        exports['skillchecks']:startLockpickingGame(1000000, 5, 5)
    elseif NotifySt == '5' then
        exports['skillchecks']:startSameGame(1000000, 10, 10)
    elseif NotifySt == '6' then
        exports['skillchecks']:startUntangleGame(1000000, 5)
    elseif NotifySt == '7' then
        exports['skillchecks']:startWordsGame(1000000, 10)
    elseif NotifySt == '7' then
        exports['skillchecks']:startFloodGame(1000000, 5, 6)
    end
end)
