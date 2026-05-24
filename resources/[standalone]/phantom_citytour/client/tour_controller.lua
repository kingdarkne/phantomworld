-- Tour controller for managing city tour flow and logic

local TourController = {}
TourController.__index = TourController

-- Tour states
local TourStates = {
    IDLE = "idle",
    STARTING = "starting",
    RUNNING = "running",
    PAUSED = "paused",
    TRANSITIONING = "transitioning",
    ENDING = "ending"
}

-- Create new tour controller
function TourController.new()
    local self = setmetatable({}, TourController)
    
    self.state = TourStates.IDLE
    self.currentLocationIndex = 1
    self.locations = TourLocations
    self.camera = Camera.new()
    self.startTime = 0
    self.totalDuration = 0
    self.currentDuration = 0
    self.isPaused = false
    self.pauseTime = 0
    self.autoAdvance = true
    self.callbacks = {}
    self.autoAdvanceTimer = nil
    
    return self
end

-- Start tour
function TourController:start()
    if self.state ~= TourStates.IDLE then
        return false, "Tour already active"
    end
    
    self.state = TourStates.STARTING
    self.currentLocationIndex = 1
    self.startTime = GetGameTimer()
    self.isPaused = false
    self.pauseTime = 0
    
    -- Initialize camera
    self.camera:initialize()
    
    -- Set up player
    self:setupPlayer()
    
    -- Start first location
    self:processLocation(self.currentLocationIndex)
    
    -- Show UI
    self:showUI()
    
    self.state = TourStates.RUNNING
    
    -- Trigger callback
    self:triggerCallback('onTourStart')
    
    return true
end

-- Stop tour
function TourController:stop()
    if self.state == TourStates.IDLE then
        return false, "Tour not active"
    end
    
    self.state = TourStates.ENDING
    
    -- Calculate total duration
    self.totalDuration = GetGameTimer() - self.startTime - self.pauseTime
    
    -- Clean up auto-advance timer
    self.autoAdvanceTimer = nil
    
    -- Clean up
    self:cleanup()
    
    -- Hide UI
    self:hideUI()
    
    -- Trigger callback
    self:triggerCallback('onTourEnd', {
        duration = self.totalDuration,
        locationsVisited = self.currentLocationIndex - 1
    })
    
    self.state = TourStates.IDLE
    
    return true
end

-- Pause tour
function TourController:pause()
    if self.state ~= TourStates.RUNNING then
        return false, "Cannot pause - tour not running"
    end
    
    self.isPaused = true
    self.pauseStartTime = GetGameTimer()
    self.state = TourStates.PAUSED
    
    -- Pause animations
    ClearPedTasks(PlayerPedId())
    
    -- Update UI
    self:updateUI({
        action = "pauseTour",
        isPaused = true
    })
    
    -- Trigger callback
    self:triggerCallback('onTourPause')
    
    return true
end

-- Resume tour
function TourController:resume()
    if self.state ~= TourStates.PAUSED then
        return false, "Cannot resume - tour not paused"
    end
    
    self.isPaused = false
    self.pauseTime = self.pauseTime + (GetGameTimer() - self.pauseStartTime)
    self.state = TourStates.RUNNING
    
    -- Resume animations
    local currentLocation = self.locations[self.currentLocationIndex]
    if currentLocation and currentLocation.player then
        self:setupPlayerAnimation(currentLocation.player.animation)
    end
    
    -- Update UI
    self:updateUI({
        action = "pauseTour",
        isPaused = false
    })
    
    -- Trigger callback
    self:triggerCallback('onTourResume')
    
    -- Auto-advance to next location after short delay
    if self.autoAdvance then
        CreateThread(function()
            Wait(1000)
            if self.state == TourStates.RUNNING and not self.isPaused then
                self:nextLocation()
            end
        end)
    end
    
    return true
end

-- Go to next location
function TourController:nextLocation()
    if self.state ~= TourStates.RUNNING and self.state ~= TourStates.PAUSED then
        return false, "Cannot change location - tour not active"
    end
    
    self.currentLocationIndex = self.currentLocationIndex + 1
    
    if self.currentLocationIndex > #self.locations then
        -- Tour completed
        self:stop()
    else
        -- Process next location
        self:processLocation(self.currentLocationIndex)
        
        -- Trigger callback
        self:triggerCallback('onLocationChange', {
            locationIndex = self.currentLocationIndex,
            location = self.locations[self.currentLocationIndex]
        })
    end
    
    return true
end

-- Go to previous location
function TourController:previousLocation()
    if self.state ~= TourStates.RUNNING and self.state ~= TourStates.PAUSED then
        return false, "Cannot change location - tour not active"
    end
    
    if self.currentLocationIndex <= 1 then
        return false, "Already at first location"
    end
    
    self.currentLocationIndex = self.currentLocationIndex - 1
    self:processLocation(self.currentLocationIndex)
    
    -- Trigger callback
    self:triggerCallback('onLocationChange', {
        locationIndex = self.currentLocationIndex,
        location = self.locations[self.currentLocationIndex]
    })
    
    return true
end

-- Skip current location
function TourController:skipLocation()
    if self.state ~= TourStates.RUNNING and self.state ~= TourStates.PAUSED then
        return false, "Cannot skip - tour not active"
    end
    
    -- Trigger callback
    self:triggerCallback('onLocationSkip', {
        locationIndex = self.currentLocationIndex,
        location = self.locations[self.currentLocationIndex]
    })
    
    return self:nextLocation()
end

-- Go to specific location
function TourController:goToLocation(index)
    if self.state ~= TourStates.RUNNING and self.state ~= TourStates.PAUSED then
        return false, "Cannot change location - tour not active"
    end
    
    if index < 1 or index > #self.locations then
        return false, "Invalid location index"
    end
    
    self.currentLocationIndex = index
    self:processLocation(self.currentLocationIndex)
    
    -- Trigger callback
    self:triggerCallback('onLocationChange', {
        locationIndex = self.currentLocationIndex,
        location = self.locations[self.currentLocationIndex]
    })
    
    return true
end

-- Process current location
function TourController:processLocation(index)
    local location = self.locations[index]
    if not location then
        return false, "Invalid location"
    end
    
    self.state = TourStates.TRANSITIONING
    
    -- Apply location effects
    self:applyLocationEffects(location.effects)
    
    -- Set up camera
    self:setupCamera(location.camera)
    
    -- Set up player
    self:setupPlayerLocation(location.player)
    
    -- Update UI
    self:updateUI({
        action = "updateLocation",
        location = {
            id = location.id,
            name = location.name,
            description = location.description,
            info = location.info,
            progress = (index / #self.locations) * 100,
            currentIndex = index,
            totalLocations = #self.locations
        }
    })
    
    -- Clean up existing auto-advance timer
    if self.autoAdvanceTimer then
        self.autoAdvanceTimer = nil
    end
    
    -- Set up auto-advance timer
    if self.autoAdvance and not self.isPaused then
        self.autoAdvanceTimer = CreateThread(function()
            Wait(location.camera.duration)
            
            -- Clear timer reference
            if self.autoAdvanceTimer == Citizen.ReturnResultHere() then
                self.autoAdvanceTimer = nil
            end
            
            if self.state == TourStates.RUNNING and not self.isPaused then
                self:nextLocation()
            end
        end)
    end
    
    self.state = TourStates.RUNNING
    
    return true
end

-- Apply location effects
function TourController:applyLocationEffects(effects)
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
    
    -- Add screen effects
    if effects.screenEffect then
        -- This would integrate with NUI for screen effects
        self:updateUI({
            action = "screenEffect",
            effect = effects.screenEffect
        })
    end
end

-- Set up camera for location
function TourController:setupCamera(cameraData)
    if not cameraData then return end
    
    -- Set camera position
    self.camera:setPosition(vector3(cameraData.start.x, cameraData.start.y, cameraData.start.z), cameraData.transitionDuration or 2.0)
    
    -- Set camera rotation
    self.camera:setRotation(vector3(cameraData.start.w, 0.0, 0.0), cameraData.transitionDuration or 2.0)
    
    -- Set FOV
    self.camera:setFOV(cameraData.fov or 50.0, 1.0)
    
    -- Point at target
    if cameraData.target then
        self.camera:pointAt(vector3(cameraData.target.x, cameraData.target.y, cameraData.target.z), cameraData.transitionDuration or 2.0)
    end
    
    -- Render camera
    self.camera:render(true)
    
    -- Add camera effects if specified
    if cameraData.effects then
        for _, effect in ipairs(cameraData.effects) do
            self:addCameraEffect(effect)
        end
    end
end

-- Add camera effect
function TourController:addCameraEffect(effect)
    if effect.type == "shake" then
        self.camera:addShake(effect.intensity or 0.5, effect.duration or 1.0)
    elseif effect.type == "zoom" then
        self.camera:addZoom(effect.targetFOV or 60.0, effect.duration or 2.0)
    elseif effect.type == "fade" then
        self.camera:addFade(effect.fadeType or "in", effect.duration or 1.0)
    elseif effect.type == "panoramic" then
        self.camera:createPanoramic(
            effect.startAngle or 0,
            effect.endAngle or 360,
            effect.radius or 10.0,
            effect.height or 5.0,
            effect.duration or 10.0
        )
    end
end

-- Set up player for location
function TourController:setupPlayerLocation(playerData)
    if not playerData then return end
    
    local ped = PlayerPedId()
    
    -- Set player position
    SetEntityCoords(ped, playerData.coords.x, playerData.coords.y, playerData.coords.z, false, false, false, false)
    SetEntityHeading(ped, playerData.heading)
    
    -- Set up animation
    self:setupPlayerAnimation(playerData.animation)
end

-- Set up player animation
function TourController:setupPlayerAnimation(animationData)
    if not animationData then return end
    
    local ped = PlayerPedId()
    
    -- Load animation dict
    RequestAnimDict(animationData.dict)
    while not HasAnimDictLoaded(animationData.dict) do
        Wait(10)
    end
    
    -- Play animation
    TaskPlayAnim(ped, animationData.dict, animationData.anim, 8.0, -8.0, -1, 1, 0, false, false, false)
end

-- Set up player (initial setup)
function TourController:setupPlayer()
    local ped = PlayerPedId()
    
    -- Hide HUD
    DisplayHud(false)
    DisplayRadar(false)
    
    -- Set player properties
    SetEntityInvincible(ped, true)
    SetEntityVisible(ped, false, 0)
    FreezeEntityPosition(ped, true)
    
    -- Clear any existing tasks
    ClearPedTasks(ped)
end

-- Clean up (restore player state)
function TourController:cleanup()
    local ped = PlayerPedId()
    
    -- Restore HUD
    DisplayHud(true)
    DisplayRadar(true)
    
    -- Restore player properties
    SetEntityInvincible(ped, false)
    SetEntityVisible(ped, true, 0)
    FreezeEntityPosition(ped, false)
    
    -- Clear weather and time overrides
    ClearWeatherTypeOverride()
    ClearTimecycleModifier()
    
    -- Clear tasks
    ClearPedTasks(ped)
    
    -- Clean up auto-advance timer
    self.autoAdvanceTimer = nil
    
    -- Clean up camera
    self.camera:destroy()
    
    -- Stop rendering camera
    RenderScriptCams(false, false, 0, true, true)
end

-- Show UI
function TourController:showUI()
    self:updateUI({
        action = "showTour",
        tourData = self:getTourOverview(),
        currentLocation = self.currentLocationIndex
    })
end

-- Hide UI
function TourController:hideUI()
    self:updateUI({
        action = "hideTour"
    })
end

-- Update UI
function TourController:updateUI(data)
    SendNUIMessage(data)
end

-- Get tour overview
function TourController:getTourOverview()
    local overview = {
        title = Config.Language.TourTitle,
        totalLocations = #self.locations,
        estimatedDuration = 0,
        categories = {},
        locations = {}
    }
    
    -- Calculate total duration
    for _, location in ipairs(self.locations) do
        overview.estimatedDuration = overview.estimatedDuration + (location.camera.duration / 1000)
        table.insert(overview.locations, {
            id = location.id,
            name = location.name,
            category = location.category,
            description = location.description
        })
    end
    
    -- Get unique categories
    local seenCategories = {}
    for _, location in ipairs(self.locations) do
        if not seenCategories[location.category] then
            seenCategories[location.category] = true
            
            -- Find category info
            for _, category in ipairs(TourCategories) do
                if category.id == location.category then
                    table.insert(overview.categories, category)
                    break
                end
            end
        end
    end
    
    return overview
end

-- Add callback
function TourController:addCallback(event, callback)
    if not self.callbacks[event] then
        self.callbacks[event] = {}
    end
    table.insert(self.callbacks[event], callback)
end

-- Trigger callback
function TourController:triggerCallback(event, data)
    if self.callbacks[event] then
        for _, callback in ipairs(self.callbacks[event]) do
            callback(data)
        end
    end
end

-- Get current state
function TourController:getState()
    return self.state
end

-- Get current location
function TourController:getCurrentLocation()
    return self.locations[self.currentLocationIndex]
end

-- Get tour progress
function TourController:getProgress()
    return {
        current = self.currentLocationIndex,
        total = #self.locations,
        percentage = (self.currentLocationIndex / #self.locations) * 100
    }
end

-- Check if tour is active
function TourController:isActive()
    return self.state ~= TourStates.IDLE
end

-- Check if tour is paused
function TourController:isPaused()
    return self.isPaused
end

-- Set auto advance
function TourController:setAutoAdvance(enabled)
    self.autoAdvance = enabled
end

-- Export tour controller
_G.TourController = TourController
