local menuOpen = false
local pendingCars = nil
local hasSpawned = false
local outfitFinished = false
--- New characters open CreateFirstCharacter after OnPlayerLoaded — block prompts until save
local awaitingFirstOutfit = false
local promptsArmed = false
local claimedLocally = false
local openToken = 0

local function forceCloseUi()
    menuOpen = false
    pcall(function()
        if lib.closeInputDialog then lib.closeInputDialog() end
    end)
    pcall(function()
        if lib.hideContext then lib.hideContext(false) end
    end)
    pcall(function()
        if lib.hideMenu then lib.hideMenu(true) end
    end)
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end

local function otherUiBlocking()
    if IsPauseMenuActive() then return true end
    if IsNuiFocused() and not menuOpen then return true end
    if LocalPlayer and LocalPlayer.state and LocalPlayer.state.invOpen then return true end
    return false
end

local function markClaimed()
    claimedLocally = true
    pendingCars = nil
    forceCloseUi()
end

local function openCarMenu(cars, manual)
    if claimedLocally then return end
    if type(cars) ~= 'table' or #cars == 0 then return end
    if menuOpen then
        forceCloseUi()
        Wait(50)
    end
    if otherUiBlocking() and not manual then
        return
    end

    menuOpen = true
    openToken = openToken + 1
    local token = openToken

    -- Safety: never leave NUI focus stuck if something goes wrong
    SetTimeout(90000, function()
        if menuOpen and openToken == token then
            forceCloseUi()
            lib.notify({
                title = 'Starter Car',
                description = 'Menu timed out. Type /startercar when you are ready.',
                type = 'inform',
                duration = 8000,
            })
        end
    end)

    local options = {}
    for i = 1, #cars do
        local c = cars[i]
        local model = c and c.model
        if model and model ~= '' then
            local label = c.label or model
            options[#options + 1] = {
                title = label,
                description = ('Claim %s as your free starter'):format(model),
                icon = 'car',
                onSelect = function()
                    menuOpen = false
                    SetNuiFocus(false, false)
                    if claimedLocally then return end
                    TriggerServerEvent('dr-starterpack:server:claimCar', model)
                end,
            }
        end
    end

    if #options == 0 then
        forceCloseUi()
        return
    end

    options[#options + 1] = {
        title = 'Decide later',
        description = 'Close this menu. Type /startercar anytime to claim.',
        icon = 'xmark',
        onSelect = function()
            forceCloseUi()
            lib.notify({
                title = 'Starter Car',
                description = 'Type /startercar when you are ready to pick your free vehicle.',
                type = 'inform',
                duration = 8000,
            })
        end,
    }

    lib.registerContext({
        id = 'dr_starter_car_select',
        title = 'Choose your free starter vehicle',
        canClose = true,
        onExit = function()
            menuOpen = false
            SetNuiFocus(false, false)
            if not manual and not claimedLocally then
                lib.notify({
                    title = 'Starter Car',
                    description = 'Type /startercar when you are ready to pick your free vehicle.',
                    type = 'inform',
                    duration = 8000,
                })
            end
        end,
        options = options,
    })

    lib.showContext('dr_starter_car_select')
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

RegisterNetEvent('dr-starterpack:client:carClaimed', function()
    markClaimed()
end)

RegisterNetEvent('dr-starterpack:client:spawnStarterCar', function(model, props)
    markClaimed()
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
    if claimedLocally then return false end
    if not pendingCars then return false end
    if not hasSpawned then return false end
    if not outfitFinished then return false end
    if awaitingFirstOutfit then return false end
    if menuOpen then return false end
    if not IsScreenFadedIn() then return false end
    if IsPauseMenuActive() then return false end
    if not NetworkIsPlayerActive(PlayerId()) then return false end
    if not IsEntityVisible(PlayerPedId()) then return false end
    if otherUiBlocking() then return false end
    return true
end

local function tryOpen(manual)
    if claimedLocally then return end
    if manual then
        -- Manual /startercar: force-close any stuck focus, then open
        forceCloseUi()
        awaitingFirstOutfit = false
        outfitFinished = true
        hasSpawned = true
        Wait(50)
        if not pendingCars or #pendingCars == 0 then return end
        openCarMenu(pendingCars, true)
        return
    end
    if not canOpenNow() then return end
    openCarMenu(pendingCars, false)
end

--- Fire once after outfit is saved (new) or returning player is fully in the world.
local function armPostOutfitPrompts()
    if promptsArmed then return end
    if awaitingFirstOutfit then return end
    if claimedLocally then return end
    promptsArmed = true
    outfitFinished = true
    hasSpawned = true

    TriggerEvent('phantom:client:characterReady')

    TriggerServerEvent('dr-starterpack:server:requestCarSelect')

    -- Single delayed open — no auto-retry loops (those stuck players in the old popup)
    SetTimeout(1200, function()
        if claimedLocally then return end
        tryOpen(false)
    end)
end

RegisterNetEvent('qb-clothes:client:CreateFirstCharacter', function()
    awaitingFirstOutfit = true
    outfitFinished = false
    promptsArmed = false
    forceCloseUi()
end)

RegisterNetEvent('illenium-appearance:client:CreateFirstCharacter', function()
    awaitingFirstOutfit = true
    outfitFinished = false
    promptsArmed = false
    forceCloseUi()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    hasSpawned = true
    claimedLocally = false
    promptsArmed = false
    forceCloseUi()
    SetTimeout(1500, function()
        if awaitingFirstOutfit then return end
        armPostOutfitPrompts()
    end)
end)

RegisterNetEvent('qb-clothing:client:onMenuClose', function()
    awaitingFirstOutfit = false
    armPostOutfitPrompts()
end)

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

RegisterNetEvent('illenium-appearance:client:appearanceLoaded', function()
    if awaitingFirstOutfit then return end
    SetTimeout(600, function()
        armPostOutfitPrompts()
    end)
end)

RegisterNetEvent('dr-starterpack:client:openCarSelect', function(cars)
    if claimedLocally then return end
    pendingCars = cars
    SetTimeout(600, function()
        if claimedLocally then return end
        tryOpen(false)
    end)
end)

RegisterCommand('startercar', function()
    if claimedLocally then
        lib.notify({
            title = 'Starter Car',
            description = 'You already claimed your starter car.',
            type = 'inform',
        })
        return
    end
    if not pendingCars or #pendingCars == 0 then
        lib.notify({
            title = 'Starter Car',
            description = 'Loading starter car list…',
            type = 'inform',
        })
        TriggerServerEvent('dr-starterpack:server:requestCarSelect', true)
        return
    end
    tryOpen(true)
end, false)

--- Emergency escape if NUI focus ever sticks again
RegisterCommand('closestarter', function()
    forceCloseUi()
    lib.notify({
        title = 'Starter Car',
        description = 'Menu closed. Use /startercar to open it again.',
        type = 'success',
    })
end, false)

-- If player presses ESC while somehow stuck with focus and no lib menu, release after pause menu
CreateThread(function()
    while true do
        Wait(1000)
        if menuOpen and IsPauseMenuActive() then
            forceCloseUi()
        end
    end
end)
