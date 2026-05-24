CreateThread(function()
    while not NetworkIsSessionStarted() do
        Wait(250)
    end

    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
end)
