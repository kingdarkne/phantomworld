local jobs = require 'shared.jobs'
local gangs = require 'shared.gangs'

---@return table<string, Job>
function GetJobs()
    return jobs
end

exports('GetJobs', GetJobs)

---@return table<string, Gang>
function GetGangs()
    return gangs
end

exports('GetGangs', GetGangs)

---@param name string
---@return Job?
function GetJob(name)
    return jobs[name]
end

exports('GetJob', GetJob)

---@param name string
---@return Gang?
function GetGang(name)
    return gangs[name]
end

exports('GetGang', GetGang)

RegisterNetEvent('qbx_core:client:onJobUpdate', function(jobName, job)
    jobs[jobName] = job
end)

RegisterNetEvent('qbx_core:client:onGangUpdate', function(gangName, gang)
    gangs[gangName] = gang
end)

-- Await must not abort client load: if this errors, GetPlayerData/GetCoreObject never register and every QB script breaks.
local ok, groups = pcall(function()
    return lib.callback.await('qbx_core:server:getGroups')
end)
if ok and groups and type(groups) == 'table' and groups.jobs and groups.gangs then
    jobs = groups.jobs
    gangs = groups.gangs
end