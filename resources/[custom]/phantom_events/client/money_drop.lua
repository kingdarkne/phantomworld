-- Phantom Events - Money Drop Event
local moneyBags = {}
local dropActive = false
local dropLocations = {}
local collectDistance = 2.0
local bagModel = nil

function StartMoneyDropEvent(data)
    dropActive = true
    bagModel = GetHashKey(Config.Events.moneyDrop.bagModel)
    RequestModel(bagModel)
    while not HasModelLoaded(bagModel) do Wait(10) end

    -- Select random location
    local location = Config.DropLocations[math.random(#Config.DropLocations)]
    dropLocations[location.name] = location

    -- Announce location
    lib.notify({
        title = '💰 MONEY RAIN!',
        description = 'Money bags falling near ' .. location.name .. '!',
        type = 'success',
        duration = 10000,
    })

    -- Create blip
    local blip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
    SetBlipSprite(blip, 431)
    SetBlipColour(blip, 2)
    SetBlipScale(blip, 1.0)
    SetBlipFlashes(blip, true)
    SetBlipFlashInterval(blip, 500)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('💰 MONEY RAIN')
    EndTextCommandSetBlipName(blip)

    -- Start dropping bags
    CreateThread(function()
        local bagCount = 0
        while dropActive and bagCount < Config.Events.moneyDrop.maxBags do
            Wait(Config.Events.moneyDrop.dropInterval * 1000)
            if not dropActive then break end

            SpawnMoneyBag(location)
            bagCount = bagCount + 1
        end
    end)

    -- Collection thread
    CreateThread(function()
        while dropActive do
            Wait(0)
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            for i = #moneyBags, 1, -1 do
                local bag = moneyBags[i]
                if DoesEntityExist(bag.entity) then
                    local bagCoords = GetEntityCoords(bag.entity)
                    local dist = #(coords - bagCoords)

                    if dist < collectDistance then
                        -- Collect!
                        CollectMoneyBag(i)
                    elseif dist < 20.0 then
                        -- Draw marker
                        DrawMarker(2, bagCoords.x, bagCoords.y, bagCoords.z + 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 0, 255, 100, 200, false, false, 2, true, nil, nil, false)
                    end
                else
                    table.remove(moneyBags, i)
                end
            end
        end
    end)
end

function SpawnMoneyBag(location)
    local radius = location.radius or 30.0
    local angle = math.random() * math.pi * 2
    local distance = math.random() * radius
    local x = location.coords.x + math.cos(angle) * distance
    local y = location.coords.y + math.sin(angle) * distance
    local z = location.coords.z + Config.Events.moneyDrop.maxDropHeight

    -- Raycast to find ground
    local foundGround, groundZ = GetGroundZFor_3dCoord(x, y, z, false)
    if not foundGround then
        groundZ = location.coords.z
    end

    -- Create falling bag
    local bag = CreateObject(bagModel, x, y, z, true, true, true)
    SetEntityHasGravity(bag, true)
    SetEntityDynamic(bag, true)
    FreezeEntityPosition(bag, false)

    -- Apply downward velocity for falling effect
    SetEntityVelocity(bag, 0.0, 0.0, -15.0)

    -- Wait for it to hit ground
    CreateThread(function()
        Wait(3000)
        if DoesEntityExist(bag) then
            local bagCoords = GetEntityCoords(bag)
            SetEntityCoords(bag, bagCoords.x, bagCoords.y, groundZ, false, false, false, false)
            FreezeEntityPosition(bag, true)

            -- Add particle effect
            local fx = StartParticleFxLoopedAtCoord('core', bagCoords.x, bagCoords.y, bagCoords.z + 0.5, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
            Wait(1000)
            StopParticleFxLooped(fx, false)
        end
    end)

    table.insert(moneyBags, {
        entity = bag,
        amount = math.random(500, Config.Events.moneyDrop.defaultAmount),
        collected = false,
    })
end

function CollectMoneyBag(index)
    local bag = moneyBags[index]
    if bag.collected then return end
    bag.collected = true

    -- Animation
    local ped = PlayerPedId()
    RequestAnimDict('pickup_object')
    while not HasAnimDictLoaded('pickup_object') do Wait(10) end
    TaskPlayAnim(ped, 'pickup_object', 'pickup_low', 8.0, -8.0, 1000, 0, 0, false, false, false)

    -- Delete bag
    if DoesEntityExist(bag.entity) then
        DeleteObject(bag.entity)
    end

    -- Sound
    PlaySoundFrontend(-1, 'Pickup_Briefcase', 'GTAO_Biker_Modes_Soundset', false)

    -- Give money via server
    TriggerServerEvent('phantom_events:server:collectMoneyBag', bag.amount)

    table.remove(moneyBags, index)
end

RegisterNetEvent('phantom_events:client:collectedMoney', function(amount)
    lib.notify({
        title = '💰 +$' .. amount,
        description = 'Money bag collected!',
        type = 'success',
        duration = 3000,
    })

    -- Screen flash green
    StartScreenEffect('HeistCelebPass', 0, false)
    Wait(500)
    StopScreenEffect('HeistCelebPass')
end)

function StopMoneyDrop()
    dropActive = false
    for _, bag in ipairs(moneyBags) do
        if DoesEntityExist(bag.entity) then
            DeleteObject(bag.entity)
        end
    end
    moneyBags = {}
    dropLocations = {}
end
