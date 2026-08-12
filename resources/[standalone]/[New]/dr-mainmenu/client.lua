local menuOpen = false

local WAYPOINTS = {
    wp_pdm = vector2(-55.99, -1096.59),
    wp_luxury = vector2(-1257.4, -369.12),
    wp_boats = vector2(-739.55, -1333.75),
    wp_airport = vector2(-1623.0, -3151.56),
    wp_jobboard = vector2(-267.0, -958.5),
    wp_housing = vector2(-174.0, -926.0),
}

local function openMenu()
    if menuOpen then return end
    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
end

local function closeMenu()
    if not menuOpen then return end
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function setWaypoint(key)
    local p = WAYPOINTS[key]
    if not p then return end
    SetNewWaypoint(p.x, p.y)
    lib.notify({ title = 'Waypoint', description = 'GPS updated', type = 'inform' })
end

RegisterNUICallback('close', function(_, cb)
    closeMenu()
    cb('ok')
end)

RegisterNUICallback('vehicles_openGarage', function(_, cb)
    closeMenu()
    if GetResourceState('qbx_garages') == 'started' then
        TriggerEvent('qbx_garages:client:openNearestGarage')
    else
        TriggerEvent('qb-garages:client:openNearestPublicGarage')
    end
    cb('ok')
end)

RegisterNUICallback('vehicles_returnCurrent', function(_, cb)
    closeMenu()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        lib.notify({ description = 'You are not in a vehicle.', type = 'error' })
        cb('ok')
        return
    end
    local veh = GetVehiclePedIsIn(ped, false)
    TaskLeaveVehicle(ped, veh, 0)
    Wait(1500)
    SetEntityAsMissionEntity(veh, true, true)
    DeleteVehicle(veh)
    lib.notify({ description = 'Vehicle returned.', type = 'success' })
    cb('ok')
end)

RegisterNUICallback('vehicles_call', function(_, cb)
    closeMenu()
    ExecuteCommand('vehicles')
    cb('ok')
end)

RegisterNUICallback('jobs_set', function(data, cb)
    closeMenu()
    local jobName = data and data.job
    if jobName then
        TriggerServerEvent('dr-mainmenu:server:setJob', jobName)
        -- also freeroam job path
        TriggerServerEvent('phantom_freeroam:setJob', jobName, false)
    end
    cb('ok')
end)

RegisterNUICallback('membership_open', function(_, cb)
    closeMenu()
    ExecuteCommand('membership')
    cb('ok')
end)

RegisterNUICallback('admin_open', function(_, cb)
    closeMenu()
    ExecuteCommand('easyadmin')
    cb('ok')
end)

RegisterNUICallback('norse_open', function(_, cb)
    closeMenu()
    ExecuteCommand('opennorseadmin')
    cb('ok')
end)

RegisterNUICallback('vmenu_open', function(_, cb)
    closeMenu()
    ExecuteCommand('vMenu')
    cb('ok')
end)

RegisterNUICallback('open_help', function(_, cb)
    closeMenu()
    ExecuteCommand('help')
    cb('ok')
end)

RegisterNUICallback('open_phone', function(_, cb)
    closeMenu()
    ExecuteCommand('phone')
    cb('ok')
end)

RegisterNUICallback('open_emotes', function(_, cb)
    closeMenu()
    ExecuteCommand('emotemenu')
    Wait(0)
    ExecuteCommand('emotes')
    cb('ok')
end)

RegisterNUICallback('starter_car', function(_, cb)
    closeMenu()
    ExecuteCommand('startercar')
    cb('ok')
end)

RegisterNUICallback('jobcall', function(_, cb)
    closeMenu()
    ExecuteCommand('jobcall')
    cb('ok')
end)

RegisterNUICallback('open_gang', function(_, cb)
    closeMenu()
    ExecuteCommand('gangmenu')
    cb('ok')
end)

RegisterNUICallback('open_cvr', function(_, cb)
    closeMenu()
    ExecuteCommand('cvr')
    cb('ok')
end)

RegisterNUICallback('open_events', function(_, cb)
    closeMenu()
    ExecuteCommand('worldevents')
    cb('ok')
end)

RegisterNUICallback('open_tour', function(_, cb)
    closeMenu()
    ExecuteCommand('citytour')
    cb('ok')
end)

RegisterNUICallback('open_scoreboard', function(_, cb)
    closeMenu()
    ExecuteCommand('scoreboard')
    cb('ok')
end)

RegisterNUICallback('toggle_blips', function(_, cb)
    closeMenu()
    ExecuteCommand('toggleblips')
    cb('ok')
end)

RegisterNUICallback('open_discord', function(_, cb)
    closeMenu()
    SendNUIMessage({ action = 'close' })
    -- FiveM open URL
    if GetResourceState('interact') ~= 'missing' then end
    TriggerEvent('chat:addMessage', {
        args = { '[Phantom]', 'Discord: discord.gg/Z9Mxu72zZ6' }
    })
    cb('ok')
end)

for action, _ in pairs(WAYPOINTS) do
    RegisterNUICallback(action, function(_, cb)
        closeMenu()
        setWaypoint(action)
        cb('ok')
    end)
end

RegisterCommand('mainmenu', function()
    if menuOpen then closeMenu() else openMenu() end
end, false)

RegisterKeyMapping('mainmenu', 'Open Phantom Interaction Hub', 'keyboard', 'F10')
