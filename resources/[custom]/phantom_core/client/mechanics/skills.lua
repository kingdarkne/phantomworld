-- Phantom Core - Skill/XP System
-- High-quality skill system with leveling

local playerSkills = {}

-- Initialize skill
function InitializeSkill(skillId)
    if not playerSkills[skillId] then
        local skillConfig = nil
        for _, skill in ipairs(Config.Mechanics.Skills.Skills) do
            if skill.id == skillId then
                skillConfig = skill
                break
            end
        end
        
        playerSkills[skillId] = {
            level = 1,
            xp = 0,
            totalActions = 0,
            name = skillConfig and skillConfig.name or skillId,
            icon = skillConfig and skillConfig.icon or '🎯'
        }
    end
end

-- Add skill XP
function AddSkillXP(skillId, xp)
    InitializeSkill(skillId)
    
    local skill = playerSkills[skillId]
    xp = xp or Config.Mechanics.Skills.XPPerAction
    
    skill.xp = skill.xp + (xp * Config.Mechanics.Skills.XPMultiplier)
    skill.totalActions = skill.totalActions + 1
    
    -- Check for level up
    local maxLevel = Config.Mechanics.Skills.MaxLevel
    local xpNeeded = skill.level * 100 -- XP formula: level * 100
    
    if skill.level < maxLevel and skill.xp >= xpNeeded then
        skill.level = skill.level + 1
        skill.xp = skill.xp - xpNeeded
        
        TriggerServerEvent('phantom:server:skillLevelUp', skillId, skill.level)
        
        SendNotification({
            notificationType = 'success',
            message = skill.name .. ' leveled up to ' .. skill.level .. '!'
        })
    end
    
    -- Sync with server
    TriggerServerEvent('phantom:server:updateSkill', skillId, skill)
end

-- Get skill info
function GetSkill(skillId)
    return playerSkills[skillId]
end

-- Get all skills
function GetAllSkills()
    return playerSkills
end

-- Open skills menu
function OpenSkillsMenu()
    local options = {}
    
    -- Add each skill
    for _, skillConfig in ipairs(Config.Mechanics.Skills.Skills) do
        local skill = GetSkill(skillConfig.id)
        if not skill then
            InitializeSkill(skillConfig.id)
            skill = GetSkill(skillConfig.id)
        end
        
        local xpNeeded = skill.level * 100
        local xpPercent = math.floor((skill.xp / xpNeeded) * 100)
        local isMaxLevel = skill.level >= Config.Mechanics.Skills.MaxLevel
        
        table.insert(options, {
            label = skill.name .. ' (Level ' .. skill.level .. ')',
            description = isMaxLevel and 'MAX LEVEL' or (xpPercent .. '% to level ' .. (skill.level + 1)),
            icon = skill.icon,
            disabled = true
        })
    end
    
    -- Add close option
    table.insert(options, {
        label = 'Close',
        description = 'Close skills menu',
        icon = '❌'
    })
    
    ShowMenu({
        title = 'Skills',
        options = options
    })
end

-- Track skill actions
CreateThread(function()
    while true do
        Wait(1000)
        
        local ped = PlayerPedId()
        
        -- Track driving skill
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            local speed = GetEntitySpeed(vehicle)
            
            if speed > 10 then -- Moving
                AddSkillXP('driving', 1)
            end
        end
        
        -- Track stamina
        if IsPedRunning(ped) then
            AddSkillXP('stamina', 1)
        end
    end
end)

-- Register command
RegisterCommand('skills', function()
    OpenSkillsMenu()
end)

-- Server events
RegisterNetEvent('phantom:client:skillLevelUp', function(skillId, newLevel)
    local skill = GetSkill(skillId)
    if skill then
        SendNotification({
            notificationType = 'success',
            message = skill.name .. ' leveled up to ' .. newLevel .. '!'
        })
    end
end)

RegisterNetEvent('phantom:client:syncSkills', function(skills)
    playerSkills = skills
end)

-- Export functions
exports('AddSkillXP', AddSkillXP)
exports('GetSkill', GetSkill)
exports('GetAllSkills', GetAllSkills)

DebugPrint('Skill system loaded')
