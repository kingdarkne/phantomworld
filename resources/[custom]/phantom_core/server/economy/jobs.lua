-- Phantom Core - Job Payout System (Server)
-- Server-side job payout logic
local activeJobs = {}
local MAX_JOB_MINUTES = 8 * 60

local function sanitizeJobName(jobName)
    if type(jobName) ~= 'string' then return nil end
    jobName = jobName:sub(1, 50)
    if not jobName:match('^[%w_-]+$') then return nil end
    return jobName
end

local function processJobPayout(source)
    local session = activeJobs[source]
    activeJobs[source] = nil
    if not session then
        return { success = false, message = 'No active job session' }
    end

    local workedMinutes = math.min(MAX_JOB_MINUTES, math.floor((os.time() - session.startedAt) / 60))
    if workedMinutes <= 0 then
        return { success = false, message = 'No payable work time' }
    end

    local citizenid = GetCitizenId(source)
    if not citizenid then return { success = false, message = 'Player data not found' } end

    local playerData = GetPlayerDataByCitizenId(citizenid)
    if not playerData then return { success = false, message = 'Player data not found' } end

    local amount = Config.Economy.Jobs.DefaultPaycheck * workedMinutes
    if workedMinutes >= 60 then
        amount = math.floor(amount * Config.Economy.Jobs.BonusMultiplier)
    end

    -- Add money to bank
    local bank = playerData.money.bank or 0
    local newBank = bank + amount

    MySQL.query([[
        UPDATE players 
        SET money = JSON_SET(money, '$.bank', ?)
        WHERE citizenid = ?
    ]], { newBank, citizenid })

    AddTransaction(citizenid, 'job_payout', amount, 'Job: ' .. session.jobName .. ' (' .. workedMinutes .. ' min)', newBank)

    TriggerClientEvent('phantom:client:jobPayout', source, amount)

    return { success = true, bank = newBank }
end

RegisterNetEvent('phantom:server:startJob', function(jobName)
    local src = source
    jobName = sanitizeJobName(jobName)
    if not jobName then return end

    activeJobs[src] = {
        jobName = jobName,
        startedAt = os.time(),
    }
end)

RegisterNetEvent('phantom:server:jobPayout', function()
    processJobPayout(source)
end)

AddEventHandler('playerDropped', function()
    activeJobs[source] = nil
end)

-- Process job payout
lib.callback.register('phantom:server:jobPayout', function(source)
    return processJobPayout(source)
end)

function AddTransaction(citizenid, type, amount, description, balanceAfter)
    MySQL.query([[
        INSERT INTO phantom_transactions (citizenid, type, amount, description, balance_after)
        VALUES (?, ?, ?, ?, ?)
    ]], { citizenid, type, amount, description, balanceAfter })
end

DebugPrint('Job payout server loaded')
