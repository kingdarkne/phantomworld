--- Detect stuck players / likely client bugs and offer /unstuck + Discord report.
--- Auto-detection is conservative: intentional freezes (city tour, menus, cams)
--- must not spam players or Discord.

local ENABLED = GetConvarInt('phantom_dashboard:stuckWatch', 1) == 1
local AUTO_REPORT = GetConvarInt('phantom_dashboard:stuckAutoReport', 0) == 1 -- off by default (prompts only)
local MOVE_STUCK_SEC = tonumber(GetConvar('phantom_dashboard:stuckMoveSeconds', '120')) or 120
local NUI_STUCK_SEC = tonumber(GetConvar('phantom_dashboard:stuckNuiSeconds', '180')) or 180
local FADE_STUCK_SEC = tonumber(GetConvar('phantom_dashboard:stuckFadeSeconds', '120')) or 120
local COOLDOWN_SEC = tonumber(GetConvar('phantom_dashboard:stuckCooldownSeconds', '900')) or 900
local PROMPT_INTERVAL_SEC = tonumber(GetConvar('phantom_dashboard:stuckPromptSeconds', '300')) or 300

local lastPromptAt = 0
local lastReportAt = 0
local moveStuckSince = nil
local nuiStuckSince = nil
local fadeStuckSince = nil

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

local function cityTourActive()
    if GetResourceState('phantom_citytour') ~= 'started' then return false end
    local ok, active = pcall(function()
        return exports.phantom_citytour:IsTourActive()
    end)
    return ok and active == true
end

--- Situations where "can't move" is expected — never treat as stuck.
local function shouldIgnoreWatch()
    local ped = cache.ped
    if not ped or ped == 0 then return true end
    if IsPauseMenuActive() then return true end
    if IsEntityPositionFrozen(ped) then return true end
    if not IsPlayerControlOn(PlayerId()) then return true end
    if IsCutsceneActive() then return true end
    if GetRenderingCam() ~= -1 then return true end
    if IsCinematicCamRendering and IsCinematicCamRendering() then return true end
    if cityTourActive() then return true end
    -- Loading / network fade transitions
    if IsPlayerSwitchInProgress and IsPlayerSwitchInProgress() then return true end
    return false
end

local function tryingToMove()
    return IsControlPressed(0, 32)
        or IsControlPressed(0, 33)
        or IsControlPressed(0, 34)
        or IsControlPressed(0, 35)
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

    notify(('You look stuck (%s). Try /unstuck — or /reportstuck if it keeps happening.'):format(reason), 'inform')

    if lib and lib.alertDialog then
        CreateThread(function()
            local choice = lib.alertDialog({
                header = 'Stuck / possible bug?',
                content = ('Detected: **%s**\n\nUse **/unstuck** to free yourself.\nUse **/reportstuck** only if you still need staff help.'):format(reason),
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

local function maybeAutoReport(reason)
    if not AUTO_REPORT then return end
    local now = GetGameTimer()
    if (now - lastReportAt) < (COOLDOWN_SEC * 1000) then return end
    lastReportAt = now
    TriggerServerEvent('phantom_dashboard:stuck:auto', reasonPayload(reason))
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
    -- Local-only: do not ping Discord for every /unstuck
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
        Wait(1500)
        if not playerReady() or isDeadOrDown() or shouldIgnoreWatch() then
            moveStuckSince, nuiStuckSince, fadeStuckSince = nil, nil, nil
            goto continue
        end

        local ped = cache.ped
        local now = GetGameTimer()

        -- 1) Trying to move but barely moving (collision / freeze / anim lock)
        -- Ignore vehicles (traffic / parking) — too many false positives.
        if tryingToMove()
            and not IsPedInAnyVehicle(ped, false)
            and not IsPedRagdoll(ped)
            and horizontalSpeed(ped) < 0.25
        then
            moveStuckSince = moveStuckSince or now
            if (now - moveStuckSince) >= (MOVE_STUCK_SEC * 1000) then
                maybePrompt('cannot move')
                maybeAutoReport('cannot_move')
                moveStuckSince = now
            end
        else
            moveStuckSince = nil
        end

        -- 2) NUI focus stuck (menu closed poorly) — skip ox_lib dialogs briefly via length
        if IsNuiFocused() and not IsPauseMenuActive() then
            local keepInput = IsNuiFocusKeepingInput and IsNuiFocusKeepingInput()
            if not keepInput then
                nuiStuckSince = nuiStuckSince or now
                if (now - nuiStuckSince) >= (NUI_STUCK_SEC * 1000) then
                    maybePrompt('menu focus stuck')
                    maybeAutoReport('nui_focus_stuck')
                    nuiStuckSince = now
                end
            else
                nuiStuckSince = nil
            end
        else
            nuiStuckSince = nil
        end

        -- 3) Black screen / fade stuck
        if IsScreenFadedOut() then
            fadeStuckSince = fadeStuckSince or now
            if (now - fadeStuckSince) >= (FADE_STUCK_SEC * 1000) then
                maybePrompt('black screen')
                maybeAutoReport('screen_faded_out')
                fadeStuckSince = now
            end
        else
            fadeStuckSince = nil
        end

        ::continue::
    end
end)

print(('[phantom_dashboard] stuck watch ready (move %ss / nui %ss / fade %ss / autoReport=%s)'):format(
    MOVE_STUCK_SEC, NUI_STUCK_SEC, FADE_STUCK_SEC, AUTO_REPORT and 'on' or 'off'
))
