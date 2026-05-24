local QBCore = exports['qbx_core']:GetCoreObject()

spawnedNPCs = {}
local npcStates = {}

-- NPC states
local NPC_STATE = {
    IDLE = 'idle',
    INTIMIDATED = 'intimidated',
    ROBBED = 'robbed',
    DEAD = 'dead'
}

-- Create NPC ped at store
function CreateStoreNPC(storeId)
    local store = Config.Stores[storeId]
    if not store then return nil end
    
    -- Load model
    local model = GetHashKey(GetRandomNPCModel())
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
    end
    
    -- Create ped
    local npc = CreatePed(4, model, store.npcCoords.x, store.npcCoords.y, store.npcCoords.z - 1.0, store.npcCoords.w, false, true)
    
    if DoesEntityExist(npc) then
        -- Set ped properties
        SetEntityHealth(npc, 100)
        SetPedArmour(npc, 0)
        SetPedDefaultComponentVariation(npc)
        SetPedRelationshipGroupHash(npc, GetHashKey("CIVMALE"))
        
        -- Make ped stay in place
        SetPedFleeAttributes(npc, 0, 0)
        SetPedCombatAttributes(npc, 46, 1)
        SetPedCombatAbility(npc, 0)
        SetPedCombatMovement(npc, 0)
        SetPedCombatRange(npc, 0)
        SetPedKeepTask(npc, true)
        
        -- Set AI behavior
        SetPedSeeingRange(npc, 0.0)
        SetPedHearingRange(npc, 0.0)
        SetPedAlertness(npc, 0)
        SetPedFleeAttributes(npc, 0, 0)
        
        -- Store NPC data
        spawnedNPCs[storeId] = npc
        npcStates[storeId] = {
            state = NPC_STATE.IDLE,
            lastIntimidation = 0,
            lastRobbery = 0
        }
        
        -- Start NPC behavior
        StartNPCBehavior(storeId)
        
        return npc
    end
    
    return nil
end

-- Start NPC behavior loop
function StartNPCBehavior(storeId)
    CreateThread(function()
        while spawnedNPCs[storeId] and DoesEntityExist(spawnedNPCs[storeId]) do
            local npc = spawnedNPCs[storeId]
            local state = npcStates[storeId]
            local store = Config.Stores[storeId]
            
            if state and store then
                -- Check for intimidation
                if state.state == NPC_STATE.IDLE then
                    CheckIntimidation(storeId, npc, state)
                end
                
                -- Handle animations based on state
                if state.state == NPC_STATE.INTIMIDATED then
                    HandleIntimidatedNPC(npc, state)
                elseif state.state == NPC_STATE.ROBBED then
                    HandleRobbedNPC(npc, state)
                else
                    HandleIdleNPC(npc, store)
                end
            end
            
            Wait(100)
        end
    end)
end

-- Check if player is intimidating NPC
function CheckIntimidation(storeId, npc, state)
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    local npcCoords = GetEntityCoords(npc)
    
    -- Check distance
    if #(playerCoords - npcCoords) > 5.0 then return end
    
    -- Check if player has weapon
    if not HasIntimidatingWeapon() then return end
    
    -- Check if player is looking at NPC
    local isLooking = IsPedAimingAtPed(ped, npc)
    if not isLooking then return end
    
    -- Check cooldown
    local currentTime = GetGameTimer()
    if currentTime - state.lastIntimidation < 3000 then return end -- 3 second cooldown
    
    -- Intimidate NPC
    state.state = NPC_STATE.INTIMIDATED
    state.lastIntimidation = currentTime
    
    -- Trigger intimidation event
    TriggerServerEvent('hybrid-storerobbery:server:NPCIntimidated', storeId)
end

-- Handle intimidated NPC behavior
function HandleIntimidatedNPC(npc, state)
    local currentTime = GetGameTimer()
    
    -- Play hands up animation
    if not IsEntityPlayingAnim(npc, 'missheistdockssetup1', 'handsup_base', 3) then
        RequestAnimDict('missheistdockssetup1')
        while not HasAnimDictLoaded('missheistdockssetup1') do
            Wait(10)
        end
        TaskPlayAnim(npc, 'missheistdockssetup1', 'handsup_base', 8.0, -8.0, -1, 49, 0, false, false, false)
    end
    
    -- Check if intimidation continues
    local ped = PlayerPedId()
    local playerCoords = GetEntityCoords(ped)
    local npcCoords = GetEntityCoords(npc)
    
    if #(playerCoords - npcCoords) > 5.0 or not HasIntimidatingWeapon() or not IsPedAimingAtPed(ped, npc) then
        state.state = NPC_STATE.IDLE
        ClearPedTasks(npc)
    end
end

-- Handle robbed NPC behavior
function HandleRobbedNPC(npc, state)
    local currentTime = GetGameTimer()
    
    -- Play cowering animation
    if not IsEntityPlayingAnim(npc, 'missheistdockssetup1', 'handsup_base', 3) then
        RequestAnimDict('missheistdockssetup1')
        while not HasAnimDictLoaded('missheistdockssetup1') do
            Wait(10)
        end
        TaskPlayAnim(npc, 'missheistdockssetup1', 'handsup_base', 8.0, -8.0, -1, 49, 0, false, false, false)
    end
    
    -- Return to idle after 30 seconds
    if currentTime - state.lastRobbery > 30000 then
        state.state = NPC_STATE.IDLE
        ClearPedTasks(npc)
    end
end

-- Handle idle NPC behavior
function HandleIdleNPC(npc, store)
    -- Play idle animation
    if not IsEntityPlayingAnim(npc, 'amb@world_human_stand_impatient@male@no_exit@base', 'base', 3) then
        RequestAnimDict('amb@world_human_stand_impatient@male@no_exit@base')
        while not HasAnimDictLoaded('amb@world_human_stand_impatient@male@no_exit@base') do
            Wait(10)
        end
        TaskPlayAnim(npc, 'amb@world_human_stand_impatient@male@no_exit@base', 'base', 8.0, -8.0, -1, 1, 0, false, false, false)
    end
end

-- Get NPC state
function GetNPCState(storeId)
    if npcStates[storeId] then
        return npcStates[storeId].state
    end
    return nil
end

-- Set NPC state
function SetNPCState(storeId, newState)
    if npcStates[storeId] then
        npcStates[storeId].state = newState
        if newState == NPC_STATE.ROBBED then
            npcStates[storeId].lastRobbery = GetGameTimer()
        end
    end
end

-- Check if NPC can be robbed
function CanRobNPC(storeId)
    local state = GetNPCState(storeId)
    if state == NPC_STATE.INTIMIDATED then
        return true
    end
    return false
end

-- Create all store NPCs
function CreateAllNPCs()
    for storeId, _ in pairs(Config.Stores) do
        CreateStoreNPC(storeId)
        Wait(100) -- Small delay between spawns
    end
end

-- Delete all NPCs
function DeleteAllNPCs()
    for storeId, npc in pairs(spawnedNPCs) do
        if DoesEntityExist(npc) then
            DeleteEntity(npc)
        end
    end
    spawnedNPCs = {}
    npcStates = {}
end

-- Initialize NPCs on resource start
CreateThread(function()
    Wait(2000) -- Wait for everything to load
    CreateAllNPCs()
end)

-- Clean up on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        DeleteAllNPCs()
    end
end)

-- Exports
exports('CreateStoreNPC', CreateStoreNPC)
exports('GetNPCState', GetNPCState)
exports('SetNPCState', SetNPCState)
exports('CanRobNPC', CanRobNPC)
exports('CreateAllNPCs', CreateAllNPCs)
exports('DeleteAllNPCs', DeleteAllNPCs)
