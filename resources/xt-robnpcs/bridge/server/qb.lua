local useQbx = GetResourceState('qbx_core') == 'started'
local useQb = GetResourceState('qb-core') == 'started'
if not useQbx and not useQb then return end

local function getCorePlayer(src)
    if useQbx then
        return exports.qbx_core:GetPlayer(src)
    end
    local QBCore = exports['qb-core']:GetCoreObject()
    return QBCore.Functions.GetPlayer(src)
end

function getPlayer(src)
    return getCorePlayer(src)
end

function getPlayerJob(src)
    local player = getPlayer(src)
    return player and player.PlayerData.job.name or nil
end