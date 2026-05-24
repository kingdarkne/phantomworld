local QBCore = exports['qbx_core']:GetCoreObject()

local isMenuOpen = false
local currentStore = nil

-- NUI Callbacks
RegisterNUICallback('closeMenu', function(data, cb)
    HideStoreMenu()
    isMenuOpen = false
    cb('ok')
end)

RegisterNUICallback('selectOption', function(data, cb)
    local storeId = data.storeId
    local option = data.option
    
    if not storeId or not option then
        cb('error')
        return
    end
    
    HideStoreMenu()
    isMenuOpen = false
    
    -- Handle menu selection
    if option == 'npc_robbery' then
        StartNPCRobbery(storeId)
    elseif option == 'lockpick_robbery' then
        StartLockpickRobbery(storeId)
    elseif option == 'shop_items' then
        OpenShopMenu(storeId)
    elseif option == 'vault_hack' then
        StartVaultHack(storeId)
    end
    
    cb('ok')
end)

RegisterNUICallback('buyItem', function(data, cb)
    local storeId = data.storeId
    local itemName = data.itemName
    local itemPrice = data.itemPrice
    
    if not storeId or not itemName or not itemPrice then
        cb('error')
        return
    end
    
    TriggerServerEvent('hybrid-storerobbery:server:BuyItem', itemName, itemPrice, storeId)
    cb('ok')
end)

-- Auto-popup menu system
function CheckForAutoPopup()
    local pedCoords = GetEntityCoords(PlayerPedId())
    
    for storeId, store in pairs(Config.Stores) do
        local distance = #(pedCoords - vector3(store.menuCoords.x, store.menuCoords.y, store.menuCoords.z))
        
        -- Check if player is close to menu location
        if distance <= Config.AutoPopupDistance and not isMenuOpen then
            -- Check if player is looking at counter
            local isLooking = IsPlayerLookingAt(store.menuCoords)
            
            if isLooking then
                currentStore = storeId
                ShowStoreMenu(storeId)
                isMenuOpen = true
                return
            end
        end
        
        -- Hide menu if player moves away
        if isMenuOpen and currentStore == storeId and distance > Config.MenuDistance then
            HideStoreMenu()
            isMenuOpen = false
            currentStore = nil
        end
    end
end

-- Check if player is looking at a position
function IsPlayerLookingAt(coords)
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    local pedHeading = GetEntityHeading(ped)
    
    -- Calculate angle to target
    local angleToTarget = math.atan2(coords.y - pedCoords.y, coords.x - pedCoords.x)
    local angleDifference = math.abs(angleToTarget - math.rad(pedHeading))
    
    -- Normalize angle difference
    if angleDifference > math.pi then
        angleDifference = 2 * math.pi - angleDifference
    end
    
    -- Check if player is looking within 45 degrees
    return angleDifference < math.rad(45)
end

-- Main loop for auto-popup detection
CreateThread(function()
    while true do
        if not isMenuOpen then
            CheckForAutoPopup()
        end
        Wait(500) -- Check every 500ms
    end
end)

-- Manual menu trigger (backup)
function ToggleStoreMenu()
    if isMenuOpen then
        HideStoreMenu()
        isMenuOpen = false
        currentStore = nil
        return
    end
    
    -- Find nearest store
    local pedCoords = GetEntityCoords(PlayerPedId())
    local nearestStore = nil
    local nearestDistance = Config.MenuDistance
    
    for storeId, store in pairs(Config.Stores) do
        local distance = #(pedCoords - vector3(store.menuCoords.x, store.menuCoords.y, store.menuCoords.z))
        if distance < nearestDistance then
            nearestDistance = distance
            nearestStore = storeId
        end
    end
    
    if nearestStore then
        currentStore = nearestStore
        ShowStoreMenu(nearestStore)
        isMenuOpen = true
    else
        Notify('No store nearby!', 'error')
    end
end

-- Keybind for manual menu toggle
RegisterKeyMapping('hybrid_storerobbery_menu', 'Toggle Store Robbery Menu', 'keyboard', 'E')

RegisterCommand('hybrid_storerobbery_menu', function()
    ToggleStoreMenu()
end)

-- Draw 3D text for store interactions
CreateThread(function()
    while true do
        local sleep = 1500
        local pedCoords = GetEntityCoords(PlayerPedId())
        
        for storeId, store in pairs(Config.Stores) do
            local distance = #(pedCoords - vector3(store.menuCoords.x, store.menuCoords.y, store.menuCoords.z))
            
            if distance <= Config.MenuDistance then
                sleep = 0
                
                local npc = spawnedNPCs[storeId]
                if npc and DoesEntityExist(npc) then
                    local npcState = GetNPCState(storeId)
                    local text = store.type:upper() .. ' STORE'
                    
                    if npcState == 'intimidated' then
                        text = text .. '\n~g~Walk up to counter for options~w~'
                    elseif npcState == 'robbed' then
                        text = text .. '\n~r~Recently Robbed~w~'
                    else
                        if HasIntimidatingWeapon() then
                            text = text .. '\n~y~Walk up to counter for options~w~'
                        else
                            text = text .. '\n~b~Walk up to counter for options~w~'
                        end
                    end
                    
                    if not IsStoreOnCooldown(storeId) then
                        text = text .. '\n~w~Press [E] for manual menu~w~'
                    end
                    
                    DrawText3D(store.menuCoords, text)
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- Events
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(1000)
    -- Reinitialize if needed
end)

RegisterNetEvent('hybrid-storerobbery:client:ResetNPC', function(storeId)
    if spawnedNPCs[storeId] and DoesEntityExist(spawnedNPCs[storeId]) then
        SetNPCState(storeId, NPC_STATE.IDLE)
        ClearPedTasks(spawnedNPCs[storeId])
    end
end)

RegisterNetEvent('hybrid-storerobbery:client:PoliceAlert', function(storeType, coords)
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

-- Exports
exports('ToggleStoreMenu', ToggleStoreMenu)
exports('IsMenuOpen', function() return isMenuOpen end)
exports('GetCurrentStore', function() return currentStore end)
