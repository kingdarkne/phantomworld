local QBCore = exports['qb-core']:GetCoreObject()

local activeHacks = {}
local hackAttempts = {}

-- Hacking difficulties
local HACK_DIFFICULTY = {
    EASY = {
        blocks = 4,
        time = 15000,
        inputs = {'W', 'A', 'S', 'D'}
    },
    MEDIUM = {
        blocks = 6,
        time = 20000,
        inputs = {'W', 'A', 'S', 'D'}
    },
    HARD = {
        blocks = 8,
        time = 25000,
        inputs = {'W', 'A', 'S', 'D'}
    }
}

-- Start vault hacking
function StartVaultHack(storeId, difficulty)
    if activeHacks[storeId] then
        Notify('Vault hack already in progress!', 'error')
        return false
    end
    
    if not CanRobStore() then
        Notify('Not enough police online!', 'error')
        return false
    end
    
    local hackConfig = HACK_DIFFICULTY[difficulty:upper()]
    if not hackConfig then
        hackConfig = HACK_DIFFICULTY.EASY
    end
    
    activeHacks[storeId] = true
    hackAttempts[storeId] = (hackAttempts[storeId] or 0) + 1
    
    -- Start minigame
    local success = lib.skillCheck({
        'easy',
        'easy',
        difficulty:lower(),
        difficulty:lower(),
        difficulty:lower()
    }, hackConfig.inputs)
    
    if success then
        -- Hack successful
        TriggerServerEvent('npc-storerobbery:server:VaultHackSuccess', storeId)
        Notify('Vault hack successful! Opening vault...', 'success')
        
        -- Start vault opening animation
        StartVaultAnimation()
        
        -- Wait for vault to open
        Wait(3000)
        
        -- Give rewards
        TriggerServerEvent('npc-storerobbery:server:GiveVaultReward', storeId)
        
        activeHacks[storeId] = false
        hackAttempts[storeId] = 0
    else
        -- Hack failed
        Notify('Vault hack failed!', 'error')
        TriggerServerEvent('npc-storerobbery:server:VaultHackFailed', storeId)
        
        if hackAttempts[storeId] >= Config.HackAttempts then
            Notify('Max hack attempts reached! Vault locked down.', 'error')
            activeHacks[storeId] = false
            hackAttempts[storeId] = 0
            SetStoreCooldown(storeId, 'vault')
        else
            activeHacks[storeId] = false
            Notify('Attempts remaining: ' .. (Config.HackAttempts - hackAttempts[storeId]), 'warning')
        end
    end
    
    return success
end

-- Start vault opening animation
function StartVaultAnimation()
    local ped = PlayerPedId()
    
    -- Load animation
    RequestAnimDict('anim@heists@prison_heiststation@cop_reactions')
    while not HasAnimDictLoaded('anim@heists@prison_heiststation@cop_reactions') do
        Wait(10)
    end
    
    -- Play animation
    TaskPlayAnim(ped, 'anim@heists@prison_heiststation@cop_reactions', 'cop_b_idle', 8.0, -8.0, -1, 1, 0, false, false, false)
    
    -- Create drill prop
    local drill = CreateObject(GetHashKey('prop_tool_drill'), 0, 0, 0, true, true, true)
    AttachEntityToEntity(drill, ped, GetPedBoneIndex(ped, 57005), 0.15, 0.05, 0.0, -80.0, 120.0, 0.0, true, false, false, false, 2, true)
    
    -- Sound effect
    PlaySoundFrontend(-1, 'Drill_Pin_Break', 'DLC_HEIST_FLEECA_SOUNDSET', true)
    
    -- Clean up after animation
    Wait(3000)
    ClearPedTasks(ped)
    if DoesEntityExist(drill) then
        DeleteEntity(drill)
    end
end

-- Check if hack is active
function IsHackActive(storeId)
    return activeHacks[storeId] or false
end

-- Get hack attempts
function GetHackAttempts(storeId)
    return hackAttempts[storeId] or 0
end

-- Reset hack attempts
function ResetHackAttempts(storeId)
    hackAttempts[storeId] = 0
end

-- Computer hacking alternative (more complex)
function StartComputerHack(storeId, difficulty)
    if activeHacks[storeId] then
        Notify('Computer hack already in progress!', 'error')
        return false
    end
    
    activeHacks[storeId] = true
    hackAttempts[storeId] = (hackAttempts[storeId] or 0) + 1
    
    -- Show input dialog for computer password
    local input = lib.inputDialog('Vault Computer', {
        {type = 'input', label = 'Username', required = true, default = 'admin'},
        {type = 'input', label = 'Password', required = true, password = true},
        {type = 'select', label = 'Security Level', options = {
            {value = '1', label = 'Level 1 - Basic'},
            {value = '2', label = 'Level 2 - Standard'},
            {value = '3', label = 'Level 3 - Advanced'}
        }, default = '1'}
    })
    
    if not input then
        activeHacks[storeId] = false
        return false
    end
    
    -- Simulate computer processing
    Notify('Processing credentials...', 'info')
    Wait(2000)
    
    -- Random success based on difficulty
    local successChance = difficulty == 'easy' and 70 or difficulty == 'medium' and 50 or 30
    local success = math.random(100) <= successChance
    
    if success then
        TriggerServerEvent('npc-storerobbery:server:VaultHackSuccess', storeId)
        Notify('Access granted! Opening vault...', 'success')
        
        StartVaultAnimation()
        Wait(3000)
        
        TriggerServerEvent('npc-storerobbery:server:GiveVaultReward', storeId)
        
        activeHacks[storeId] = false
        hackAttempts[storeId] = 0
    else
        Notify('Access denied! Invalid credentials.', 'error')
        TriggerServerEvent('npc-storerobbery:server:VaultHackFailed', storeId)
        
        if hackAttempts[storeId] >= Config.HackAttempts then
            Notify('System locked down! Too many failed attempts.', 'error')
            activeHacks[storeId] = false
            hackAttempts[storeId] = 0
            SetStoreCooldown(storeId, 'vault')
        else
            activeHacks[storeId] = false
            Notify('Attempts remaining: ' .. (Config.HackAttempts - hackAttempts[storeId]), 'warning')
        end
    end
    
    return success
end

-- Thermite hacking alternative
function StartThermiteHack(storeId, difficulty)
    if activeHacks[storeId] then
        Notify('Thermite charge already placed!', 'error')
        return false
    end
    
    -- Check if player has thermite
    if not QBCore.Functions.HasItem('thermite') then
        Notify('You need thermite to blow the vault!', 'error')
        return false
    end
    
    activeHacks[storeId] = true
    
    -- Start thermite minigame
    local success = lib.skillCheck({'easy', 'medium', 'hard'}, {'W', 'A', 'S', 'D'})
    
    if success then
        -- Remove thermite
        TriggerServerEvent('QBCore:Server:RemoveItem', 'thermite', 1)
        TriggerEvent('inventory:client:ItemBox', QBCore.Shared.Items['thermite'], 'remove')
        
        -- Start explosion effect
        StartThermiteEffect()
        
        Wait(2000)
        
        TriggerServerEvent('npc-storerobbery:server:VaultHackSuccess', storeId)
        TriggerServerEvent('npc-storerobbery:server:GiveVaultReward', storeId)
        
        Notify('Vault breached! Grab the money!', 'success')
        
        activeHacks[storeId] = false
        hackAttempts[storeId] = 0
    else
        Notify('Thermite placement failed!', 'error')
        activeHacks[storeId] = false
    end
    
    return success
end

-- Thermite visual effect
function StartThermiteEffect()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    
    -- Create particle effect
    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do
        Wait(10)
    end
    
    UseParticleFxAsset('core')
    StartParticleFxNonLoopedAtCoord('exp_grd_bazooka', coords.x, coords.y, coords.z + 1.0, 0.0, 0.0, 0.0, 1.0, false, false, false)
    
    -- Sound effect
    PlaySoundFrontend(-1, 'Car_Bomb_P Explode', 'GTAO_FM_Events_Soundset', true)
    
    -- Screen shake
    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 1.0)
end

-- Exports
exports('StartVaultHack', StartVaultHack)
exports('StartComputerHack', StartComputerHack)
exports('StartThermiteHack', StartThermiteHack)
exports('IsHackActive', IsHackActive)
exports('GetHackAttempts', GetHackAttempts)
exports('ResetHackAttempts', ResetHackAttempts)
