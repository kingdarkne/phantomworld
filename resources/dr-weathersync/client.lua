-- Forwards dr-weathersync client events to qb-weathersync (provided by Renewed-Weathersync).

RegisterNetEvent('dr-weathersync:client:DisableSync', function()
    TriggerEvent('qb-weathersync:client:DisableSync')
end)

RegisterNetEvent('dr-weathersync:client:EnableSync', function()
    TriggerEvent('qb-weathersync:client:EnableSync')
end)

RegisterNetEvent('dr-weathersync:client:SyncWeather', function(weather, blackout)
    TriggerEvent('qb-weathersync:client:SyncWeather', weather, blackout)
end)

RegisterNetEvent('dr-weathersync:client:SyncTime', function(base, offset, freeze)
    TriggerEvent('qb-weathersync:client:SyncTime', base, offset, freeze)
end)
