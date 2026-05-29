local wantedLevel = 0
local wantedPoints = 0
local lastPedCrime = {}

local function isFenixPoliceActive()
    return GetResourceState('fenix-police') == 'started'
end

local dispatchServices = {
    [1] = true,  -- Police Vehicles
    [2] = true,  -- Police Helicopters
    [3] = true,  -- Fire Department Vehicles
    [4] = true,  -- Swat Vehicles
    [5] = true,  -- Ambulance Vehicles
    [6] = true,  -- Police Motorcycles
    [7] = true,  -- Police Backup
    [8] = true,  -- Police Roadblocks
    [9] = true,  -- PoliceAutomobileWaitPulledOver
    [10] = true, -- PoliceAutomobileWaitCruising
    [12] = true, -- Swat Helicopters
    [13] = true, -- Police Boats
}

local function enableNativePoliceResponse()
    SetAudioFlag('PoliceScannerDisabled', false)
    SetCreateRandomCops(true)
    SetCreateRandomCopsNotOnScenarios(true)
    SetCreateRandomCopsOnScenarios(true)
    DistantCopCarSirens(true)
    SetMaxWantedLevel(5)
    SetPoliceIgnorePlayer(PlayerId(), false)
    SetDispatchCopsForPlayer(PlayerId(), true)

    for service, enabled in pairs(dispatchServices) do
        EnableDispatchService(service, enabled)
    end
end

local function applyNativeWanted(level)
    level = math.max(0, math.min(tonumber(level) or 0, 5))

    if isFenixPoliceActive() then
        if level <= 0 then
            ClearPlayerWantedLevel(PlayerId())
            SetPlayerWantedLevelNow(PlayerId(), false)
        else
            exports['fenix-police']:SetWantedLevel(level)
        end
        return
    end

    if level <= 0 then
        ClearPlayerWantedLevel(PlayerId())
        SetPlayerWantedLevelNow(PlayerId(), false)
        return
    end

    SetMaxWantedLevel(5)
    SetPlayerWantedLevel(PlayerId(), level, false)
    SetPlayerWantedLevelNow(PlayerId(), false)

    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= 0 then
        SetVehicleIsWanted(vehicle, true)
    end

    enableNativePoliceResponse()
end

RegisterNetEvent('dr-wanted:client:update', function(level, points)
    wantedLevel = level or 0
    wantedPoints = points or 0
    applyNativeWanted(wantedLevel)
end)

local function DrawTextSimple(x, y, scale, text, r, g, b, a)
    SetTextFont(4)
    SetTextProportional(0)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 205)
    SetTextOutline()
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(x, y)
end

CreateThread(function()
    while true do
        Wait(0)
        if wantedLevel > 0 then
            local txt = ('Wanted: %d ⭐ (%d pts)'):format(wantedLevel, wantedPoints)
            DrawTextSimple(0.80, 0.05, 0.4, txt, 255, 60, 60, 255)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(5000)
        if wantedLevel > 0 and not isFenixPoliceActive() then
            applyNativeWanted(wantedLevel)
        end
    end
end)

-- Automatic wanted: detect shots fired

CreateThread(function()
    while true do
        local sleep = 250
        local ped = PlayerPedId()
        if IsPedArmed(ped, 6) and IsPedShooting(ped) then
            sleep = 1000 -- basic rate limiting
            TriggerServerEvent('dr-wanted:server:shotsFired')
        end
        Wait(sleep)
    end
end)

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end

    local victim = args[1]
    local attacker = args[2]
    local ped = PlayerPedId()

    if attacker ~= ped or victim == ped or not victim or victim == 0 or not DoesEntityExist(victim) or not IsEntityAPed(victim) then
        return
    end

    local now = GetGameTimer()
    if lastPedCrime[victim] and now - lastPedCrime[victim] < 5000 then
        return
    end
    lastPedCrime[victim] = now

    local isFatal = IsEntityDead(victim)
    if IsPedAPlayer(victim) then
        local targetPlayer = NetworkGetPlayerIndexFromPed(victim)
        if targetPlayer ~= -1 then
            TriggerServerEvent('dr-wanted:server:playerHit', GetPlayerServerId(targetPlayer), isFatal)
        end
        return
    end

    TriggerServerEvent('dr-wanted:server:npcAttack', isFatal)
end)

-- Damage events above attribute crimes from the attacker's client. Avoid
-- assigning homicide to the victim based on proximity after death.

