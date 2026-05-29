local QBCore = exports['qbx_core']:GetCoreObject()

local function countEmsOnline()
    local count = 0
    for _, src in ipairs(GetPlayers()) do
        local player = QBCore.Functions.GetPlayer(tonumber(src))
        if player and player.PlayerData and player.PlayerData.job then
            local job = player.PlayerData.job
            for i = 1, #Config.EmsJobs do
                local rule = Config.EmsJobs[i]
                if job.name == rule.jobName then
                    if not rule.onDutyOnly or job.onduty then
                        count = count + 1
                        break
                    end
                end
            end
        end
    end
    return count
end

RegisterNetEvent('fenix-ems:server:playerDown', function()
    local src = source
    if countEmsOnline() >= (Config.EmsJobsRequired or 1) then
        return
    end
    TriggerClientEvent('fenix-ems:client:tryAutoDispatch', src)
end)

RegisterNetEvent('fenix-ems:server:logDispatch', function()
    local src = source
    print(('[fenix-ems] AI EMS dispatched for player %s'):format(src))
end)

RegisterNetEvent('fenix-ems:server:clearDeathState', function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    player.Functions.SetMetaData('isdead', false)
    player.Functions.SetMetaData('inlaststand', false)
end)

RegisterNetEvent('fenix-ems:server:chargeFee', function()
    local src = source
    local fee = Config.ChargeFee or 0
    if fee <= 0 then return end
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    if player.Functions.RemoveMoney('bank', fee, 'ai-ems-response') then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'EMS Billing',
            description = ('You were charged $%s for AI EMS treatment.'):format(fee),
            type = 'inform',
        })
    end
end)

RegisterCommand('aiems', function(source)
    if source <= 0 then return end
    TriggerClientEvent('fenix-ems:client:dispatch', source)
end, false)
