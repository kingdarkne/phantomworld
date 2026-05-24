local QBCore = exports['qbx_core']:GetCoreObject()

-- Server-side tour management
local PlayerTours = {}
local TourStats = {}

-- Track player tour completion
local function TrackPlayerTour(source, tourData)
    local playerId = source
    local citizenid = QBCore.Functions.GetIdentifier(playerId, 'license')
    
    if not citizenid then return end
    
    -- Initialize player data if not exists
    if not TourStats[citizenid] then
        TourStats[citizenid] = {
            toursCompleted = 0,
            totalTimeSpent = 0,
            lastTourTime = 0,
            favoriteLocation = nil,
            locationsVisited = {}
        }
    end
    
    -- Update stats
    TourStats[citizenid].toursCompleted = TourStats[citizenid].toursCompleted + 1
    TourStats[citizenid].totalTimeSpent = TourStats[citizenid].totalTimeSpent + (tourData.duration or 0)
    TourStats[citizenid].lastTourTime = os.time()
    
    -- Track visited locations
    if tourData.locationsVisited then
        for _, locationId in ipairs(tourData.locationsVisited) do
            TourStats[citizenid].locationsVisited[locationId] = (TourStats[citizenid].locationsVisited[locationId] or 0) + 1
        end
    end
    
    -- Find favorite location
    local maxVisits = 0
    for locationId, visits in pairs(TourStats[citizenid].locationsVisited) do
        if visits > maxVisits then
            maxVisits = visits
            TourStats[citizenid].favoriteLocation = locationId
        end
    end
    
    -- Save to database (if you have a database system)
    -- This would typically save to your player data table
    TriggerClientEvent('QBCore:Notify', playerId, 'Tour completed! Stats updated.', 'success')
end

-- Get player tour stats
local function GetPlayerTourStats(source)
    local playerId = source
    local citizenid = QBCore.Functions.GetIdentifier(playerId, 'license')
    
    if not citizenid or not TourStats[citizenid] then
        return {
            toursCompleted = 0,
            totalTimeSpent = 0,
            lastTourTime = 0,
            favoriteLocation = nil,
            locationsVisited = {}
        }
    end
    
    return TourStats[citizenid]
end

-- Check if player can start tour (cooldown, permissions)
local function CanStartTour(source)
    local playerId = source
    local citizenid = QBCore.Functions.GetIdentifier(playerId, 'license')
    
    if not citizenid then return false, "Invalid player" end
    
    -- Check cooldown
    if TourStats[citizenid] and TourStats[citizenid].lastTourTime > 0 then
        local timeSinceLastTour = os.time() - TourStats[citizenid].lastTourTime
        local cooldownMinutes = Config.NewPlayerSettings.CooldownTime
        
        if timeSinceLastTour < (cooldownMinutes * 60) then
            local remainingTime = cooldownMinutes - math.floor(timeSinceLastTour / 60)
            return false, "Please wait " .. remainingTime .. " minutes before starting another tour."
        end
    end
    
    -- Check if player is in a vehicle
    local ped = GetPlayerPed(playerId)
    if IsPedInAnyVehicle(ped, false) then
        return false, "Please exit your vehicle before starting the tour."
    end
    
    -- Check if player is in combat
    if IsPlayerInCombat(playerId) then
        return false, "Cannot start tour while in combat."
    end
    
    return true, "Tour can be started"
end

-- Check if player is in combat (basic implementation)
function IsPlayerInCombat(source)
    local ped = GetPlayerPed(source)
    
    -- Check if player is wanted or has recent damage
    local health = GetEntityHealth(ped)
    local maxHealth = GetEntityMaxHealth(ped)
    
    -- If health is less than 75%, assume in combat
    if health < (maxHealth * 0.75) then
        return true
    end
    
    -- Check if player has recent weapon activity (you could expand this)
    local currentWeapon = GetSelectedPedWeapon(ped)
    if currentWeapon ~= `WEAPON_UNARMED` then
        return true
    end
    
    return false
end

-- Get tour leaderboard
local function GetTourLeaderboard(limit)
    limit = limit or 10
    local leaderboard = {}
    
    -- Sort players by tours completed
    for citizenid, stats in pairs(TourStats) do
        table.insert(leaderboard, {
            citizenid = citizenid,
            toursCompleted = stats.toursCompleted,
            totalTimeSpent = stats.totalTimeSpent,
            favoriteLocation = stats.favoriteLocation
        })
    end
    
    -- Sort by tours completed (descending)
    table.sort(leaderboard, function(a, b)
        return a.toursCompleted > b.toursCompleted
    end)
    
    -- Limit results
    local result = {}
    for i = 1, math.min(limit, #leaderboard) do
        table.insert(result, leaderboard[i])
    end
    
    return result
end

-- Get popular locations
local function GetPopularLocations()
    local locationStats = {}
    
    -- Aggregate location visits across all players
    for citizenid, stats in pairs(TourStats) do
        for locationId, visits in pairs(stats.locationsVisited) do
            locationStats[locationId] = (locationStats[locationId] or 0) + visits
        end
    end
    
    -- Sort by popularity
    local sortedLocations = {}
    for locationId, visits in pairs(locationStats) do
        table.insert(sortedLocations, {
            locationId = locationId,
            visits = visits
        })
    end
    
    table.sort(sortedLocations, function(a, b)
        return a.visits > b.visits
    end)
    
    return sortedLocations
end

-- Admin functions
local function AdminForceTourStart(source, targetId)
    if not source then return end
    
    -- Check if source is admin
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or not Player.PlayerData.group or not Config.AdminSettings.AdminPermissions[Player.PlayerData.group] then
        TriggerClientEvent('QBCore:Notify', source, 'You don\'t have permission for this command.', 'error')
        return
    end
    
    -- Force start tour for target
    if targetId then
        TriggerClientEvent('phantom_citytour:forceStart', targetId)
        TriggerClientEvent('QBCore:Notify', source, 'Tour forced for player.', 'success')
    else
        TriggerClientEvent('QBCore:Notify', source, 'Invalid player ID.', 'error')
    end
end

local function AdminForceTourStop(source, targetId)
    if not source then return end
    
    -- Check if source is admin
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or not Player.PlayerData.group or not Config.AdminSettings.AdminPermissions[Player.PlayerData.group] then
        TriggerClientEvent('QBCore:Notify', source, 'You don\'t have permission for this command.', 'error')
        return
    end
    
    -- Force stop tour for target
    if targetId then
        TriggerClientEvent('phantom_citytour:forceStop', targetId)
        TriggerClientEvent('QBCore:Notify', source, 'Tour stopped for player.', 'success')
    else
        TriggerClientEvent('QBCore:Notify', source, 'Invalid player ID.', 'error')
    end
end

local function AdminGetTourStats(source)
    if not source then return end
    
    -- Check if source is admin
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or not Player.PlayerData.group or not Config.AdminSettings.AdminPermissions[Player.PlayerData.group] then
        TriggerClientEvent('QBCore:Notify', source, 'You don\'t have permission for this command.', 'error')
        return
    end
    
    -- Send tour stats to admin
    local stats = {
        totalTours = 0,
        totalPlayers = 0,
        leaderboard = GetTourLeaderboard(10),
        popularLocations = GetPopularLocations()
    }
    
    -- Calculate totals
    for citizenid, playerStats in pairs(TourStats) do
        stats.totalTours = stats.totalTours + playerStats.toursCompleted
        stats.totalPlayers = stats.totalPlayers + 1
    end
    
    TriggerClientEvent('phantom_citytour:adminStats', source, stats)
end

-- Events
RegisterNetEvent('phantom_citytour:tourCompleted', function(tourData)
    local source = source
    TrackPlayerTour(source, tourData)
end)

RegisterNetEvent('phantom_citytour:requestStats', function()
    local source = source
    local stats = GetPlayerTourStats(source)
    TriggerClientEvent('phantom_citytour:receiveStats', source, stats)
end)

RegisterNetEvent('phantom_citytour:canStartTour', function()
    local source = source
    local canStart, message = CanStartTour(source)
    TriggerClientEvent('phantom_citytour:tourStartResponse', source, canStart, message)
end)

RegisterNetEvent('phantom_citytour:requestLeaderboard', function()
    local source = source
    local leaderboard = GetTourLeaderboard()
    TriggerClientEvent('phantom_citytour:receiveLeaderboard', source, leaderboard)
end)

RegisterNetEvent('phantom_citytour:requestPopularLocations', function()
    local source = source
    local popularLocations = GetPopularLocations()
    TriggerClientEvent('phantom_citytour:receivePopularLocations', source, popularLocations)
end)

-- Admin commands
RegisterCommand('forcetour', function(source, args, rawCommand)
    local targetId = tonumber(args[1])
    AdminForceTourStart(source, targetId)
end, false)

RegisterCommand('stoptour', function(source, args, rawCommand)
    local targetId = tonumber(args[1])
    AdminForceTourStop(source, targetId)
end, false)

RegisterCommand('tourstats', function(source, args, rawCommand)
    AdminGetTourStats(source)
end, false)

-- Debug commands (if enabled)
if Config.AdminSettings.DebugMode then
    RegisterCommand('resettourstats', function(source, args, rawCommand)
        local targetId = args[1]
        
        if targetId then
            local targetPlayer = QBCore.Functions.GetPlayer(tonumber(targetId))
            if targetPlayer then
                local citizenid = targetPlayer.PlayerData.citizenid
                TourStats[citizenid] = nil
                TriggerClientEvent('QBCore:Notify', source, 'Tour stats reset for player.', 'success')
            end
        else
            -- Reset all stats
            TourStats = {}
            TriggerClientEvent('QBCore:Notify', source, 'All tour stats reset.', 'success')
        end
    end, false)
end

-- Save tour stats periodically (if you have a database system)
CreateThread(function()
    while true do
        Wait(300000) -- Save every 5 minutes
        
        -- This would typically save to your database
        -- For example: MySQL.Async.execute('UPDATE player_tours SET ...', TourStats)
        
        if Config.AdminSettings.DebugMode then
            print('[Phantom City Tour] Tour stats auto-saved')
        end
    end
end)

-- Initialize on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print('[Phantom City Tour] Server-side tour management initialized')
        
        -- Load tour stats from database (if you have one)
        -- This would typically load from your player data table
    end
end)
