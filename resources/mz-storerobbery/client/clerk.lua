local QBCore = exports['qb-core']:GetCoreObject()

if not Config.ClerkRobberyEnabled then return end

local storeClerks = {}
local clerkEntityToStore = {}
local handsUpClerks = {}
local isClerkRobbing = false
local clerkCopsCalled = false

local function notify(msg, nType)
    if Config.NotifyType == 'qb' then
        QBCore.Functions.Notify(msg, nType or 'primary', 3500)
    elseif Config.NotifyType == 'okok' then
        exports['okokNotify']:Alert('STORE ROBBERY', msg, 3500, nType or 'info')
    end
end

local function getRegisterTable()
    return Config.UseGabz and Config.RegistersTargetGabz or Config.RegistersTarget
end

local function getClosestRegisterKey(coords)
    local registers = getRegisterTable()
    local bestKey, bestDist = nil, 9999.0
    for key, reg in pairs(registers) do
        local d = #(coords - reg.coords)
        if d < bestDist then
            bestDist = d
            bestKey = key
        end
    end
    if bestDist > 25.0 then return nil end
    return bestKey
end

local function triggerFenixStoreRobberyWanted(stars)
    if GetResourceState('fenix-police') ~= 'started' then return end
    pcall(function()
        exports['fenix-police']:ApplyWantedLevel(stars or 2)
    end)
end

local function loadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return end
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do
        Wait(10)
    end
end

local function requestModel(model)
    if not IsModelInCdimage(model) then return false end
    RequestModel(model)
    local timeout = GetGameTimer() + 10000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do
        Wait(10)
    end
    return HasModelLoaded(model)
end

local function drawText3D(coords, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    DrawText(0.0, 0.0)
    local factor = string.len(text) / 370
    DrawRect(0.0, 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
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
    if not requestModel(model) then return nil end

    local c = store.clerk
    local ped = CreatePed(0, model, c.x, c.y, c.z - 1.0, c.w, false, false)
    SetModelAsNoLongerNeeded(model)
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
    for _, store in ipairs(Config.ClerkStores or {}) do
        if not storeClerks[store.id] or not DoesEntityExist(storeClerks[store.id].ped) then
            spawnStoreClerk(store)
        end
    end
end

local function isOurClerk(entity)
    return clerkEntityToStore[entity] ~= nil
end

local function startClerkRegisterRobbery(store, clerkPed)
    if isClerkRobbing then return end

    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then return end

    local registerKey = getClosestRegisterKey(vector3(store.clerk.x, store.clerk.y, store.clerk.z))
    if not registerKey then
        notify('No register nearby for this clerk.', 'error')
        return
    end

    QBCore.Functions.TriggerCallback('mz-storerobbery:server:getCops', function(cops)
        local registers = getRegisterTable()
        local register = registers[registerKey]
        if not register then return end

        if register.robbed then
            notify('This register was already emptied recently.', 'error')
            return
        end

        if cops < Config.MinimumStoreRobberyPolice then
            notify(('Not enough police (%d required)'):format(Config.MinimumStoreRobberyPolice), 'error')
            return
        end

        isClerkRobbing = true
        TriggerServerEvent('mz-storerobbery:server:setRegisterStatus', registerKey)

        if Config.psdispatch and not clerkCopsCalled then
            TriggerEvent('mz-storerobbery:client:mzRegisterHit')
            clerkCopsCalled = true
            SetTimeout(Config.DispatchRegisterDelay * 1000, function()
                clerkCopsCalled = false
            end)
        end

        triggerFenixStoreRobberyWanted(2)

        if clerkPed and DoesEntityExist(clerkPed) then
            setClerkCower(clerkPed)
        end

        TriggerEvent('animations:client:EmoteCommandStart', { 'uncuff' })
        local robTime = (Config.ClerkRobTime or 15) * 1000
        local storeLabel = store.label or ('Store #' .. tostring(store.id))
        RobberyNui.show(storeLabel, 'Intimidating clerk & emptying register', 'clerk')
        RobberyNui.trackProgress(robTime, storeLabel, 'Emptying the register...', 'clerk')
        QBCore.Functions.Progressbar('clerk_register_rob', 'Robbing the register...', robTime, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function()
            RobberyNui.hide()
            TriggerEvent('animations:client:EmoteCommandStart', { 'c' })
            ClearPedTasks(ped)
            TriggerServerEvent('mz-storerobbery:server:takeMoney', registerKey, true, false)
            if Config.mzskills then
                local chance = math.random(Config.HeistXPlow2, Config.HeistXPHigh2)
                exports['mz-skills']:UpdateSkill(Config.CriminalXPSkill, chance)
            end
            if clerkPed and DoesEntityExist(clerkPed) then
                resetClerkIdle(clerkPed)
            end
            isClerkRobbing = false
        end, function()
            RobberyNui.hide()
            TriggerEvent('animations:client:EmoteCommandStart', { 'c' })
            ClearPedTasks(ped)
            TriggerServerEvent('mz-storerobbery:server:setRegisterStatusFailed', registerKey)
            if clerkPed and DoesEntityExist(clerkPed) then
                resetClerkIdle(clerkPed)
            end
            notify('Process cancelled', 'error')
            isClerkRobbing = false
        end)
    end)
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

CreateThread(function()
    local aimedClerk = nil
    while true do
        local sleep = 500
        local ped = PlayerPedId()
        local newAimedClerk = nil
        local promptCoords = nil

        if not isClerkRobbing and IsPedArmed(ped, 4) and IsPlayerFreeAiming(PlayerId()) then
            sleep = 0
            local _, entity = GetEntityPlayerIsFreeAimingAt(PlayerId())
            if entity and DoesEntityExist(entity) and IsEntityAPed(entity) and isOurClerk(entity) then
                local pCoords = GetEntityCoords(ped)
                local cCoords = GetEntityCoords(entity)
                if #(pCoords - cCoords) < (Config.ClerkAimDistance or 6.0) then
                    local store = clerkEntityToStore[entity]
                    if store then
                        newAimedClerk = entity
                        promptCoords = vector3(cCoords.x, cCoords.y, cCoords.z + 1.0)
                        setClerkHandsUp(entity, true)
                        drawText3D(promptCoords, '[E] Rob the register')

                        if IsControlJustPressed(0, 38) then
                            startClerkRegisterRobbery(store, entity)
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
        end

        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for _, data in pairs(storeClerks) do
        if DoesEntityExist(data.ped) then
            DeleteEntity(data.ped)
        end
    end
end)
