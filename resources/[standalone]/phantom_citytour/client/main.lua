local QBCore = exports['qbx_core']:GetCoreObject()
local isTourActive = false
local currentLocationIndex = 1
local isPaused = false
local cameraHandle = nil
local playerHandle = nil

-- Local variables
local PlayerData = {}
local tourStartTime = 0
local lastTourTime = 0
local tourCompleted = false

-- #region agent log
local DBG_TOUR_LOG_PATH = '/tmp/cursor-debug-logs/phantom_citytour.ndjson'
local function DbgTour(hypothesisId, location, message, data)
    local payload = {
        hypothesisId = hypothesisId,
        location = location,
        message = message,
        data = data or {},
        timestamp = GetGameTimer and GetGameTimer() or 0,
        resource = GetCurrentResourceName and GetCurrentResourceName() or 'phantom_citytour'
    }
    local okJson, line = pcall(json.encode, payload)
    if not okJson then
        line = ('{"hypothesisId":"%s","location":"%s","message":"%s"}'):format(
            tostring(hypothesisId), tostring(location), tostring(message)
        )
    end
    print(('[DBG-TOUR][%s] %s | %s | %s'):format(
        tostring(hypothesisId), tostring(location), tostring(message), line
    ))
    pcall(function()
        local f = io.open(DBG_TOUR_LOG_PATH, 'a')
        if f then
            f:write(line .. '\n')
            f:close()
        end
    end)
end
-- #endregion

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

-- Main tour functions
function StartCityTour()
    -- #region agent log
    DbgTour('C', 'main.lua:StartCityTour', 'entry', {
        isTourActive = isTourActive,
        tourCompleted = tourCompleted,
        currentLocationIndex = currentLocationIndex
    })
    -- #endregion

    if isTourActive then
        TriggerEvent('chat:addMessage', {
            color = {255, 165, 0},
            multiline = true,
            args = {"[Phantom Tour]", "Tour is already active!"}
        })
        -- #region agent log
        DbgTour('C', 'main.lua:StartCityTour', 'early_return_already_active', {})
        -- #endregion
        return
    end
    
    -- Repeat tours only after the player has completed once.
    if tourCompleted then
        local currentTime = GetGameTimer()
        local cooldownMs = Config.NewPlayerSettings.CooldownTime * 60000

        if currentTime - lastTourTime < cooldownMs then
            local remainingTime = math.ceil((cooldownMs - (currentTime - lastTourTime)) / 60000)
            TriggerEvent('chat:addMessage', {
                color = {255, 165, 0},
                multiline = true,
                args = {'[Phantom Tour]', 'Please wait ' .. remainingTime .. ' minutes before starting another tour.'}
            })
            -- #region agent log
            DbgTour('C', 'main.lua:StartCityTour', 'early_return_cooldown', { remainingMinutes = remainingTime })
            -- #endregion
            return
        end
    end
    
    isTourActive = true
    currentLocationIndex = 1
    isPaused = false
    tourStartTime = GetGameTimer()
    
    -- Initialize tour
    -- #region agent log
    DbgTour('C', 'main.lua:StartCityTour', 'before_InitializeTour', {
        ped = PlayerPedId(),
        coords = GetEntityCoords(PlayerPedId())
    })
    -- #endregion
    InitializeTour()
    -- #region agent log
    DbgTour('C', 'main.lua:StartCityTour', 'after_InitializeTour_before_ProcessLocation', {
        pedVisible = IsEntityVisible(PlayerPedId()),
        pedFrozen = IsEntityPositionFrozen(PlayerPedId())
    })
    -- #endregion
    
    -- Start first location
    ProcessLocation(currentLocationIndex)

    -- #region agent log
    DbgTour('D', 'main.lua:StartCityTour', 'after_ProcessLocation_before_showTour_NUI', {
        isTourActive = isTourActive,
        currentLocationIndex = currentLocationIndex,
        cameraHandle = cameraHandle
    })
    -- #endregion
    
    -- Show UI
    SendNUIMessage({
        action = "showTour",
        tourData = GetTourOverview(),
        currentLocation = currentLocationIndex
    })

    -- #region agent log
    DbgTour('D', 'main.lua:StartCityTour', 'showTour_NUI_sent', {
        currentLocationIndex = currentLocationIndex,
        totalLocations = #TourLocations
    })
    -- #endregion
    
    TriggerEvent('chat:addMessage', {
        color = {0, 255, 0},
        multiline = true,
        args = {"[Phantom Tour]", "Welcome to " .. Config.Language.TourTitle}
    })
end

function StopCityTour(markCompleted)
    -- #region agent log
    DbgTour('C', 'main.lua:StopCityTour', 'entry', {
        isTourActive = isTourActive,
        markCompleted = markCompleted == true,
        currentLocationIndex = currentLocationIndex,
        cameraHandle = cameraHandle
    })
    -- #endregion

    if not isTourActive then return end
    
    isTourActive = false
    isPaused = false
    lastTourTime = GetGameTimer()

    if markCompleted then
        tourCompleted = true
        TriggerServerEvent('phantom_citytour:markCompleted')
    end
    
    if cameraHandle then
        RenderScriptCams(false, true, 500, true, true)
        DestroyCam(cameraHandle, false)
        cameraHandle = nil
    end
    
    -- Restore player
    RestorePlayer()
    
    -- Hide UI
    SendNUIMessage({
        action = "hideTour"
    })

    -- #region agent log
    DbgTour('C', 'main.lua:StopCityTour', 'exit_restored', {
        pedVisible = IsEntityVisible(PlayerPedId()),
        pedFrozen = IsEntityPositionFrozen(PlayerPedId())
    })
    -- #endregion
    
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
    -- #region agent log
    DbgTour('A', 'main.lua:ProcessLocation', 'entry', {
        index = index,
        isTourActive = isTourActive,
        total = #TourLocations
    })
    -- #endregion

    if not isTourActive then
        return
    end

    if index > #TourLocations then
        StopCityTour(true)
        return
    end
    
    local location = TourLocations[index]
    if not location then
        -- #region agent log
        DbgTour('A', 'main.lua:ProcessLocation', 'missing_location_skip', { index = index })
        -- #endregion
        NextLocation()
        return
    end

    -- #region agent log
    DbgTour('A', 'main.lua:ProcessLocation', 'location_resolved', {
        index = index,
        id = location.id,
        name = location.name,
        hasCamera = location.camera ~= nil,
        hasPlayer = location.player ~= nil,
        animDict = location.player and location.player.animation and location.player.animation.dict or nil,
        duration = location.camera and location.camera.duration or nil
    })
    -- #endregion
    
    -- Apply effects
    ApplyLocationEffects(location.effects)
    
    -- Set up camera
    -- #region agent log
    DbgTour('B', 'main.lua:ProcessLocation', 'before_SetupCamera', {
        index = index,
        camStart = location.camera and location.camera.start or nil,
        camTarget = location.camera and location.camera.target or nil
    })
    -- #endregion
    SetupCamera(location.camera)
    -- #region agent log
    DbgTour('B', 'main.lua:ProcessLocation', 'after_SetupCamera', {
        cameraHandle = cameraHandle,
        renderingScriptCams = IsGameplayCamRendering and (not IsGameplayCamRendering()) or nil
    })
    -- #endregion
    
    -- Set up player
    -- #region agent log
    DbgTour('A', 'main.lua:ProcessLocation', 'before_SetupPlayer', {
        index = index,
        coords = location.player and location.player.coords or nil
    })
    -- #endregion
    SetupPlayer(location.player)
    -- #region agent log
    DbgTour('A', 'main.lua:ProcessLocation', 'after_SetupPlayer', {
        index = index,
        pedCoords = GetEntityCoords(PlayerPedId())
    })
    -- #endregion
    
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

    -- #region agent log
    DbgTour('D', 'main.lua:ProcessLocation', 'updateLocation_NUI_sent', {
        index = index,
        id = location.id,
        name = location.name
    })
    -- #endregion
    
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
    -- #region agent log
    DbgTour('B', 'main.lua:SetupCamera', 'entry', {
        hasData = cameraData ~= nil,
        hasStart = cameraData and cameraData.start ~= nil,
        hasTarget = cameraData and cameraData.target ~= nil,
        fov = cameraData and cameraData.fov or nil,
        prevCameraHandle = cameraHandle
    })
    -- #endregion

    if not cameraData then
        -- #region agent log
        DbgTour('B', 'main.lua:SetupCamera', 'early_return_nil_cameraData', {})
        -- #endregion
        return
    end
    
    if cameraHandle then
        DestroyCam(cameraHandle, false)
        cameraHandle = nil
    end
    
    cameraHandle = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    -- #region agent log
    DbgTour('B', 'main.lua:SetupCamera', 'CreateCam_result', {
        cameraHandle = cameraHandle,
        camExists = cameraHandle and DoesCamExist(cameraHandle) or false,
        start = cameraData.start,
        target = cameraData.target
    })
    -- #endregion
    SetCamCoord(cameraHandle, cameraData.start.x, cameraData.start.y, cameraData.start.z)
    SetCamRot(cameraHandle, cameraData.start.w, 0.0, 0.0)
    SetCamFov(cameraHandle, cameraData.fov or 50.0)
    
    -- Point camera at target
    PointCamAtCoord(cameraHandle, cameraData.target.x, cameraData.target.y, cameraData.target.z)
    
    -- Render camera
    RenderScriptCams(true, false, 0, true, true)

    -- #region agent log
    DbgTour('B', 'main.lua:SetupCamera', 'RenderScriptCams_called', {
        cameraHandle = cameraHandle,
        isCamActive = cameraHandle and IsCamActive(cameraHandle) or false,
        isCamRendering = cameraHandle and IsCamRendering(cameraHandle) or false
    })
    -- #endregion
    
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
    -- #region agent log
    DbgTour('A', 'main.lua:SetupPlayer', 'entry', {
        hasData = playerData ~= nil,
        hasAnim = playerData and playerData.animation ~= nil,
        coords = playerData and playerData.coords or nil,
        animDict = playerData and playerData.animation and playerData.animation.dict or nil,
        animName = playerData and playerData.animation and playerData.animation.anim or nil
    })
    -- #endregion

    if not playerData then return end
    
    local ped = PlayerPedId()
    
    -- Set player position
    SetEntityCoords(ped, playerData.coords.x, playerData.coords.y, playerData.coords.z, false, false, false, false)
    SetEntityHeading(ped, playerData.heading)

    -- #region agent log
    DbgTour('A', 'main.lua:SetupPlayer', 'after_teleport', {
        ped = ped,
        coords = GetEntityCoords(ped),
        heading = GetEntityHeading(ped),
        visible = IsEntityVisible(ped),
        frozen = IsEntityPositionFrozen(ped)
    })
    -- #endregion
    
    -- Apply animation
    if playerData.animation then
        -- #region agent log
        DbgTour('A', 'main.lua:SetupPlayer', 'before_LoadAnimDict', {
            dict = playerData.animation.dict,
            alreadyLoaded = HasAnimDictLoaded(playerData.animation.dict)
        })
        -- #endregion
        LoadAnimDict(playerData.animation.dict)
        -- #region agent log
        DbgTour('A', 'main.lua:SetupPlayer', 'after_LoadAnimDict', {
            dict = playerData.animation.dict,
            loaded = HasAnimDictLoaded(playerData.animation.dict)
        })
        -- #endregion
        TaskPlayAnim(ped, playerData.animation.dict, playerData.animation.anim, 8.0, -8.0, -1, 1, 0, false, false, false)
    end

    -- #region agent log
    DbgTour('A', 'main.lua:SetupPlayer', 'exit', {})
    -- #endregion
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
    -- #region agent log
    DbgTour('A', 'main.lua:LoadAnimDict', 'entry', {
        dict = dict,
        alreadyLoaded = HasAnimDictLoaded(dict)
    })
    -- #endregion
    local attempts = 0
    local startMs = GetGameTimer()
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        attempts = attempts + 1
        -- #region agent log
        if attempts == 1 or attempts % 200 == 0 then
            DbgTour('A', 'main.lua:LoadAnimDict', 'waiting_heartbeat', {
                dict = dict,
                attempts = attempts,
                elapsedMs = GetGameTimer() - startMs,
                loaded = HasAnimDictLoaded(dict)
            })
        end
        -- #endregion
        Wait(5)
    end
    -- #region agent log
    DbgTour('A', 'main.lua:LoadAnimDict', 'loaded_ok', {
        dict = dict,
        attempts = attempts,
        elapsedMs = GetGameTimer() - startMs
    })
    -- #endregion
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
    -- #region agent log
    DbgTour('E', 'main.lua:phantom_citytour_skip', 'skip_command_fired', {
        isTourActive = isTourActive,
        currentLocationIndex = currentLocationIndex
    })
    -- #endregion
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
exports('StopCityTour', StopCityTour)
exports('IsTourActive', function() return isTourActive end)

-- Commands
RegisterCommand('citytour', function()
    -- #region agent log
    DbgTour('C', 'main.lua:citytour_cmd', 'command_fired', {
        isTourActive = isTourActive,
        tourCompleted = tourCompleted
    })
    -- #endregion
    if isTourActive then
        StopCityTour(false)
    else
        StartCityTour()
    end
end, false)

RegisterCommand('stoptour', function()
    -- #region agent log
    DbgTour('C', 'main.lua:stoptour_cmd', 'command_fired', { isTourActive = isTourActive })
    -- #endregion
    StopCityTour(false)
end, false)

RegisterNetEvent('phantom_citytour:forceStart', function()
    StartCityTour()
end)

RegisterNetEvent('phantom_citytour:forceStop', function()
    StopCityTour(false)
end)

-- #region agent log
-- Cam keep-alive probe: does NOT fix; only logs if script cams drop while tour is active (hyp B/E).
CreateThread(function()
    while true do
        if isTourActive then
            local active = cameraHandle and DoesCamExist(cameraHandle) and IsCamActive(cameraHandle)
            local rendering = cameraHandle and IsCamRendering(cameraHandle)
            DbgTour('B', 'main.lua:cam_keepalive_probe', 'tour_active_cam_state', {
                cameraHandle = cameraHandle,
                camExists = cameraHandle and DoesCamExist(cameraHandle) or false,
                isCamActive = active == true,
                isCamRendering = rendering == true,
                currentLocationIndex = currentLocationIndex,
                pedVisible = IsEntityVisible(PlayerPedId()),
                pedFrozen = IsEntityPositionFrozen(PlayerPedId())
            })
            Wait(2000)
        else
            Wait(1000)
        end
    end
end)
-- #endregion
