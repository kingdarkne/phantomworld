local RankXP = {}

-- Roughly tuned to feel like GTA Online:
-- - Small payouts give a little RP
-- - Bigger jobs give more, but with diminishing returns
-- - Different jobs can have different base rates
RankXP.JobXP = {
    default = 30,   -- generic jobs / payouts
    police  = 45,   -- on-duty LEO
    ambulance = 45, -- EMS
    mechanic = 35,
    taxi    = 25,
}

-- Global tuning knobs
RankXP.Config = {
    -- Money scaling: we normalize the payout by this before applying sqrt()
    MoneyScaleDivisor = 800.0,  -- higher = slower XP from big payouts

    -- Clamp the sqrt scale so tiny payouts still give something,
    -- and huge payouts don't explode XP.
    MinScale = 0.25,   -- minimum scale for very small payouts
    MaxScale = 6.0,    -- maximum scale for very large payouts

    -- Per-tick XP clamp (one money change event)
    MinXPPerTick = 5,
    MaxXPPerTick = 250,

    -- Different money types can be worth slightly more/less RP
    MoneyTypeMultiplier = {
        cash   = 1.0,
        bank   = 0.9,  -- bank deposits a bit less RP than cash-in-hand
        crypto = 1.1,
    },
}

--- Internal: give XP to a specific player
--- @param src number - server id
--- @param amount number - XP amount (> 0)
local function GiveXP(src, amount)
    amount = tonumber(amount) or 0
    if not src or amount <= 0 then return end
    -- XNLRankBar client listens for this and will:
    --  - update the native GTAO rank bar
    --  - persist XP via its own SQL table
    TriggerClientEvent('XNL_NET:AddPlayerXP', src, amount)
end

exports('GiveXP', GiveXP)

-- Admin: /givexp <amount> (yourself) or /givexp <player_id> <amount> (target player)
-- Defer so QBCore.Commands is ready; use raw RegisterCommand if Add fails (e.g. wrong param order)
local function registerGiveXPCommand()
    local handler = function(source, args, rawCommand)
        args = args or {}
        local src = source
        if not IsPlayerAceAllowed(src, 'command') and not IsPlayerAceAllowed(src, 'admin') then
            TriggerClientEvent('ox_lib:notify', src, { title = 'Rank', description = 'No permission.', type = 'error' })
            return
        end
        local targetId, amount
        if args[2] and args[2] ~= '' then
            targetId = tonumber(args[1])
            amount = tonumber(args[2]) or 0
        else
            targetId = src
            amount = tonumber(args[1]) or 0
        end
        if not targetId or amount <= 0 then
            TriggerClientEvent('ox_lib:notify', src, { title = 'Rank', description = 'Use: /givexp <amount> or /givexp <player_id> <amount>', type = 'error' })
            return
        end
        local target = exports.qbx_core:GetPlayer(targetId)
        if not target then
            TriggerClientEvent('ox_lib:notify', src, { title = 'Rank', description = 'Player not found (ID ' .. tostring(targetId) .. ')', type = 'error' })
            return
        end
        GiveXP(targetId, amount)
        TriggerClientEvent('ox_lib:notify', targetId, { title = 'Rank', description = 'You received ' .. amount .. ' RP', type = 'success' })
        if targetId ~= src then
            TriggerClientEvent('ox_lib:notify', src, { title = 'Rank', description = 'Gave ' .. amount .. ' RP to player ' .. targetId, type = 'success' })
        end
    end

    -- Use RegisterCommand only so callback is never misinterpreted (avoids "no valid callback ref is table")
    RegisterCommand('givexp', handler, false)
end

CreateThread(function()
    Wait(500)
    registerGiveXPCommand()
end)

-- Server console: srv_givexp <player_id> <amount> — give RP from server console (e.g. srv_givexp 1 5000)
RegisterCommand('srv_givexp', function(_, args)
    local id = tonumber(args[1])
    local amount = tonumber(args[2]) or 0
    if not id or amount <= 0 then
        print('^1Usage: srv_givexp <player_id> <amount> (e.g. srv_givexp 1 5000)^7')
        return
    end
    GiveXP(id, amount)
    print('^2[dr-rankxp]^7 Gave ' .. amount .. ' XP to player ' .. id)
end, true)

RegisterNetEvent('dr-rankxp:server:GiveXP', function(amount)
    local src = source
    GiveXP(src, amount)
end)

-- Hook money gains -> XP (lightweight, generic for all jobs)
-- Uses QBCore:Server:OnMoneyChange so we don't have to touch every script.
RegisterNetEvent('QBCore:Server:OnMoneyChange', function(src, moneyType, amount, action)
    if action ~= 'add' then return end
    amount = tonumber(amount) or 0
    if amount <= 0 then return end

    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end

    local jobName = Player.PlayerData.job and Player.PlayerData.job.name or 'default'
    local base = RankXP.JobXP[jobName] or RankXP.JobXP.default

    -- Money-type weight (cash / bank / crypto)
    local moneyMult = RankXP.Config.MoneyTypeMultiplier[moneyType] or 1.0

    -- GTAO-style feel: diminishing returns using sqrt of normalized payout.
    -- Example: 800$ => sqrt(1) = 1x, 3,200$ => sqrt(4) = 2x, 12,800$ => sqrt(16) = 4x.
    local normalized = math.max(amount, 0) / RankXP.Config.MoneyScaleDivisor
    local scale = math.sqrt(normalized)
    if scale < RankXP.Config.MinScale then
        scale = RankXP.Config.MinScale
    elseif scale > RankXP.Config.MaxScale then
        scale = RankXP.Config.MaxScale
    end

    local xp = math.floor(base * scale * moneyMult)

    -- Clamp to per-tick bounds so single huge payments don't grant absurd XP
    if xp < RankXP.Config.MinXPPerTick then
        xp = RankXP.Config.MinXPPerTick
    elseif xp > RankXP.Config.MaxXPPerTick then
        xp = RankXP.Config.MaxXPPerTick
    end

    GiveXP(src, xp)
end)

