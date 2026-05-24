-- Phantom Events - Treasure Hunt
local treasures = {}
local treasureActive = false
local treasureBlips = {}

function StartTreasureHunt(data)
    treasureActive = true

    -- Select random locations
    local shuffled = {}
    for _, loc in ipairs(Config.TreasureLocations) do
        table.insert(shuffled, loc)
    end
    for i = #shuffled, 2, -1 do
        local j = math.random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end

    local count = math.min(Config.Events.treasureHunt.treasureCount, #shuffled)

    -- Spawn treasure chests
    for i = 1, count do
        local loc = shuffled[i]
        local model = GetHashKey(Config.Events.treasureHunt.chestModels[math.random(#Config.Events.treasureHunt.chestModels)])
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(10) end

        local chest = CreateObject(model, loc.x, loc.y, loc.z - 0.5, true, true, true)
        PlaceObjectOnGroundProperly(chest)
        FreezeEntityPosition(chest, true)
        SetModelAsNoLongerNeeded(model)

        -- Blip
        local blip = AddBlipForRadius(loc.x, loc.y, loc.z, 50.0)
        SetBlipColour(blip, 46)
        SetBlipAlpha(blip, 80)
        SetBlipAsShortRange(blip, true)

        table.insert(treasures, {
            entity = chest,
            coords = loc,
            blip = blip,
            opened = false,
        })
    end

    -- Announce
    lib.notify({
        title = '🏴‍☠️ TREASURE HUNT!',
        description = count .. ' treasures hidden across the map! Find them before time runs out!',
        type = 'success',
        duration = 12000,
    })

    -- Play "X marks the spot" style sound
    PlaySoundFrontend(-1, 'RACE_PLACED', 'HUD_AWARDS', false)

    -- Collection thread
    CreateThread(function()
        while treasureActive do
            Wait(0)
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            for i = #treasures, 1, -1 do
                local treasure = treasures[i]
                if not treasure.opened and DoesEntityExist(treasure.entity) then
                    local dist = #(coords - treasure.coords)

                    if dist < 30.0 then
                        -- Draw marker
                        DrawMarker(2, treasure.coords.x, treasure.coords.y, treasure.coords.z + 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.8, 0.8, 0.8, 255, 215, 0, 200, false, false, 2, true, nil, nil, false)
                    end

                    if dist < 1.5 then
                        Draw3DText(treasure.coords + vec3(0, 0, 1.0), '~y~[E]~w~ Open Treasure', 0.35, 4)
                        if IsControlJustPressed(0, 38) then
                            OpenTreasure(i)
                        end
                    end
                end
            end
        end
    end)
end

function OpenTreasure(index)
    local treasure = treasures[index]
    if treasure.opened then return end
    treasure.opened = true

    -- Animation
    local ped = PlayerPedId()
    RequestAnimDict('mini@repair')
    while not HasAnimDictLoaded('mini@repair') do Wait(10) end
    TaskPlayAnim(ped, 'mini@repair', 'fixing_a_player', 8.0, -8.0, 2000, 0, 0, false, false, false)

    -- Open chest animation (rotate lid if possible, or just particles)
    SetEntityRotation(treasure.entity, -45.0, 0.0, GetEntityHeading(treasure.entity), 2, true)

    -- Particles
    UseParticleFxAssetNextCall('core')
    local fx = StartParticleFxLoopedAtCoord('ent_dst_chest_ground', treasure.coords.x, treasure.coords.y, treasure.coords.z + 0.5, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
    Wait(1000)
    StopParticleFxLooped(fx, false)

    -- Sound
    PlaySoundFrontend(-1, 'PICKUP_MONEY_BAG', 'HUD_FRONTEND_CUSTOM_SOUNDSET', false)

    -- Delete entity after animation
    Wait(1000)
    if DoesEntityExist(treasure.entity) then
        DeleteObject(treasure.entity)
    end
    if DoesBlipExist(treasure.blip) then
        RemoveBlip(treasure.blip)
    end

    -- Server reward
    TriggerServerEvent('phantom_events:server:openTreasure', index)
end

RegisterNetEvent('phantom_events:client:treasureOpened', function(amount)
    lib.notify({
        title = '🏴‍☠️ TREASURE FOUND!',
        description = 'You found $' .. amount .. '!',
        type = 'success',
        duration = 5000,
    })

    -- Screen flash gold
    StartScreenEffect('HeistCelebPass', 0, false)
    Wait(500)
    StopScreenEffect('HeistCelebPass')
end)

function StopTreasureHunt()
    treasureActive = false
    for _, t in ipairs(treasures) do
        if DoesEntityExist(t.entity) then
            DeleteObject(t.entity)
        end
        if DoesBlipExist(t.blip) then
            RemoveBlip(t.blip)
        end
    end
    treasures = {}
end

function Draw3DText(coords, text, scale, font)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if onScreen then
        SetTextScale(scale, scale)
        SetTextFont(font)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry('STRING')
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end
