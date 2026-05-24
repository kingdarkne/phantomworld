local pedSpawned = false
local ShopPed = {}

local spawncarcoords
local location

local function openRentMenu(data)
    SendNUIMessage({
        action = "OPEN",
        data = data
    })
    SetNuiFocus(true, true)
end

local function createBlips()
    if pedSpawned then return end

    for store in pairs(Config.Locations) do
        if Config.Locations[store]["showblip"] then
            local StoreBlip = AddBlipForCoord(Config.Locations[store]["coords"]["x"], Config.Locations[store]["coords"]["y"], Config.Locations[store]["coords"]["z"])
            SetBlipSprite(StoreBlip, Config.Locations[store]["blipsprite"])
            SetBlipScale(StoreBlip, Config.Locations[store]["blipscale"])
            SetBlipDisplay(StoreBlip, 4)
            SetBlipColour(StoreBlip, Config.Locations[store]["blipcolor"])
            SetBlipAsShortRange(StoreBlip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(Config.Locations[store]["label"])
            EndTextCommandSetBlipName(StoreBlip)
        end
    end
end

local function createPeds()
    if pedSpawned then return end

    for k, v in pairs(Config.Locations) do
        local current = type(v["ped"]) == "number" and v["ped"] or joaat(v["ped"])

        RequestModel(current)
        while not HasModelLoaded(current) do
            Wait(0)
        end

        ShopPed[k] = CreatePed(0, current, v["coords"].x, v["coords"].y, v["coords"].z-1, v["coords"].w, false, false)
        TaskStartScenarioInPlace(ShopPed[k], v["scenario"], 0, true)
        FreezeEntityPosition(ShopPed[k], true)
        SetEntityInvincible(ShopPed[k], true)
        SetBlockingOfNonTemporaryEvents(ShopPed[k], true)

        exports['qb-target']:AddTargetEntity(ShopPed[k], {
            options = {
                {
                    label = v["targetLabel"],
                    icon = v["targetIcon"],
                    action = function()
                        spawncarcoords = k
                        openRentMenu(v.categorie)
                    end,
                }
            },
            distance = 2.0
        })
    end

    pedSpawned = true
end


local function deletePeds()
    if not pedSpawned then return end
    for _, v in pairs(ShopPed) do
        DeletePed(v)
    end
    pedSpawned = false
end

-- qb-core player events removed (QBX uses LocalPlayer.state.isLoggedIn gate)
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    deletePeds()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    createBlips()
    createPeds()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    deletePeds()
end)


RegisterNUICallback('close', function()
    SetNuiFocus(false, false)
end)

local function GetSpawnPoint(garage)
    local location = nil
    if #garage.carspawn > 1 then
        local maxTries = #garage.carspawn
        for i = 1, maxTries do
            local randomIndex = math.random(1, #garage.carspawn)
            local chosenSpawnPoint = garage.carspawn[randomIndex]
            local isOccupied = IsPositionOccupied(
                chosenSpawnPoint.x,
                chosenSpawnPoint.y,
                chosenSpawnPoint.z,
                5.0,   -- range
                false,
                true,  -- checkVehicles
                false, -- checkPeds
                false,
                false,
                0,
                false
            )
            if not isOccupied then
                location = chosenSpawnPoint
                break
            end
        end
    elseif #garage.carspawn == 1 then
        location = garage.carspawn[1]
    end
    if not location then
        lib.notify({ description = 'All spots are occupied', type = 'error' })
    end
    return location
end

RegisterNUICallback('rent', function(data)
    SetNuiFocus(false, false)
    location = GetSpawnPoint(Config.Locations[spawncarcoords])
    if not location then return end
    if tonumber(data.carDay) < 1 then
        lib.notify({ description = 'Invalid rental duration.', type = 'error', duration = 4500 })
        return
    end
    TriggerServerEvent("dr-rental:sv:rentVehicle", data)
end)

RegisterNetEvent('dr-rental:cl:spawnVehicle', function(model,time)
    model = tostring(model or '')
    if model == '' or not location then return end

    local hash = joaat(model)
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) do
        Wait(0)
        timeout += 1
        if timeout > 5000 then
            lib.notify({ description = 'Failed to load vehicle model.', type = 'error' })
            return
        end
    end

    local vehicle = CreateVehicle(hash, location.x, location.y, location.z, location.w, true, false)
    if vehicle == 0 then
        lib.notify({ description = 'Failed to spawn vehicle.', type = 'error' })
        return
    end

    SetVehicleOnGroundProperly(vehicle)
    SetEntityHeading(vehicle, location.w)
    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)

    local plate = lib.string.trim(GetVehicleNumberPlateText(vehicle) or '')
    if plate ~= '' then
        TriggerEvent("vehiclekeys:client:SetOwner", plate)
    end

    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleDirtLevel(vehicle, 0.0)
    if Config.Fuel and exports[Config.Fuel] and exports[Config.Fuel].SetFuel then
        pcall(exports[Config.Fuel].SetFuel, vehicle, 100)
    end

    TriggerServerEvent("dr-rental:sv:updatesql", plate, model, time)
end)

-- QBX login gate (instead of qb-core player loaded events)
CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do
        Wait(500)
    end
    createBlips()
    createPeds()
end)

CreateThread(function()
    while true do
        TriggerServerEvent("dr-rental:sv:checktime")
        Wait(3600000)
    end
end)