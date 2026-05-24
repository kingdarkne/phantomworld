-- Phantom Heists - Minigames (Hacking, Thermite, Drilling)

-- HACKING MINIGAME
-- Grid-based memory matching game
function StartHackMinigame(duration)
    local success = false
    local completed = false

    -- Open NUI for hacking
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'startHack',
        duration = duration,
        gridSize = Config.Minigames.hacking.gridSize,
        requiredMatches = Config.Minigames.hacking.requiredMatches,
    })

    -- Wait for result
    local resultReceived = false
    RegisterNUICallback('hackResult', function(data, cb)
        success = data.success
        resultReceived = true
        cb({})
    end)

    while not resultReceived do Wait(100) end
    SetNuiFocus(false, false)
    return success
end

-- THERMITE MINIGAME
-- Grid-based pattern matching (like GTA thermite)
function StartThermiteMinigame(duration)
    local success = false
    local resultReceived = false

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'startThermite',
        duration = duration,
        gridSize = Config.Minigames.thermite.gridSize,
        requiredMatches = Config.Minigames.thermite.requiredMatches,
    })

    RegisterNUICallback('thermiteResult', function(data, cb)
        success = data.success
        resultReceived = true
        cb({})
    end)

    while not resultReceived do Wait(100) end
    SetNuiFocus(false, false)
    return success
end

-- DRILLING MINIGAME
-- Precision drilling with heat management
function StartDrillMinigame(duration)
    local success = false
    local resultReceived = false

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'startDrill',
        duration = duration,
        targetDepth = Config.Minigames.drilling.targetDepth,
        heatLimit = Config.Minigames.drilling.heatLimit,
    })

    RegisterNUICallback('drillResult', function(data, cb)
        success = data.success
        resultReceived = true
        cb({})
    end)

    while not resultReceived do Wait(100) end
    SetNuiFocus(false, false)
    return success
end

-- NUI Close handler
RegisterNUICallback('closeMinigame', function(data, cb)
    SetNuiFocus(false, false)
    cb({})
end)
