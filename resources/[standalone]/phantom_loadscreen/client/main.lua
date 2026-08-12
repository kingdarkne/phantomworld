-- Soft handoff: Afterlife LoadResource already calls ShutdownLoadingScreen.
-- Keep this light so the NUI can react to native load progress only.

CreateThread(function()
    while true do
        if not GetIsLoadingScreenActive() then
            break
        end
        Wait(500)
    end
end)
