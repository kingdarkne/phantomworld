-- Phantom Events - Free Car Event
local freeCarActive = false
local carMenuOpen = false
local claimedCars = 0

function StartFreeCarEvent(data)
    freeCarActive = true
    claimedCars = 0

    -- Big announcement
    lib.notify({
        title = '🚗 FREE CAR GIVEAWAY!',
        description = 'All vehicles are FREE! Use /freecar to claim yours!',
        type = 'success',
        duration = 15000,
    })

    -- Create blip at spawn location
    local blip = AddBlipForCoord(Config.Events.freeCars.spawnLocation.x, Config.Events.freeCars.spawnLocation.y, Config.Events.freeCars.spawnLocation.z)
    SetBlipSprite(blip, 523)
    SetBlipColour(blip, 38)
    SetBlipScale(blip, 1.0)
    SetBlipFlashes(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('🚗 FREE CAR EVENT')
    EndTextCommandSetBlipName(blip)

    -- Marker at spawn
    CreateThread(function()
        while freeCarActive do
            Wait(0)
            local spawn = Config.Events.freeCars.spawnLocation
            DrawMarker(1, spawn.x, spawn.y, spawn.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 5.0, 5.0, 2.0, 0, 150, 255, 100, false, false, 2, false, nil, nil, false)

            -- Text
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local dist = #(coords - spawn)
            if dist < 10.0 then
                Draw3DText(spawn + vec3(0, 0, 2.0), '~b~FREE CAR EVENT~w~\nUse /freecar', 0.5, 4)
            end
        end

        RemoveBlip(blip)
    end)
end

-- Free car command
RegisterCommand('freecar', function()
    if not freeCarActive then
        lib.notify({ title = 'No Active Event', description = 'Free car event is not running', type = 'error' })
        return
    end

    OpenFreeCarMenu()
end)

function OpenFreeCarMenu()
    if carMenuOpen then return end
    carMenuOpen = true

    -- Vehicle categories
    local categories = {
        { name = 'Sports', models = { 'elegy', 'buffalo', 'fusilade', 'penumbra', 'fusilade' } },
        { name = 'Super', models = { 'adder', 'zentorno', 't20', 'osiris', 'turismor' } },
        { name = 'Muscle', models = { 'dominator', 'gauntlet', 'sabregt', 'vigero', 'ruiner' } },
        { name = 'Sedan', models = { 'jackal', 'oracle', 'schafter2', 'superd', 'washington' } },
        { name = 'SUV', models = { 'baller', 'cavalcade', 'gresley', 'huntley', 'xls' } },
        { name = 'Motorcycle', models = { 'bati', 'akuma', 'double', 'hexer', 'vader' } },
    }

    local options = {}
    for _, cat in ipairs(categories) do
        for _, model in ipairs(cat.models) do
            table.insert(options, {
                title = model:upper(),
                description = cat.name,
                onSelect = function()
                    ClaimFreeCar(model)
                end
            })
        end
    end

    lib.registerContext({
        id = 'free_car_menu',
        title = '🚗 FREE CAR - Pick Your Ride!',
        options = options
    })
    lib.showContext('free_car_menu')
    carMenuOpen = false
end

function ClaimFreeCar(model)
    if claimedCars >= Config.Events.freeCars.maxCarsPerPlayer then
        lib.notify({ title = 'Limit Reached', description = 'Max ' .. Config.Events.freeCars.maxCarsPerPlayer .. ' cars!', type = 'error' })
        return
    end

    -- Check if model valid
    local hash = GetHashKey(model)
    if not IsModelInCdimage(hash) then
        lib.notify({ title = 'Invalid Vehicle', type = 'error' })
        return
    end

    -- Find free spawn
    local spawn = nil
    for _, s in ipairs(Config.FreeCarSpawns) do
        if not IsVehicleOccupied(s) then
            spawn = s
            break
        end
    end

    if not spawn then
        lib.notify({ title = 'No Spawn Points', description = 'All spots taken, try again!', type = 'error' })
        return
    end

    -- Spawn vehicle
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(10) end
    local vehicle = CreateVehicle(hash, spawn.x, spawn.y, spawn.z, spawn.w, true, false)
    SetModelAsNoLongerNeeded(hash)
    SetVehicleOnGroundProperly(vehicle)

    -- Fancy spawn effect
    StartParticleFxLoopedAtCoord('core', spawn.x, spawn.y, spawn.z, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
    PlaySoundFromCoord(-1, 'Car_Mod_Done', spawn.x, spawn.y, spawn.z, 'Car_Upgrade_Soundset', false, 0, false)

    -- Give keys (placeholder for your vehicle keys system)
    -- TriggerEvent('vehiclekeys:client:SetOwner', GetVehicleNumberPlateText(vehicle))

    TriggerServerEvent('phantom_events:server:claimFreeCar', model)
    claimedCars = claimedCars + 1

    lib.notify({
        title = '🚗 Free Car Claimed!',
        description = model:upper() .. ' spawned! (' .. claimedCars .. '/' .. Config.Events.freeCars.maxCarsPerPlayer .. ')',
        type = 'success',
        duration = 5000,
    })
end

function IsVehicleOccupied(spawn)
    -- Check if any vehicle is near spawn
    local vehicles = GetGamePool('CVehicle')
    for _, v in ipairs(vehicles) do
        local vCoords = GetEntityCoords(v)
        if #(vCoords - vec3(spawn.x, spawn.y, spawn.z)) < 3.0 then
            return true
        end
    end
    return false
end

RegisterNetEvent('phantom_events:client:carClaimed', function(model)
    -- Client-side confirmation
end)

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
