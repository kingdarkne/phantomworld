-- Event-specific server logic

-- Money Drop: Give money when player picks up bag
RegisterNetEvent('phantom_events:server:collectMoneyBag', function(amount)
    local src = source
    if not IsEventActive('moneyDrop') then return end

    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end

    Player.Functions.AddMoney('cash', amount, 'event-money-drop')
    TriggerClientEvent('phantom_events:client:collectedMoney', src, amount)
end)

-- Free Cars: Track claimed cars
RegisterNetEvent('phantom_events:server:claimFreeCar', function(vehicleModel)
    local src = source
    if not IsEventActive('freeCars') then return end

    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end

    local cid = Player.PlayerData.citizenid
    if not playerEventData[cid] then playerEventData[cid] = {} end
    if not playerEventData[cid].freeCars then playerEventData[cid].freeCars = 0 end

    if playerEventData[cid].freeCars >= Config.Events.freeCars.maxCarsPerPlayer then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Limit Reached', description = 'Max ' .. Config.Events.freeCars.maxCarsPerPlayer .. ' free cars!', type = 'error' })
        return
    end

    playerEventData[cid].freeCars = playerEventData[cid].freeCars + 1

    -- Save to garage (placeholder - integrate with your garage system)
    TriggerClientEvent('phantom_events:client:carClaimed', src, vehicleModel)
    TriggerClientEvent('ox_lib:notify', src, { title = 'Free Car Claimed!', description = vehicleModel:upper() .. ' added!', type = 'success' })
end)

-- Treasure Hunt: Give reward
RegisterNetEvent('phantom_events:server:openTreasure', function(treasureId)
    local src = source
    if not IsEventActive('treasureHunt') then return end

    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end

    -- Roll reward
    local roll = math.random(100)
    local cumulative = 0
    local reward = nil

    for _, r in ipairs(Config.Events.treasureHunt.rewards) do
        cumulative = cumulative + r.chance
        if roll <= cumulative then
            reward = r
            break
        end
    end

    if not reward then reward = Config.Events.treasureHunt.rewards[1] end

    local amount = math.random(reward.min, reward.max)
    Player.Functions.AddMoney('cash', amount, 'event-treasure')

    TriggerClientEvent('phantom_events:client:treasureOpened', src, amount)
end)

-- Lottery: Buy ticket
RegisterNetEvent('phantom_events:server:buyLotteryTicket', function()
    local src = source
    if not IsEventActive('lottery') then
        TriggerClientEvent('ox_lib:notify', src, { title = 'No Active Lottery', type = 'error' })
        return
    end

    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end

    local ticketPrice = Config.Events.lottery.ticketPrice
    if Player.PlayerData.money.cash < ticketPrice then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Insufficient Funds', description = 'Need $' .. ticketPrice, type = 'error' })
        return
    end

    Player.Functions.RemoveMoney('cash', ticketPrice, 'lottery-ticket')

    -- Add to lottery pool
    local event = activeEvents['lottery']
    if not event.tickets then event.tickets = {} end
    table.insert(event.tickets, {
        citizenid = Player.PlayerData.citizenid,
        name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        source = src,
    })

    -- Add to prize pool
    event.prizePool = (event.prizePool or Config.Events.lottery.defaultPrize) + math.floor(ticketPrice * 0.8)

    TriggerClientEvent('phantom_events:client:lotteryTicketBought', src, #event.tickets)
end)

-- Lottery: Draw winner (called when event ends or admin forces it)
RegisterNetEvent('phantom_events:server:drawLottery', function()
    local src = source
    if not IsAdmin(src) then return end

    local event = activeEvents['lottery']
    if not event or not event.tickets or #event.tickets == 0 then
        TriggerClientEvent('ox_lib:notify', src, { title = 'No Tickets Sold', type = 'error' })
        return
    end

    -- Pick winner
    local winner = event.tickets[math.random(#event.tickets)]
    local prize = event.prizePool or Config.Events.lottery.defaultPrize

    -- Pay winner
    local Player = exports.qbx_core:GetPlayer(winner.source)
    if Player then
        Player.Functions.AddMoney('bank', prize, 'lottery-win')
    end

    -- Announce
    TriggerClientEvent('phantom_events:client:lotteryWinner', -1, {
        winner = winner.name,
        prize = prize,
        totalTickets = #event.tickets,
    })

    -- End event
    EndEvent('lottery')
end)
