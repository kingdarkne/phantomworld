-- Phantom Core - Skill/XP System (Server)
-- Server-side skill management

-- Get player skills
lib.callback.register('phantom:server:getPlayerSkills', function(source)
    local citizenid = GetCitizenId(source)
    if not citizenid then return {} end
    
    local skills = MySQL.query.await('SELECT * FROM phantom_skills WHERE citizenid = ?', { citizenid })
    local skillData = {}
    
    for _, skill in ipairs(skills) do
        skillData[skill.skill_id] = {
            level = skill.level,
            xp = skill.xp,
            last_updated = skill.last_updated
        }
    end
    
    return skillData
end)

-- Update player skill
lib.callback.register('phantom:server:updateSkill', function(source, skillId, skillData)
    local citizenid = GetCitizenId(source)
    if not citizenid then return false end
    
    MySQL.query([[
        INSERT INTO phantom_skills (citizenid, skill_id, level, xp)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE level = VALUES(level), xp = VALUES(xp), last_updated = CURRENT_TIMESTAMP
    ]], { citizenid, skillId, skillData.level, skillData.xp })
    
    return true
end)

-- Skill level up
lib.callback.register('phantom:server:skillLevelUp', function(source, skillId, newLevel)
    local citizenid = GetCitizenId(source)
    if not citizenid then return false end
    
    -- Could add bonuses or rewards for leveling up
    return true
end)

-- Sync skills on player load
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local source = source
    local citizenid = GetCitizenId(source)
    if not citizenid then return end
    
    local skills = MySQL.query.await('SELECT * FROM phantom_skills WHERE citizenid = ?', { citizenid })
    local skillData = {}
    
    for _, skill in ipairs(skills) do
        skillData[skill.skill_id] = {
            level = skill.level,
            xp = skill.xp
        }
    end
    
    TriggerClientEvent('phantom:client:syncSkills', source, skillData)
end)

DebugPrint('Skill server loaded')
