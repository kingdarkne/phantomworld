local QBCore = exports['qbx_core']:GetCoreObject()

local storeCooldowns = {}
local vaultCooldowns = {}

-- Initialize
CreateThread(function()
    -- Reset cooldowns on server start
    storeCooldowns = {}
    vaultCooldowns = {}
end)

-- Check if store is on cooldown
function IsStoreOnCooldown(storeId)
    local currentTime = GetGameTimer()
    
    -- Check register cooldown
    if storeCooldowns[storeId] and storeCooldowns[storeId] > currentTime then
        return true
    end
    
    -- Check vault cooldown
    if vaultCooldowns[storeId] and vaultCooldowns[storeId] > currentTime then
        return true
    end
    
    return false
end

-- Set store cooldown
function SetStoreCooldown(storeId, type)
    local currentTime = GetGameTimer()
    
    if type == 'register' then
        storeCooldowns[storeId] = currentTime + Config.RegisterCooldown
    elseif type == 'vault' then
        vaultCooldowns[storeId] = currentTime + Config.VaultCooldown
    end
end

-- Get cooldown time remaining
function GetCooldownTime(storeId, type)
    local currentTime = GetGameTimer()
    
    if type == 'register' and storeCooldowns[storeId] then
        local remaining = math.max(0, storeCooldowns[storeId] - currentTime)
        return math.floor(remaining / 1000) -- Convert to seconds
    elseif type == 'vault' and vaultCooldowns[storeId] then
        local remaining = math.max(0, vaultCooldowns[storeId] - currentTime)
        return math.floor(remaining / 1000) -- Convert to seconds
    end
    
    return 0
end

-- Give register reward
RegisterNetEvent('hybrid-storerobbery:server:GiveRegisterReward', function(storeId, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Add dirty money
    Player.Functions.AddItem('markedbills', 1, false, {worth = amount})
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['markedbills'], 'add')
    
    -- Log the robbery
    LogRobbery(src, storeId, 'register', amount)
end)

-- Give register reward with player sharing
RegisterNetEvent('hybrid-storerobbery:server:GiveRegisterRewardWithShare', function(storeId, totalAmount, playerCount, nearbyPlayers)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Calculate individual shares
    local individualShare = math.floor(totalAmount / playerCount)
    local remainder = totalAmount - (individualShare * playerCount)
    
    -- Give main robber their share plus any remainder
    local mainReward = individualShare + remainder
    Player.Functions.AddItem('markedbills', 1, false, {worth = mainReward})
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['markedbills'], 'add')
    
    -- Notify main robber
    TriggerClientEvent('QBCore:Notify', src, 'Register robbed! Got $' .. mainReward .. ' (Your share + remainder)', 'success')
    
    -- Share with nearby players
    for _, playerData in ipairs(nearbyPlayers) do
        local nearbyPlayerId = playerData.id
        local nearbyPlayer = QBCore.Functions.GetPlayer(nearbyPlayerId)
        
        if nearbyPlayer then
            -- Give nearby player their share
            nearbyPlayer.Functions.AddItem('markedbills', 1, false, {worth = individualShare})
            TriggerClientEvent('inventory:client:ItemBox', nearbyPlayerId, QBCore.Shared.Items['markedbills'], 'add')
            
            -- Notify nearby player
            TriggerClientEvent('QBCore:Notify', nearbyPlayerId, 'Received $' .. individualShare .. ' from nearby robbery!', 'success')
            
            -- Log shared reward
            print('[Hybrid Store Robbery] ' .. GetPlayerName(nearbyPlayerId) .. ' received shared reward: $' .. individualShare)
        end
    end
    
    -- Log the robbery with sharing details
    LogSharedRobbery(src, storeId, 'register', totalAmount, playerCount, individualShare, nearbyPlayers)
end)

-- Give vault reward (integrates with existing systems)
RegisterNetEvent('hybrid-storerobbery:server:GiveVaultReward', function(storeId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local store = Config.Stores[storeId]
    if not store then return end
    
    -- Calculate reward based on store type
    local reward = math.random(store.vaultReward.min, store.vaultReward.max)
    
    -- Add cash and dirty money mix
    local cashAmount = math.floor(reward * 0.6)
    local dirtyAmount = math.floor(reward * 0.4)
    
    Player.Functions.AddMoney('cash', cashAmount, 'Store Robbery - Vault')
    
    -- Add dirty money as marked bills
    if dirtyAmount > 0 then
        Player.Functions.AddItem('markedbills', 1, false, {worth = dirtyAmount})
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['markedbills'], 'add')
    end
    
    -- Log the robbery
    LogRobbery(src, storeId, 'vault', reward)
end)

-- Give vault reward with player sharing
RegisterNetEvent('hybrid-storerobbery:server:GiveVaultRewardWithShare', function(storeId, totalAmount, playerCount, nearbyPlayers)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local store = Config.Stores[storeId]
    if not store then return end
    
    -- Calculate individual shares
    local individualShare = math.floor(totalAmount / playerCount)
    local remainder = totalAmount - (individualShare * playerCount)
    
    -- Split reward into cash and dirty money
    local cashShare = math.floor(individualShare * 0.6)
    local dirtyShare = math.floor(individualShare * 0.4)
    
    -- Give main robber their share plus any remainder
    local mainCash = cashShare + math.floor(remainder * 0.6)
    local mainDirty = dirtyShare + math.floor(remainder * 0.4)
    
    Player.Functions.AddMoney('cash', mainCash, 'Vault Robbery - Your Share')
    
    if mainDirty > 0 then
        Player.Functions.AddItem('markedbills', 1, false, {worth = mainDirty})
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['markedbills'], 'add')
    end
    
    -- Notify main robber
    TriggerClientEvent('QBCore:Notify', src, 'Vault hacked! Got $' .. mainCash + mainDirty .. ' (Your share + remainder)', 'success')
    
    -- Share with nearby players
    for _, playerData in ipairs(nearbyPlayers) do
        local nearbyPlayerId = playerData.id
        local nearbyPlayer = QBCore.Functions.GetPlayer(nearbyPlayerId)
        
        if nearbyPlayer then
            -- Give nearby player their share
            nearbyPlayer.Functions.AddMoney('cash', cashShare, 'Vault Robbery - Shared Reward')
            
            if dirtyShare > 0 then
                nearbyPlayer.Functions.AddItem('markedbills', 1, false, {worth = dirtyShare})
                TriggerClientEvent('inventory:client:ItemBox', nearbyPlayerId, QBCore.Shared.Items['markedbills'], 'add')
            end
            
            -- Notify nearby player
            TriggerClientEvent('QBCore:Notify', nearbyPlayerId, 'Received $' .. (cashShare + dirtyShare) .. ' from nearby vault hack!', 'success')
            
            -- Log shared reward
            print('[Hybrid Store Robbery] ' .. GetPlayerName(nearbyPlayerId) .. ' received vault share: $' .. (cashShare + dirtyShare))
        end
    end
    
    -- Log the vault robbery with sharing details
    LogSharedRobbery(src, storeId, 'vault', totalAmount, playerCount, individualShare, nearbyPlayers)
end)

-- Buy item from shop
RegisterNetEvent('hybrid-storerobbery:server:BuyItem', function(itemName, price, storeId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player has enough money
    if not Player.Functions.RemoveMoney('cash', price, 'Shop Purchase') then
        TriggerClientEvent('QBCore:Notify', src, 'Not enough cash!', 'error')
        return
    end
    
    -- Give item to player
    if Player.Functions.AddItem(itemName, 1) then
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'add')
        TriggerClientEvent('QBCore:Notify', src, 'Purchased ' .. itemName .. ' for $' .. price, 'success')
        
        -- Log purchase
        LogPurchase(src, storeId, itemName, price)
    else
        -- Refund money if item couldn't be added
        Player.Functions.AddMoney('cash', price, 'Shop Refund')
        TriggerClientEvent('QBCore:Notify', src, 'Cannot carry this item!', 'error')
    end
end)

-- Start NPC robbery
RegisterNetEvent('hybrid-storerobbery:server:StartNPCRobbery', function(storeId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Validate robbery
    if IsStoreOnCooldown(storeId) then
        TriggerClientEvent('QBCore:Notify', src, 'This store was recently robbed!', 'error')
        return
    end
    
    local policeCount = GetPoliceCount()
    if policeCount < Config.PoliceRequired then
        TriggerClientEvent('QBCore:Notify', src, 'Not enough police online!', 'error')
        return
    end
    
    -- Start robbery on client
    TriggerClientEvent('hybrid-storerobbery:client:StartNPCRobbery', src, storeId)
end)

-- Police alert
RegisterNetEvent('hybrid-storerobbery:server:PoliceAlert', function(storeType, coords)
    local src = source
    
    -- Get player info
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Send alert to all police
    for _, playerId in ipairs(GetPlayers()) do
        local policePlayer = QBCore.Functions.GetPlayer(tonumber(playerId))
        if policePlayer and (policePlayer.PlayerData.job.name == 'police' or policePlayer.PlayerData.job.type == 'leo') and policePlayer.PlayerData.job.onduty then
            TriggerClientEvent('hybrid-storerobbery:client:PoliceAlert', playerId, storeType, coords)
        end
    end
    
    -- Log to console
    print('[Hybrid Store Robbery] Police alert triggered for ' .. storeType .. ' store at ' .. tostring(coords))
end)

-- NPC intimidated
RegisterNetEvent('hybrid-storerobbery:server:NPCIntimidated', function(storeId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Log intimidation
    print('[Hybrid Store Robbery] ' .. GetPlayerName(src) .. ' intimidated NPC at store ' .. storeId)
end)

-- Callbacks
if lib and lib.callback then
    lib.callback.register('hybrid-storerobbery:server:IsStoreOnCooldown', function(source, storeId)
        return IsStoreOnCooldown(storeId)
    end)
end

-- Utility functions
function GetPlayerName(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        return Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    end
    return 'Unknown'
end

function GetPoliceCount()
    local count = 0
    for _, player in ipairs(GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(tonumber(player))
        if Player and (Player.PlayerData.job.name == 'police' or Player.PlayerData.job.type == 'leo') and Player.PlayerData.job.onduty then
            count = count + 1
        end
    end
    return count
end

function LogRobbery(source, storeId, type, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local store = Config.Stores[storeId]
    if not store then return end
    
    local playerName = GetPlayerName(source)
    local citizenid = Player.PlayerData.citizenid
    
    -- Log to database (if you have a logging system)
    print('[Hybrid Store Robbery] ' .. playerName .. ' (' .. citizenid .. ') robbed ' .. store.type .. ' store - ' .. type .. ': $' .. amount)
    
    -- Trigger AI cops response
    TriggerAICopsResponse(storeId, type, store.coords)
    
    -- You can add database logging here if you have one
    -- Example: exports.oxmysql:execute('INSERT INTO hybrid_robbery_logs (citizenid, store_id, type, amount, timestamp) VALUES (?, ?, ?, ?, ?)', {citizenid, storeId, type, amount, os.time()})
end

function LogSharedRobbery(source, storeId, type, totalAmount, playerCount, individualShare, nearbyPlayers)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local store = Config.Stores[storeId]
    if not store then return end
    
    local playerName = GetPlayerName(source)
    local citizenid = Player.PlayerData.citizenid
    
    -- Log to database with sharing details
    print('[Hybrid Store Robbery] ' .. playerName .. ' (' .. citizenid .. ') robbed ' .. store.type .. ' store - ' .. type .. ': $' .. totalAmount .. ' (shared with ' .. playerCount .. ' players, $' .. individualShare .. ' each)')
    
    -- Trigger AI cops response
    TriggerAICopsResponse(storeId, type, store.coords)
    
    -- You can add database logging here if you have one
    -- Example: exports.oxmysql:execute('INSERT INTO hybrid_robbery_logs (citizenid, store_id, type, amount, players, share, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?)', {citizenid, storeId, type, totalAmount, playerCount, individualShare, os.time()})
end

function TriggerAICopsResponse(storeId, robberyType, coords)
    -- Trigger AI cops response for store robberies
    if robberyType == 'register' then
        -- Trigger wanted level for store robbery
        TriggerClientEvent('fenix-police:client:triggerWantedLevel', -1, 2, coords, 'Store Robbery')
        
        -- Send AI police to location
        TriggerClientEvent('fenix-police:client:dispatchPolice', -1, {
            type = 'store_robbery',
            coords = coords,
            storeId = storeId,
            priority = 'medium'
        })
        
        print('[Hybrid Store Robbery] AI cops dispatched to store robbery at ' .. tostring(coords))
    elseif robberyType == 'vault' then
        -- Higher wanted level for vault robbery
        TriggerClientEvent('fenix-police:client:triggerWantedLevel', -1, 3, coords, 'Vault Robbery')
        
        -- Send more AI police for vault robbery
        TriggerClientEvent('fenix-police:client:dispatchPolice', -1, {
            type = 'vault_robbery',
            coords = coords,
            storeId = storeId,
            priority = 'high'
        })
        
        print('[Hybrid Store Robbery] AI cops dispatched to vault robbery at ' .. tostring(coords))
    end
end

function LogPurchase(source, storeId, itemName, price)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local store = Config.Stores[storeId]
    if not store then return end
    
    local playerName = GetPlayerName(source)
    local citizenid = Player.PlayerData.citizenid
    
    -- Log purchase
    print('[Hybrid Store Robbery] ' .. playerName .. ' (' .. citizenid .. ') purchased ' .. itemName .. ' from ' .. store.type .. ' store for $' .. price)
end

-- Commands
QBCore.Commands.Add('resethybridrobbery', 'Reset hybrid store robbery cooldowns (Admin)', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player is admin
    if not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('QBCore:Notify', src, 'You don\'t have permission to use this command!', 'error')
        return
    end
    
    -- Reset all cooldowns
    storeCooldowns = {}
    vaultCooldowns = {}
    
    -- Reset all NPCs
    TriggerClientEvent('hybrid-storerobbery:client:ResetNPC', -1)
    
    TriggerClientEvent('QBCore:Notify', src, 'All hybrid store robbery cooldowns reset!', 'success')
end)

QBCore.Commands.Add('hybridrobberycooldown', 'Check hybrid store robbery cooldowns', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player is admin
    if not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('QBCore:Notify', src, 'You don\'t have permission to use this command!', 'error')
        return
    end
    
    local message = 'Hybrid Store Robbery Cooldowns:\n'
    
    for storeId, store in pairs(Config.Stores) do
        local registerTime = GetCooldownTime(storeId, 'register')
        local vaultTime = GetCooldownTime(storeId, 'vault')
        
        if registerTime > 0 or vaultTime > 0 then
            message = message .. storeId .. ' - Register: ' .. registerTime .. 's, Vault: ' .. vaultTime .. 's\n'
        end
    end
    
    if message == 'Hybrid Store Robbery Cooldowns:\n' then
        message = 'No active cooldowns'
    end
    
    TriggerClientEvent('QBCore:Notify', src, message, 'info')
end)

-- Export functions
exports('IsStoreOnCooldown', IsStoreOnCooldown)
exports('SetStoreCooldown', SetStoreCooldown)
exports('GetCooldownTime', GetCooldownTime)
exports('GetPoliceCount', GetPoliceCount)
