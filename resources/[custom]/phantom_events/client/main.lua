-- Phantom Events - Main Client
local QBCore = exports['qbx_core']:GetCoreObject()
local activeEventsClient = {}
local eventTimers = {}

-- Initialize
CreateThread(function()
    Wait(2000)
    print('^2[Phantom Events]^7 Client initialized')
end)

-- Event started handler
RegisterNetEvent('phantom_events:client:eventStarted', function(data)
    activeEventsClient[data.type] = {
        name = data.name,
        description = data.description,
        startTime = os.time(),
        duration = data.duration,
        colors = data.colors,
    }

    -- Big announcement
    ShowBigAnnouncement(data)

    -- Start countdown
    StartEventCountdown(data.type, data.duration)

    -- Event-specific handlers
    if data.type == 'moneyDrop' then
        StartMoneyDropEvent(data)
    elseif data.type == 'freeCars' then
        StartFreeCarEvent(data)
    elseif data.type == 'treasureHunt' then
        StartTreasureHunt(data)
    elseif data.type == 'doubleXP' then
        StartBonusEvent('doubleXP', data)
    elseif data.type == 'doublePayday' then
        StartBonusEvent('doublePayday', data)
    elseif data.type == 'lottery' then
        StartLotteryEvent(data)
    elseif data.type == 'vipBonus' then
        StartVIPBonus(data)
    end
end)

-- Event ended handler
RegisterNetEvent('phantom_events:client:eventEnded', function(data)
    activeEventsClient[data.type] = nil
    eventTimers[data.type] = nil

    ShowEventEnded(data)

    -- Stop event-specific effects
    if data.type == 'moneyDrop' then
        StopMoneyDrop()
    elseif data.type == 'treasureHunt' then
        StopTreasureHunt()
    end
end)

-- Big announcement with flashy UI
function ShowBigAnnouncement(data)
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'bigAnnouncement',
        title = data.name:upper(),
        description = data.description,
        colors = data.colors,
        duration = Config.UI.announcementDuration,
    })

    -- Sound effect (if you have sound files)
    PlaySoundFrontend(-1, 'Event_Start_Text', 'GTAO_FM_Events_Soundset', false)

    -- Screen flash
    StartScreenEffect('HeistCelebPass', 0, false)
    Wait(2000)
    StopScreenEffect('HeistCelebPass')
end

-- Event countdown display
function StartEventCountdown(eventType, duration)
    eventTimers[eventType] = duration

    CreateThread(function()
        while eventTimers[eventType] and eventTimers[eventType] > 0 do
            Wait(1000)
            eventTimers[eventType] = eventTimers[eventType] - 1
        end
    end)
end

-- HUD for active events
CreateThread(function()
    while true do
        Wait(0)
        if TableLength(activeEventsClient) > 0 then
            DrawActiveEventsHUD()
        end
    end
end)

function DrawActiveEventsHUD()
    local yOffset = 0.15
    local eventCount = 0

    for eventType, event in pairs(activeEventsClient) do
        local timeLeft = eventTimers[eventType] or 0
        local mins = math.floor(timeLeft / 60)
        local secs = timeLeft % 60
        local timeStr = string.format('%02d:%02d', mins, secs)

        -- Background
        DrawRect(0.88, yOffset + (eventCount * 0.06), 0.2, 0.05, 0, 0, 0, 180)

        -- Event name
        DrawTxt(0.88, yOffset - 0.012 + (eventCount * 0.06), 0.25, event.name, 4, 255, 255, 255, 255, true)

        -- Timer
        DrawTxt(0.88, yOffset + 0.01 + (eventCount * 0.06), 0.22, timeStr, 4, 255, 215, 0, 255, true)

        eventCount = eventCount + 1
    end
end

-- Event ended notification
function ShowEventEnded(data)
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'eventEnded',
        title = data.name .. ' ENDED',
        duration = 5000,
    })

    PlaySoundFrontend(-1, 'Event_End_Text', 'GTAO_FM_Events_Soundset', false)
end

-- Open events menu for players
RegisterNetEvent('phantom_events:client:openEventsMenu', function()
    local events = lib.callback.await('phantom_events:server:getActiveEvents', false)
    local options = {}

    if #events == 0 then
        table.insert(options, {
            title = 'No Active Events',
            description = 'Check back later!',
            disabled = true,
        })
    else
        for _, event in ipairs(events) do
            local mins = math.floor(event.timeRemaining / 60)
            local secs = event.timeRemaining % 60
            table.insert(options, {
                title = event.name,
                description = 'Time left: ' .. string.format('%02d:%02d', mins, secs),
                disabled = true,
            })
        end
    end

    table.insert(options, {
        title = 'Buy Lottery Ticket',
        description = 'Enter the active lottery',
        onSelect = function()
            TriggerServerEvent('phantom_events:server:buyLotteryTicket')
        end
    })

    lib.registerContext({ id = 'events_menu', title = '🎉 Active Events', options = options })
    lib.showContext('events_menu')
end)

-- Open admin panel
RegisterNetEvent('phantom_events:client:openAdminPanel', function()
    if not IsAdmin() then
        lib.notify({ title = 'No Permission', type = 'error' })
        return
    end

    -- Reset NUI focus first to ensure clean state
    SetNuiFocus(false, false)
    Wait(100)

    -- Send message to show panel
    SendNUIMessage({
        action = 'openAdminPanel',
        events = Config.Events,
        activeEvents = activeEventsClient,
    })

    -- Set focus after a small delay to ensure HTML is ready
    Wait(100)
    SetNuiFocus(true, true)
end)

-- Admin check
function IsAdmin()
    return lib.callback.await('phantom_events:server:isAdmin', false)
end

-- NUI close
RegisterNUICallback('closeAdminPanel', function(data, cb)
    SetNuiFocus(false, false)
    cb({})
end)

-- NUI start event
RegisterNUICallback('startEvent', function(data, cb)
    TriggerServerEvent('phantom_events:server:startEvent', data.eventType, data.options)
    cb({ success = true })
end)

-- NUI stop event
RegisterNUICallback('stopEvent', function(data, cb)
    TriggerServerEvent('phantom_events:server:stopEvent', data.eventType)
    cb({ success = true })
end)

-- Helper: Draw text
function DrawTxt(x, y, scale, text, font, r, g, b, a, centered)
    SetTextFont(font)
    SetTextProportional(0)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    if centered then SetTextCentre(1) end
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(x, y)
end

-- Helper: Table length
function TableLength(table)
    local count = 0
    for _ in pairs(table) do count = count + 1 end
    return count
end

-- Admin command
RegisterCommand('adminevents', function()
    TriggerEvent('phantom_events:client:openAdminPanel')
end)

-- Reset command (in case panel gets stuck)
RegisterCommand('resetevents', function()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hide' })
    Wait(500)
    lib.notify({ title = 'Events UI Reset', description = 'Use /adminevents to reopen', type = 'info' })
end)

print('^2[Phantom Events]^7 Client loaded')
