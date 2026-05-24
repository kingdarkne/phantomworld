-- Phantom Core - Custom Job System with Progression
-- High-quality job system with progression and ranks

local jobProgression = {
    police = {
        ranks = {
            { level = 1, name = 'Cadet', pay = 500 },
            { level = 2, name = 'Officer', pay = 750 },
            { level = 3, name = 'Sergeant', pay = 1000 },
            { level = 4, name = 'Lieutenant', pay = 1500 },
            { level = 5, name = 'Captain', pay = 2000 },
            { level = 6, name = 'Chief', pay = 3000 },
        },
        xpPerAction = 25,
    },
    ems = {
        ranks = {
            { level = 1, name = 'Intern', pay = 500 },
            { level = 2, name = 'Paramedic', pay = 750 },
            { level = 3, name = 'Senior Paramedic', pay = 1000 },
            { level = 4, name = 'Doctor', pay = 1500 },
            { level = 5, name = 'Chief Surgeon', pay = 2500 },
        },
        xpPerAction = 25,
    },
    mechanic = {
        ranks = {
            { level = 1, name = 'Apprentice', pay = 300 },
            { level = 2, name = 'Mechanic', pay = 450 },
            { level = 3, name = 'Senior Mechanic', pay = 600 },
            { level = 4, name = 'Master Mechanic', pay = 800 },
            { level = 5, name = 'Shop Owner', pay = 1200 },
        },
        xpPerAction = 20,
    },
}

local playerJobProgression = {}

-- Initialize job progression
function InitializeJobProgression(jobName)
    if not playerJobProgression[jobName] then
        playerJobProgression[jobName] = {
            level = 1,
            xp = 0,
            totalActions = 0
        }
    end
end

-- Add job XP
function AddJobXP(jobName, xp)
    InitializeJobProgression(jobName)
    
    local progression = playerJobProgression[jobName]
    progression.xp = progression.xp + xp
    progression.totalActions = progression.totalActions + 1
    
    -- Check for level up
    local jobData = jobProgression[jobName]
    if jobData then
        local maxLevel = #jobData.ranks
        
        if progression.level < maxLevel then
            local nextRank = jobData.ranks[progression.level + 1]
            local xpNeeded = progression.level * 100 -- XP formula: level * 100
            
            if progression.xp >= xpNeeded then
                progression.level = progression.level + 1
                progression.xp = progression.xp - xpNeeded
                
                TriggerServerEvent('phantom:server:jobLevelUp', jobName, progression.level)
                
                SendNotification({
                    type = 'success',
                    message = 'Promoted to ' .. nextRank.name .. '!'
                })
            end
        end
    end
    
    -- Sync with server
    TriggerServerEvent('phantom:server:updateJobProgression', jobName, progression)
end

-- Get job rank info
function GetJobRank(jobName, level)
    local jobData = jobProgression[jobName]
    if not jobData then return nil end
    
    return jobData.ranks[level] or jobData.ranks[#jobData.ranks]
end

-- Get current job progression
function GetJobProgression(jobName)
    return playerJobProgression[jobName]
end

-- Open job progression menu
function OpenJobProgressionMenu()
    local playerData = GetPlayerData()
    local currentJob = playerData and playerData.job and playerData.job.name
    
    if not currentJob then
        SendNotification({
            type = 'error',
            message = 'You are not employed'
        })
        return
    end
    
    InitializeJobProgression(currentJob)
    local progression = GetJobProgression(currentJob)
    local currentRank = GetJobRank(currentJob, progression.level)
    local nextRank = GetJobRank(currentJob, progression.level + 1)
    local jobData = jobProgression[currentJob]
    local xpNeeded = progression.level * 100
    
    local options = {}
    
    -- Current rank
    table.insert(options, {
        label = 'Current Rank: ' .. currentRank.name,
        description = 'Level ' .. progression.level .. ' - Pay: ' .. FormatMoney(currentRank.pay),
        icon = '⭐',
        disabled = true
    })
    
    -- XP progress
    local xpPercent = math.floor((progression.xp / xpNeeded) * 100)
    table.insert(options, {
        label = 'XP Progress: ' .. progression.xp .. '/' .. xpNeeded,
        description = xpPercent .. '% to next rank',
        icon = '📊',
        disabled = true
    })
    
    -- Next rank
    if nextRank then
        table.insert(options, {
            label = 'Next Rank: ' .. nextRank.name,
            description = 'Level ' .. (progression.level + 1) .. ' - Pay: ' .. FormatMoney(nextRank.pay),
            icon = '🎯',
            disabled = true
        })
    else
        table.insert(options, {
            label = 'Max Rank Reached',
            description = 'You are at the highest rank',
            icon = '🏆',
            disabled = true
        })
    end
    
    -- Total actions
    table.insert(options, {
        label = 'Total Actions: ' .. progression.totalActions,
        description = 'Job actions completed',
        icon = '📋',
        disabled = true
    })
    
    ShowMenu({
        title = 'Job Progression',
        options = options
    })
end

-- Register command
RegisterCommand('jobprogress', function()
    OpenJobProgressionMenu()
end)

-- Server events
RegisterNetEvent('phantom:client:jobLevelUp', function(jobName, newLevel)
    local rank = GetJobRank(jobName, newLevel)
    if rank then
        SendNotification({
            type = 'success',
            message = 'Promoted to ' .. rank.name .. '!'
        })
    end
end)

RegisterNetEvent('phantom:client:syncJobProgression', function(jobName, progression)
    playerJobProgression[jobName] = progression
end)

-- Export functions
exports('AddJobXP', AddJobXP)
exports('GetJobProgression', GetJobProgression)
exports('GetJobRank', GetJobRank)

DebugPrint('Job progression system loaded')
