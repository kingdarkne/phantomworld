local QBCore = exports['qbx_core']:GetCoreObject()

local playerBlips = {}
local nearbyPlayers = {}
local isAdmin = false
local showBlips = true
blipUpdateInterval = 5000 -- Update every 5 seconds

-- Blip colors for different player states
local blipColors = {
    normal = 2,    -- Green
    police = 3,    -- Blue
    ems = 1,       -- Red
    mechanic = 17,  -- Orange
    vip = 5,       -- Yellow
    admin = 47      -- Purple
}

-- Blip sprites
local blipSprites = {
    normal = 1,    -- Standard blip
    police = 56,   -- Police car
    ems = 61,      -- Ambulance
    mechanic = 422, -- Wrench
    vip = 52,      -- Star
    admin = 304    -- Crown
}

-- Check if player is admin
function IsPlayerAdmin()
    local PlayerData = QBCore.Functions.GetPlayerData()
    if not PlayerData then return false end
    
    -- Check admin via player metadata (QBX method)
    return PlayerData.metadata and (PlayerData.metadata['isadmin'] == true or PlayerData.metadata['admin'] == true) or false
end

-- Get player job color
function GetPlayerJobColor(job)
    if job == 'lspd' or job == 'sahp' or job == 'bcso' then return blipColors.police
    elseif job == 'lsfd' or job == 'ambulance' or job == 'ems' then return blipColors.ems
    elseif job == 'mechanic' then return blipColors.mechanic
    else return blipColors.normal end
end

-- Get player job sprite
function GetPlayerJobSprite(job)
    if job == 'lspd' or job == 'sahp' or job == 'bcso' then return blipSprites.police
    elseif job == 'lsfd' or job == 'ambulance' or job == 'ems' then return blipSprites.ems
    elseif job == 'mechanic' then return blipSprites.mechanic
    else return blipSprites.normal end
end

-- Create or update player blip
function UpdatePlayerBlip(playerId, playerData)
    -- Remove existing blip if it exists
    if playerBlips[playerId] then
        RemoveBlip(playerBlips[playerId])
        playerBlips[playerId] = nil
    end
    
    -- Don't create blip for self
    if playerId == GetPlayerServerId(PlayerId()) then
        return
    end
    
    -- Check if we should show this player's blip
    if not shouldShowPlayerBlip(playerId, playerData) then
        return
    end
    
    -- Create new blip
    local blip = AddBlipForEntity(GetPlayerPed(GetPlayerFromServerId(playerId)))
    
    -- Set blip properties
    local color = GetPlayerJobColor(playerData.job)
    local sprite = GetPlayerJobSprite(playerData.job)
    
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, color)
    SetBlipScale(blip, 0.8)
    SetBlipAsShortRange(blip, true)
    
    -- Set blip name
    local name = playerData.name or 'Unknown'
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(name)
    EndTextCommandSetBlipName(blip)
    
    -- Store blip
    playerBlips[playerId] = blip
end

-- Check if we should show player's blip
function shouldShowPlayerBlip(playerId, playerData)
    -- Admins see all players
    if isAdmin then
        return true
    end
    
    -- Regular players only see nearby players
    local targetPed = GetPlayerPed(GetPlayerFromServerId(playerId))
    if not targetPed then return false end
    
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local targetCoords = GetEntityCoords(targetPed)
    
    local distance = #(myCoords - targetCoords)
    
    -- Show blip if within 500 meters
    return distance <= 500.0
end

-- Update all player blips
function UpdateAllPlayerBlips()
    local players = GetActivePlayers()
    
    for _, player in ipairs(players) do
        local playerId = GetPlayerServerId(player)
        local playerData = GetPlayerData(playerId)
        
        if playerData then
            UpdatePlayerBlip(playerId, playerData)
        end
    end
end

-- Get player data
function GetPlayerData(playerId)
    -- This would need to be implemented with your framework
    -- For now, we'll use basic data
    local ped = GetPlayerPed(GetPlayerFromServerId(playerId))
    if not ped then return nil end
    
    return {
        name = GetPlayerName(playerId),
        job = 'unknown' -- Would need to be fetched from server
    }
end

-- Clean up blips for disconnected players
function CleanupBlips()
    local activePlayers = {}
    
    for _, player in ipairs(GetActivePlayers()) do
        table.insert(activePlayers, GetPlayerServerId(player))
    end
    
    for playerId, blip in pairs(playerBlips) do
        local found = false
        for _, activeId in ipairs(activePlayers) do
            if playerId == activeId then
                found = true
                break
            end
        end
        
        if not found then
            RemoveBlip(blip)
            playerBlips[playerId] = nil
        end
    end
end

-- Toggle blips visibility
function ToggleBlips()
    showBlips = not showBlips
    
    if not showBlips then
        -- Hide all blips
        for playerId, blip in pairs(playerBlips) do
            SetBlipAlpha(blip, 0)
        end
    else
        -- Show all blips
        UpdateAllPlayerBlips()
    end
    
    QBCore.Functions.Notify('Player blips ' .. (showBlips and 'enabled' or 'disabled'), 'info')
end

-- Main update loop
CreateThread(function()
    while true do
        if showBlips then
            UpdateAllPlayerBlips()
            CleanupBlips()
        end
        Wait(blipUpdateInterval)
    end
end)

-- Check admin status on load
CreateThread(function()
    Wait(2000)
    isAdmin = IsPlayerAdmin()
end)

-- Events
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    isAdmin = IsPlayerAdmin()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    -- Update blips when job changes
    UpdateAllPlayerBlips()
end)

-- Commands
RegisterCommand('toggleblips', function()
    ToggleBlips()
end, false)

RegisterKeyMapping('toggleblips', 'Toggle Player Blips', 'keyboard', 'PERIOD')

-- NUI Callback for admin panel (if you have one)
RegisterNUICallback('updatePlayerBlips', function(data, cb)
    if isAdmin then
        UpdateAllPlayerBlips()
    end
    cb('ok')
end)

-- Exports
exports('ToggleBlips', ToggleBlips)
exports('IsAdmin', function() return isAdmin end)
exports('GetBlipCount', function() 
    local count = 0
    for _ in pairs(playerBlips) do
        count = count + 1
    end
    return count
end)
