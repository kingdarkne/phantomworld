local QBCore

CreateThread(function()
    while GetResourceState('qbx_core') ~= 'started' do
        Wait(100)
    end
    QBCore = exports['qbx_core']:GetCoreObject()
end)

local VALID = {
    unemployed = true,
    trucker = true,
    garbage = true,
    tow = true,
    taxi = true,
    mechanic = true,
    burgershot = true,
    security = true,
    recycle = true,
    hunter = true,
    police = true,
    ambulance = true,
    criminal = true, -- meta flag via unemployed + phone contracts
}

RegisterNetEvent('phantom_freeroam:setJob', function(jobId, criminal)
    local src = source
    if not QBCore then return end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if type(jobId) ~= 'string' or not VALID[jobId] then return end

    if jobId == 'criminal' then
        Player.Functions.SetJob('unemployed', 0)
        Player.Functions.SetMetaData('phantom_contracts', true)
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Contact',
            description = 'Stay by your phone — contracts will start coming in.',
            type = 'inform',
        })
        TriggerEvent('phantom_jobcalls:enableContracts', src)
        return
    end

    -- hunter maps to unemployed + hunting tip (sm_hunting is activity based)
    if jobId == 'hunter' then
        Player.Functions.SetJob('unemployed', 0)
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Hunting',
            description = 'Head north — use your hunting gear near the cabin blip.',
            type = 'success',
        })
        return
    end

    local ok, err = pcall(function()
        Player.Functions.SetJob(jobId, 0)
    end)
    if not ok then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Job Board',
            description = ('Could not set job %s'):format(jobId),
            type = 'error',
        })
        print(('[phantom_freeroam] SetJob failed for %s: %s'):format(jobId, tostring(err)))
        return
    end

    Player.Functions.SetMetaData('phantom_contracts', criminal == true)
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Job Updated',
        description = ('You are now: %s'):format(jobId),
        type = 'success',
    })
end)
