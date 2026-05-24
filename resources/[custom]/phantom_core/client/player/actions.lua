-- Phantom Core - Player Actions
-- High-quality player actions (hands up, surrender, crouch, etc.)

local handsUp = false
local surrendering = false
local crouching = false
local pointing = false

-- Toggle hands up
function ToggleHandsUp()
    local ped = PlayerPedId()
    
    if handsUp then
        ClearPedSecondaryTask(ped)
        handsUp = false
    else
        if PlayAnimation('missminuteman_1ig_2', 'handsup_base', -1, 50) then
            handsUp = true
        end
    end
end

-- Toggle surrender
function ToggleSurrender()
    local ped = PlayerPedId()
    
    if surrendering then
        ClearPedSecondaryTask(ped)
        SetEnableHandcuffs(ped, false)
        surrendering = false
    else
        if PlayAnimation('random@arrests', 'kneeling_arrest_get_up', -1, 49) then
            SetEnableHandcuffs(ped, true)
            surrendering = true
        end
    end
end

-- Toggle crouch
function ToggleCrouch()
    local ped = PlayerPedId()
    
    if crouching then
        ResetPedStrafeClip(ped)
        SetPedMovementClipset(ped, 'default', 0.25)
        crouching = false
    else
        RequestAnimSet('move_ped_crouched')
        local timeout = 0
        while not HasAnimSetLoaded('move_ped_crouched') and timeout < 50 do
            Wait(10)
            timeout = timeout + 1
        end
        
        if HasAnimSetLoaded('move_ped_crouched') then
            SetPedMovementClipset(ped, 'move_ped_crouched', 0.25)
            SetPedStrafeClip(ped, 'move_ped_crouched_strafing')
            crouching = true
        end
    end
end

-- Toggle pointing
function TogglePointing()
    local ped = PlayerPedId()
    
    if pointing then
        ClearPedSecondaryTask(ped)
        pointing = false
    else
        if PlayAnimation('anim@mp_point', 'task_pointing_01', -1, 49) then
            pointing = true
        end
    end
end

-- Main thread for action keys
CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        
        -- Hands up - X key
        if IsControlJustPressed(0, 73) then
            ToggleHandsUp()
        end
        
        -- Surrender - K key
        if IsControlJustPressed(0, 311) then
            ToggleSurrender()
        end
        
        -- Crouch - CTRL key
        if IsControlJustPressed(0, 36) then
            ToggleCrouch()
        end
        
        -- Point - B key
        if IsControlJustPressed(0, 29) then
            TogglePointing()
        end
        
        -- Update pointing animation
        if pointing then
            local camPitch = GetGameplayCamRelativePitch()
            if camPitch < -70.0 then
                camPitch = -70.0
            elseif camPitch > 42.0 then
                camPitch = 42.0
            end
            camPitch = (camPitch + 70.0) / 112.0
            
            local camHeading = GetGameplayCamRelativeHeading()
            local cosCamHeading = Cos(camHeading)
            local sinCamHeading = Sin(camHeading)
            if camHeading < 0.0 then
                camHeading = camHeading + 360.0
            elseif camHeading > 360.0 then
                camHeading = camHeading - 360.0
            end
            camHeading = (camHeading + 360.0) / 720.0
            
            SetTaskMoveNetworkSignalFloat(ped, 'Pitch', camPitch)
            SetTaskMoveNetworkSignalFloat(ped, 'Heading', camHeading * -1.0 + 1.0)
        end
    end
end)

-- Clear actions on death
RegisterNetEvent('phantom:client:playerDied', function()
    if handsUp then ToggleHandsUp() end
    if surrendering then ToggleSurrender() end
    if pointing then TogglePointing() end
end)

-- Export functions
exports('ToggleHandsUp', ToggleHandsUp)
exports('ToggleSurrender', ToggleSurrender)
exports('ToggleCrouch', ToggleCrouch)
exports('TogglePointing', TogglePointing)

DebugPrint('Player actions loaded')
