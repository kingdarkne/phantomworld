--- Detect stuck players / likely client bugs and offer /unstuck + Discord report.

local ENABLED = GetConvarInt('phantom_dashboard:stuckWatch', 1) == 1
local MOVE_STUCK_SEC = tonumber(GetConvar('phantom_dashboard:stuckMoveSeconds', '25')) or 25
local NUI_STUCK_SEC = tonumber(GetConvar('phantom_dashboard:stuckNuiSeconds', '120')) or 120
local FADE_STUCK_SEC = tonumber(GetConvar('phantom_dashboard:stuckFadeSeconds', '75')) or 75
local COOLDOWN_SEC = tonumber(GetConvar('phantom_dashboard:stuckCooldownSeconds', '180')) or 180
local PROMPT_INTERVAL_SEC = tonumber(GetConvar('phantom_dashboard:stuckPromptSeconds', '90')) or 90

local lastPromptAt = 0
local lastReportAt = 0
local moveStuckSince = nil
local nuiStuckSince = nil
local fadeStuckSince = nil
local watching = false

local function playerReady()
    return LocalPlayer.state.isLoggedIn == true
end

local function isDeadOrDown()
    local ped = cache.ped
    if not ped or ped == 0 then return true end
    if IsEntityDead(ped) then return true end
    local pd = QBX and QBX.PlayerData
    local meta = pd and pd.metadata
    if meta and (meta.isdead or meta.inlaststand) then return true end
    return false
end

local function tryingToMove()
    -- WASD / analog move
    return IsControlPressed(0, 32) -- W
        or IsControlPressed(0, 33) -- S
        or IsControlPressed(0, 34) -- A
        or IsControlPressed(0, 35) -- D
        or IsControlPressed(0, 21) -- sprint (still implies want to move)
end

local function horizontalSpeed(ped)
    local v = GetEntityVelocity(ped)
    return math.sqrt(v.x * v.x + v.y * v.y)
end

local function reasonPayload(reason, extra)
    local ped = cache.ped
    local c = GetEntityCoords(ped)
    return {
        reason = reason,
        extra = extra or '',
        coords = { x = c.x + 0.0, y = c.y + 0.0, z = c.z + 0.0 },
        heading = GetEntityHeading(ped) + 0.0,
        inVehicle = IsPedInAnyVehicle(ped, false),
        nuiFocused = IsNuiFocused(),
        pause = IsPauseMenuActive(),
        faded = IsScreenFadedOut(),
        frozen = IsEntityPositionFrozen(ped),
        speed = horizontalSpeed(ped),
        street = (function()
            local h = GetStreetNameAtCoord(c.x, c.y, c.z)
            return GetStreetNameFromHashKey(h) or 'unknown'
        end)(),
    }
end

local function notify(msg, nType)
    if lib and lib.notify then
        lib.notify({ title = 'Phantom Assist', description = msg, type = nType or 'inform' })
    else
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(msg)
        EndTextCommandThefeedPostTicker(false, false)
    end
end

local function maybePrompt(reason)
    local now = GetGameTimer()
    if (now - lastPromptAt) < (PROMPT_INTERVAL_SEC * 1000) then return end
    lastPromptAt = now

    notify(('You look stuck (%s). Try /unstuck — or /reportstuck if it keeps happening.'):format(reason), 'error')

    if lib and lib.alertDialog then
        CreateThread(function()
            local choice = lib.alertDialog({
                header = 'Stuck / possible bug?',
                content = ('Detected: **%s**\n\nUse **/unstuck** to free yourself.\nUse **/reportstuck** to alert staff on Discord.'):format(reason),
                centered = true,
                cancel = true,
                labels = { confirm = 'Unstuck now', cancel = 'Dismiss' },
            })
            if choice == 'confirm' then
                ExecuteCommand('unstuck')
            end
        end)
    end
end

local function doUnstuckLocal()
    local ped = cache.ped
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    FreezeEntityPosition(ped, false)
    ClearPedTasksImmediately(ped)

    if IsScreenFadedOut() then
        DoScreenFadeIn(500)
    end

    -- Soft nudge: lift slightly and place on ground
    local c = GetEntityCoords(ped)
    local found, groundZ = GetGroundZFor_3dCoord(c.x, c.y, c.z + 50.0, false)
    local z = found and (groundZ + 1.0) or (c.z + 1.0)
    if c.z < -50.0 or (found and math.abs(c.z - groundZ) > 25.0) then
        SetEntityCoordsNoOffset(ped, c.x, c.y, z, false, false, false)
    else
        SetEntityCoordsNoOffset(ped, c.x, c.y, c.z + 0.35, false, false, false)
    end

    SetPedToRagdoll(ped, 10, 10, 0, false, false, false)
    Wait(50)
    ClearPedTasksImmediately(ped)
    notify('Unstuck applied. If you are still jammed, use /reportstuck.', 'success')
end

RegisterCommand('unstuck', function()
    if not playerReady() then
        notify('Wait until your character has loaded.', 'error')
        return
    end
    doUnstuckLocal()
    TriggerServerEvent('phantom_dashboard:stuck:unstuckUsed', reasonPayload('manual_unstuck'))
end, false)

RegisterCommand('stuck', function()
    ExecuteCommand('unstuck')
end, false)

RegisterCommand('reportstuck', function()
    if not playerReady() then return end
    local now = GetGameTimer()
    if (now - lastReportAt) < (COOLDOWN_SEC * 1000) then
        notify('Please wait before sending another stuck report.', 'error')
        return
    end
    lastReportAt = now
    TriggerServerEvent('phantom_dashboard:stuck:report', reasonPayload('player_report', 'manual /reportstuck'))
    notify('Stuck report sent to staff. Thanks.', 'success')
end, false)

TriggerEvent('chat:addSuggestion', '/unstuck', 'Free yourself if you are stuck (NUI/freeze/clip)')
TriggerEvent('chat:addSuggestion', '/stuck', 'Alias of /unstuck')
TriggerEvent('chat:addSuggestion', '/reportstuck', 'Report a stuck bug to staff Discord')

RegisterNetEvent('phantom_dashboard:stuck:forceUnstuck', function()
    doUnstuckLocal()
end)

CreateThread(function()
    if not ENABLED then
        print('[phantom_dashboard] stuck watch disabled')
        return
    end

    while true do
        Wait(1000)
        if not playerReady() or isDeadOrDown() then
            moveStuckSince, nuiStuckSince, fadeStuckSince = nil, nil, nil
            goto continue
        end

        local ped = cache.ped
        local now = GetGameTimer()

        -- 1) Trying to move but barely moving (collision / freeze / anim lock)
        if tryingToMove() and not IsPauseMenuActive() and horizontalSpeed(ped) < 0.35 then
            -- ignore if ragdolling briefly
            if not IsPedRagdoll(ped) then
                moveStuckSince = moveStuckSince or now
                if (now - moveStuckSince) >= (MOVE_STUCK_SEC * 1000) then
                    maybePrompt('cannot move')
                    if (now - lastReportAt) >= (COOLDOWN_SEC * 1000) then
                        lastReportAt = now
                        TriggerServerEvent('phantom_dashboard:stuck:auto', reasonPayload('cannot_move'))
                    end
                    moveStuckSince = now -- reset window so we don't spam every second
                end
            end
        else
            moveStuckSince = nil
        end

        -- 2) NUI focus stuck (menu closed poorly)
        if IsNuiFocused() and not IsPauseMenuActive() then
            nuiStuckSince = nuiStuckSince or now
            if (now - nuiStuckSince) >= (NUI_STUCK_SEC * 1000) then
                maybePrompt('menu focus stuck')
                if (now - lastReportAt) >= (COOLDOWN_SEC * 1000) then
                    lastReportAt = now
                    TriggerServerEvent('phantom_dashboard:stuck:auto', reasonPayload('nui_focus_stuck'))
                end
                nuiStuckSince = now
            end
        else
            nuiStuckSince = nil
        end

        -- 3) Black screen / fade stuck
        if IsScreenFadedOut() then
            fadeStuckSince = fadeStuckSince or now
            if (now - fadeStuckSince) >= (FADE_STUCK_SEC * 1000) then
                maybePrompt('black screen')
                if (now - lastReportAt) >= (COOLDOWN_SEC * 1000) then
                    lastReportAt = now
                    TriggerServerEvent('phantom_dashboard:stuck:auto', reasonPayload('screen_faded_out'))
                end
                fadeStuckSince = now
            end
        else
            fadeStuckSince = nil
        end

        ::continue::
    end
end)

print(('[phantom_dashboard] stuck watch ready (move %ss / nui %ss / fade %ss)'):format(
    MOVE_STUCK_SEC, NUI_STUCK_SEC, FADE_STUCK_SEC
))
