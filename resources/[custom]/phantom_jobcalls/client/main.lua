local activeCall = nil
local activeMission = nil
local callOpen = false

local function notify(msg, ntype)
    lib.notify({ title = 'Phone Contract', description = msg, type = ntype or 'inform' })
end

local function hideCall()
    callOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hide' })
end

local function showCall(contact)
    callOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'incoming',
        name = contact.name,
        title = contact.title,
        blurb = contact.blurb,
        ringSeconds = Config.RingSeconds,
    })
end

local function startHitman(contact)
    local ply = PlayerPedId()
    local pcoords = GetEntityCoords(ply)
    local angle = math.random() * math.pi * 2
    local dist = math.random(80, 140)
    local tx = pcoords.x + math.cos(angle) * dist
    local ty = pcoords.y + math.sin(angle) * dist
    local tz = pcoords.z
    local found, z = GetGroundZFor_3dCoord(tx, ty, tz + 50.0, false)
    if found then tz = z end

    SetNewWaypoint(tx, ty)
    notify('Target marked on GPS. Eliminate them.', 'inform')

    local model = contact.pedModel or `g_m_y_lost_01`
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
    local ped = CreatePed(4, model, tx, ty, tz, 0.0, true, true)
    SetPedArmour(ped, 50)
    SetPedAccuracy(ped, 40)
    GiveWeaponToPed(ped, `WEAPON_PISTOL`, 60, false, true)
    SetPedCombatAttributes(ped, 46, true)
    TaskCombatPed(ped, ply, 0, 16)
    SetModelAsNoLongerNeeded(model)

    activeMission = { type = 'hitman', ped = ped, contact = contact }
    CreateThread(function()
        while activeMission and activeMission.type == 'hitman' do
            if not DoesEntityExist(ped) or IsEntityDead(ped) then
                local payout = math.random(contact.payout.min, contact.payout.max)
                TriggerServerEvent('phantom_jobcalls:complete', contact.id, payout)
                notify(('Contract complete. +$%s'):format(payout), 'success')
                activeMission = nil
                break
            end
            Wait(500)
        end
    end)
end

local function startRobbery(contact)
    local shops = {
        vec3(28.0, -1340.0, 29.5),
        vec3(-47.2, -1757.9, 29.4),
        vec3(-707.3, -914.4, 19.2),
        vec3(1165.3, -322.6, 69.2),
    }
    local spot = shops[math.random(#shops)]
    SetNewWaypoint(spot.x, spot.y)
    notify('Hit the marked store register. Stay nearby 20s.', 'inform')
    activeMission = { type = 'robbery', coords = spot, contact = contact, started = false }
    CreateThread(function()
        while activeMission and activeMission.type == 'robbery' do
            local d = #(GetEntityCoords(PlayerPedId()) - spot)
            if d < 3.0 then
                if not activeMission.started then
                    activeMission.started = true
                    if lib.progressCircle({
                        duration = 20000,
                        label = 'Cracking the register...',
                        position = 'bottom',
                        useWhileDead = false,
                        canCancel = true,
                        disable = { move = true, combat = true },
                        anim = { dict = 'oddjobs@shop_robbery@rob_till', clip = 'loop' },
                    }) then
                        local payout = math.random(contact.payout.min, contact.payout.max)
                        TriggerServerEvent('phantom_jobcalls:complete', contact.id, payout)
                        notify(('Score secured. +$%s'):format(payout), 'success')
                    else
                        notify('Robbery cancelled.', 'error')
                    end
                    activeMission = nil
                    break
                end
            end
            Wait(400)
        end
    end)
end

local function startRepo(contact)
    local vehicles = { `sultan`, `oracle`, `buffalo`, `fugitive` }
    local model = vehicles[math.random(#vehicles)]
    local ply = GetEntityCoords(PlayerPedId())
    local angle = math.random() * math.pi * 2
    local dist = math.random(100, 180)
    local tx = ply.x + math.cos(angle) * dist
    local ty = ply.y + math.sin(angle) * dist
    local tz = ply.z
    local found, z = GetGroundZFor_3dCoord(tx, ty, tz + 80.0, false)
    if found then tz = z end

    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
    local veh = CreateVehicle(model, tx, ty, tz, math.random(0, 360) + 0.0, true, true)
    SetVehicleDoorsLocked(veh, 1)
    SetNewWaypoint(tx, ty)
    SetModelAsNoLongerNeeded(model)
    notify('Repo the marked vehicle and bring it to Simeon (Dockyard).', 'inform')

    local drop = vec3(1204.5, -3117.0, 5.5)
    activeMission = { type = 'repo', veh = veh, contact = contact }
    CreateThread(function()
        local blippedDrop = false
        while activeMission and activeMission.type == 'repo' do
            if not DoesEntityExist(veh) then
                notify('Vehicle destroyed — contract failed.', 'error')
                activeMission = nil
                break
            end
            if IsPedInVehicle(PlayerPedId(), veh, false) and not blippedDrop then
                SetNewWaypoint(drop.x, drop.y)
                blippedDrop = true
                notify('Deliver to the dockyard marker.', 'inform')
            end
            if IsPedInVehicle(PlayerPedId(), veh, false) and #(GetEntityCoords(PlayerPedId()) - drop) < 8.0 then
                local payout = math.random(contact.payout.min, contact.payout.max)
                DeleteEntity(veh)
                TriggerServerEvent('phantom_jobcalls:complete', contact.id, payout)
                notify(('Repo complete. +$%s'):format(payout), 'success')
                activeMission = nil
                break
            end
            Wait(500)
        end
    end)
end

local function startCops(contact)
    local ply = GetEntityCoords(PlayerPedId())
    local angle = math.random() * math.pi * 2
    local dist = math.random(90, 150)
    local tx = ply.x + math.cos(angle) * dist
    local ty = ply.y + math.sin(angle) * dist
    local tz = ply.z
    local found, z = GetGroundZFor_3dCoord(tx, ty, tz + 50.0, false)
    if found then tz = z end
    SetNewWaypoint(tx, ty)

    local model = `g_m_y_ballaorig_01`
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
    local ped = CreatePed(4, model, tx, ty, tz, 0.0, true, true)
    GiveWeaponToPed(ped, `WEAPON_MICROSMG`, 120, false, true)
    TaskCombatPed(ped, PlayerPedId(), 0, 16)
    SetModelAsNoLongerNeeded(model)
    notify('Suspect marked. Neutralize them for the bounty.', 'inform')
    activeMission = { type = 'cops', ped = ped, contact = contact }
    CreateThread(function()
        while activeMission and activeMission.type == 'cops' do
            if not DoesEntityExist(ped) or IsEntityDead(ped) then
                local payout = math.random(contact.payout.min, contact.payout.max)
                TriggerServerEvent('phantom_jobcalls:complete', contact.id, payout)
                notify(('Bounty collected. +$%s'):format(payout), 'success')
                activeMission = nil
                break
            end
            Wait(500)
        end
    end)
end

local function acceptCall()
    if not activeCall then return end
    local contact = activeCall
    hideCall()
    activeCall = nil
    if contact.type == 'hitman' then
        startHitman(contact)
    elseif contact.type == 'robbery' then
        startRobbery(contact)
    elseif contact.type == 'repo' then
        startRepo(contact)
    else
        startCops(contact)
    end
end

local function declineCall()
    hideCall()
    activeCall = nil
    notify('Call ignored.', 'inform')
end

RegisterNUICallback('accept', function(_, cb)
    acceptCall()
    cb(1)
end)

RegisterNUICallback('decline', function(_, cb)
    declineCall()
    cb(1)
end)

RegisterNetEvent('phantom_jobcalls:incoming', function(contact)
    if callOpen or activeMission then return end
    -- Merge shared Config so pedModel / payout stay authoritative
    if contact and contact.id then
        for _, c in ipairs(Config.Contacts) do
            if c.id == contact.id then
                contact = c
                break
            end
        end
    end
    activeCall = contact
    showCall(contact)
    CreateThread(function()
        local ends = GetGameTimer() + ((contact.ringSeconds or Config.RingSeconds) * 1000)
        while callOpen and GetGameTimer() < ends do
            Wait(200)
        end
        if callOpen then
            declineCall()
        end
    end)
end)

-- Optional: /jobcall to force a test call
RegisterCommand('jobcall', function()
    local contact = Config.Contacts[math.random(#Config.Contacts)]
    TriggerEvent('phantom_jobcalls:incoming', contact)
end, false)
