local Membership = {}

Membership.Tiers = {
    none    = 0,
    bronze  = 1,
    silver  = 2,
    gold    = 3,
    diamond = 4,
}

Membership.DefaultTier = 'none'
Membership.DefaultCoins = 0

-- Optional: gate specific custom vehicles behind membership tiers.
-- This does not automatically hook every script; instead, other resources
-- can call HasVehicleAccess or HasTierAtLeast before giving/spawning cars.
Membership.VehicleAccess = {
    -- example: ['adder'] = 'gold',
    -- ['your_custom_model'] = 'gold',
    -- ['another_model'] = 'diamond',
}

-- Note: qbx_core does not expose a vehicle list export in this build.
-- Keep `Membership.VehicleAccess` manual (models -> tier) instead of auto-populating.

local function EnsureMeta(Player)
    if not Player then return end
    local meta = Player.PlayerData.metadata or {}
    local src = Player.PlayerData.source

    if meta.membership_tier == nil or Membership.Tiers[meta.membership_tier] == nil then
        Player.Functions.SetMetaData('membership_tier', Membership.DefaultTier)
    end

    if meta.membership_coins == nil then
        Player.Functions.SetMetaData('membership_coins', Membership.DefaultCoins)
    end

    -- One-time starter trial: give new players a 30-day gold membership + starter perks
    -- We key this off a metadata flag so it only runs once per character.
    if not meta.membership_trial_given then
        local now = os.time()
        local trialDays = 30
        local expires = now + (trialDays * 86400)

        Player.Functions.SetMetaData('membership_trial_given', true)
        Player.Functions.SetMetaData('membership_trial_expires', expires)
        Player.Functions.SetMetaData('membership_tier', 'gold')

        -- Economy / rank boost: 30 million and a large RP bump (approx rank 120 feel).
        -- Adjust these numbers later if you want it slower/faster.
        Player.Functions.AddMoney('bank', 30000000, 'starter-membership-bonus')

        -- If dr-rankxp is running, give a big RP grant.
        if GetResourceState('dr-rankxp') == 'started' then
            -- Give a large chunk of XP; XNLRankBar will handle exact level.
            exports['dr-rankxp']:GiveXP(src, 1500000)
        end

    end

    Player.Functions.Save()
end

local function GetPlayerFromId(id)
    local src = tonumber(id)
    if not src then return nil end
    return exports.qbx_core:GetPlayer(src)
end

local function GetTier(src)
    local Player = GetPlayerFromId(src)
    if not Player then return Membership.DefaultTier end
    local meta = Player.PlayerData.metadata or {}
    local tier = meta.membership_tier or Membership.DefaultTier
    if not Membership.Tiers[tier] then
        tier = Membership.DefaultTier
    end
    return tier
end

local function SetTier(src, tier)
    tier = tier and tier:lower() or Membership.DefaultTier
    if not Membership.Tiers[tier] then
        return false, ('Invalid tier "%s"'):format(tostring(tier))
    end

    local Player = GetPlayerFromId(src)
    if not Player then
        return false, 'Player not online'
    end

    EnsureMeta(Player)
    Player.Functions.SetMetaData('membership_tier', tier)
    Player.Functions.Save()
    return true
end

local function GetCoins(src)
    local Player = GetPlayerFromId(src)
    if not Player then return 0 end
    local meta = Player.PlayerData.metadata or {}
    return tonumber(meta.membership_coins or 0) or 0
end

local function GetTrialRemaining(src)
    local Player = GetPlayerFromId(src)
    if not Player then return nil end
    local meta = Player.PlayerData.metadata or {}
    local expires = meta.membership_trial_expires
    if not expires then return nil end
    local now = os.time()
    local remaining = tonumber(expires) - now
    if remaining <= 0 then
        return 0
    end
    return remaining
end

local function SetCoins(src, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount < 0 then amount = 0 end

    local Player = GetPlayerFromId(src)
    if not Player then
        return false, 'Player not online'
    end

    EnsureMeta(Player)
    Player.Functions.SetMetaData('membership_coins', amount)
    Player.Functions.Save()
    return true
end

local function AddCoins(src, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount == 0 then return false, 'Amount is zero' end
    local current = GetCoins(src)
    return SetCoins(src, current + amount)
end

local function RemoveCoins(src, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount == 0 then return false, 'Amount is zero' end
    local current = GetCoins(src)
    if amount > current then amount = current end
    return SetCoins(src, current - amount)
end

local function HasTierAtLeast(src, requiredTier)
    requiredTier = requiredTier and requiredTier:lower() or Membership.DefaultTier
    if not Membership.Tiers[requiredTier] then
        return false
    end
    local currentTier = GetTier(src)
    return (Membership.Tiers[currentTier] or 0) >= (Membership.Tiers[requiredTier] or 0)
end

-- QBCore events

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    if Player then
        EnsureMeta(Player)

        -- If a trial exists and is expired, downgrade membership back to none
        local meta = Player.PlayerData.metadata or {}
        local expires = meta.membership_trial_expires
        if expires and os.time() > tonumber(expires) then
            Player.Functions.SetMetaData('membership_tier', Membership.DefaultTier)
            Player.Functions.SetMetaData('membership_trial_expires', nil)
            Player.Functions.Save()
            TriggerClientEvent('ox_lib:notify', src, { description = 'Your free membership trial has expired. Visit the store to renew.', type = 'error' })
        end
    end
end)

-- Exports for other resources

exports('GetTier', GetTier)
exports('HasTierAtLeast', HasTierAtLeast)
exports('GetCoins', GetCoins)
exports('AddCoins', AddCoins)
exports('RemoveCoins', RemoveCoins)
exports('HasVehicleAccess', function(src, model)
    model = tostring(model or ''):lower()
    local required = Membership.VehicleAccess[model]
    if not required then return true end -- no restriction configured for this model
    return HasTierAtLeast(src, required)
end)

-- Admin commands

RegisterCommand('setmembership', function(source, args)
    local src = source
    if src > 0 and not IsPlayerAceAllowed(src, 'admin') then return end
    local targetId = tonumber(args[1])
    local tier = args[2] and tostring(args[2]):lower() or nil

    if not targetId or not tier then
        TriggerClientEvent('ox_lib:notify', src, { description = 'Usage: /setmembership [id] [none|bronze|silver|gold|diamond]', type = 'error' })
        return
    end

    local ok, err = SetTier(targetId, tier)
    if not ok then
        TriggerClientEvent('ox_lib:notify', src, { description = err or 'Failed to set membership', type = 'error' })
        return
    end

    TriggerClientEvent('ox_lib:notify', src, { description = ('Set membership for ID %d to %s'):format(targetId, tier), type = 'success' })
    TriggerClientEvent('ox_lib:notify', targetId, { description = ('Your membership tier is now: %s'):format(tier), type = 'success' })
end, true)

RegisterCommand('addcoins', function(source, args)
    local src = source
    if src > 0 and not IsPlayerAceAllowed(src, 'admin') then return end
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2] or 0)

    if not targetId or not amount then
        TriggerClientEvent('ox_lib:notify', src, { description = 'Usage: /addcoins [id] [amount]', type = 'error' })
        return
    end

    local ok, err = AddCoins(targetId, amount)
    if not ok then
        TriggerClientEvent('ox_lib:notify', src, { description = err or 'Failed to add coins', type = 'error' })
        return
    end

    TriggerClientEvent('ox_lib:notify', src, { description = ('Added %d coins to ID %d'):format(amount, targetId), type = 'success' })
    TriggerClientEvent('ox_lib:notify', targetId, { description = ('You received %d membership coins'):format(amount), type = 'success' })
end, true)

RegisterCommand('removecoins', function(source, args)
    local src = source
    if src > 0 and not IsPlayerAceAllowed(src, 'admin') then return end
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2] or 0)

    if not targetId or not amount then
        TriggerClientEvent('ox_lib:notify', src, { description = 'Usage: /removecoins [id] [amount]', type = 'error' })
        return
    end

    local ok, err = RemoveCoins(targetId, amount)
    if not ok then
        TriggerClientEvent('ox_lib:notify', src, { description = err or 'Failed to remove coins', type = 'error' })
        return
    end

    TriggerClientEvent('ox_lib:notify', src, { description = ('Removed %d coins from ID %d'):format(amount, targetId), type = 'success' })
    TriggerClientEvent('ox_lib:notify', targetId, { description = ('%d membership coins were removed from your account'):format(amount), type = 'error' })
end, true)

-- Player command to check their own status

RegisterCommand('membership', function(source)
    local src = source
    local tier = GetTier(src)
    local coins = GetCoins(src)
    local remaining = GetTrialRemaining(src)
    local msg
    if remaining and remaining > 0 and tier ~= Membership.DefaultTier then
        local days  = math.floor(remaining / 86400)
        local hours = math.floor((remaining % 86400) / 3600)
        msg = ('Membership: %s (trial ~%d days %d hours left) | Coins: %d'):format(tier, days, hours, coins)
    else
        msg = ('Membership: %s | Coins: %d'):format(tier, coins)
    end
    TriggerClientEvent('ox_lib:notify', src, { description = msg, type = 'inform' })
end, false)

