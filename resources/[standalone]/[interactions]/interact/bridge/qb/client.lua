local function getQBCore()
    if GetResourceState('qbx_core') == 'started' then
        local ok, obj = pcall(function()
            return exports.qbx_core:GetCoreObject()
        end)
        if ok and obj then return obj end
    end
    error('[interact] No QBCore object: start qbx_core.')
end

local QBCore = getQBCore()
local Player = {}

-- Group Updaters --
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    if not Player.Group then return end

    Player.Group[Player.job] = nil
    Player.Group[job.name] = job.grade.level
    Player.job = job.name

    TriggerEvent('interact:groupsChanged', Player.Group)
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(job)
    if not Player.Group then return end

    Player.Group[Player.gang] = nil
    Player.Group[job.name] = job.grade.level
    Player.gang = job.name

    TriggerEvent('interact:groupsChanged', Player.Group)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    local PlayerData = QBCore.Functions.GetPlayerData()

    Player = {
        Group = {
            [PlayerData.job.name] = PlayerData.job.grade.level,
            [PlayerData.gang.name] = PlayerData.gang.grade.level
        },
        job = PlayerData.job.name,
        gang = PlayerData.gang.name,
    }

    TriggerEvent('interact:groupsChanged', Player.Group)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    Player = table.wipe(Player)

    TriggerEvent('interact:groupsChanged', {})
end)