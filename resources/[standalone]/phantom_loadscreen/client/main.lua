-- Soft handoff: Afterlife LoadResource calls ShutdownLoadingScreen.
-- Failsafe: never leave the player stuck on the native/NUI loadscreen.

CreateThread(function()
    local deadline = GetGameTimer() + 90000
    while GetIsLoadingScreenActive() and GetGameTimer() < deadline do
        Wait(500)
    end
    if GetIsLoadingScreenActive() then
        print('[phantom_loadscreen] failsafe shutdown after 90s')
        ShutdownLoadingScreen()
        ShutdownLoadingScreenNui()
    end
end)
