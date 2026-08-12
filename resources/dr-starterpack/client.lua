local dialogBusy = false
--- After closing the car dialog without picking, offer one automatic reopen (still can use /startercar anytime)
local carMenuAutoRetryLeft = 1
local tryOpen -- forward declare (openCarMenu retries call this)

local function openCarMenu(cars, manual)
    if type(cars) ~= 'table' or #cars == 0 then return end
    if dialogBusy then return end
    dialogBusy = true

    local selectOptions = {}
    for i = 1, #cars do
        local c = cars[i]
        local label = c.label or c.model or ('Car #%s'):format(i)
        local value = c.model
        if value then
            selectOptions[#selectOptions + 1] = {
                label = label,
                value = value,
                description = ('Free starter — %s (dealers sell the rest)'):format(value),
            }
        end
    end

    -- ox_lib keeps a global `input` promise; if it was not cleared when the dialog closed (ESC/back),
    -- the next lib.inputDialog returns nil immediately and never opens. Reset before showing.
    if lib.closeInputDialog then
        lib.closeInputDialog()
    end
    Wait(0)

    local result
    local ok, err = pcall(function()
        result = lib.inputDialog('Choose your free starter vehicle', {
            {
                type = 'select',
                label = 'Economy starter',
                description = 'One free used/economy ride. Sports & luxury are at dealerships.',
                options = selectOptions,
                required = true,
            }
        })
    end)
    if not ok then
        if lib and lib.print and lib.print.error then
            lib.print.error(('[dr-starterpack] inputDialog error: %s'):format(err))
        end
    end

    dialogBusy = false

    if not result then
        if manual then
            lib.notify({
                title = 'Starter Car',
                description = 'Selection cancelled.',
                type = 'inform'
            })
        else
            lib.notify({
                title = 'Starter Car',
                description = 'When you are ready, type /startercar to pick your free vehicle.',
                type = 'inform',
                duration = 8000
            })
            if carMenuAutoRetryLeft > 0 then
                carMenuAutoRetryLeft = carMenuAutoRetryLeft - 1
                SetTimeout(3500, function()
                    if tryOpen then tryOpen(false) end
                end)
            end
        end
        return
    end

    carMenuAutoRetryLeft = 0

    local model = result[1]
    if not model or model == '' then return end
    TriggerServerEvent('dr-starterpack:server:claimCar', model)
end

local pendingCars = nil
local hasSpawned = false
local outfitFinished = false

local function requestModel(model)
    model = type(model) == 'string' and joaat(model) or model
    if not model or model == 0 then return nil end
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) do
        Wait(0)
        timeout = timeout + 1
        if timeout > 5000 then
            return nil
        end
    end
    return model
end

RegisterNetEvent('dr-starterpack:client:spawnStarterCar', function(model, props)
    model = tostring(model or '')
    if model == '' then return end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    local hash = requestModel(model)
    if not hash then
        lib.notify({ title = 'Starter Car', description = 'Failed to load vehicle model.', type = 'error' })
        return
    end

    local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, false)
    if not vehicle or vehicle == 0 then
        lib.notify({ title = 'Starter Car', description = 'Failed to spawn vehicle.', type = 'error' })
        return
    end

    local netTimeout = GetGameTimer() + 8000
    while not NetworkGetEntityIsNetworked(vehicle) and GetGameTimer() < netTimeout do
        NetworkRegisterEntityAsNetworked(vehicle)
        Wait(0)
    end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if netId and netId ~= 0 then
        SetNetworkIdExistsOnAllMachines(netId, true)
        SetNetworkIdCanMigrate(netId, true)
    end

    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehicleOnGroundProperly(vehicle)

    if type(props) == 'table' then
        if props.plate and props.plate ~= '' then
            SetVehicleNumberPlateText(vehicle, props.plate)
        end
        lib.setVehicleProperties(vehicle, props)
    end

    TaskWarpPedIntoVehicle(ped, vehicle, -1)

    SetTimeout(500, function()
        local plateRaw = GetVehicleNumberPlateText(vehicle) or ''
        local plate
        if lib and lib.string and lib.string.trim then
            plate = lib.string.trim(plateRaw)
        else
            plate = (tostring(plateRaw):gsub('^%s*(.-)%s*$', '%1'))
        end
        if plate ~= '' then
            TriggerEvent('vehiclekeys:client:SetOwner', plate)
            if netId and netId ~= 0 then
                TriggerServerEvent('qb-vehiclekeys:server:setVehLockState', netId, 1)
            end
        end
    end)

    lib.notify({ title = 'Starter Car', description = 'Enjoy your new ride.', type = 'success' })
end)

--- When illenium / fivem-appearance is running, players never close qb-clothing's menu — but qb-clothing
--- may still be `started` on the server, which would block this menu forever without this check.
local function appearanceUsesQbClothingOnly()
    if GetResourceState('qb-clothing') ~= 'started' then return false end
    if GetResourceState('illenium-appearance') == 'started' then return false end
    if GetResourceState('fivem-appearance') == 'started' then return false end
    return true
end

--- Wait for outfit when qb-clothing-only, or when illenium / fivem-appearance runs (they replace qb-clothing gating).
local function mustWaitForOutfit()
    if GetResourceState('illenium-appearance') == 'started' then return true end
    if GetResourceState('fivem-appearance') == 'started' then return true end
    return appearanceUsesQbClothingOnly()
end

local function canOpenNow()
    if not pendingCars then return false end
    if not hasSpawned then return false end
    if dialogBusy then return false end

    if mustWaitForOutfit() and not outfitFinished then
        return false
    end

    if not IsScreenFadedIn() then return false end
    if IsPauseMenuActive() then return false end
    if not NetworkIsPlayerActive(PlayerId()) then return false end
    if not IsEntityVisible(PlayerPedId()) then return false end
    return true
end

tryOpen = function(manual)
    if not canOpenNow() then return end
    openCarMenu(pendingCars, manual == true)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    hasSpawned = true
    SetTimeout(2500, function()
        tryOpen(false)
    end)
    -- If illenium never fires appearanceLoaded/characterCreated (race or edge case), do not block forever.
    if mustWaitForOutfit() then
        SetTimeout(30000, function()
            if pendingCars and not outfitFinished then
                outfitFinished = true
                tryOpen(false)
            end
        end)
    end
end)

RegisterNetEvent('qb-clothing:client:onMenuClose', function()
    outfitFinished = true
    SetTimeout(400, function()
        tryOpen(false)
    end)
end)

RegisterNetEvent('illenium-appearance:client:characterCreated', function()
    outfitFinished = true
    SetTimeout(400, function()
        tryOpen(false)
    end)
end)

-- Returning players: appearance applied from DB (new characters have no row yet — they use characterCreated above)
RegisterNetEvent('illenium-appearance:client:appearanceLoaded', function()
    outfitFinished = true
    SetTimeout(400, function()
        tryOpen(false)
    end)
end)

RegisterNetEvent('fivem-appearance:client:characterCreated', function()
    outfitFinished = true
    SetTimeout(400, function()
        tryOpen(false)
    end)
end)

-- Illenium applies skin on OnPlayerLoaded; no separate event — allow menu shortly after load.
RegisterNetEvent('illenium-appearance:client:reloadSkin', function()
    outfitFinished = true
end)

CreateThread(function()
    while true do
        if hasSpawned and GetResourceState('qb-clothing') ~= 'started'
            and GetResourceState('illenium-appearance') ~= 'started'
            and GetResourceState('fivem-appearance') ~= 'started'
            and not outfitFinished then
            outfitFinished = true
        end
        Wait(1000)
    end
end)

RegisterNetEvent('dr-starterpack:client:openCarSelect', function(cars)
    pendingCars = cars
    carMenuAutoRetryLeft = 1
    SetTimeout(1800, function()
        tryOpen(false)
    end)
    -- Server may send this before appearance events; ensure menu opens even if outfit gate never clears.
    if mustWaitForOutfit() then
        SetTimeout(25000, function()
            if pendingCars and not outfitFinished then
                outfitFinished = true
                tryOpen(false)
            end
        end)
    end
end)

RegisterCommand('startercar', function()
    -- Ask server for choices (works even if openCarSelect was missed on first load)
    if not pendingCars or #pendingCars == 0 then
        lib.notify({
            title = 'Starter Car',
            description = 'Loading starter car list…',
            type = 'inform',
        })
        TriggerServerEvent('dr-starterpack:server:requestCarSelect')
        return
    end
    outfitFinished = true
    hasSpawned = true
    tryOpen(true)
end, false)

-- Soft nudge after spawn if the car list never arrived
CreateThread(function()
    local waited = 0
    while waited < 20000 do
        Wait(1000)
        waited = waited + 1000
        if pendingCars and #pendingCars > 0 then return end
        if hasSpawned then
            TriggerServerEvent('dr-starterpack:server:requestCarSelect')
            return
        end
    end
end)
