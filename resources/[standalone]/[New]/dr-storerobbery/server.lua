local lastRobbed = {}

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

RegisterNetEvent('dr-storerobbery:server:tryRob', function(storeId, registerIndex)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end

    storeId = tonumber(storeId)
    registerIndex = tonumber(registerIndex)
    if not storeId or not registerIndex then return end

    if CountCops() < (Config.MinCops or 0) then
        TriggerClientEvent('ox_lib:notify', src, { description = 'Not enough police on duty.', type = 'error' })
        return
    end

    local now = os.time()
    local cooldownKey = ('store_%s'):format(storeId)
    local last = lastRobbed[cooldownKey] or 0
    if now - last < (Config.RegisterCooldown or 600) then
        local remaining = Config.RegisterCooldown - (now - last)
        local mins = math.ceil(remaining / 60)
        TriggerClientEvent('ox_lib:notify', src, {
            description = ('This store was robbed recently. Wait about %d minutes.'):format(mins),
            type = 'error',
        })
        return
    end

    lastRobbed[cooldownKey] = now

    local baseMin, baseMax = Config.Reward.min, Config.Reward.max
    if Config.RedRegisters and Config.RedRegisters[registerIndex] then
        baseMin = 50000
        baseMax = 250000
    end

    local reward = math.random(baseMin, baseMax)
    local multi = GetMembershipMultiplier(src)
    reward = math.floor(reward * multi)

    Player.Functions.AddMoney('cash', reward, 'store-robbery')
    TriggerClientEvent('ox_lib:notify', src, {
        description = ('You grabbed $%d from the register.'):format(reward),
        type = 'success',
    })

    if GetResourceState('dr-rankxp') == 'started' and Config.XPReward and Config.XPReward > 0 then
        exports['dr-rankxp']:GiveXP(src, Config.XPReward)
    end

    for _, pid in ipairs(GetPlayers()) do
        local policeSrc = tonumber(pid)
        if policeSrc then
            local p = exports.qbx_core:GetPlayer(policeSrc)
            local job = p and p.PlayerData and p.PlayerData.job
            if job and job.name == 'police' and job.onduty then
                TriggerClientEvent('ox_lib:notify', policeSrc, {
                    description = 'Robbery in progress at a store! Check your GPS.',
                    type = 'error',
                })
                TriggerClientEvent('dr-storerobbery:client:blip', policeSrc, registerIndex)
            end
        end
    end
end)
