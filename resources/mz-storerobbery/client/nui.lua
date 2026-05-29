RobberyNui = {
    active = false,
}

function RobberyNui.send(action, data)
    SendNUIMessage({
        action = action,
        data = data or {},
    })
end

function RobberyNui.show(label, phase, mode)
    if not Config.RobberyReactUi then return end
    RobberyNui.active = true
    RobberyNui.send('showRobbery', {
        label = label or 'Store',
        phase = phase or 'Robbery in progress',
        mode = mode or 'register',
    })
end

function RobberyNui.update(percent, phase, cash, mode)
    if not Config.RobberyReactUi or not RobberyNui.active then return end
    RobberyNui.send('updateProgress', {
        percent = percent,
        phase = phase,
        cash = cash,
        mode = mode,
    })
end

function RobberyNui.hide()
    if not Config.RobberyReactUi then return end
    RobberyNui.active = false
    RobberyNui.send('hideRobbery', {})
end

function RobberyNui.trackProgress(durationMs, label, phase, mode)
    if not Config.RobberyReactUi then return end
    local startTime = GetGameTimer()
    CreateThread(function()
        while RobberyNui.active do
            local elapsed = GetGameTimer() - startTime
            local pct = math.min(100, math.floor((elapsed / durationMs) * 100))
            local maxCash = Config.RobberyUiMaxCash or 850
            if mode == 'safe' then
                maxCash = Config.RobberyUiMaxSafeCash or 22000
            end
            local cash = math.floor((pct / 100) * maxCash)
            RobberyNui.update(pct, phase, cash, mode)
            if pct >= 100 then break end
            Wait(100)
        end
    end)
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    RobberyNui.hide()
end)
