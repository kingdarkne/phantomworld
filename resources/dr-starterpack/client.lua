local dialogBusy = false
--- After closing the car dialog without picking, offer one automatic reopen (still can use /startercar anytime)
local carMenuAutoRetryLeft = 1
local tryOpen -- forward declare (openCarMenu retries call this)

local pendingCars = nil
local hasSpawned = false
local outfitFinished = false
--- New characters open CreateFirstCharacter after OnPlayerLoaded — block prompts until save
local awaitingFirstOutfit = false
local promptsArmed = false

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

local function canOpenNow()
    if not pendingCars then return false end
    if not hasSpawned then return false end
    if not outfitFinished then return false end
    if awaitingFirstOutfit then return false end
    if dialogBusy then return false end
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

--- Fire once after outfit is saved (new) or returning player is fully in the world.
local function armPostOutfitPrompts()
    if promptsArmed then return end
    if awaitingFirstOutfit then return end
    promptsArmed = true
    outfitFinished = true
    hasSpawned = true

    -- Tell other resources (city tour) that character + outfit are ready
    TriggerEvent('phantom:client:characterReady')

    -- Ask server for starter car list (server no longer pushes this during OnPlayerLoaded)
    TriggerServerEvent('dr-starterpack:server:requestCarSelect')

    SetTimeout(800, function()
        tryOpen(false)
    end)
end

-- New character: clothing UI is about to open — do not prompt yet
RegisterNetEvent('qb-clothes:client:CreateFirstCharacter', function()
    awaitingFirstOutfit = true
    outfitFinished = false
    promptsArmed = false
end)

RegisterNetEvent('illenium-appearance:client:CreateFirstCharacter', function()
    awaitingFirstOutfit = true
    outfitFinished = false
    promptsArmed = false
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    hasSpawned = true
    -- New chars: CreateFirstCharacter usually fires right after this; give it a moment.
    SetTimeout(1500, function()
        if awaitingFirstOutfit then return end
        -- Returning character (no first-outfit flow) — safe to prompt
        armPostOutfitPrompts()
    end)
end)

RegisterNetEvent('qb-clothing:client:onMenuClose', function()
    awaitingFirstOutfit = false
    armPostOutfitPrompts()
end)

-- New character saved outfit in illenium
RegisterNetEvent('illenium-appearance:client:characterCreated', function()
    awaitingFirstOutfit = false
    SetTimeout(600, function()
        armPostOutfitPrompts()
    end)
end)

RegisterNetEvent('fivem-appearance:client:characterCreated', function()
    awaitingFirstOutfit = false
    SetTimeout(600, function()
        armPostOutfitPrompts()
    end)
end)

-- Returning players: appearance applied from DB
RegisterNetEvent('illenium-appearance:client:appearanceLoaded', function()
    if awaitingFirstOutfit then return end
    SetTimeout(600, function()
        armPostOutfitPrompts()
    end)
end)

RegisterNetEvent('dr-starterpack:client:openCarSelect', function(cars)
    pendingCars = cars
    carMenuAutoRetryLeft = 1
    -- Only open if outfit/character is already ready (never during multichar / creator)
    SetTimeout(500, function()
        tryOpen(false)
    end)
end)

RegisterCommand('startercar', function()
    if not pendingCars or #pendingCars == 0 then
        lib.notify({
            title = 'Starter Car',
            description = 'Loading starter car list…',
            type = 'inform',
        })
        TriggerServerEvent('dr-starterpack:server:requestCarSelect', true)
        return
    end
    awaitingFirstOutfit = false
    outfitFinished = true
    hasSpawned = true
    tryOpen(true)
end, false)
