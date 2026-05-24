local QBCore = exports['qbx_core']:GetCoreObject()

-- Utility functions
function DrawText3D(coords, text)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry('STRING')
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(x, y)
        local factor = (string.len(text)) / 370
        DrawRect(x, y + 0.0125, 0.015 + factor, 0.03, 41, 41, 41, 68)
    end
end

function Notify(message, type)
    if Config.NotifySystem == 'ox_lib' then
        lib.notify({
            title = 'Hybrid Store Robbery',
            description = message,
            type = type or 'info'
        })
    elseif Config.NotifySystem == 'qb' then
        QBCore.Functions.Notify(message, type, 5000)
    end
end

function IsWeaponIntimidating(weaponHash)
    for _, weapon in ipairs(Config.IntimidationWeapons) do
        if GetHashKey(weapon) == weaponHash then
            return true
        end
    end
    return false
end

function HasIntimidatingWeapon()
    local ped = PlayerPedId()
    local currentWeapon = GetSelectedPedWeapon(ped)
    return IsWeaponIntimidating(currentWeapon)
end

function GetRandomNPCModel()
    return Config.NPCModels[math.random(#Config.NPCModels)]
end

function PlayMoneyBagAnimation()
    local ped = PlayerPedId()
    local dict = Config.MoneyBagAnim.dict
    local clip = Config.MoneyBagAnim.clip
    
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end
    
    TaskPlayAnim(ped, dict, clip, 8.0, -8.0, -1, 1, 0, false, false, false)
    
    -- Attach money bag prop
    local prop = CreateObject(GetHashKey(Config.MoneyBagProp), 0, 0, 0, true, true, true)
    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 57005), 0.12, 0.0, 0.0, -80.0, 120.0, 0.0, true, false, false, false, 2, true)
    
    return prop
end

function StopMoneyBagAnimation(prop)
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    
    if prop and DoesEntityExist(prop) then
        DeleteEntity(prop)
    end
end

function GetPoliceCount()
    local count = 0
    for _, player in ipairs(GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(tonumber(player))
        if Player and (Player.PlayerData.job.name == 'police' or Player.PlayerData.job.type == 'leo') and Player.PlayerData.job.onduty then
            count = count + 1
        end
    end
    return count
end

function SendPoliceAlert(storeType, coords)
    local chance = Config.PoliceAlertChance
    if math.random(100) <= chance then
        TriggerServerEvent('hybrid-storerobbery:server:PoliceAlert', storeType, coords)
    end
end

function IsStoreOnCooldown(storeId)
    return lib.callback.await('hybrid-storerobbery:server:IsStoreOnCooldown', false, storeId)
end

function SetStoreCooldown(storeId, type)
    TriggerServerEvent('hybrid-storerobbery:server:SetStoreCooldown', storeId, type)
end

function CanRobStore()
    local policeCount = GetPoliceCount()
    return policeCount >= Config.PoliceRequired
end

function GetDistanceFromPlayer(coords)
    local pedCoords = GetEntityCoords(PlayerPedId())
    return #(pedCoords - vector3(coords.x, coords.y, coords.z))
end

function IsPlayerInStore(storeId)
    local store = Config.Stores[storeId]
    if not store then return false end
    
    local distance = GetDistanceFromPlayer(store.coords)
    return distance <= 10.0
end

function ShowStoreMenu(storeId)
    SendNUIMessage({
        action = 'showMenu',
        storeId = storeId,
        storeType = Config.Stores[storeId].type,
        items = Config.ShopItems[Config.Stores[storeId].type]
    })
end

function HideStoreMenu()
    SendNUIMessage({
        action = 'hideMenu'
    })
end

function OpenShopMenu(storeId)
    local store = Config.Stores[storeId]
    if not store then return end
    
    local items = Config.ShopItems[store.type]
    if not items then return end
    
    -- Create shop menu using ox_lib
    local options = {}
    
    for _, item in ipairs(items) do
        table.insert(options, {
            title = item.label,
            description = '$' .. item.price,
            onSelect = function()
                TriggerServerEvent('hybrid-storerobbery:server:BuyItem', item.name, item.price, storeId)
            end
        })
    end
    
    lib.showContext({
        id = 'shop_menu',
        title = store.type:upper() .. ' Store',
        options = options
    })
end

function StartNPCRobbery(storeId)
    if not HasIntimidatingWeapon() then
        Notify('You need a weapon to intimidate the clerk!', 'error')
        return false
    end
    
    if IsStoreOnCooldown(storeId) then
        Notify('This store was recently robbed!', 'error')
        return false
    end
    
    if not CanRobStore() then
        Notify('Not enough police online!', 'error')
        return false
    end
    
    TriggerServerEvent('hybrid-storerobbery:server:StartNPCRobbery', storeId)
    return true
end

function StartLockpickRobbery(storeId)
    if not QBCore.Functions.HasItem('lockpick') then
        Notify('You need a lockpick!', 'error')
        return false
    end
    
    if IsStoreOnCooldown(storeId) then
        Notify('This store was recently robbed!', 'error')
        return false
    end
    
    if not CanRobStore() then
        Notify('Not enough police online!', 'error')
        return false
    end
    
    -- Trigger existing robbery system (MZ-StoreRobbery)
    TriggerEvent('mz-storerobbery:client:startRegisterRobbery', storeId)
    return true
end

function StartVaultHack(storeId)
    local store = Config.Stores[storeId]
    if not store then return false end
    
    if IsStoreOnCooldown(storeId) then
        Notify('Vault was recently accessed!', 'error')
        return false
    end
    
    if not CanRobStore() then
        Notify('Not enough police online!', 'error')
        return false
    end
    
    -- Start enhanced vault hacking with progress bar
    local totalReward = math.random(store.vaultReward.min, store.vaultReward.max)
    local nearbyPlayers = GetNearbyRobberyPlayers()
    local playerCount = #nearbyPlayers + 1
    local individualShare = math.floor(totalReward / playerCount)
    
    -- Enhanced vault hacking progress bar
    local vaultProgressData = {
        label = 'Hacking Vault ($' .. totalReward .. ')',
        duration = store.hackDifficulty == 'easy' and 15000 or store.hackDifficulty == 'medium' and 20000 or 25000,
        anim = {
            dict = 'anim@heists@prison_heiststation@cop_reactions',
            clip = 'cop_b_idle',
            flags = 49,
        },
        prop = {
            model = 'prop_tool_drill',
            bone = 57005,
            coords = vec3(0.15, 0.05, 0.0),
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
            hackDifficulty = store.hackDifficulty,
            hackProgress = 0,
            hackRate = 100 / (store.hackDifficulty == 'easy' and 15 or store.hackDifficulty == 'medium' and 20 or 25) -- Progress per second
        }
    }
    
    -- Trigger vault hacking progress bar
    TriggerEvent('progressbar:client:progress', vaultProgressData, function(cancelled)
        if cancelled then
            Notify('Vault hack cancelled!', 'error')
            return false
        end
        
        -- Vault hack successful
        TriggerServerEvent('hybrid-storerobbery:server:GiveVaultRewardWithShare', storeId, totalReward, playerCount, nearbyPlayers)
        Notify('Vault hack successful! Got $' .. individualShare .. ' (Your share)', 'success')
        
        -- Set cooldown
        SetStoreCooldown(storeId, 'vault')
        
        return true
    end)
    
    return true
end

exports('DrawText3D', DrawText3D)
exports('Notify', Notify)
exports('IsWeaponIntimidating', IsWeaponIntimidating)
exports('HasIntimidatingWeapon', HasIntimidatingWeapon)
exports('GetRandomNPCModel', GetRandomNPCModel)
exports('PlayMoneyBagAnimation', PlayMoneyBagAnimation)
exports('StopMoneyBagAnimation', StopMoneyBagAnimation)
exports('GetPoliceCount', GetPoliceCount)
exports('SendPoliceAlert', SendPoliceAlert)
exports('IsStoreOnCooldown', IsStoreOnCooldown)
exports('SetStoreCooldown', SetStoreCooldown)
exports('CanRobStore', CanRobStore)
exports('GetDistanceFromPlayer', GetDistanceFromPlayer)
exports('IsPlayerInStore', IsPlayerInStore)
exports('ShowStoreMenu', ShowStoreMenu)
exports('HideStoreMenu', HideStoreMenu)
exports('OpenShopMenu', OpenShopMenu)
exports('StartNPCRobbery', StartNPCRobbery)
exports('StartLockpickRobbery', StartLockpickRobbery)
exports('StartVaultHack', StartVaultHack)
