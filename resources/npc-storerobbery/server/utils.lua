local QBCore = exports['qb-core']:GetCoreObject()

-- Server utility functions

-- Get all police on duty
function GetPoliceOnDuty()
    local police = {}
    for _, playerId in ipairs(GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(tonumber(playerId))
        if Player and (Player.PlayerData.job.name == 'police' or Player.PlayerData.job.type == 'leo') and Player.PlayerData.job.onduty then
            table.insert(police, {
                id = playerId,
                name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                callsign = Player.PlayerData.metadata.callsign or 'Unknown'
            })
        end
    end
    return police
end

-- Send message to all police
function SendPoliceMessage(message, type)
    for _, playerId in ipairs(GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(tonumber(playerId))
        if Player and (Player.PlayerData.job.name == 'police' or Player.PlayerData.job.type == 'leo') and Player.PlayerData.job.onduty then
            TriggerClientEvent('QBCore:Notify', playerId, message, type or 'info')
        end
    end
end

-- Check if player has required items
function HasRequiredItems(source, items)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    for _, item in ipairs(items) do
        if not Player.Functions.GetItemByName(item) then
            return false
        end
    end
    
    return true
end

-- Remove item from player
function RemoveItem(source, item, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    return Player.Functions.RemoveItem(item, amount or 1)
end

-- Add item to player
function AddItem(source, item, amount, metadata)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    return Player.Functions.AddItem(item, amount or 1, false, metadata or {})
end

-- Add money to player
function AddMoney(source, type, amount, reason)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    return Player.Functions.AddMoney(type, amount, reason or 'Unknown')
end

-- Get player coordinates
function GetPlayerCoords(source)
    local ped = GetPlayerPed(source)
    return GetEntityCoords(ped)
end

-- Get distance between player and coordinates
function GetPlayerDistance(source, coords)
    local playerCoords = GetPlayerCoords(source)
    return #(playerCoords - coords)
end

-- Format time remaining
function FormatTimeRemaining(milliseconds)
    local seconds = math.floor(milliseconds / 1000)
    local minutes = math.floor(seconds / 60)
    local hours = math.floor(minutes / 60)
    
    if hours > 0 then
        return string.format('%dh %dm %ds', hours, minutes % 60, seconds % 60)
    elseif minutes > 0 then
        return string.format('%dm %ds', minutes, seconds % 60)
    else
        return string.format('%ds', seconds)
    end
end

-- Generate random license plate
function GenerateLicensePlate()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local plate = ''
    
    for i = 1, 8 do
        local random = math.random(#chars)
        plate = plate .. string.sub(chars, random, random)
    end
    
    return plate
end

-- Log to file (if you have a logging system)
function LogToFile(message)
    local timestamp = os.date('%Y-%m-%d %H:%M:%S')
    local logMessage = '[' .. timestamp .. '] ' .. message .. '\n'
    
    -- Write to file (you may need to adjust the path)
    local file = io.open('npc-storerobbery.log', 'a')
    if file then
        file:write(logMessage)
        file:close()
    end
    
    -- Also print to console
    print(logMessage)
end

-- Webhook for Discord notifications (optional)
function SendDiscordWebhook(title, description, color)
    -- You'll need to configure your webhook URL in config
    local webhookUrl = Config.DiscordWebhook or nil
    
    if not webhookUrl then return end
    
    local embed = {
        {
            ['title'] = title,
            ['description'] = description,
            ['color'] = color or 16711680, -- Red color
            ['timestamp'] = os.date('!%Y-%m-%dT%H:%M:%S')
        }
    }
    
    PerformHttpRequest(webhookUrl, function(errorCode, resultData, resultHeaders)
        if errorCode ~= 200 then
            print('Discord webhook failed: ' .. tostring(errorCode))
        end
    end, 'POST', json.encode({
        username = 'NPC Store Robbery',
        embeds = embed
    }), {['Content-Type'] = 'application/json'})
end

-- Get store info by ID
function GetStoreInfo(storeId)
    return Config.Stores[storeId]
end

-- Get all stores
function GetAllStores()
    return Config.Stores
end

-- Get nearby stores to player
function GetNearbyStores(source, radius)
    local playerCoords = GetPlayerCoords(source)
    local nearbyStores = {}
    
    for storeId, store in pairs(Config.Stores) do
        local distance = #(playerCoords - store.coords)
        if distance <= (radius or 50.0) then
            table.insert(nearbyStores, {
                id = storeId,
                store = store,
                distance = distance
            })
        end
    end
    
    -- Sort by distance
    table.sort(nearbyStores, function(a, b)
        return a.distance < b.distance
    end)
    
    return nearbyStores
end

-- Check if player is in store
function IsPlayerInStore(source, storeId)
    local store = Config.Stores[storeId]
    if not store then return false end
    
    local distance = GetPlayerDistance(source, store.coords)
    return distance <= 10.0
end

-- Get player weapon
function GetPlayerWeapon(source)
    local ped = GetPlayerPed(source)
    local currentWeapon = GetSelectedPedWeapon(ped)
    return currentWeapon
end

-- Check if weapon is intimidating
function IsWeaponIntimidating(weaponHash)
    for _, weapon in ipairs(Config.IntimidationWeapons) do
        if GetHashKey(weapon) == weaponHash then
            return true
        end
    end
    return false
end

-- Get player job info
function GetPlayerJob(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return nil end
    
    return {
        name = Player.PlayerData.job.name,
        label = Player.PlayerData.job.label,
        type = Player.PlayerData.job.type,
        onDuty = Player.PlayerData.job.onduty,
        grade = Player.PlayerData.job.grade.name
    }
end

-- Check if player is police
function IsPlayerPolice(source)
    local job = GetPlayerJob(source)
    if not job then return false end
    
    return job.name == 'police' or job.type == 'leo'
end

-- Check if player is on duty
function IsPlayerOnDuty(source)
    local job = GetPlayerJob(source)
    if not job then return false end
    
    return job.onDuty
end

-- Exports
exports('GetPoliceOnDuty', GetPoliceOnDuty)
exports('SendPoliceMessage', SendPoliceMessage)
exports('HasRequiredItems', HasRequiredItems)
exports('RemoveItem', RemoveItem)
exports('AddItem', AddItem)
exports('AddMoney', AddMoney)
exports('GetPlayerCoords', GetPlayerCoords)
exports('GetPlayerDistance', GetPlayerDistance)
exports('FormatTimeRemaining', FormatTimeRemaining)
exports('GenerateLicensePlate', GenerateLicensePlate)
exports('LogToFile', LogToFile)
exports('SendDiscordWebhook', SendDiscordWebhook)
exports('GetStoreInfo', GetStoreInfo)
exports('GetAllStores', GetAllStores)
exports('GetNearbyStores', GetNearbyStores)
exports('IsPlayerInStore', IsPlayerInStore)
exports('GetPlayerWeapon', GetPlayerWeapon)
exports('IsWeaponIntimidating', IsWeaponIntimidating)
exports('GetPlayerJob', GetPlayerJob)
exports('IsPlayerPolice', IsPlayerPolice)
exports('IsPlayerOnDuty', IsPlayerOnDuty)
