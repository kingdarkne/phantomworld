local QBCore = exports['qb-core']:GetCoreObject()

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
RegisterNetEvent('npc-storerobbery:server:GiveRegisterReward', function(storeId, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Add dirty money
    Player.Functions.AddItem('markedbills', 1, false, {worth = amount})
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['markedbills'], 'add')
    
    -- Log the robbery
    LogRobbery(src, storeId, 'register', amount)
end)

-- Give vault reward
RegisterNetEvent('npc-storerobbery:server:GiveVaultReward', function(storeId)
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

-- Police alert
RegisterNetEvent('npc-storerobbery:server:PoliceAlert', function(storeType, coords)
    local src = source
    
    -- Get player info
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Send alert to all police
    for _, playerId in ipairs(GetPlayers()) do
        local policePlayer = QBCore.Functions.GetPlayer(tonumber(playerId))
        if policePlayer and (policePlayer.PlayerData.job.name == 'police' or policePlayer.PlayerData.job.type == 'leo') and policePlayer.PlayerData.job.onduty then
            TriggerClientEvent('npc-storerobbery:client:PoliceAlert', playerId, storeType, coords)
        end
    end
    
    -- Log to console
    print('[NPC Store Robbery] Police alert triggered for ' .. storeType .. ' store at ' .. tostring(coords))
end)

-- NPC intimidated
RegisterNetEvent('npc-storerobbery:server:NPCIntimidated', function(storeId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Log intimidation
    print('[NPC Store Robbery] ' .. GetPlayerName(src) .. ' intimidated NPC at store ' .. storeId)
end)

-- Vault hack success
RegisterNetEvent('npc-storerobbery:server:VaultHackSuccess', function(storeId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Log successful hack
    print('[NPC Store Robbery] ' .. GetPlayerName(src) .. ' successfully hacked vault at store ' .. storeId)
end)

-- Vault hack failed
RegisterNetEvent('npc-storerobbery:server:VaultHackFailed', function(storeId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Log failed hack
    print('[NPC Store Robbery] ' .. GetPlayerName(src) .. ' failed to hack vault at store ' .. storeId)
end)

-- Callbacks
lib.callback.register('npc-storerobbery:server:IsStoreOnCooldown', function(source, storeId)
    return IsStoreOnCooldown(storeId)
end)

-- Utility functions
function GetPlayerName(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        return Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    end
    return 'Unknown'
end

function LogRobbery(source, storeId, type, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local store = Config.Stores[storeId]
    if not store then return end
    
    local playerName = GetPlayerName(source)
    local citizenid = Player.PlayerData.citizenid
    
    -- Log to database (if you have a logging system)
    print('[NPC Store Robbery] ' .. playerName .. ' (' .. citizenid .. ') robbed ' .. store.type .. ' store - ' .. type .. ': $' .. amount)
    
    -- You can add database logging here if you have one
    -- Example: exports.oxmysql:execute('INSERT INTO npc_robbery_logs (citizenid, store_id, type, amount, timestamp) VALUES (?, ?, ?, ?, ?)', {citizenid, storeId, type, amount, os.time()})
end

-- Commands
QBCore.Commands.Add('resetnpcrobbery', 'Reset NPC store robbery cooldowns (Admin)', {}, false, function(source, args)
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
    TriggerClientEvent('npc-storerobbery:client:ResetNPC', -1)
    
    TriggerClientEvent('QBCore:Notify', src, 'All NPC store robbery cooldowns reset!', 'success')
end)

QBCore.Commands.Add('npcrobberycooldown', 'Check NPC store robbery cooldowns', {}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player is admin
    if not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('QBCore:Notify', src, 'You don\'t have permission to use this command!', 'error')
        return
    end
    
    local message = 'NPC Store Robbery Cooldowns:\n'
    
    for storeId, store in pairs(Config.Stores) do
        local registerTime = GetCooldownTime(storeId, 'register')
        local vaultTime = GetCooldownTime(storeId, 'vault')
        
        if registerTime > 0 or vaultTime > 0 then
            message = message .. storeId .. ' - Register: ' .. registerTime .. 's, Vault: ' .. vaultTime .. 's\n'
        end
    end
    
    if message == 'NPC Store Robbery Cooldowns:\n' then
        message = 'No active cooldowns'
    end
    
    TriggerClientEvent('QBCore:Notify', src, message, 'info')
end)

-- Export functions
exports('IsStoreOnCooldown', IsStoreOnCooldown)
exports('SetStoreCooldown', SetStoreCooldown)
exports('GetCooldownTime', GetCooldownTime)
