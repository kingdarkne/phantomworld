local cam = nil
local charPed = nil
local loadScreenCheckState = false
local QBX = exports.qbx_core
local cached_player_skins = {}

local randommodels = { -- models possible to load when choosing empty slot
    'mp_m_freemode_01',
    'mp_f_freemode_01',
}

local function openCharacterCreator()
    SetNuiFocus(false, false)
    ShutdownLoadingScreenNui()
    CreateThread(function()
        Wait(150)
        -- Match illenium-appearance: startPlayerCustomization waits on IsScreenFadedIn()
        DoScreenFadeIn(500)
        Wait(200)
        if GetResourceState('illenium-appearance') == 'started' then
            TriggerEvent('qb-clothes:client:CreateFirstCharacter')
            return
        end
        if GetResourceState('fivem-appearance') == 'started' then
            TriggerEvent('fivem-appearance:client:openCreator')
            return
        end
        if GetResourceState('qb-clothing') == 'started' then
            TriggerEvent('qb-clothing:client:CreateFirstCharacter')
        end
    end)
end

-- Joaat function definition
local function joaat(key)
    local str = string.upper(key)
    local hash, i = 0, 1
    while i <= #str do
        hash = hash + string.byte(str, i)
        hash = hash + (hash << 10)
        hash = hash ~ (hash >> 6)
        i = i + 1
    end
    hash = hash + (hash << 3)
    hash = hash ~ (hash >> 11)
    hash = hash + (hash << 15)
    return hash
end

-- Main Thread

CreateThread(function()
    local timeout = 0
    while true do
        Wait(500)
        if NetworkIsSessionStarted() then
            TriggerEvent('dr-multicharacter:client:chooseChar')
            return
        end
        timeout = timeout + 500
        if timeout >= 45000 then
            ShutdownLoadingScreen()
            ShutdownLoadingScreenNui()
            TriggerEvent('dr-multicharacter:client:chooseChar')
            return
        end
    end
end)

-- Functions

local function loadModel(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
end


local function initializePedModel(model, data)
    CreateThread(function()
        if not model then
            model = joaat(randommodels[math.random(#randommodels)])
        end
        loadModel(model)
        charPed = CreatePed(2, model, Config.PedCoords.x, Config.PedCoords.y, Config.PedCoords.z - 0.98,
            Config.PedCoords.w, false, true)
        SetPedComponentVariation(charPed, 0, 0, 0, 2)
        FreezeEntityPosition(charPed, false)
        SetEntityInvincible(charPed, true)
        PlaceObjectOnGroundProperly(charPed)
        SetBlockingOfNonTemporaryEvents(charPed, true)
        if data then
            if GetResourceState('illenium-appearance') == 'started' then
                pcall(function()
                    exports['illenium-appearance']:setPedAppearance(charPed, data)
                end)
            else
                TriggerEvent('qb-clothing:client:loadPlayerClothing', data, charPed)
            end
        end
    end)
end

local function skyCam(bool)
    TriggerEvent('dr-weathersync:client:DisableSync')
    if bool then
        -- No more blurry dark background: keep normal timecycle
        DoScreenFadeIn(1000)
        FreezeEntityPosition(PlayerPedId(), false)
        cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", Config.CamCoords.x, Config.CamCoords.y, Config.CamCoords.z,
            0.0, 0.0, Config.CamCoords.w, 60.00, false, 0)
        SetCamActive(cam, true)
        RenderScriptCams(true, false, 1, true, true)
    else
        -- Restore normal camera
        SetTimecycleModifier('default')
        if cam ~= nil then
            SetCamActive(cam, false)
            DestroyCam(cam, true)
        end
        RenderScriptCams(false, false, 1, true, true)
        FreezeEntityPosition(PlayerPedId(), false)
    end
end

local function openCharMenu(bool)
    CreateThread(function()
        Wait(20000)
        if not loadScreenCheckState then
            ShutdownLoadingScreenNui()
            loadScreenCheckState = true
        end
    end)
    local characters, amount = lib.callback.await('qbx_core:server:getCharacters', false)
        -- Build flat `translations` object for NUI:
        -- e.g. JS expects `translations["characters_header"]`, not `translations["ui.characters_header"]`.
        local translations = {}
        local uiPhrases = (Lang.phrases and Lang.phrases.ui)
            or (Lang.fallback and Lang.fallback.phrases and Lang.fallback.phrases.ui)
            or {}
        for key in pairs(uiPhrases) do
            -- Prefer Lang:t() for real locale resolution; fall back to raw phrase string.
            local value = (Lang and type(Lang.t) == "function" and Lang:t(("ui.%s"):format(key)))
                or uiPhrases[key]
            translations[key] = value or ""
        end
        SetNuiFocus(bool, bool)
        SendNUIMessage({
            action = "ui",
            customNationality = Config.customNationality,
            toggle = bool,
            nChar = amount or 2,
            enableDeleteButton = Config.EnableDeleteButton,
            translations = translations
        })
        skyCam(bool)
        if not loadScreenCheckState then
            ShutdownLoadingScreenNui()
            loadScreenCheckState = true
        end
end

-- Events

RegisterNetEvent('dr-multicharacter:client:closeNUIdefault',
    function()                                                             -- This event is only for no starting apartments
        DeleteEntity(charPed)
        SetNuiFocus(false, false)
        DoScreenFadeOut(500)
        Wait(2000)
        SetEntityCoords(PlayerPedId(), Config.DefaultSpawn.x, Config.DefaultSpawn.y, Config.DefaultSpawn.z)
        TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
        TriggerEvent('QBCore:Client:OnPlayerLoaded')
        TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
        TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
        Wait(500)
        openCharMenu()
        SetEntityVisible(PlayerPedId(), true)
        Wait(500)
        DoScreenFadeIn(250)
        TriggerEvent('dr-weathersync:client:EnableSync')
        openCharacterCreator()
    end)

RegisterNetEvent('dr-multicharacter:client:closeNUI', function()
    DeleteEntity(charPed)
    SetNuiFocus(false, false)
end)

RegisterNetEvent('dr-multicharacter:client:chooseChar', function()
    SetNuiFocus(false, false)
    DoScreenFadeOut(10)
    Wait(1000)
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    local interior = GetInteriorAtCoords(Config.Interior.x, Config.Interior.y, Config.Interior.z - 18.9)
    LoadInterior(interior)
    local interiorWait = 0
    while not IsInteriorReady(interior) do
        Wait(500)
        interiorWait = interiorWait + 500
        if interiorWait >= 15000 then break end
    end
    FreezeEntityPosition(PlayerPedId(), true)
    SetEntityCoords(PlayerPedId(), Config.HiddenCoords.x, Config.HiddenCoords.y, Config.HiddenCoords.z)
    Wait(1500)
    openCharMenu(true)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

    print('working #dr-multicharacter')
end)


RegisterNetEvent('dr-multicharacter:client:spawnLastLocation', function(coords, cData)
    -- Deprecated with QBX conversion. Spawn is handled by renzu_spawn after character load.
end)

-- NUI Callbacks

RegisterNUICallback('closeUI', function(data, cb)
    DoScreenFadeOut(10)
    -- no-op: selection is handled via selectCharacter
    openCharMenu(false)
    SetEntityAsMissionEntity(charPed, true, true)
    DeleteEntity(charPed)
    if Config.SkipSelection then
        SetNuiFocus(false, false)
        skyCam(false)
    else
        openCharMenu(false)
    end
    cb("ok")
end)

RegisterNUICallback('disconnectButton', function(_, cb)
    SetEntityAsMissionEntity(charPed, true, true)
    DeleteEntity(charPed)
    TriggerServerEvent('dr-multicharacter:server:disconnect')
    cb("ok")
end)

local function runSpawnSelector()
    if GetResourceState('renzu_spawn') ~= 'started' then return end
    exports.renzu_spawn:Selector()
end

local function finalizePlayerSpawn()
    -- renzu_spawn often bypasses spawnmanager (which normally calls ShutdownLoadingScreen)
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    -- Standard QBCore compatibility events (many scripts listen for these)
    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
    TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
    TriggerEvent('dr-weathersync:client:EnableSync')
end

RegisterNUICallback('selectCharacter', function(data, cb)
    local cData = data.cData
    DoScreenFadeOut(10)
    if cData and cData.citizenid then
        lib.callback.await('qbx_core:server:loadCharacter', false, cData.citizenid)
        openCharMenu(false)
        SetEntityAsMissionEntity(charPed, true, true)
        DeleteEntity(charPed)
        skyCam(false)
        DoScreenFadeIn(250)
        runSpawnSelector()
        finalizePlayerSpawn()
    end
    openCharMenu(false)
    SetEntityAsMissionEntity(charPed, true, true)
    DeleteEntity(charPed)
    cb("ok")
end)

RegisterNUICallback('cDataPed', function(nData, cb)
    local cData = nData.cData
    SetEntityAsMissionEntity(charPed, true, true)
    DeleteEntity(charPed)
    if cData ~= nil then
        if not cached_player_skins[cData.citizenid] then
            local temp_model = promise.new()
            local temp_data = promise.new()

            local skin, model = lib.callback.await('qbx_core:server:getPreviewPedData', false, cData.citizenid)
            temp_model:resolve(model)
            temp_data:resolve(skin and json.encode(skin) or nil)

            local resolved_model = Citizen.Await(temp_model)
            local resolved_data = Citizen.Await(temp_data)

            cached_player_skins[cData.citizenid] = { model = resolved_model, data = resolved_data }
        end

        local model = cached_player_skins[cData.citizenid].model
        local data = cached_player_skins[cData.citizenid].data

        model = model ~= nil and tonumber(model) or false

        if model ~= nil then
            initializePedModel(model, json.decode(data))
        else
            initializePedModel()
        end
        cb("ok")
    else
        initializePedModel()
        cb("ok")
    end
end)

RegisterNUICallback('setupCharacters', function(_, cb)
    local characters = lib.callback.await('qbx_core:server:getCharacters', false)
    cached_player_skins = {}
    SendNUIMessage({
        action = "setupCharacters",
        characters = characters or {}
    })
    cb("ok")
end)

RegisterNUICallback('removeBlur', function(_, cb)
    SetTimecycleModifier('default')
    cb("ok")
end)

RegisterNUICallback('createNewCharacter', function(data, cb)
    local cData = data
    DoScreenFadeOut(150)
    if cData.gender == "Male" then
        cData.gender = 0
    elseif cData.gender == "Female" then
        cData.gender = 1
    end
    local newData = lib.callback.await('qbx_core:server:createCharacter', false, {
        firstname = cData.firstname,
        lastname = cData.lastname,
        nationality = cData.nationality,
        gender = cData.gender,
        birthdate = cData.birthdate,
        cid = tonumber(cData.cid) or 1
    })
    Wait(500)
    skyCam(false)
    DoScreenFadeIn(250)
    runSpawnSelector()
    finalizePlayerSpawn()
    openCharacterCreator()
    cb("ok")
end)

RegisterNUICallback('removeCharacter', function(data, cb)
    if data and data.citizenid then
        lib.callback.await('qbx_core:server:deleteCharacter', false, data.citizenid)
    end
    TriggerEvent('dr-multicharacter:client:chooseChar')
    cb("ok")
end)
