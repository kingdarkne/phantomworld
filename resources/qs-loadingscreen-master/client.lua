local ClientLoadPlayer = false

AddEventHandler('playerSpawned', function()
    if not ClientLoadPlayer then
        ShutdownLoadingScreenNui()
        ClientLoadPlayer = true
        DoScreenFadeOut(0)
        Wait(3000)
        DoScreenFadeIn(2500)
    end
end)