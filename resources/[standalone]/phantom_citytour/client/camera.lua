-- Advanced camera system for cinematic city tour

local Camera = {}
Camera.__index = Camera

-- Camera states
local CameraStates = {
    IDLE = "idle",
    TRANSITIONING = "transitioning",
    FOCUSING = "focusing",
    PANORAMIC = "panoramic",
    FOLLOWING = "following"
}

-- Camera effects
local CameraEffects = {
    ZOOM = "zoom",
    SHAKE = "shake",
    FADE = "fade",
    BLUR = "blur"
}

-- Create new camera instance
function Camera.new()
    local self = setmetatable({}, Camera)
    self.handle = nil
    self.state = CameraStates.IDLE
    self.position = vector3(0, 0, 0)
    self.rotation = vector3(0, 0, 0)
    self.fov = 50.0
    self.target = nil
    self.effects = {}
    self.transitionProgress = 0.0
    self.transitionDuration = 2.0
    self.transitionStartTime = 0
    
    return self
end

-- Initialize camera
function Camera:initialize()
    if self.handle then
        DeleteEntity(self.handle)
    end
    
    self.handle = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    self.state = CameraStates.IDLE
    
    return self.handle
end

-- Set camera position with smooth transition
function Camera:setPosition(position, duration, easeType)
    duration = duration or Config.TourSettings.CameraTransitionSpeed
    easeType = easeType or "easeInOut"
    
    self.state = CameraStates.TRANSITIONING
    self.transitionStartTime = GetGameTimer()
    self.transitionDuration = duration * 1000
    self.targetPosition = position
    self.startPosition = self.position
    
    -- Create transition thread
    CreateThread(function()
        while self.state == CameraStates.TRANSITIONING do
            local elapsed = GetGameTimer() - self.transitionStartTime
            local progress = math.min(elapsed / self.transitionDuration, 1.0)
            
            -- Apply easing
            local easedProgress = self:applyEasing(progress, easeType)
            
            -- Interpolate position
            local newPos = vector3(
                self.startPosition.x + (self.targetPosition.x - self.startPosition.x) * easedProgress,
                self.startPosition.y + (self.targetPosition.y - self.startPosition.y) * easedProgress,
                self.startPosition.z + (self.targetPosition.z - self.startPosition.z) * easedProgress
            )
            
            SetCamCoord(self.handle, newPos.x, newPos.y, newPos.z)
            self.position = newPos
            
            if progress >= 1.0 then
                self.state = CameraStates.IDLE
                break
            end
            
            Wait(0)
        end
    end)
end

-- Set camera rotation with smooth transition
function Camera:setRotation(rotation, duration, easeType)
    duration = duration or Config.TourSettings.CameraTransitionSpeed
    easeType = easeType or "easeInOut"
    
    self.state = CameraStates.TRANSITIONING
    self.transitionStartTime = GetGameTimer()
    self.transitionDuration = duration * 1000
    self.targetRotation = rotation
    self.startRotation = self.rotation
    
    CreateThread(function()
        while self.state == CameraStates.TRANSITIONING do
            local elapsed = GetGameTimer() - self.transitionStartTime
            local progress = math.min(elapsed / self.transitionDuration, 1.0)
            
            local easedProgress = self:applyEasing(progress, easeType)
            
            -- Interpolate rotation
            local newRot = vector3(
                self.startRotation.x + (self.targetRotation.x - self.startRotation.x) * easedProgress,
                self.startRotation.y + (self.targetRotation.y - self.startRotation.y) * easedProgress,
                self.startRotation.z + (self.targetRotation.z - self.startRotation.z) * easedProgress
            )
            
            SetCamRot(self.handle, newRot.x, newRot.y, newRot.z, 2)
            self.rotation = newRot
            
            if progress >= 1.0 then
                self.state = CameraStates.IDLE
                break
            end
            
            Wait(0)
        end
    end)
end

-- Point camera at target with smooth focusing
function Camera:pointAt(target, duration, easeType)
    duration = duration or Config.TourSettings.CameraTransitionSpeed
    easeType = easeType or "easeInOut"
    
    self.state = CameraStates.FOCUSING
    self.target = target
    
    CreateThread(function()
        local startTime = GetGameTimer()
        local durationMs = duration * 1000
        
        while GetGameTimer() - startTime < durationMs do
            local progress = math.min((GetGameTimer() - startTime) / durationMs, 1.0)
            local easedProgress = self:applyEasing(progress, easeType)
            
            -- Smooth look at target
            local camPos = GetCamCoord(self.handle)
            local targetPos = type(target) == "vector3" and target or vector3(target.x, target.y, target.z)
            
            -- Calculate rotation to look at target
            local direction = targetPos - camPos
            local distance = #direction
            
            if distance > 0.0 then
                local normalizedDir = direction / distance
                local pitch = math.asin(-normalizedDir.z) * (180.0 / math.pi)
                local yaw = math.atan2(normalizedDir.x, normalizedDir.y) * (180.0 / math.pi)
                
                -- Apply easing to rotation
                local targetRot = vector3(pitch, 0.0, yaw)
                local currentRot = vector3(GetCamRot(self.handle))
                local newRot = vector3(
                    currentRot.x + (targetRot.x - currentRot.x) * easedProgress,
                    currentRot.y + (targetRot.y - currentRot.y) * easedProgress,
                    currentRot.z + (targetRot.z - currentRot.z) * easedProgress
                )
                
                SetCamRot(self.handle, newRot.x, newRot.y, newRot.z, 2)
            end
            
            Wait(0)
        end
        
        self.state = CameraStates.IDLE
    end)
end

-- Set field of view with smooth transition
function Camera:setFOV(fov, duration, easeType)
    duration = duration or 1.0
    easeType = easeType or "easeInOut"
    
    local startFOV = self.fov
    local startTime = GetGameTimer()
    local durationMs = duration * 1000
    
    CreateThread(function()
        while GetGameTimer() - startTime < durationMs do
            local progress = math.min((GetGameTimer() - startTime) / durationMs, 1.0)
            local easedProgress = self:applyEasing(progress, easeType)
            
            local newFOV = startFOV + (fov - startFOV) * easedProgress
            SetCamFov(self.handle, newFOV)
            self.fov = newFOV
            
            Wait(0)
        end
    end)
end

-- Add camera shake effect
function Camera:addShake(intensity, duration)
    intensity = intensity or 0.5
    duration = duration or 1.0
    
    ShakeCam(self.handle, intensity, duration)
    table.insert(self.effects, {
        type = CameraEffects.SHAKE,
        intensity = intensity,
        duration = duration,
        startTime = GetGameTimer()
    })
end

-- Add zoom effect
function Camera:addZoom(targetFOV, duration)
    duration = duration or 2.0
    
    self:setFOV(targetFOV, duration, "easeInOut")
    table.insert(self.effects, {
        type = CameraEffects.ZOOM,
        targetFOV = targetFOV,
        duration = duration,
        startTime = GetGameTimer()
    })
end

-- Add fade effect
function Camera:addFade(type, duration)
    duration = duration or 1.0
    
    -- This would integrate with NUI for fade effects
    SendNUIMessage({
        action = "cameraEffect",
        effect = CameraEffects.FADE,
        type = type, -- "in" or "out"
        duration = duration
    })
    
    table.insert(self.effects, {
        type = CameraEffects.FADE,
        fadeType = type,
        duration = duration,
        startTime = GetGameTimer()
    })
end

-- Create panoramic shot
function Camera:createPanoramic(startAngle, endAngle, radius, height, duration)
    duration = duration or 10.0
    self.state = CameraStates.PANORAMIC
    
    local center = self.position
    local startTime = GetGameTimer()
    local durationMs = duration * 1000
    
    CreateThread(function()
        while GetGameTimer() - startTime < durationMs do
            local progress = math.min((GetGameTimer() - startTime) / durationMs, 1.0)
            local easedProgress = self:applyEasing(progress, "easeInOut")
            
            -- Calculate panoramic position
            local currentAngle = startAngle + (endAngle - startAngle) * easedProgress
            local radians = currentAngle * (math.pi / 180.0)
            
            local x = center.x + math.sin(radians) * radius
            local y = center.y + math.cos(radians) * radius
            local z = center.z + height
            
            SetCamCoord(self.handle, x, y, z)
            
            -- Look at center
            PointCamAtCoord(self.handle, center.x, center.y, center.z)
            
            Wait(0)
        end
        
        self.state = CameraStates.IDLE
    end)
end

-- Follow player with smooth tracking
function Camera:followPlayer(offset, distance, height)
    offset = offset or vector3(0, 0, 0)
    distance = distance or 5.0
    height = height or 2.0
    
    self.state = CameraStates.FOLLOWING
    
    CreateThread(function()
        while self.state == CameraStates.FOLLOWING do
            local playerPed = PlayerPedId()
            local playerPos = GetEntityCoords(playerPed)
            local playerHeading = GetEntityHeading(playerPed)
            
            -- Calculate camera position behind player
            local radians = (playerHeading - 90.0) * (math.pi / 180.0)
            local camX = playerPos.x + math.sin(radians) * distance + offset.x
            local camY = playerPos.y + math.cos(radians) * distance + offset.y
            local camZ = playerPos.z + height + offset.z
            
            -- Smooth camera movement
            SetCamCoord(self.handle, camX, camY, camZ)
            PointCamAtCoord(self.handle, playerPos.x, playerPos.y, playerPos.z + 1.0)
            
            Wait(0)
        end
    end)
end

-- Apply easing functions
function Camera:applyEasing(t, easeType)
    if easeType == "linear" then
        return t
    elseif easeType == "easeIn" then
        return t * t
    elseif easeType == "easeOut" then
        return t * (2.0 - t)
    elseif easeType == "easeInOut" then
        return t < 0.5 and 2.0 * t * t or -1.0 + (4.0 - 2.0 * t) * t
    elseif easeType == "easeInCubic" then
        return t * t * t
    elseif easeType == "easeOutCubic" then
        local t1 = t - 1.0
        return t1 * t1 * t1 + 1.0
    elseif easeType == "easeInOutCubic" then
        return t < 0.5 and 4.0 * t * t * t or (t - 1.0) * (2.0 * t - 2.0) * (2.0 * t - 2.0) + 1.0
    else
        return t -- Default to linear
    end
end

-- Clean up camera
function Camera:destroy()
    if self.handle then
        DeleteEntity(self.handle)
        self.handle = nil
    end
    
    self.state = CameraStates.IDLE
    self.effects = {}
end

-- Get camera state
function Camera:getState()
    return self.state
end

-- Check if camera is busy
function Camera:isBusy()
    return self.state ~= CameraStates.IDLE
end

-- Render camera
function Camera:render(active)
    if self.handle then
        RenderScriptCams(active or true, false, 0, true, true)
    end
end

-- Export camera class
_G.Camera = Camera
