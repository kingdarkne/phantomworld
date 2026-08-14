local QBCore = exports['qbx_core']:GetCoreObject()
local isTourActive = false
local currentLocationIndex = 1
local isPaused = false
local cameraHandle = nil
local playerHandle = nil
local preMulticharMode = false
local activeSubtitle = nil
local KVP_DONE = 'phantom_citytour_done'

-- Local variables
local PlayerData = {}
local tourStartTime = 0
local lastTourTime = 0
local tourCompleted = false

local function refreshTourCompleted()
    local ok, completed = pcall(function()
        return lib.callback.await('phantom_citytour:hasCompleted', false)
    end)
    if ok then
        tourCompleted = completed == true
        -- Keep client KVP in sync with server so skips/resets behave correctly.
        if tourCompleted then
            SetResourceKvpInt(KVP_DONE, 1)
        else
            SetResourceKvpInt(KVP_DONE, 0)
        end
    end
    return tourCompleted
end

-- Initialize
CreateThread(function()
    while not QBCore do
        Wait(100)
        QBCore = exports['qbx_core']:GetCoreObject()
    end
    
    PlayerData = QBCore.Functions.GetPlayerData()
    
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        PlayerData = QBCore.Functions.GetPlayerData()
        tourPromptShown = false
        CheckForNewPlayer()
    end)
    
    RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
        PlayerData.job = JobInfo
    end)

    -- Fallback if the player was already loaded when this resource started/restarted.
    for _ = 1, 20 do
        Wait(1000)
        PlayerData = QBCore.Functions.GetPlayerData() or PlayerData
        if PlayerData and PlayerData.citizenid then
            CheckForNewPlayer()
            break
        end
    end
end)

function HasPlayerCompletedTour()
    return tourCompleted
end

-- First join: ask (dialog) whether to take the city tour. Returning players use F7 /citytour.
local tourPromptShown = false

local function markTourSkipped()
    tourCompleted = true
    SetResourceKvpInt(KVP_DONE, 1)
    TriggerServerEvent('phantom_citytour:markCompleted')
    if lib and lib.notify then
        lib.notify({
            title = 'Phantom World',
            description = Config.Language.TourSkipped or 'Tour skipped — press F7 anytime.',
            type = 'inform',
            duration = 8000
        })
    end
end

function CheckForNewPlayer()
    CreateThread(function()
        refreshTourCompleted()

        if tourCompleted or isTourActive or tourPromptShown then
            return
        end

        local delay = (Config.NewPlayerSettings.AutoStartDelay or 8) * 1000
        Wait(delay)

        refreshTourCompleted()
        if tourCompleted or isTourActive or tourPromptShown then
            return
        end

        -- Prefer ox_lib ask dialog so the player explicitly chooses Start / Skip.
        if Config.NewPlayerSettings.AskDialogOnFirstJoin ~= false and lib and lib.alertDialog then
            tourPromptShown = true
            local choice = lib.alertDialog({
                header = Config.Language.TourPromptHeader or Config.Language.TourTitle,
                content = Config.Language.WelcomeMessage,
                centered = true,
                cancel = true,
                labels = {
                    confirm = Config.Language.TourPromptStart or 'Start Tour',
                    cancel = Config.Language.TourPromptSkip or 'Skip',
                }
            })

            if choice == 'confirm' then
                StartCityTour()
                return
            end

            if Config.NewPlayerSettings.MarkCompletedOnSkip ~= false then
                markTourSkipped()
            elseif Config.NewPlayerSettings.ShowPromptOnSpawn then
                TriggerEvent('chat:addMessage', {
                    color = {0, 255, 0},
                    multiline = true,
                    args = {'[Phantom Tour]', Config.Language.PressToStart:format(Config.Keybinds.StartTour)}
                })
            end
            return
        end

        if Config.NewPlayerSettings.AutoStartOnFirstJoin then
            if lib and lib.notify then
                lib.notify({
                    title = 'Phantom World',
                    description = Config.Language.WelcomeMessage,
                    type = 'inform',
                    duration = 10000
                })
            end
            StartCityTour()
            return
        end

        if Config.NewPlayerSettings.ShowPromptOnSpawn then
            TriggerEvent('chat:addMessage', {
                color = {0, 255, 0},
                multiline = true,
                args = {'[Phantom Tour]', Config.Language.PressToStart:format(Config.Keybinds.StartTour)}
            })
        end
    end)
end

function StartCityTourPreMultichar()
    -- Fast path: freeroam does not gate character select on the cinematic tour.
    if not Config.NewPlayerSettings.ForceBeforeMultichar then
        TriggerEvent('phantom_citytour:client:finished')
        return
    end

    if isTourActive then
        TriggerEvent('phantom_citytour:client:finished')
        return
    end

    local alreadyDone = GetResourceKvpInt(KVP_DONE) == 1
    if alreadyDone and not Config.NewPlayerSettings.ForceEveryJoin then
        TriggerEvent('phantom_citytour:client:finished')
        return
    end

    preMulticharMode = true
    CreateThread(function()
        Wait(400)
        local ok, err = pcall(StartCityTour)
        if not ok then
            print(('[phantom_citytour] tour error: %s'):format(tostring(err)))
            preMulticharMode = false
            TriggerEvent('phantom_citytour:client:finished')
            return
        end
        if preMulticharMode and not isTourActive then
            preMulticharMode = false
            TriggerEvent('phantom_citytour:client:finished')
        end
    end)
end

-- Main tour functions
function StartCityTour()
    if isTourActive then
        TriggerEvent('chat:addMessage', {
            color = {255, 165, 0},
            multiline = true,
            args = {"[Phantom Tour]", "Tour is already active!"}
        })
        return
    end
    
    -- Repeat tours only after the player has completed once.
    if not preMulticharMode and tourCompleted then
        local currentTime = GetGameTimer()
        local cooldownMs = (Config.NewPlayerSettings.CooldownTime or 30) * 60000

        if lastTourTime > 0 and currentTime - lastTourTime < cooldownMs then
            local remainingTime = math.ceil((cooldownMs - (currentTime - lastTourTime)) / 60000)
            TriggerEvent('chat:addMessage', {
                color = {255, 165, 0},
                multiline = true,
                args = {'[Phantom Tour]', 'Please wait ' .. remainingTime .. ' minutes before starting another tour.'}
            })
            return
        end
    end

    if type(TourLocations) ~= 'table' or #TourLocations < 1 then
        print('[phantom_citytour] TourLocations missing — aborting')
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            multiline = true,
            args = {'[Phantom Tour]', 'Tour data failed to load. Try again later.'}
        })
        return
    end
    
    isTourActive = true
    currentLocationIndex = 1
    isPaused = false
    tourStartTime = GetGameTimer()
    activeSubtitle = Config.Language.TourTitle or 'City Tour'
    
    local ok, err = pcall(function()
        InitializeTour()

        -- Show UI first so captions / hints appear even if a later step fails.
        SendNUIMessage({
            action = "showTour",
            tourData = GetTourOverview(),
            speakEnabled = Config.TourSettings.EnableNarration ~= false,
            currentLocation = nil
        })

        ProcessLocation(currentLocationIndex)
    end)

    if not ok then
        print(('[phantom_citytour] StartCityTour failed: %s'):format(tostring(err)))
        isTourActive = false
        RestorePlayer()
        if cameraHandle then
            RenderScriptCams(false, false, 0, true, true)
            DestroyCam(cameraHandle, false)
            cameraHandle = nil
        end
        SendNUIMessage({ action = 'hideTour' })
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            multiline = true,
            args = {'[Phantom Tour]', 'Tour failed to start — you should be visible again.'}
        })
        return
    end
    
    TriggerEvent('chat:addMessage', {
        color = {0, 255, 0},
        multiline = true,
        args = {"[Phantom Tour]", "Welcome to " .. Config.Language.TourTitle .. " — SPACE skip · F7 stop"}
    })
end

function StopCityTour(markCompleted)
    if not isTourActive then return end
    
    isTourActive = false
    isPaused = false
    lastTourTime = GetGameTimer()
    activeSubtitle = nil

    if markCompleted then
        tourCompleted = true
        SetResourceKvpInt(KVP_DONE, 1)
        TriggerServerEvent('phantom_citytour:markCompleted')
    end
    
    if cameraHandle then
        RenderScriptCams(false, true, 500, true, true)
        DestroyCam(cameraHandle, false)
        cameraHandle = nil
    end
    
    -- Restore player
    RestorePlayer()
    
    -- Hide UI / stop narration
    SendNUIMessage({ action = "stopSpeak" })
    SendNUIMessage({
        action = "hideTour"
    })

    if preMulticharMode then
        preMulticharMode = false
        TriggerEvent('phantom_citytour:client:finished')
    end
    
    -- Show completion message
    local tourDuration = math.floor((GetGameTimer() - tourStartTime) / 1000)
    TriggerEvent('chat:addMessage', {
        color = {0, 255, 0},
        multiline = true,
        args = {"[Phantom Tour]", Config.Language.TourCompleted .. " (Duration: " .. tourDuration .. "s)"}
    })
end

function InitializeTour()
    -- Hide HUD
    DisplayHud(false)
    DisplayRadar(false)
    
    -- Set player invincible
    SetEntityInvincible(PlayerPedId(), true)
    SetEntityVisible(PlayerPedId(), false, 0)
    
    -- Freeze player
    FreezeEntityPosition(PlayerPedId(), true)
    
    -- Set time and weather for first location
    local firstLocation = TourLocations[1]
    if firstLocation and firstLocation.effects then
        ApplyLocationEffects(firstLocation.effects)
    end
end

function RestorePlayer()
    -- Show HUD
    DisplayHud(true)
    DisplayRadar(true)
    
    -- Restore player
    local ped = PlayerPedId()
    SetEntityInvincible(ped, false)
    SetEntityVisible(ped, true, false)
    SetLocalPlayerVisibleLocally(true)
    NetworkSetEntityInvisibleToNetwork(ped, false)
    FreezeEntityPosition(ped, false)
    
    -- Clear weather / look modifiers (FiveM: ClearOverrideWeather, not ClearWeatherTypeOverride)
    pcall(function()
        ClearOverrideWeather()
        ClearWeatherTypePersist()
        SetWeatherTypeNow('CLEAR')
        SetWeatherTypeNowPersist('CLEAR')
    end)
    ClearTimecycleModifier()
    ClearExtraTimecycleModifier()
    
    -- Clear any tasks
    ClearPedTasks(ped)
end

function ProcessLocation(index)
    if not isTourActive then
        return
    end

    if index > #TourLocations then
        StopCityTour(true)
        return
    end
    
    local location = TourLocations[index]
    if not location then
        NextLocation()
        return
    end

    local info = location.info or {}
    local narration = table.concat({
        info.title or location.name or '',
        info.subtitle or '',
        info.description or location.description or ''
    }, '. ')

    -- Captions first — never gate UI on camera/player setup.
    activeSubtitle = info.title or location.name or ('Stop ' .. tostring(index))
    SendNUIMessage({
        action = "updateLocation",
        location = {
            id = location.id,
            name = location.name,
            description = location.description,
            category = location.category,
            info = info,
            progress = (index / #TourLocations) * 100,
            narration = narration,
            currentIndex = index,
            totalLocations = #TourLocations
        }
    })

    local okEffects, errEffects = pcall(ApplyLocationEffects, location.effects)
    if not okEffects then
        print(('[phantom_citytour] effects error @%s: %s'):format(tostring(location.id), tostring(errEffects)))
    end

    local okCam, errCam = pcall(SetupCamera, location.camera)
    if not okCam then
        print(('[phantom_citytour] camera error @%s: %s'):format(tostring(location.id), tostring(errCam)))
    end

    -- Player setup must never block the tour (anim dict hangs were freezing players invisible).
    CreateThread(function()
        local okPed, errPed = pcall(SetupPlayer, location.player)
        if not okPed then
            print(('[phantom_citytour] player setup error @%s: %s'):format(tostring(location.id), tostring(errPed)))
        end
    end)
    
    local duration = (location.camera and tonumber(location.camera.duration)) or 8000
    CreateThread(function()
        Wait(duration)
        
        if isTourActive and not isPaused and currentLocationIndex == index then
            NextLocation()
        end
    end)
end

function ApplyLocationEffects(effects)
    if not effects then return end

    ClearTimecycleModifier()
    
    -- Time is stored as hour-of-day (0-23), not a fraction of a day.
    if effects.time then
        local hour = math.floor(tonumber(effects.time) or 12) % 24
        NetworkOverrideClockTime(hour, 0, 0)
    end
    
    -- Set weather (FiveM: SetOverrideWeather, not SetWeatherTypeOverride)
    if effects.weather then
        pcall(function()
            SetWeatherTypeOvertimePersist(effects.weather, 0.0)
            SetWeatherTypeNow(effects.weather)
            SetWeatherTypeNowPersist(effects.weather)
            SetOverrideWeather(effects.weather)
        end)
    end
    
    -- Only apply known/requested timecycles that exist in data (optional)
    if effects.timecycle and effects.timecycle ~= '' and effects.timecycle ~= 'default' then
        SetTimecycleModifier(effects.timecycle)
    end
end

function SetupCamera(cameraData)
    if not cameraData or not cameraData.start or not cameraData.target then
        print('[phantom_citytour] SetupCamera missing start/target')
        return
    end
    
    if cameraHandle then
        DestroyCam(cameraHandle, false)
        cameraHandle = nil
    end
    
    local start = cameraData.start
    local target = cameraData.target
    local camX, camY, camZ = start.x + 0.0, start.y + 0.0, start.z + 0.0
    local lookX, lookY, lookZ = target.x + 0.0, target.y + 0.0, target.z + 0.0

    -- Old data pointed straight down (same XY). Offset the eye so we frame the landmark.
    local dx = lookX - camX
    local dy = lookY - camY
    if (dx * dx + dy * dy) < 25.0 then
        local heading = start.w or 0.0
        local rad = math.rad(heading)
        local dist = cameraData.distance or Config.TourSettings.CameraFallbackDistance or 18.0
        local height = cameraData.height or Config.TourSettings.CameraFallbackHeight or 8.0
        camX = lookX - (math.sin(rad) * dist)
        camY = lookY + (math.cos(rad) * dist)
        camZ = lookZ + height
        lookZ = lookZ + 1.5
    end

    RequestCollisionAtCoord(camX, camY, camZ)
    RequestCollisionAtCoord(lookX, lookY, lookZ)
    local deadline = GetGameTimer() + 1500
    while GetGameTimer() < deadline and (not HasCollisionLoadedAroundEntity(PlayerPedId())) do
        RequestCollisionAtCoord(camX, camY, camZ)
        Wait(0)
    end

    cameraHandle = CreateCamWithParams(
        'DEFAULT_SCRIPTED_CAMERA',
        camX, camY, camZ,
        0.0, 0.0, 0.0,
        cameraData.fov or Config.TourSettings.CameraFOV or 50.0,
        false,
        2
    )
    if not cameraHandle or cameraHandle == 0 then
        cameraHandle = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamCoord(cameraHandle, camX, camY, camZ)
        SetCamFov(cameraHandle, cameraData.fov or Config.TourSettings.CameraFOV or 50.0)
    end

    PointCamAtCoord(cameraHandle, lookX, lookY, lookZ)
    SetCamActive(cameraHandle, true)
    RenderScriptCams(true, true, 800, true, true)
end

function SetupPlayer(playerData)
    if not playerData or not playerData.coords then return end
    
    local ped = PlayerPedId()
    local x, y, z = playerData.coords.x + 0.0, playerData.coords.y + 0.0, playerData.coords.z + 0.0

    RequestCollisionAtCoord(x, y, z)
    SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
    if playerData.heading then
        SetEntityHeading(ped, playerData.heading + 0.0)
    end
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, false, false)
    SetEntityInvincible(ped, true)

    -- Animations are optional decoration — never block the cinematic on them.
    if playerData.animation and playerData.animation.dict and playerData.animation.anim then
        if LoadAnimDict(playerData.animation.dict, 1500) then
            TaskPlayAnim(ped, playerData.animation.dict, playerData.animation.anim, 8.0, -8.0, -1, 1, 0, false, false, false)
        end
    end
end

function NextLocation()
    if not isTourActive then return end
    
    currentLocationIndex = currentLocationIndex + 1
    
    if currentLocationIndex > #TourLocations then
        StopCityTour(true)
    else
        if isPaused then
            -- Just update UI to show next location is ready
            SendNUIMessage({
                action = "updateProgress",
                progress = (currentLocationIndex / #TourLocations) * 100
            })
        else
            ProcessLocation(currentLocationIndex)
        end
    end
end

function PreviousLocation()
    if not isTourActive or currentLocationIndex <= 1 then return end
    
    currentLocationIndex = currentLocationIndex - 1
    ProcessLocation(currentLocationIndex)
end

function SkipLocation()
    if not isTourActive then return end
    
    NextLocation()
end

function PauseTour()
    if not isTourActive then return end
    
    isPaused = not isPaused
    
    if isPaused then
        -- Pause current animations
        ClearPedTasks(PlayerPedId())
        SendNUIMessage({ action = 'stopSpeak' })
        
        SendNUIMessage({
            action = "pauseTour",
            isPaused = true
        })
    else
        -- Resume tour
        local location = TourLocations[currentLocationIndex]
        if location and location.player then
            CreateThread(function()
                SetupPlayer(location.player)
            end)
        end
        
        SendNUIMessage({
            action = "pauseTour",
            isPaused = false
        })
        
        -- Continue after a short delay
        CreateThread(function()
            Wait(1000)
            if isTourActive and not isPaused then
                NextLocation()
            end
        end)
    end
end

-- Keep script cam alive + native controls/captions (NUI alone is not enough).
CreateThread(function()
    while true do
        if isTourActive then
            if cameraHandle and DoesCamExist(cameraHandle) then
                if not IsCamActive(cameraHandle) then
                    SetCamActive(cameraHandle, true)
                end
                RenderScriptCams(true, false, 0, true, true)
            end

            DisableControlAction(0, 30, true) -- move LR
            DisableControlAction(0, 31, true) -- move UD
            DisableControlAction(0, 21, true) -- sprint
            DisableControlAction(0, 22, true) -- jump / space
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 37, true)

            -- SPACE skip (works even when keybind conflicts)
            if IsDisabledControlJustPressed(0, 22) or IsControlJustPressed(0, 22) then
                SkipLocation()
            end

            if activeSubtitle then
                SetTextFont(4)
                SetTextScale(0.55, 0.55)
                SetTextColour(255, 255, 255, 255)
                SetTextCentre(true)
                SetTextDropshadow(2, 0, 0, 0, 255)
                SetTextOutline()
                BeginTextCommandDisplayText('STRING')
                AddTextComponentSubstringPlayerName(activeSubtitle)
                EndTextCommandDisplayText(0.5, 0.82)

                SetTextFont(4)
                SetTextScale(0.35, 0.35)
                SetTextColour(200, 220, 255, 220)
                SetTextCentre(true)
                BeginTextCommandDisplayText('STRING')
                AddTextComponentSubstringPlayerName(('SPACE skip  ·  F7 stop  ·  %s/%s'):format(
                    currentLocationIndex,
                    #TourLocations
                ))
                EndTextCommandDisplayText(0.5, 0.88)
            end

            Wait(0)
        else
            Wait(250)
        end
    end
end)

-- On-screen fallback caption while the cinematic runs (legacy duplicate removed — handled above)

function GetTourOverview()
    local overview = {
        title = Config.Language.TourTitle,
        totalLocations = #TourLocations,
        estimatedDuration = 0, -- Calculate total duration
        categories = {}
    }
    
    -- Calculate total duration
    for _, location in ipairs(TourLocations) do
        overview.estimatedDuration = overview.estimatedDuration + (location.camera.duration / 1000)
    end
    
    -- Get unique categories
    local seenCategories = {}
    for _, location in ipairs(TourLocations) do
        if not seenCategories[location.category] then
            seenCategories[location.category] = true
            table.insert(overview.categories, location.category)
        end
    end
    
    return overview
end

-- Utility functions
function LoadAnimDict(dict, timeoutMs)
    if not dict or dict == '' then return false end
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local deadline = GetGameTimer() + (timeoutMs or 1500)
    while not HasAnimDictLoaded(dict) do
        if GetGameTimer() >= deadline then
            print(('[phantom_citytour] anim dict timeout: %s'):format(tostring(dict)))
            return false
        end
        RequestAnimDict(dict)
        Wait(10)
    end
    return true
end

RegisterCommand('+phantom_citytour_toggle', function()
    if isTourActive then
        StopCityTour(false)
    else
        StartCityTour()
    end
end, false)
RegisterCommand('-phantom_citytour_toggle', function() end, false)
RegisterKeyMapping('+phantom_citytour_toggle', 'Phantom City Tour (start/stop)', 'keyboard', Config.Keybinds.StartTour)

RegisterCommand('phantom_citytour_skip', function()
    if isTourActive then SkipLocation() end
end, false)
RegisterKeyMapping('phantom_citytour_skip', 'Phantom City Tour (skip location)', 'keyboard', Config.Keybinds.SkipLocation)

RegisterCommand('phantom_citytour_pause', function()
    if isTourActive then PauseTour() end
end, false)

RegisterCommand('phantom_citytour_toggle_ui', function()
    if isTourActive then
        SendNUIMessage({ action = 'toggleUI' })
    end
end, false)
RegisterKeyMapping('phantom_citytour_toggle_ui', 'Phantom City Tour (toggle UI)', 'keyboard', Config.Keybinds.ToggleUI)

-- NUI callbacks
RegisterNUICallback('startTour', function(data, cb)
    StartCityTour()
    cb('ok')
end)

RegisterNUICallback('stopTour', function(data, cb)
    StopCityTour(false)
    cb('ok')
end)

RegisterNUICallback('nextLocation', function(data, cb)
    NextLocation()
    cb('ok')
end)

RegisterNUICallback('previousLocation', function(data, cb)
    PreviousLocation()
    cb('ok')
end)

RegisterNUICallback('skipLocation', function(data, cb)
    SkipLocation()
    cb('ok')
end)

RegisterNUICallback('pauseTour', function(data, cb)
    PauseTour()
    cb('ok')
end)

RegisterNUICallback('setWaypoint', function(data, cb)
    if data.waypoint then
        SetNewWaypoint(data.waypoint.x, data.waypoint.y)
    end
    cb('ok')
end)

-- Exports
exports('StartCityTour', StartCityTour)
exports('StartCityTourPreMultichar', StartCityTourPreMultichar)
exports('StopCityTour', StopCityTour)
exports('IsTourActive', function() return isTourActive end)

-- Commands
RegisterCommand('citytour', function()
    if isTourActive then
        StopCityTour(false)
    else
        StartCityTour()
    end
end, false)

RegisterCommand('stoptour', function()
    StopCityTour(false)
end, false)

RegisterNetEvent('phantom_citytour:forceStart', function()
    StartCityTour()
end)

RegisterNetEvent('phantom_citytour:forceStop', function()
    StopCityTour(false)
end)
