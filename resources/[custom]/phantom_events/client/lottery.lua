-- Phantom Events - Lottery Event Client

function StartLotteryEvent(data)
    lib.notify({
        title = '🎟️ LOTTERY OPEN!',
        description = 'Buy tickets with /lottery for a chance to win!',
        type = 'success',
        duration = 10000,
    })
end

-- Lottery command
RegisterCommand('lottery', function()
    local activeEvents = lib.callback.await('phantom_events:server:getActiveEvents', false)
    local lotteryActive = false
    for _, event in ipairs(activeEvents) do
        if event.type == 'lottery' then
            lotteryActive = true
            break
        end
    end

    if not lotteryActive then
        lib.notify({ title = 'No Active Lottery', type = 'error' })
        return
    end

    local confirm = lib.alertDialog({
        header = 'Buy Lottery Ticket',
        content = 'Price: $1,000 per ticket\nWant to buy a ticket?',
        cancel = true,
        labels = { confirm = 'BUY TICKET', cancel = 'Cancel' }
    })

    if confirm == 'confirm' then
        TriggerServerEvent('phantom_events:server:buyLotteryTicket')
    end
end)

RegisterNetEvent('phantom_events:client:lotteryTicketBought', function(ticketCount)
    lib.notify({
        title = '🎟️ Ticket Purchased!',
        description = 'You are in the draw! (' .. ticketCount .. ' total tickets)',
        type = 'success',
        duration = 5000,
    })
end)

RegisterNetEvent('phantom_events:client:lotteryWinner', function(data)
    ShowWinnerEffect(data.winner, data.prize)
end)
