local spawnedPeds = {}
local textUiShown = false
local lastTextUi = nil

local function loadModel(model)
    if type(model) == 'string' then model = joaat(model) end
    if not IsModelInCdimage(model) then return false end
    RequestModel(model)
    local t = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < t do
        Wait(10)
    end
    return HasModelLoaded(model)
end

local function spawnJobPeds()
    for _, def in ipairs(Config.JobPeds) do
        if loadModel(def.model) then
            local ped = CreatePed(0, def.model, def.coords.x, def.coords.y, def.coords.z - 1.0, def.coords.w, false, true)
            SetEntityAsMissionEntity(ped, true, true)
            SetPedFleeAttributes(ped, 0, false)
            SetBlockingOfNonTemporaryEvents(ped, true)
            SetEntityInvincible(ped, true)
            FreezeEntityPosition(ped, true)
            if def.scenario then
                TaskStartScenarioInPlace(ped, def.scenario, 0, true)
            end
            spawnedPeds[#spawnedPeds + 1] = { ped = ped, def = def }

            if def.blip then
                local blip = AddBlipForCoord(def.coords.x, def.coords.y, def.coords.z)
                SetBlipSprite(blip, def.blip.sprite or 408)
                SetBlipColour(blip, def.blip.color or 5)
                SetBlipScale(blip, def.blip.scale or 0.75)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentSubstringPlayerName(def.label)
                EndTextCommandSetBlipName(blip)
            end

            SetModelAsNoLongerNeeded(def.model)
        end
    end
end

local function openJobMenu(def)
    local options = {}
    for _, job in ipairs(def.jobs or {}) do
        options[#options + 1] = {
            title = job.label,
            description = job.desc,
            icon = def.criminal and 'skull' or 'briefcase',
            onSelect = function()
                TriggerServerEvent('phantom_freeroam:setJob', job.id, def.criminal == true)
            end,
        }
    end
    lib.registerContext({
        id = 'phantom_freeroam_jobs',
        title = def.label,
        options = options,
    })
    lib.showContext('phantom_freeroam_jobs')
end

local function openShop(zone)
    if zone.appearance then
        if GetResourceState('illenium-appearance') == 'started' then
            TriggerEvent('illenium-appearance:client:openClothingShopMenu')
        else
            lib.notify({ title = 'Clothing', description = 'Appearance system offline', type = 'error' })
        end
        return
    end
    if zone.bank then
        if GetResourceState('omes_banking') == 'started' then
            TriggerEvent('omes_banking:openUI')
        elseif GetResourceState('Renewed-Banking') == 'started' then
            TriggerEvent('Renewed-Banking:client:openBankUI', { atm = false })
        else
            lib.notify({ title = 'Bank', description = 'Use a teller / ATM nearby', type = 'inform' })
        end
        return
    end
    if zone.shop and GetResourceState('ox_inventory') == 'started' then
        local ok = pcall(function()
            exports.ox_inventory:openInventory('shop', { type = zone.shop })
        end)
        if ok then return end
    end
    lib.notify({ title = zone.label, description = 'Shop unavailable — try the counter target', type = 'error' })
end

local function getClosestPedInteract(maxDist)
    local ply = PlayerPedId()
    local pcoords = GetEntityCoords(ply)
    local best, bestDist
    for _, entry in ipairs(spawnedPeds) do
        if DoesEntityExist(entry.ped) then
            local d = #(pcoords - GetEntityCoords(entry.ped))
            if d < (maxDist or 2.2) and (not bestDist or d < bestDist) then
                best, bestDist = entry, d
            end
        end
    end
    return best, bestDist
end

local function getClosestShop(maxDist)
    local pcoords = GetEntityCoords(PlayerPedId())
    local best, bestDist
    for _, zone in ipairs(Config.ShopZones) do
        local d = #(pcoords - zone.coords)
        if d < (zone.radius or maxDist or 2.0) and (not bestDist or d < bestDist) then
            best, bestDist = zone, d
        end
    end
    return best, bestDist
end

local function setTextUi(label)
    if label then
        if not textUiShown or lastTextUi ~= label then
            lib.showTextUI(label)
            textUiShown = true
            lastTextUi = label
        end
    elseif textUiShown then
        lib.hideTextUI()
        textUiShown = false
        lastTextUi = nil
    end
end

CreateThread(function()
    Wait(2500)
    spawnJobPeds()
    for _, d in ipairs(Config.DealerBlips or {}) do
        local blip = AddBlipForCoord(d.coords.x, d.coords.y, d.coords.z)
        SetBlipSprite(blip, d.sprite or 326)
        SetBlipColour(blip, d.color or 2)
        SetBlipScale(blip, 0.75)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(d.label)
        EndTextCommandSetBlipName(blip)
    end
end)

-- One-time freeroam orientation after character load
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    SetTimeout(8000, function()
        lib.notify({
            title = 'Phantom World',
            description = 'Free starter car: /startercar · Buy rides at PDM · Homes via next_housing for-sale markers',
            type = 'inform',
            duration = 12000,
        })
    end)
end)

CreateThread(function()
    while true do
        local sleep = 750
        local pedEntry = getClosestPedInteract(Config.InteractDist + 0.4)
        local shop = getClosestShop(Config.InteractDist)

        if pedEntry then
            sleep = 0
            setTextUi(('[E] %s'):format(pedEntry.def.label))
            if IsControlJustReleased(0, Config.InteractKey) then
                setTextUi(nil)
                openJobMenu(pedEntry.def)
                Wait(400)
            end
        elseif shop then
            sleep = 0
            setTextUi(('[E] %s'):format(shop.label))
            if IsControlJustReleased(0, Config.InteractKey) then
                setTextUi(nil)
                openShop(shop)
                Wait(400)
            end
        else
            setTextUi(nil)
        end
        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, entry in ipairs(spawnedPeds) do
        if DoesEntityExist(entry.ped) then DeleteEntity(entry.ped) end
    end
    setTextUi(nil)
end)
