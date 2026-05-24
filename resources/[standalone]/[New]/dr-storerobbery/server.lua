local lastRobbed = {} -- [registerIndex] = os.time()

local function CountCops()
    local count = 0
    for _, pid in ipairs(GetPlayers()) do
        local src = tonumber(pid)
        if src then
            local Player = exports.qbx_core:GetPlayer(src)
            local job = Player and Player.PlayerData and Player.PlayerData.job
            if job and job.name == 'police' and job.onduty then
                count += 1
            end
        end
    end
    return count
end

local function GetMembershipMultiplier(src)
    if GetResourceState('dr-membership') ~= 'started' or not Config.MembershipBonus then
        return 1.0
    end
    local tier = exports['dr-membership'].GetTier and exports['dr-membership']:GetTier(src)
    if not tier then return 1.0 end
    local bonus = Config.MembershipBonus[tier]
    if not bonus or bonus <= 0 then
        return 1.0
    end
    return 1.0 + bonus
end

RegisterNetEvent('dr-storerobbery:server:tryRob', function(index)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end

    if CountCops() < Config.MinCops then
        TriggerClientEvent('ox_lib:notify', src, { description = 'Not enough police on duty.', type = 'error' })
        return
    end

    local now = os.time()
    local last = lastRobbed[index] or 0
    if now - last < Config.RegisterCooldown then
        local remaining = Config.RegisterCooldown - (now - last)
        local mins = math.ceil(remaining / 60)
        TriggerClientEvent('ox_lib:notify', src, { description = ('This register was robbed recently. Wait about %d minutes.'):format(mins), type = 'error' })
        return
    end

    lastRobbed[index] = now

    -- Payout with membership bonus
    local baseMin, baseMax = Config.Reward.min, Config.Reward.max
    -- If this is a red-zone register, boost the base dramatically
    if Config.RedRegisters and Config.RedRegisters[index] then
        baseMin = 50000   -- 50k minimum
        baseMax = 250000  -- 250k max before membership bonus
    end

    local reward = math.random(baseMin, baseMax)
    local multi = GetMembershipMultiplier(src)
    reward = math.floor(reward * multi)

    Player.Functions.AddMoney('cash', reward, 'store-robbery')
    TriggerClientEvent('ox_lib:notify', src, { description = ('You grabbed $%d from the register.'):format(reward), type = 'success' })

    -- XP (if dr-rankxp exists)
    if GetResourceState('dr-rankxp') == 'started' and Config.XPReward and Config.XPReward > 0 then
        exports['dr-rankxp']:GiveXP(src, Config.XPReward)
    end

    -- Simple dispatch to cops
    for _, pid in ipairs(GetPlayers()) do
        local policeSrc = tonumber(pid)
        if policeSrc then
            local p = exports.qbx_core:GetPlayer(policeSrc)
            local job = p and p.PlayerData and p.PlayerData.job
            if job and job.name == 'police' and job.onduty then
                TriggerClientEvent('ox_lib:notify', policeSrc, { description = 'Robbery in progress at a store! Check your GPS.', type = 'error' })
                TriggerClientEvent('dr-storerobbery:client:blip', policeSrc, index)
            end
        end
    end
end)

