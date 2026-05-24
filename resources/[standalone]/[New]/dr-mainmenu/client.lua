local menuOpen = false

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

RegisterNUICallback('jobs_set', function(data, cb)
    closeMenu()
    local jobName = data and data.job
    if jobName then
        TriggerServerEvent('dr-mainmenu:server:setJob', jobName)
    end
    cb('ok')
end)

RegisterNUICallback('membership_open', function(_, cb)
    closeMenu()
    -- Open membership info using your existing command
    ExecuteCommand('membership')
    cb('ok')
end)

RegisterNUICallback('admin_open', function(_, cb)
    closeMenu()
    -- EasyAdmin (permissions enforced inside EasyAdmin)
    ExecuteCommand('easyadmin')
    cb('ok')
end)

-- Command + keybind to open menu
RegisterCommand('mainmenu', function()
    openMenu()
end, false)

RegisterKeyMapping('mainmenu', 'Open Phantom main menu', 'keyboard', 'F10')

