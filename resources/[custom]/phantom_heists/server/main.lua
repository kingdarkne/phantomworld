-- Phantom Heists - Server Main
local activeHeists = {}
local heistCooldowns = {}
local heistLog = {}

-- Check cooldown
lib.callback.register('phantom_heists:server:checkCooldown', function(source, heistId)
    if not heistCooldowns[heistId] then return true end
    local remaining = heistCooldowns[heistId] - os.time()
    return remaining <= 0
end)

-- Get police count
lib.callback.register('phantom_heists:server:getPoliceCount', function(source)
    local count = 0
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local Player = exports.qbx_core:GetPlayer(tonumber(playerId))
        if Player and Player.PlayerData.job.name == 'police' then
            count = count + 1
        end
    end
    return count
end)

-- Start heist
lib.callback.register('phantom_heists:server:startHeist', function(source, heistId)
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return false end

    -- Find heist config
    local heistConfig = nil
    for _, h in ipairs(Config.Heists) do
        if h.id == heistId then
            heistConfig = h
            break
        end
    end
    if not heistConfig then return false end

    -- Check cooldown
    if heistCooldowns[heistId] and heistCooldowns[heistId] > os.time() then
        return false
    end

    -- Check/setup cost
    local cash = Player.PlayerData.money.cash
    if cash < heistConfig.setupCost then
        TriggerClientEvent('ox_lib:notify', source, { title = 'Insufficient Funds', description = 'Need $' .. heistConfig.setupCost, type = 'error' })
        return false
    end

    -- Deduct setup cost
    Player.Functions.RemoveMoney('cash', heistConfig.setupCost, 'heist-setup')

    -- Start heist
    activeHeists[heistId] = {
        id = heistId,
        starter = source,
        starterName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        startTime = os.time(),
        phase = 'hack',
        loot = 0,
        policeAlerted = false,
        policeAlertTime = nil,
        completed = false,
    }

    -- Set cooldown
    heistCooldowns[heistId] = os.time() + (heistConfig.cooldown * 60)

    -- Log
    table.insert(heistLog, {
        heistId = heistId,
        player = Player.PlayerData.citizenid,
        time = os.time(),
        type = 'start',
    })

    -- Notify all players in heist (solo for now, can expand to crews)
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Heist Started',
        description = heistConfig.name .. ' heist is active!',
        type = 'info',
        duration = 8000
    })

    -- Schedule police alert
    CreateThread(function()
        Wait((heistConfig.policeDelay or 30) * 1000)
        local heist = activeHeists[heistId]
        if heist and not heist.completed then
            AlertPolice(heistId, heistConfig)
        end
    end)

    return true
end)

-- Heist complete
RegisterNetEvent('phantom_heists:server:heistComplete', function(heistId, lootAmount)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end

    local heist = activeHeists[heistId]
    if not heist or heist.completed then return end

    heist.completed = true
    heist.loot = lootAmount

    -- Calculate payout
    local heistConfig = nil
    for _, h in ipairs(Config.Heists) do
        if h.id == heistId then heistConfig = h break end
    end
    if not heistConfig then return end

    local payoutPerBag = math.random(heistConfig.payoutMin, heistConfig.payoutMax) / 3
    local totalPayout = math.floor(payoutPerBag * lootAmount)

    -- Add money
    Player.Functions.AddMoney('cash', totalPayout, 'heist-payout')

    -- Update database
    MySQL.insert('INSERT INTO phantom_heists_log (citizenid, heist_id, heist_name, loot_amount, payout, completed_at) VALUES (?, ?, ?, ?, ?, ?)', {
        Player.PlayerData.citizenid,
        heistId,
        heistConfig.name,
        lootAmount,
        totalPayout,
        os.time()
    })

    -- Notify
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Heist Payout',
        description = 'You received $' .. totalPayout .. ' for ' .. lootAmount .. ' bags!',
        type = 'success',
        duration = 10000
    })

    -- Notify police heist is over
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local p = exports.qbx_core:GetPlayer(tonumber(playerId))
        if p and p.PlayerData.job.name == 'police' then
            TriggerClientEvent('ox_lib:notify', tonumber(playerId), {
                title = 'Heist Update',
                description = heistConfig.name .. ' - Suspects escaped!',
                type = 'info',
                duration = 8000
            })
        end
    end
end)

-- Trigger alarm early
RegisterNetEvent('phantom_heists:server:triggerAlarm', function(heistId, early)
    local heist = activeHeists[heistId]
    if not heist or heist.policeAlerted then return end

    local heistConfig = nil
    for _, h in ipairs(Config.Heists) do
        if h.id == heistId then heistConfig = h break end
    end
    if not heistConfig then return end

    AlertPolice(heistId, heistConfig, early)
end)

-- Alert police function
function AlertPolice(heistId, heistConfig, early)
    local heist = activeHeists[heistId]
    if not heist or heist.policeAlerted then return end

    heist.policeAlerted = true
    heist.policeAlertTime = os.time()

    local alertData = {
        title = Config.Dispatch.alertTitle,
        message = Config.Dispatch.alertMessage:gsub('{location}', heistConfig.name),
        location = heistConfig.name,
        coords = heistConfig.coords,
        heistId = heistId,
    }

    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local p = exports.qbx_core:GetPlayer(tonumber(playerId))
        if p and p.PlayerData.job.name == 'police' then
            TriggerClientEvent('phantom_heists:client:policeAlert', tonumber(playerId), alertData)
        end
    end

    print('^1[Phantom Heists]^7 Police alerted for ' .. heistConfig.name .. (early and ' (EARLY)' or ''))
end

-- Heist failed/cancelled cleanup
AddEventHandler('playerDropped', function()
    local src = source
    for heistId, heist in pairs(activeHeists) do
        if heist.starter == src and not heist.completed then
            activeHeists[heistId] = nil
            print('^3[Phantom Heists]^7 Heist ' .. heistId .. ' cancelled - player disconnected')
        end
    end
end)

-- Database init
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS phantom_heists_log (
                id INT AUTO_INCREMENT PRIMARY KEY,
                citizenid VARCHAR(50) NOT NULL,
                heist_id VARCHAR(50) NOT NULL,
                heist_name VARCHAR(100),
                loot_amount INT DEFAULT 0,
                payout INT DEFAULT 0,
                completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_citizenid (citizenid),
                INDEX idx_heist (heist_id)
            )
        ]])

        print('^2[Phantom Heists]^7 Server loaded')
    end
end)

-- Admin commands
RegisterCommand('heistreset', function(source, args)
    if not IsPlayerAceAllowed(source, 'command') then
        TriggerClientEvent('ox_lib:notify', source, { title = 'No Permission', type = 'error' })
        return
    end

    local heistId = args[1]
    if heistId then
        heistCooldowns[heistId] = nil
        activeHeists[heistId] = nil
        TriggerClientEvent('ox_lib:notify', source, { title = 'Heist Reset', description = heistId .. ' cooldown cleared', type = 'success' })
    else
        heistCooldowns = {}
        activeHeists = {}
        TriggerClientEvent('ox_lib:notify', source, { title = 'All Heists Reset', type = 'success' })
    end
end, true)
