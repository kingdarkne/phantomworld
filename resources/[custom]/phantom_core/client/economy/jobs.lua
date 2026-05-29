-- Phantom Core - Job Payout System
-- High-quality job payout system with bonuses

local currentJob = nil
local jobTimer = nil
local timeWorked = 0

-- Start job
function StartJob(jobName)
    currentJob = jobName
    timeWorked = 0
    
    SendNotification({
        notificationType = 'success',
        message = 'Started job: ' .. jobName
    })
    
    -- Start timer
    CreateThread(function()
        while currentJob do
            Wait(60000) -- 1 minute
            timeWorked = timeWorked + 1
        end
    end)
end

-- Stop job
function StopJob()
    if not currentJob then return end
    
    local workedMinutes = timeWorked
    local basePay = Config.Economy.Jobs.DefaultPaycheck
    local totalPay = basePay * workedMinutes
    
    -- Apply bonus multiplier
    if workedMinutes >= 60 then -- Bonus for working 1+ hour
        totalPay = totalPay * Config.Economy.Jobs.BonusMultiplier
    end
    
    -- Payout
    TriggerServerEvent('phantom:server:jobPayout', currentJob, workedMinutes, totalPay)
    
    SendNotification({
        notificationType = 'info',
        message = 'Job ended. Worked: ' .. workedMinutes .. ' minutes'
    })
    
    currentJob = nil
    timeWorked = 0
end

-- Get job info
function GetJobInfo()
    local playerData = GetPlayerData()
    if not playerData or not playerData.job then
        return nil
    end
    
    return {
        name = playerData.job.name,
        label = playerData.job.label,
        grade = playerData.job.grade.level,
        gradeLabel = playerData.job.grade.name,
        isOnDuty = playerData.job.onduty
    }
end

-- Register command
RegisterCommand('startjob', function(source, args)
    if #args == 0 then
        SendNotification({
            notificationType = 'error',
            message = 'Usage: /startjob [jobname]'
        })
        return
    end
    
    StartJob(args[1])
end)

RegisterCommand('stopjob', function()
    StopJob()
end)

-- Server event
RegisterNetEvent('phantom:client:jobPayout', function(amount)
    SendNotification({
        notificationType = 'money',
        message = 'Received ' .. FormatMoney(amount) .. ' from job'
    })
end)

-- Export functions
exports('StartJob', StartJob)
exports('StopJob', StopJob)
exports('GetJobInfo', GetJobInfo)

DebugPrint('Job payout system loaded')
