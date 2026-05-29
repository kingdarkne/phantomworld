local storeClerks = {}
local clerkEntityToStore = {}
local handsUpClerks = {}
local isRobbing = false

local function loadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return end
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do
        Wait(10)
    end
end

local function applyFenixWanted(stars)
    if GetResourceState('fenix-police') ~= 'started' then return end
    pcall(function()
        exports['fenix-police']:ApplyWantedLevel(stars or Config.WantedStars or 2)
    end)
end

local function sendNui(action, data)
    SendNUIMessage({
        action = action,
        data = data or {},
    })
end

local function setClerkHandsUp(ped, enabled)
    if not DoesEntityExist(ped) then return end
    if enabled then
        if handsUpClerks[ped] then return end
        handsUpClerks[ped] = true
        loadAnimDict('missminuteman_1ig_2')
        TaskPlayAnim(ped, 'missminuteman_1ig_2', 'handsup_base', 8.0, -8.0, -1, 49, 0, false, false, false)
    else
        if not handsUpClerks[ped] then return end
        handsUpClerks[ped] = nil
        ClearPedTasks(ped)
        FreezeEntityPosition(ped, true)
    end
end

local function setClerkCower(ped)
    if not DoesEntityExist(ped) then return end
    handsUpClerks[ped] = nil
    loadAnimDict('random@shop_robbery')
    TaskPlayAnim(ped, 'random@shop_robbery', 'robbery_action_b', 8.0, -8.0, -1, 1, 0, false, false, false)
end

local function resetClerkIdle(ped)
    if not DoesEntityExist(ped) then return end
    handsUpClerks[ped] = nil
    ClearPedTasks(ped)
    FreezeEntityPosition(ped, true)
end

local function spawnStoreClerk(store)
    local modelIndex = ((store.id - 1) % #Config.ClerkModels) + 1
    local model = Config.ClerkModels[modelIndex]
    lib.requestModel(model, 10000)

    local c = store.clerk
    local ped = CreatePed(0, model, c.x, c.y, c.z - 1.0, c.w, false, false)
    if not DoesEntityExist(ped) then return nil end

    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 46, true)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    SetPedKeepTask(ped, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)

    storeClerks[store.id] = { ped = ped, store = store }
    clerkEntityToStore[ped] = store
    return ped
end

local function spawnAllClerks()
    for _, store in ipairs(Config.Stores or {}) do
        if not storeClerks[store.id] or not DoesEntityExist(storeClerks[store.id].ped) then
            spawnStoreClerk(store)
        end
    end
end

local function getStoreFromEntity(entity)
    return clerkEntityToStore[entity]
end

local function isOurClerk(entity)
    return getStoreFromEntity(entity) ~= nil
end

local function IsClerkPed(entity)
    if isOurClerk(entity) then return true end
    if not DoesEntityExist(entity) or not IsPedHuman(entity) then return false end
    local model = GetEntityModel(entity)
    for _, m in ipairs(Config.StoreClerkModels or {}) do
        if model == m then return true end
    end
    return false
end

CreateThread(function()
    Wait(2000)
    spawnAllClerks()
end)

CreateThread(function()
    while true do
        Wait(15000)
        for id, data in pairs(storeClerks) do
            if not DoesEntityExist(data.ped) then
                storeClerks[id] = nil
                spawnStoreClerk(data.store)
            end
        end
    end
end)

RegisterNetEvent('dr-storerobbery:client:useRegister', function(storeId, registerIndex)
    if isRobbing then return end
    local store = nil
    for _, s in ipairs(Config.Stores or {}) do
        if s.id == storeId then store = s break end
    end
    if not store then return end

    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then return end

    local clerkData = storeClerks[storeId]
    local clerkPed = clerkData and clerkData.ped
    if clerkPed and DoesEntityExist(clerkPed) then
        setClerkCower(clerkPed)
    end

    isRobbing = true
    applyFenixWanted(Config.WantedStars or 2)

    sendNui('showRobbery', {
        label = store.label or 'Store',
        duration = Config.RobTime,
    })

    local startTime = GetGameTimer()
    CreateThread(function()
        while isRobbing do
            local elapsed = GetGameTimer() - startTime
            local pct = math.min(100, math.floor((elapsed / Config.RobTime) * 100))
            sendNui('updateProgress', { percent = pct })
            if pct >= 100 then break end
            Wait(100)
        end
    end)

    local ok = lib.progressBar({
        duration = Config.RobTime,
        label = 'Robbing the register...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'anim@heists@ornate_bank@grab_cash', clip = 'grab', flag = 49 },
    })

    ClearPedTasks(ped)
    sendNui('hideRobbery', {})
    isRobbing = false

    if clerkPed and DoesEntityExist(clerkPed) then
        resetClerkIdle(clerkPed)
    end

    if ok then
        TriggerServerEvent('dr-storerobbery:server:tryRob', storeId, registerIndex)
    end
end)

RegisterNetEvent('dr-storerobbery:client:blip', function(registerIndex)
    local reg = Config.Registers[registerIndex]
    if not reg then return end
    local blip = AddBlipForCoord(reg.coords.x, reg.coords.y, reg.coords.z)
    SetBlipSprite(blip, 161)
    SetBlipScale(blip, 1.2)
    if Config.RedRegisters and Config.RedRegisters[registerIndex] then
        SetBlipColour(blip, 1)
    else
        SetBlipColour(blip, 5)
    end
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Store Robbery')
    EndTextCommandSetBlipName(blip)
    SetBlipAsShortRange(blip, false)
    PulseBlip(blip)
    SetTimeout(60000, function()
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end)
end)

CreateThread(function()
    local aimedClerk = nil
    while true do
        local sleep = 500
        local ped = PlayerPedId()
        local newAimedClerk = nil

        if not isRobbing and IsPedArmed(ped, 4) and IsPlayerFreeAiming(PlayerId()) then
            sleep = 0
            local _, entity = GetEntityPlayerIsFreeAimingAt(PlayerId())
            if entity and DoesEntityExist(entity) and IsEntityAPed(entity) and isOurClerk(entity) then
                local pCoords = GetEntityCoords(ped)
                local cCoords = GetEntityCoords(entity)
                if #(pCoords - cCoords) < 6.0 then
                    local store = getStoreFromEntity(entity)
                    if store and store.registerIndex then
                        newAimedClerk = entity
                        setClerkHandsUp(entity, true)
                        lib.showTextUI('[E] Rob the register', { position = 'right-center' })

                        if IsControlJustPressed(0, 38) then
                            lib.hideTextUI()
                            TriggerEvent('dr-storerobbery:client:useRegister', store.id, store.registerIndex)
                            Wait(1000)
                        end
                    end
                end
            end
        end

        if newAimedClerk ~= aimedClerk then
            if aimedClerk and aimedClerk ~= newAimedClerk then
                setClerkHandsUp(aimedClerk, false)
            end
            aimedClerk = newAimedClerk
            if not aimedClerk then
                lib.hideTextUI()
            end
        end

        Wait(sleep)
    end
end)

function GetClosestRegisterToCoords(coords)
    if not Config.Registers or not next(Config.Registers) then return nil end
    local idx, closest, dist = nil, nil, 9999.0
    for i, reg in ipairs(Config.Registers) do
        local d = #(coords - reg.coords)
        if d < dist then
            dist = d
            closest = reg
            idx = i
        end
    end
    return idx, closest, dist
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    lib.hideTextUI()
    sendNui('hideRobbery', {})
    for _, data in pairs(storeClerks) do
        if DoesEntityExist(data.ped) then DeleteEntity(data.ped) end
    end
end)
