local QBCore = nil
local isTourActive = false
local currentLocationIndex = 1
local isPaused = false
local cameraHandle = nil
local playerHandle = nil
local preMulticharMode = false

-- Local variables
local PlayerData = {}
local tourStartTime = 0
local lastTourTime = 0
local tourCompleted = false
local KVP_DONE = 'phantom_citytour_pre_done'

local function getCore()
    if QBCore then return QBCore end
    local ok, core = pcall(function()
        return exports['qbx_core']:GetCoreObject()
    end)
    if ok then QBCore = core end
    return QBCore
end

local function refreshTourCompleted()
    -- Prefer KVP for pre-multichar; fall back to server metadata when loaded
    if GetResourceKvpInt(KVP_DONE) == 1 then
        tourCompleted = true
        return true
    end
    local core = getCore()
    if not core then return tourCompleted end
    local ok, completed = pcall(function()
        return lib.callback.await('phantom_citytour:hasCompleted', false)
    end)
    if ok then
        tourCompleted = completed == true
    end
    return tourCompleted
end

-- Initialize (post-spawn helpers only — pre-multichar does not wait on this)
CreateThread(function()
    while not getCore() do
        Wait(200)
    end

    PlayerData = QBCore.Functions.GetPlayerData() or {}

    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        PlayerData = QBCore.Functions.GetPlayerData() or {}
        -- Do not auto-start tour after spawn; it already ran before multichar.
    end)

    RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
        PlayerData.job = JobInfo
    end)
end)

function HasPlayerCompletedTour()
    return tourCompleted or GetResourceKvpInt(KVP_DONE) == 1
end

-- First join: auto-play tour once. Returning players skip unless they press F7 or /citytour.
function CheckForNewPlayer()
    -- Disabled: tour is started from Afterlife before CharactersMenu.
end

--- Run cinematic tour before multicharacter. Signals `phantom_citytour:client:finished` when done.
function StartCityTourPreMultichar()
    if isTourActive then
        TriggerEvent('phantom_citytour:client:finished')
        return
    end

    -- Returning clients (KVP) skip straight to multichar unless ForceEveryJoin is on.
    local alreadyDone = GetResourceKvpInt(KVP_DONE) == 1
    if alreadyDone and not Config.NewPlayerSettings.ForceEveryJoin then
        TriggerEvent('phantom_citytour:client:finished')
        return
    end

    preMulticharMode = true
    CreateThread(function()
        -- Brief settle after loadscreen fade so cams/NUI attach cleanly
        Wait(400)
        StartCityTour()
        if lib and lib.notify then
            lib.notify({
                title = 'City Tour',
                description = 'SPACE skip location · BACKSPACE skip whole tour',
                type = 'inform',
                duration = 7000,
            })
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

    -- Repeat tours only after the player has completed once (manual F7/citytour).
    if not preMulticharMode and tourCompleted then
        local currentTime = GetGameTimer()
        local cooldownMs = (Config.NewPlayerSettings.CooldownTime or 30) * 60000

        if currentTime - lastTourTime < cooldownMs then
            local remainingTime = math.ceil((cooldownMs - (currentTime - lastTourTime)) / 60000)
            TriggerEvent('chat:addMessage', {
                color = {255, 165, 0},
                multiline = true,
                args = {'[Phantom Tour]', 'Please wait ' .. remainingTime .. ' minutes before starting another tour.'}
            })
            return
        end
    end

    isTourActive = true
    currentLocationIndex = 1
    isPaused = false
    tourStartTime = GetGameTimer()

    InitializeTour()
    ProcessLocation(currentLocationIndex)

    SendNUIMessage({
        action = "showTour",
        tourData = GetTourOverview(),
        currentLocation = currentLocationIndex
    })

    if lib and lib.notify then
        lib.notify({
            title = 'Phantom World',
            description = Config.Language.WelcomeMessage,
            type = 'inform',
            duration = 8000
        })
    else
        TriggerEvent('chat:addMessage', {
            color = {0, 255, 0},
            multiline = true,
            args = {"[Phantom Tour]", "Welcome to " .. Config.Language.TourTitle}
        })
    end
end

function StopCityTour(markCompleted)
    if not isTourActive then
        if preMulticharMode then
            preMulticharMode = false
            TriggerEvent('phantom_citytour:client:finished')
        end
        return
    end

    isTourActive = false
    isPaused = false
    lastTourTime = GetGameTimer()

    if markCompleted then
        tourCompleted = true
        SetResourceKvpInt(KVP_DONE, 1)
        -- Best-effort metadata when a character is already loaded
        pcall(function()
            TriggerServerEvent('phantom_citytour:markCompleted')
        end)
    end

    if cameraHandle then
        RenderScriptCams(false, true, 500, true, true)
        DestroyCam(cameraHandle, false)
        cameraHandle = nil
    end

    RestorePlayer()

    SendNUIMessage({
        action = "hideTour"
    })

    local tourDuration = math.floor((GetGameTimer() - tourStartTime) / 1000)
    if not preMulticharMode then
        TriggerEvent('chat:addMessage', {
            color = {0, 255, 0},
            multiline = true,
            args = {"[Phantom Tour]", Config.Language.TourCompleted .. " (Duration: " .. tourDuration .. "s)"}
        })
    end

    if preMulticharMode then
        preMulticharMode = false
        -- Keep ped hidden/frozen briefly — Afterlife CharactersMenu takes over next
        DisplayRadar(false)
        TriggerEvent('phantom_citytour:client:finished')
    end
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
        NetworkOverrideClockTime(firstLocation.effects.time * 24, 0, 0)
        SetWeatherTypeOverride(firstLocation.effects.weather)
    end
end

function RestorePlayer()
    -- Show HUD
    DisplayHud(true)
    DisplayRadar(true)
    
    -- Restore player
    SetEntityInvincible(PlayerPedId(), false)
    SetEntityVisible(PlayerPedId(), true, 0)
    FreezeEntityPosition(PlayerPedId(), false)
    
    -- Clear weather override
    ClearWeatherTypeOverride()
    
    -- Clear any tasks
    ClearPedTasks(PlayerPedId())
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
    
    -- Apply effects
    ApplyLocationEffects(location.effects)
    
    -- Set up camera
    SetupCamera(location.camera)
    
    -- Set up player
    SetupPlayer(location.player)
    
    -- Send location info to UI
    SendNUIMessage({
        action = "updateLocation",
        location = {
            id = location.id,
            name = location.name,
            description = location.description,
            info = location.info,
            progress = (index / #TourLocations) * 100
        }
    })
    
    -- Wait for location duration
    CreateThread(function()
        Wait(location.camera.duration)
        
        if isTourActive and not isPaused then
            NextLocation()
        end
    end)
end

function ApplyLocationEffects(effects)
    if not effects then return end
    
    -- Set time
    if effects.time then
        NetworkOverrideClockTime(effects.time * 24, 0, 0)
    end
    
    -- Set weather
    if effects.weather then
        SetWeatherTypeOverride(effects.weather)
    end
    
    -- Set timecycle
    if effects.timecycle then
        SetTimecycleModifier(effects.timecycle)
    end
end

function SetupCamera(cameraData)
    if not cameraData then return end
    
    if cameraHandle then
        DestroyCam(cameraHandle, false)
        cameraHandle = nil
    end
    
    cameraHandle = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(cameraHandle, cameraData.start.x, cameraData.start.y, cameraData.start.z)
    SetCamRot(cameraHandle, cameraData.start.w, 0.0, 0.0)
    SetCamFov(cameraHandle, cameraData.fov or 50.0)
    
    -- Point camera at target
    PointCamAtCoord(cameraHandle, cameraData.target.x, cameraData.target.y, cameraData.target.z)
    
    -- Render camera
    RenderScriptCams(true, false, 0, true, true)
    
    -- Smooth transition
    CreateThread(function()
        local startTime = GetGameTimer()
        local duration = Config.TourSettings.CameraTransitionSpeed * 1000
        
        while GetGameTimer() - startTime < duration do
            local progress = (GetGameTimer() - startTime) / duration
            local easeProgress = math.sin((progress * math.pi) / 2) -- Ease in-out
            
            -- Smooth camera movement
            if progress < 1.0 then
                Wait(0)
            else
                break
            end
        end
    end)
end

function SetupPlayer(playerData)
    if not playerData then return end
    
    local ped = PlayerPedId()
    
    -- Set player position
    SetEntityCoords(ped, playerData.coords.x, playerData.coords.y, playerData.coords.z, false, false, false, false)
    SetEntityHeading(ped, playerData.heading)
    
    -- Apply animation
    if playerData.animation then
        LoadAnimDict(playerData.animation.dict)
        TaskPlayAnim(ped, playerData.animation.dict, playerData.animation.anim, 8.0, -8.0, -1, 1, 0, false, false, false)
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
        
        SendNUIMessage({
            action = "pauseTour",
            isPaused = true
        })
    else
        -- Resume tour
        local location = TourLocations[currentLocationIndex]
        if location and location.player then
            SetupPlayer(location.player)
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
function LoadAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(5)
    end
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

RegisterCommand('phantom_citytour_skip_all', function()
    if isTourActive then
        StopCityTour(true)
    end
end, false)
RegisterKeyMapping('phantom_citytour_skip_all', 'Phantom City Tour (skip entire tour)', 'keyboard', Config.Keybinds.SkipTour or 'BACK')

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
    -- Skipping from the pre-multichar tour still counts as completed
    StopCityTour(preMulticharMode == true)
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
