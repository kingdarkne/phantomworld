local QBCore = exports['qb-core']:GetCoreObject()

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
            title = 'Store Robbery',
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
        TriggerServerEvent('npc-storerobbery:server:PoliceAlert', storeType, coords)
    end
end

function IsStoreOnCooldown(storeId)
    return lib.callback.await('npc-storerobbery:server:IsStoreOnCooldown', false, storeId)
end

function SetStoreCooldown(storeId, type)
    TriggerServerEvent('npc-storerobbery:server:SetStoreCooldown', storeId, type)
end

function CanRobStore()
    local policeCount = GetPoliceCount()
    return policeCount >= Config.PoliceRequired
end

function GetDistanceFromPlayer(coords)
    local pedCoords = GetEntityCoords(PlayerPedId())
    return #(pedCoords - coords)
end

function IsPlayerInStore(storeId)
    local store = Config.Stores[storeId]
    if not store then return false end
    
    local distance = GetDistanceFromPlayer(store.coords)
    return distance <= 10.0
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
