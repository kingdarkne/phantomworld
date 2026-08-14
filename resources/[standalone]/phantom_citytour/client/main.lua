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
    end
    return tourCompleted
end

-- Initialize
CreateThread(function()
    while not QBCore do
        Wait(100)
    end
    
    PlayerData = QBCore.Functions.GetPlayerData()
    
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        PlayerData = QBCore.Functions.GetPlayerData()
        CheckForNewPlayer()
    end)
    
    RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
        PlayerData.job = JobInfo
    end)

    Wait(4000)
    if PlayerData and PlayerData.citizenid then
        CheckForNewPlayer()
    end
end)

function HasPlayerCompletedTour()
    return tourCompleted
end

-- First join: auto-play tour once. Returning players skip unless they press F7 or /citytour.
function CheckForNewPlayer()
    CreateThread(function()
        refreshTourCompleted()

        if tourCompleted then
            return
        end

        local delay = (Config.NewPlayerSettings.AutoStartDelay or 5) * 1000
        Wait(delay)

        if tourCompleted or isTourActive then
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
        local cooldownMs = Config.NewPlayerSettings.CooldownTime * 60000

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
    
    -- Initialize tour
    InitializeTour()
    
    -- Show UI first so captions are ready for location updates
    SendNUIMessage({
        action = "showTour",
        tourData = GetTourOverview(),
        speakEnabled = Config.TourSettings.EnableNarration ~= false,
        currentLocation = nil
    })

    -- Start first location
    ProcessLocation(currentLocationIndex)
    
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
    SetEntityInvincible(PlayerPedId(), false)
    SetEntityVisible(PlayerPedId(), true, 0)
    FreezeEntityPosition(PlayerPedId(), false)
    
    -- Clear weather / look modifiers
    ClearWeatherTypeOverride()
    ClearTimecycleModifier()
    ClearExtraTimecycleModifier()
    
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

    local info = location.info or {}
    local narration = table.concat({
        info.title or location.name or '',
        info.subtitle or '',
        info.description or location.description or ''
    }, '. ')

    activeSubtitle = info.title or location.name

    -- Send location info to UI (+ narration text)
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
            currentIndex = index
        }
    })
    
    -- Wait for location duration
    CreateThread(function()
        Wait(location.camera.duration)
        
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
    
    -- Set weather
    if effects.weather then
        SetWeatherTypeNowPersist(effects.weather)
        SetWeatherTypeOverride(effects.weather)
    end
    
    -- Only apply known/requested timecycles that exist in data (optional)
    if effects.timecycle and effects.timecycle ~= '' and effects.timecycle ~= 'default' then
        SetTimecycleModifier(effects.timecycle)
    end
end

function SetupCamera(cameraData)
    if not cameraData or not cameraData.start or not cameraData.target then return end
    
    if cameraHandle then
        DestroyCam(cameraHandle, false)
        cameraHandle = nil
    end
    
    local start = cameraData.start
    local target = cameraData.target
    local camX, camY, camZ = start.x, start.y, start.z
    local lookX, lookY, lookZ = target.x, target.y, target.z

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

    cameraHandle = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(cameraHandle, camX, camY, camZ)
    SetCamFov(cameraHandle, cameraData.fov or Config.TourSettings.CameraFOV or 50.0)
    PointCamAtCoord(cameraHandle, lookX, lookY, lookZ)
    SetCamActive(cameraHandle, true)
    RenderScriptCams(true, true, 800, true, true)
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
        SendNUIMessage({ action = 'stopSpeak' })
        
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

-- On-screen fallback caption while the cinematic runs
CreateThread(function()
    while true do
        if isTourActive and activeSubtitle then
            SetTextFont(4)
            SetTextScale(0.45, 0.45)
            SetTextColour(255, 255, 255, 220)
            SetTextCentre(true)
            SetTextDropshadow(1, 0, 0, 0, 200)
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName(activeSubtitle)
            EndTextCommandDisplayText(0.5, 0.88)
            Wait(0)
        else
            Wait(250)
        end
    end
end)

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
