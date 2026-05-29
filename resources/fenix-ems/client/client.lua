local QBCore = exports['qbx_core']:GetCoreObject()

local activeCall = false
local lastCallAt = 0
local responseBlip = nil
local spawnedVehicle = nil
local spawnedMedic = nil

local function debugPrint(msg)
    if Config.Debug then
        print(('[fenix-ems] %s'):format(msg))
    end
end

local function notify(msg, nType)
    if lib and lib.notify then
        lib.notify({ title = 'Emergency Medical', description = msg, type = nType or 'inform', duration = 7000 })
        return
    end
    QBCore.Functions.Notify(msg, nType or 'primary', 7000)
end

local function loadModel(model)
    if type(model) == 'string' then model = joaat(model) end
    if not IsModelInCdimage(model) then return false end
    RequestModel(model)
    local timeout = GetGameTimer() + 10000
    while not HasModelLoaded(model) do
        if GetGameTimer() > timeout then return false end
        Wait(10)
    end
    return true
end

local function clearBlip()
    if responseBlip and DoesBlipExist(responseBlip) then
        RemoveBlip(responseBlip)
    end
    responseBlip = nil
end

local function cleanupUnits()
    clearBlip()
    if spawnedMedic and DoesEntityExist(spawnedMedic) then
        DeleteEntity(spawnedMedic)
    end
    if spawnedVehicle and DoesEntityExist(spawnedVehicle) then
        DeleteEntity(spawnedVehicle)
    end
    spawnedMedic = nil
    spawnedVehicle = nil
    activeCall = false
end

local function isPlayerDown()
    local ped = PlayerPedId()
    if IsEntityDead(ped) or IsPedFatallyInjured(ped) or IsPedDeadOrDying(ped, true) then
        return true
    end

    local state = LocalPlayer.state
    if state.isDead or state.dead or state.inLastStand or state.inlaststand then
        return true
    end

    local pdata = QBCore.Functions.GetPlayerData()
    if pdata and pdata.metadata then
        if pdata.metadata.isdead or pdata.metadata.inlaststand then
            return true
        end
    end
    return false
end

local function notifyPlayerDown()
    local now = GetGameTimer()
    if notifyPlayerDown.lastAt and (now - notifyPlayerDown.lastAt) < 5000 then
        return
    end
    notifyPlayerDown.lastAt = now
    TriggerServerEvent('fenix-ems:server:playerDown')
end

local function revivePlayer()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
    SetEntityInvincible(ped, false)
    ClearPedTasksImmediately(ped)
    SetEntityMaxHealth(ped, 200)
    SetEntityHealth(ped, Config.ReviveHealth or 200)
    SetPedArmour(ped, Config.ReviveArmor or 0)
    ClearPedBloodDamage(ped)

    TriggerServerEvent('fenix-ems:server:clearDeathState')
    TriggerEvent('hospital:client:Revive')
    TriggerEvent('qb-deathscreen:revive')

    notify('AI EMS revived you on scene.', 'success')
end

local function attachBlip(entity)
    clearBlip()
    responseBlip = AddBlipForEntity(entity)
    SetBlipSprite(responseBlip, Config.BlipSprite)
    SetBlipColour(responseBlip, Config.BlipColor)
    SetBlipScale(responseBlip, 0.9)
    SetBlipAsShortRange(responseBlip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.BlipLabel or 'AI EMS')
    EndTextCommandSetBlipName(responseBlip)
end

local function findRoadNear(coords, minDist, maxDist)
    for _ = 1, 12 do
        local found, nodePos = GetClosestVehicleNodeWithHeading(
            coords.x + math.random(-maxDist, maxDist),
            coords.y + math.random(-maxDist, maxDist),
            coords.z,
            0, 3, 0
        )
        if found then
            local dist = #(coords - nodePos)
            if dist >= minDist and dist <= maxDist then
                return nodePos
            end
        end
    end
    return coords
end

local function driveMedicToPlayer()
    CreateThread(function()
        local playerPed = PlayerPedId()
        local deadline = GetGameTimer() + (Config.ResponseTimeout or 120000)

        while activeCall and GetGameTimer() < deadline do
            if not isPlayerDown() then
                cleanupUnits()
                return
            end

            if not DoesEntityExist(spawnedVehicle) or not DoesEntityExist(spawnedMedic) then
                cleanupUnits()
                notify('AI EMS could not reach you.', 'error')
                return
            end

            local pCoords = GetEntityCoords(playerPed)
            local vCoords = GetEntityCoords(spawnedVehicle)
            local dist = #(pCoords - vCoords)

            if dist <= (Config.ReviveDistance or 12.0) then
                TaskVehicleTempAction(spawnedMedic, spawnedVehicle, 27, 3000)
                Wait(1500)
                TaskLeaveVehicle(spawnedMedic, spawnedVehicle, 256)
                Wait(2000)
                TaskGoToCoordAnyMeans(spawnedMedic, pCoords.x, pCoords.y, pCoords.z, 2.0, 0, false, 786603, 0.0)
                local approachDeadline = GetGameTimer() + 20000
                while GetGameTimer() < approachDeadline do
                    if not isPlayerDown() then break end
                    local medicCoords = GetEntityCoords(spawnedMedic)
                    if #(medicCoords - pCoords) <= 2.5 then break end
                    Wait(500)
                end
                TaskStartScenarioInPlace(spawnedMedic, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
                notify('AI EMS is treating you...', 'inform')
                Wait(5000)
                revivePlayer()
                TriggerServerEvent('fenix-ems:server:chargeFee')
                cleanupUnits()
                return
            end

            TaskVehicleDriveToCoordLongrange(
                spawnedMedic,
                spawnedVehicle,
                pCoords.x, pCoords.y, pCoords.z,
                18.0,
                786603,
                5.0
            )
            Wait(2500)
        end

        if activeCall then
            notify('AI EMS timed out — call again if still down.', 'error')
            cleanupUnits()
        end
    end)
end

local function spawnAiEms()
    if activeCall then return end
    if (GetGameTimer() - lastCallAt) < ((Config.CallCooldown or 120) * 1000) then return end
    if not isPlayerDown() then return end

    activeCall = true
    lastCallAt = GetGameTimer()

    local playerPed = PlayerPedId()
    local pCoords = GetEntityCoords(playerPed)
    local spawnCoords = findRoadNear(pCoords, 35.0, 90.0)

    if not loadModel(Config.AmbulanceModel) or not loadModel(Config.MedicModel) then
        activeCall = false
        notify('AI EMS failed to spawn (model error).', 'error')
        return
    end

    spawnedVehicle = CreateVehicle(Config.AmbulanceModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, true, false)
    SetEntityAsMissionEntity(spawnedVehicle, true, true)
    SetVehicleOnGroundProperly(spawnedVehicle)
    SetVehicleEngineOn(spawnedVehicle, true, true, false)
    SetVehicleSiren(spawnedVehicle, true)

    spawnedMedic = CreatePedInsideVehicle(spawnedVehicle, 26, Config.MedicModel, -1, true, false)
    SetEntityAsMissionEntity(spawnedMedic, true, true)
    SetBlockingOfNonTemporaryEvents(spawnedMedic, true)
    SetPedFleeAttributes(spawnedMedic, 0, false)
    SetPedCombatAttributes(spawnedMedic, 46, true)
    SetDriverAbility(spawnedMedic, 1.0)
    SetDriverAggressiveness(spawnedMedic, 0.0)

    attachBlip(spawnedVehicle)
    notify('EMS dispatched — AI unit en route to your location.', 'inform')
    TriggerServerEvent('fenix-ems:server:logDispatch')

    driveMedicToPlayer()
end

RegisterNetEvent('fenix-ems:client:dispatch', function()
    spawnAiEms()
end)

RegisterNetEvent('fenix-ems:client:tryAutoDispatch', function()
    if not isPlayerDown() then return end
    notify('No medics on duty — calling AI EMS...', 'inform')
    Wait((Config.AutoDispatchDelay or 8) * 1000)
    if isPlayerDown() then
        spawnAiEms()
    end
end)

-- Detect death / last stand locally and ask server if AI EMS should respond.
CreateThread(function()
    local wasDown = false
    while true do
        Wait(400)
        local down = isPlayerDown()
        if down and not wasDown then
            notifyPlayerDown()
        elseif not down and wasDown then
            cleanupUnits()
        end
        wasDown = down
    end
end)

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end
    if args[1] ~= PlayerPedId() then return end
    if isPlayerDown() then
        notifyPlayerDown()
    end
end)

RegisterNetEvent('hospital:client:SetDeathStatus', function(isDead)
    if isDead and isPlayerDown() then
        notifyPlayerDown()
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    cleanupUnits()
end)

exports('RequestAiEms', spawnAiEms)
