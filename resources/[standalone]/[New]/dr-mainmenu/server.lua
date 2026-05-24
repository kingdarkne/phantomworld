local AllowedJobs = {
    ['unemployed'] = true,
    ['trucker'] = true,
    ['garbage'] = true,
    ['tow'] = true,
    ['taxi'] = true,
    ['security'] = true,
}

RegisterNetEvent('dr-mainmenu:server:setJob', function(jobName)
    local src = source
    jobName = tostring(jobName or ''):lower()
    if not AllowedJobs[jobName] then
        TriggerClientEvent('ox_lib:notify', src, { description = 'That job cannot be selected here.', type = 'error' })
        return
    end

    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then return end

    Player.Functions.SetJob(jobName, 0)
    local jobs = exports.qbx_core:GetJobs()
    local label = (jobs and jobs[jobName] and jobs[jobName].label) or jobName
    TriggerClientEvent('ox_lib:notify', src, { description = ('Job changed to %s.'):format(label), type = 'success' })
end)

