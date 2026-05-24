local QBCore = exports['qbx_core']:GetCoreObject()

local isRobbing = false
local currentStore = nil
local moneyBagProp = nil

-- Initialize
CreateThread(function()
    Wait(1000)
    SetupTargets()
end)

-- Setup ox_target for stores
function SetupTargets()
    for storeId, store in pairs(Config.Stores) do
        -- Register NPC target (for manual interaction)
        if spawnedNPCs[storeId] then
            exports.ox_target:addLocalEntity(spawnedNPCs[storeId], {
                {
                    name = 'hybrid_robbery_' .. storeId,
                    icon = 'fas fa-hand-holding-usd',
                    label = 'Store Options',
                    distance = 3.0,
                    canInteract = function(entity, distance, coords, name)
                        return not isMenuOpen
                    end,
                    onSelect = function()
                        currentStore = storeId
                        ShowStoreMenu(storeId)
                        isMenuOpen = true
                    end
                }
            })
        end
        
        -- Register vault target (if using existing systems)
        exports.ox_target:addSphereZone({
            coords = store.coords,
            radius = 2.0,
            debug = false,
            options = {
                {
                    name = 'hybrid_vault_' .. storeId,
                    icon = 'fas fa-laptop-code',
                    label = 'Hack Vault',
                    distance = 2.0,
                    canInteract = function()
                        return not IsStoreOnCooldown(storeId) and CanRobStore() and Config.UseMZStoreRobbery
                    end,
                    onSelect = function()
                        StartVaultHack(storeId)
                    end
                }
            }
        })
    end
end

-- Start NPC robbery process
function StartNPCRobberyProcess(storeId)
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
        TriggerServerEvent('hybrid-storerobbery:server:GiveRegisterReward', storeId, reward)
        
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

-- Robbery animation sequence with enhanced progress bar
function RobberyAnimation(storeId)
    local ped = PlayerPedId()
    local npc = spawnedNPCs[storeId]
    if not npc or not DoesEntityExist(npc) then return false end
    
    local store = Config.Stores[storeId]
    if not store then return false end
    
    -- Calculate reward for progress bar
    local totalReward = math.random(store.registerReward.min, store.registerReward.max)
    local nearbyPlayers = GetNearbyRobberyPlayers()
    local playerCount = #nearbyPlayers + 1 -- Include current player
    
    -- Calculate individual share
    local individualShare = math.floor(totalReward / playerCount)
    
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
    
    -- Play intimidation animation with progress bar
    RequestAnimDict('missheistdockssetup1')
    while not HasAnimDictLoaded('missheistdockssetup1') do
        Wait(10)
    end
    
    -- Enhanced progress bar showing money and player distribution
    local progressData = {
        label = 'Intimidating Clerk',
        duration = 3000,
        anim = {
            dict = 'missheistdockssetup1',
            clip = 'handsup_base',
            flags = 49,
        },
        prop = {
            model = 'prop_w_me_hatchet_01',
            bone = 57005,
            coords = vec3(0.08, 0.0, -0.02),
            rotation = vec3(0.0, 0.0, 0.0),
        },
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = false,
        },
        customData = {
            totalReward = totalReward,
            playerCount = playerCount,
            individualShare = individualShare,
            nearbyPlayers = nearbyPlayers
        }
    }
    
    -- Trigger enhanced progress bar
    TriggerEvent('progressbar:client:progress', progressData, function(cancelled)
        if cancelled then
            ClearPedTasks(ped)
            ClearPedTasks(npc)
            Notify('Robbery cancelled!', 'error')
            return false
        end
        
        -- Player points gun
        TaskPlayAnim(ped, 'missheistdockssetup1', 'handsup_base', 8.0, -8.0, -1, 49, 0, false, false, false)
        
        -- NPC puts hands up
        TaskPlayAnim(npc, 'missheistdockssetup1', 'handsup_base', 8.0, -8.0, -1, 49, 0, false, false, false)
        
        Wait(1000)
        
        -- Start money bag animation with progress bar
        moneyBagProp = PlayMoneyBagAnimation()
        
        local moneyProgressData = {
            label = 'Collecting Money ($' .. totalReward .. ')',
            duration = 3000,
            anim = {
                dict = 'anim@heists@ornate_bank@grab_cash_heels',
                clip = 'grab',
                flags = 49,
            },
            prop = {
                model = 'prop_heist_bag_p2',
                bone = 57005,
                coords = vec3(0.12, 0.0, 0.0),
                rotation = vec3(-80.0, 120.0, 0.0),
            },
            useWhileDead = false,
            canCancel = false,
            disable = {
                move = true,
                car = true,
                combat = true,
                mouse = false,
            },
            customData = {
                totalReward = totalReward,
                playerCount = playerCount,
                individualShare = individualShare,
                nearbyPlayers = nearbyPlayers,
                moneyCollected = 0,
                collectionRate = totalReward / 3000 -- Money per second
            }
        }
        
        -- Trigger money collection progress bar
        TriggerEvent('progressbar:client:progress', moneyProgressData, function(cancelled)
            if cancelled then
                StopMoneyBagAnimation(moneyBagProp)
                ClearPedTasks(ped)
                ClearPedTasks(npc)
                Notify('Money collection cancelled!', 'error')
                return false
            end
            
            -- NPC gives money animation
            RequestAnimDict('anim@amb@clubhouse@mini@clothing@')
            while not HasAnimDictLoaded('anim@amb@clubhouse@mini@clothing@') do
                Wait(10)
            end
            
            TaskPlayAnim(npc, 'anim@amb@clubhouse@mini@clothing@', 'clothing_loop', 8.0, -8.0, -1, 1, 0, false, false, false)
            
            Wait(2000)
            
            -- Stop animations
            StopMoneyBagAnimation(moneyBagProp)
            ClearPedTasks(ped)
            ClearPedTasks(npc)
            
            -- Send reward to server with player distribution data
            TriggerServerEvent('hybrid-storerobbery:server:GiveRegisterRewardWithShare', storeId, totalReward, playerCount, nearbyPlayers)
            
            return true
        end)
        
        return true
    end)
    
    return true
end

-- Get nearby robbery players
function GetNearbyRobberyPlayers()
    local pedCoords = GetEntityCoords(PlayerPedId())
    local nearbyPlayers = {}
    
    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(pedCoords - targetCoords)
            
            if distance <= 15.0 then -- Within 15 meters
                local playerName = GetPlayerName(playerId)
                table.insert(nearbyPlayers, {
                    id = playerId,
                    name = playerName,
                    distance = distance
                })
            end
        end
    end
    
    return nearbyPlayers
end

-- Events
RegisterNetEvent('hybrid-storerobbery:client:StartNPCRobbery', function(storeId)
    StartNPCRobberyProcess(storeId)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(1000)
    SetupTargets()
end)

-- Keybinds
RegisterKeyMapping('hybridrobbery_reload', 'Reload Hybrid Store Robbery', 'keyboard', 'F3')

RegisterCommand('hybridrobbery_reload', function()
    DeleteAllNPCs()
    Wait(1000)
    CreateAllNPCs()
    SetupTargets()
    Notify('Hybrid Store Robbery reloaded!', 'info')
end)

-- Exports
exports('StartNPCRobberyProcess', StartNPCRobberyProcess)
exports('IsRobbing', function() return isRobbing end)
exports('GetCurrentStore', function() return currentStore end)
