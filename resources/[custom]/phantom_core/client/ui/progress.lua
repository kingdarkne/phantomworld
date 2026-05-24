-- Phantom Core - UI Progress Bar System
-- High-quality progress bar with circular and linear options

local activeProgress = nil

-- Show progress bar
function ShowProgressBar(options)
    if activeProgress then
        return false, 'Progress bar already active'
    end
    
    options = options or {}
    local duration = options.duration or Config.UI.Progress.DefaultDuration
    local label = options.label or 'Processing...'
    local canCancel = options.canCancel ~= nil and options.canCancel or Config.UI.Progress.CanCancel
    local useWhileDead = options.useWhileDead or false
    local controlDisables = options.controlDisables or {
        move = true,
        car = true,
        combat = true,
        mouse = false,
    }
    local anim = options.anim or {
        dict = 'missheistdockssetup1clipboard@base',
        clip = 'base'
    }
    
    -- Start animation
    if anim.dict and anim.clip then
        RequestAnimDict(anim.dict)
        local timeout = 0
        while not HasAnimDictLoaded(anim.dict) and timeout < 50 do
            Wait(10)
            timeout = timeout + 1
        end
        
        if HasAnimDictLoaded(anim.dict) then
            TaskPlayAnim(PlayerPedId(), anim.dict, anim.clip, 8.0, -8.0, duration, 49, 0, false, false, false)
        end
    end
    
    -- Send to NUI
    SendNUIMessage({
        action = 'showProgress',
        duration = duration,
        label = label,
        canCancel = canCancel
    })
    
    activeProgress = {
        startTime = GetGameTimer(),
        duration = duration,
        canCancel = canCancel,
        cancelled = false,
        anim = anim
    }
    
    -- Handle cancellation
    if canCancel then
        CreateThread(function()
            while activeProgress and not activeProgress.cancelled do
                if IsControlJustPressed(0, Config.UI.Progress.CancelKey) then
                    activeProgress.cancelled = true
                    ClearProgress()
                    return
                end
                Wait(0)
            end
        end)
    end
    
    -- Wait for completion
    CreateThread(function()
        Wait(duration)
        
        if activeProgress and not activeProgress.cancelled then
            ClearProgress()
        end
    end)
    
    return true
end

-- Clear progress bar
function ClearProgress()
    if not activeProgress then return end
    
    -- Clear animation
    if activeProgress.anim and activeProgress.anim.dict then
        ClearAnimation()
    end
    
    -- Hide from NUI
    SendNUIMessage({
        action = 'hideProgress'
    })
    
    local wasCancelled = activeProgress.cancelled
    activeProgress = nil
    
    return wasCancelled
end

-- Check if progress is active
function IsProgressActive()
    return activeProgress ~= nil
end

-- Export functions
exports('ShowProgressBar', ShowProgressBar)
exports('ClearProgress', ClearProgress)
exports('IsProgressActive', IsProgressActive)

-- Debug command
if Config.Debug then
    RegisterCommand('testprogress', function()
        ShowProgressBar({
            duration = 5000,
            label = 'Testing progress bar...',
            canCancel = true
        })
    end)
end

DebugPrint('Progress bar system loaded')
