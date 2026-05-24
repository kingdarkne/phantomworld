local Core, CoreName = nil, nil

-- Qbox: use qbx_core + qb-core export bridge when legacy qb-core resource is not started.
if GetResourceState('qbx_core') == 'started' or GetResourceState('qb-core') == 'started' then
    Core = DrGetQBCore()
    while Core == nil do
        Core = DrGetQBCore()
        TriggerEvent('QBCore:GetObject', function(obj) Core = obj end)
        Wait(30)
    end
    CoreName = 'qb-core'
elseif GetResourceState('es_extended') == 'started' then
    Core = exports['es_extended']:getSharedObject()
    while Core == nil do
        TriggerEvent('esx:getSharedObject', function(obj) Core = obj end)
        Wait(30)
    end
    CoreName = 'es_extended'
else
    Core = 'not_found'
    CoreName = 'standlone'
end

CreateThread(function()
    if CoreName == 'qb-core' then
        RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
        AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
            TriggerEvent('dr-Earthquake:StartUI')
        end)
    elseif CoreName == 'es_extended' then
        RegisterNetEvent('esx:playerLoaded')
        AddEventHandler('esx:playerLoaded', function()
            TriggerEvent('dr-Earthquake:StartUI')
        end)
    else
        Wait(10000)
        TriggerEvent('dr-Earthquake:StartUI')
    end
end)

-- Event's
RegisterNetEvent('onResourceStart')
AddEventHandler('onResourceStart', function(resourceName)
	if (GetCurrentResourceName() == resourceName) then
        while true do
            if GetResourceState(GetCurrentResourceName()) == 'started' then
                TriggerEvent('dr-Earthquake:StartUI')
                break;
            else
                Wait(100)
            end
        end
	end
end)

RegisterNetEvent('dr-Earthquake:StartUI')
AddEventHandler('dr-Earthquake:StartUI', function()
    SendNUIMessage({
        type = 'main',
        bool = 'update',
        locs = Locales[Config.Locales]
    })
end)

local ragdollFix = false
local shakedAmount = 0

RegisterNetEvent('dr-Earthquake:TxAdmin')
AddEventHandler('dr-Earthquake:TxAdmin', function(minutesRemaining)
    local playerPed = PlayerPedId()
    ragdollFix = false
    SendNUIMessage({
        type = 'main',
        bool = 'open',
        minutes = minutesRemaining
    })
    CreateThread(function()
        while true do
            if shakedAmount < 60 then
                shakedAmount = shakedAmount + 1
                ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.1)
                if not ragdollFix then
                    if IsPedWalking(playerPed) or IsPedRunning(playerPed) then
                        ragdollFix = true
                        SetPedToRagdoll(playerPed, 1000, 1000, 0, false, false, false)
                        SetTimeout(5000, function()
                            ragdollFix = false
                        end)
                    else
                        local myVeh = GetVehiclePedIsIn(playerPed, false)
                        local isDriver = GetPedInVehicleSeat(myVeh, -1) == playerPed
                        if myVeh and isDriver then
                            if (GetEntitySpeed(myVeh) > 20.0) then
                                local biasRandom = (math.random(-1, 1) + 0.0)
                                SetVehicleSteerBias(myVeh, biasRandom)
                                SetVehicleReduceGrip(myVeh, true)
                                Wait(math.random(200, 450))
                                SetVehicleSteerBias(myVeh, biasRandom)
                                SetVehicleReduceGrip(myVeh, false)
                                SetTimeout(math.random(1750, 3000), function()
                                    ragdollFix = false
                                end)
                            end
                        end
                    end
                end
            else
                shakedAmount = 0
                break
            end
            Wait(500)
        end
    end)
    SetTimeout(30000, function()
        SendNUIMessage({
            type = 'main',
            bool = 'close'
        })
    end)
end)

if Config.Random then
    RegisterNetEvent('dr-Earthquake:Random')
    AddEventHandler('dr-Earthquake:Random', function()
        local playerPed = PlayerPedId()
        ragdollFix = false
        local randomValue = math.random(15, 60)
        local targetShakedAmount = randomValue * 2
        SendNUIMessage({
            type = 'main',
            bool = 'open2'
        })
        CreateThread(function()
            while true do
                if shakedAmount < targetShakedAmount then
                    shakedAmount = shakedAmount + 1
                    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.1)
                    if not ragdollFix then
                        if IsPedWalking(playerPed) or IsPedRunning(playerPed) then
                            ragdollFix = true
                            SetPedToRagdoll(playerPed, 1000, 1000, 0, false, false, false)
                            SetTimeout(5000, function()
                                ragdollFix = false
                            end)
                        else
                            local myVeh = GetVehiclePedIsIn(playerPed, false)
                            local isDriver = GetPedInVehicleSeat(myVeh, -1) == playerPed
                            if myVeh and isDriver then
                                if (GetEntitySpeed(myVeh) > 20.0) then
                                    local biasRandom = (math.random(-1, 1) + 0.0)
                                    SetVehicleSteerBias(myVeh, biasRandom)
                                    SetVehicleReduceGrip(myVeh, true)
                                    Wait(math.random(200, 450))
                                    SetVehicleSteerBias(myVeh, biasRandom)
                                    SetVehicleReduceGrip(myVeh, false)
                                    SetTimeout(math.random(1750, 3000), function()
                                        ragdollFix = false
                                    end)
                                end
                            end
                        end
                    end
                else
                    shakedAmount = 0
                    break
                end
                Wait(500)
            end
        end)
        SetTimeout(randomValue * 1000, function()
            SendNUIMessage({
                type = 'main',
                bool = 'close'
            })
        end)
    end)    
end