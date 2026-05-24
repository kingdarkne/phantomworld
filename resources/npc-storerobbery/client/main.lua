local QBCore = exports['qb-core']:GetCoreObject()

local isRobbing = false
local currentStore = nil
local moneyBagProp = nil
local targetPeds = {}

-- Initialize
CreateThread(function()
    Wait(1000)
    SetupTargets()
end)

-- Setup ox_target for stores
function SetupTargets()
    for storeId, store in pairs(Config.Stores) do
        -- Register NPC target
        exports.ox_target:addLocalEntity(spawnedNPCs[storeId], {
            {
                name = 'npc_robbery_' .. storeId,
                icon = 'fas fa-hand-holding-usd',
                label = 'Intimidate Clerk',
                distance = 3.0,
                canInteract = function(entity, distance, coords, name)
                    return CanRobNPC(storeId) and HasIntimidatingWeapon() and not IsStoreOnCooldown(storeId)
                end,
                onSelect = function()
                    StartRobbery(storeId)
                end
            }
        })
        
        -- Register vault target
        exports.ox_target:addSphereZone({
            coords = store.vaultCoords,
            radius = 1.5,
            debug = false,
            options = {
                {
                    name = 'vault_hack_' .. storeId,
                    icon = 'fas fa-laptop-code',
                    label = 'Hack Vault',
                    distance = 2.0,
                    canInteract = function()
                        return not IsHackActive(storeId) and not IsStoreOnCooldown(storeId) and CanRobStore()
                    end,
                    onSelect = function()
                        StartVaultHacking(storeId, store.hackDifficulty)
                    end
                }
            }
        })
    end
end

-- Start robbery process
function StartRobbery(storeId)
    if isRobbing then
        Notify('Already robbing a store!', 'error')
        return
    end
    
    if not CanRobStore() then
        Notify('Not enough police online!', 'error')
        return
    end
    
    if IsStoreOnCooldown(storeId) then
        Notify('This store was recently robbed!', 'error')
        return
    end
    
    local store = Config.Stores[storeId]
    if not store then return end
    
    currentStore = storeId
    isRobbing = true
    
    -- Send police alert
    SendPoliceAlert(store.type, store.coords)
    
    -- Start robbery animation
    local success = RobberyAnimation(storeId)
    
    if success then
        -- Get reward
        local reward = math.random(store.registerReward.min, store.registerReward.max)
        TriggerServerEvent('npc-storerobbery:server:GiveRegisterReward', storeId, reward)
        
        -- Set NPC as robbed
        SetNPCState(storeId, NPC_STATE.ROBBED)
        
        -- Set cooldown
        SetStoreCooldown(storeId, 'register')
        
        Notify('Register robbed! Got $' .. reward, 'success')
    else
        Notify('Robbery failed!', 'error')
    end
    
    isRobbing = false
    currentStore = nil
end

-- Robbery animation sequence
function RobberyAnimation(storeId)
    local ped = PlayerPedId()
    local npc = spawnedNPCs[storeId]
    if not npc or not DoesEntityExist(npc) then return false end
    
    -- Move to NPC
    local npcCoords = GetEntityCoords(npc)
    TaskGoStraightToCoord(ped, npcCoords.x, npcCoords.y, npcCoords.z, 1.0, -1, 0.0, 0.0)
    
    -- Wait until close to NPC
    while #(GetEntityCoords(ped) - npcCoords) > 1.5 do
        Wait(100)
        if not HasIntimidatingWeapon() then
            Notify('You need a weapon to intimidate the clerk!', 'error')
            return false
        end
    end
    
    -- Face NPC
    TaskLookAtEntity(ped, npc, 5000, 512)
    TaskLookAtEntity(npc, ped, 5000, 512)
    
    -- Clear tasks
    ClearPedTasks(ped)
    ClearPedTasks(npc)
    
    -- Play intimidation animation
    RequestAnimDict('missheistdockssetup1')
    while not HasAnimDictLoaded('missheistdockssetup1') do
        Wait(10)
    end
    
    -- Player points gun
    TaskPlayAnim(ped, 'missheistdockssetup1', 'handsup_base', 8.0, -8.0, -1, 49, 0, false, false, false)
    
    -- NPC puts hands up
    TaskPlayAnim(npc, 'missheistdockssetup1', 'handsup_base', 8.0, -8.0, -1, 49, 0, false, false, false)
    
    Wait(2000)
    
    -- Start money bag animation
    moneyBagProp = PlayMoneyBagAnimation()
    
    -- NPC gives money animation
    RequestAnimDict('anim@amb@clubhouse@mini@clothing@')
    while not HasAnimDictLoaded('anim@amb@clubhouse@mini@clothing@') do
        Wait(10)
    end
    
    TaskPlayAnim(npc, 'anim@amb@clubhouse@mini@clothing@', 'clothing_loop', 8.0, -8.0, -1, 1, 0, false, false, false)
    
    Wait(3000)
    
    -- Stop animations
    StopMoneyBagAnimation(moneyBagProp)
    ClearPedTasks(ped)
    ClearPedTasks(npc)
    
    return true
end

-- Start vault hacking
function StartVaultHacking(storeId, difficulty)
    if isRobbing then
        Notify('Cannot hack vault while robbing!', 'error')
        return
    end
    
    if IsHackActive(storeId) then
        Notify('Hack already in progress!', 'error')
        return
    end
    
    if IsStoreOnCooldown(storeId) then
        Notify('Vault was recently accessed!', 'error')
        return
    end
    
    -- Choose hack type based on difficulty
    local success = false
    if difficulty == 'easy' then
        success = StartVaultHack(storeId, difficulty)
    elseif difficulty == 'medium' then
        success = StartComputerHack(storeId, difficulty)
    else
        success = StartThermiteHack(storeId, difficulty)
    end
    
    if success then
        SetStoreCooldown(storeId, 'vault')
    end
end

-- Draw 3D text for nearby stores
CreateThread(function()
    while true do
        local sleep = 1500
        local pedCoords = GetEntityCoords(PlayerPedId())
        
        for storeId, store in pairs(Config.Stores) do
            local distance = #(pedCoords - store.coords)
            
            if distance <= 10.0 then
                sleep = 0
                
                -- Draw store info
                local npc = spawnedNPCs[storeId]
                if npc and DoesEntityExist(npc) then
                    local npcState = GetNPCState(storeId)
                    local text = store.type:upper() .. ' STORE'
                    
                    if npcState == 'intimidated' then
                        text = text .. '\n~g~[E] Rob Register~w~'
                    elseif npcState == 'robbed' then
                        text = text .. '\n~r~Recently Robbed~w~'
                    else
                        if HasIntimidatingWeapon() then
                            text = text .. '\n~y~[E] Intimidate Clerk~w~'
                        end
                    end
                    
                    if not IsHackActive(storeId) and not IsStoreOnCooldown(storeId) then
                        text = text .. '\n~b~[E] Hack Vault~w~'
                    end
                    
                    DrawText3D(store.coords, text)
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- Events
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(1000)
    SetupTargets()
end)

RegisterNetEvent('npc-storerobbery:client:ResetNPC', function(storeId)
    if spawnedNPCs[storeId] and DoesEntityExist(spawnedNPCs[storeId]) then
        SetNPCState(storeId, NPC_STATE.IDLE)
        ClearPedTasks(spawnedNPCs[storeId])
    end
end)

RegisterNetEvent('npc-storerobbery:client:PoliceAlert', function(storeType, coords)
    if QBCore.Functions.GetPlayerData().job and (QBCore.Functions.GetPlayerData().job.name == 'police' or QBCore.Functions.GetPlayerData().job.type == 'leo') then
        local street = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        local streetName = GetStreetNameFromHashKey(street)
        
        TriggerEvent('QBCore:Notify', '10-90: Store robbery at ' .. streetName, 'error')
        
        -- Add blip
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, 161)
        SetBlipColour(blip, 1)
        SetBlipScale(blip, 1.0)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString('Store Robbery')
        EndTextCommandSetBlipName(blip)
        
        -- Remove blip after 30 seconds
        SetTimeout(30000, function()
            RemoveBlip(blip)
        end)
    end
end)

-- Keybinds
RegisterKeyMapping('npcrobbery_reload', 'Reload NPC Store Robbery', 'keyboard', 'F5')

RegisterCommand('npcrobbery_reload', function()
    DeleteAllNPCs()
    Wait(1000)
    CreateAllNPCs()
    SetupTargets()
    Notify('NPC Store Robbery reloaded!', 'info')
end)

-- Exports
exports('StartRobbery', StartRobbery)
exports('StartVaultHacking', StartVaultHacking)
exports('IsRobbing', function() return isRobbing end)
exports('GetCurrentStore', function() return currentStore end)
