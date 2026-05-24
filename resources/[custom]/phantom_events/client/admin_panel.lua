-- Admin panel (NUI interactions in main.lua)
-- This file handles additional admin client features

-- Quick admin commands for events
RegisterCommand('moneyrain', function(source, args)
    local amount = tonumber(args[1]) or Config.Events.moneyDrop.defaultAmount
    local duration = tonumber(args[2]) or Config.Events.moneyDrop.defaultDuration
    TriggerServerEvent('phantom_events:server:startEvent', 'moneyDrop', { amount = amount, duration = duration })
end)

RegisterCommand('freecars', function(source, args)
    local duration = tonumber(args[1]) or Config.Events.freeCars.defaultDuration
    TriggerServerEvent('phantom_events:server:startEvent', 'freeCars', { duration = duration })
end)

RegisterCommand('doublexp', function(source, args)
    local duration = tonumber(args[1]) or Config.Events.doubleXP.defaultDuration
    TriggerServerEvent('phantom_events:server:startEvent', 'doubleXP', { duration = duration })
end)

RegisterCommand('doublepay', function(source, args)
    local duration = tonumber(args[1]) or Config.Events.doublePayday.defaultDuration
    TriggerServerEvent('phantom_events:server:startEvent', 'doublePayday', { duration = duration })
end)

RegisterCommand('treasurehunt', function(source, args)
    local duration = tonumber(args[1]) or Config.Events.treasureHunt.defaultDuration
    TriggerServerEvent('phantom_events:server:startEvent', 'treasureHunt', { duration = duration })
end)

RegisterCommand('lottery', function(source, args)
    local prize = tonumber(args[1]) or Config.Events.lottery.defaultPrize
    local duration = tonumber(args[2]) or Config.Events.lottery.defaultDuration
    TriggerServerEvent('phantom_events:server:startEvent', 'lottery', { prize = prize, duration = duration })
end)

RegisterCommand('viphour', function(source, args)
    local duration = tonumber(args[1]) or Config.Events.vipBonus.defaultDuration
    TriggerServerEvent('phantom_events:server:startEvent', 'vipBonus', { duration = duration })
end)

RegisterCommand('stopevent', function(source, args)
    local eventType = args[1]
    if eventType then
        TriggerServerEvent('phantom_events:server:stopEvent', eventType)
    else
        lib.notify({ title = 'Usage', description = '/stopevent [eventType]', type = 'info' })
    end
end)

-- Lottery draw command
RegisterCommand('drawlottery', function(source)
    TriggerServerEvent('phantom_events:server:drawLottery')
end)
