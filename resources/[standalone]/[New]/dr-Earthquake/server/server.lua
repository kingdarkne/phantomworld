if Config.TxAdminRestart then
    AddEventHandler('txAdmin:events:scheduledRestart', function(eventData)
        local minutesRemaining = math.floor(eventData.secondsRemaining / 60)
        if 5 >= minutesRemaining then
            if minutesRemaining >= 1 then
                TriggerClientEvent("dr-Earthquake:TxAdmin", -1, minutesRemaining)
            end
        end
    end)
end

if Config.Random then
    CreateThread(function()
        while true do
            Wait(math.random(Config.RandomOptions.min, Config.RandomOptions.max))
            TriggerClientEvent("dr-Earthquake:Random", -1)
        end
    end)
end

RegisterCommand(Config.EarthquakeCommand, function(source, args, rawCommand)
    if (source == 0) then
        TriggerClientEvent("dr-Earthquake:Random", -1)
    end
end, false)