-- Phantom Mechanic - Client
-- Custom orders and mechanic tablet system (works with kaves_mechanic)

local QBCore = exports['qbx_core']:GetCoreObject()
local tabletOpen = false
local currentOrder = nil
local shopPoints = {}

local function isMechanic()
    local pd = QBCore.Functions.GetPlayerData()
    if not pd or not pd.job then return false end
    if Config.BlockedJobs and Config.BlockedJobs[pd.job.name] then return false end
    if pd.job.name ~= Config.Job then return false end
    if Config.RequireOnDuty and not pd.job.onduty then return false end
    return true
end

-- Open order menu for customers
function OpenOrderMenu()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 then
        lib.notify({ description = 'You must be in a vehicle', type = 'error' })
        return
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))

    local upgrades = {
        { category = 'Performance', items = {
            { name = 'engine', label = 'Engine Upgrade', price = 15000 },
            { name = 'brakes', label = 'Brake Upgrade', price = 8000 },
            { name = 'transmission', label = 'Transmission Upgrade', price = 12000 },
            { name = 'suspension', label = 'Suspension Upgrade', price = 6000 },
            { name = 'turbo', label = 'Turbo Kit', price = 25000 },
        }},
        { category = 'Visual', items = {
            { name = 'spoiler', label = 'Spoiler', price = 5000 },
            { name = 'bumper_f', label = 'Front Bumper', price = 4000 },
            { name = 'bumper_r', label = 'Rear Bumper', price = 3500 },
            { name = 'skirt', label = 'Side Skirts', price = 3000 },
            { name = 'exhaust', label = 'Exhaust System', price = 4500 },
            { name = 'hood', label = 'Hood', price = 3500 },
        }},
        { category = 'Paint', items = {
            { name = 'paint_custom', label = 'Custom Paint Job', price = 3000 },
            { name = 'paint_matte', label = 'Matte Finish', price = 2500 },
            { name = 'paint_metallic', label = 'Metallic Finish', price = 2000 },
            { name = 'paint_chrome', label = 'Chrome Finish', price = 5000 },
        }},
        { category = 'Wheels', items = {
            { name = 'wheels_sport', label = 'Sport Wheels', price = 4000 },
            { name = 'wheels_racing', label = 'Racing Wheels', price = 6000 },
            { name = 'wheels_offroad', label = 'Off-Road Wheels', price = 5000 },
        }},
    }

    local selectedUpgrades = {}
    local totalPrice = 0
    local options = {}

    for _, category in ipairs(upgrades) do
        for _, item in ipairs(category.items) do
            table.insert(options, {
                title = item.label .. ' - $' .. item.price,
                description = category.category .. ' upgrade',
                onSelect = function()
                    if selectedUpgrades[item.name] then
                        selectedUpgrades[item.name] = nil
                        totalPrice = totalPrice - item.price
                        lib.notify({ description = 'Removed ' .. item.label, type = 'info' })
                    else
                        selectedUpgrades[item.name] = item
                        totalPrice = totalPrice + item.price
                        lib.notify({ description = 'Added ' .. item.label, type = 'success' })
                    end
                end
            })
        end
    end

    table.insert(options, {
        title = 'Submit Order ($' .. totalPrice .. ')',
        description = 'Place custom order with mechanic shop',
        onSelect = function()
            if totalPrice <= 0 then
                lib.notify({ description = 'Select at least one upgrade', type = 'error' })
                return
            end

            local input = lib.inputDialog('Order Details', {
                { type = 'textarea', label = 'Description', placeholder = 'Any special requests...', required = false },
            })

            if not input then return end

            local orderUpgrades = {}
            for _, item in pairs(selectedUpgrades) do
                table.insert(orderUpgrades, item)
            end

            local result = lib.callback.await('phantom_mechanic:server:createOrder', false, {
                plate = plate,
                vehicleModel = model,
                upgrades = orderUpgrades,
                description = input[1] or '',
                totalPrice = totalPrice
            })

            if result.success then
                lib.notify({ description = 'Order placed! ID: ' .. result.orderId, type = 'success' })
            else
                lib.notify({ description = result.message or 'Failed to place order', type = 'error' })
            end
        end
    })

    lib.registerContext({
        id = 'phantom_mechanic_order',
        title = 'Custom Order - ' .. model,
        options = options
    })
    lib.showContext('phantom_mechanic_order')
end

function OpenMechanicTablet()
    if not isMechanic() then
        lib.notify({ description = 'You are not a mechanic', type = 'error' })
        return
    end

    tabletOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openTablet' })
    LoadTabletData()
end

function LoadTabletData()
    local pendingOrders = lib.callback.await('phantom_mechanic:server:getPendingOrders', false)
    local myOrders = lib.callback.await('phantom_mechanic:server:getMyOrders', false)

    SendNUIMessage({
        action = 'loadOrders',
        pending = pendingOrders,
        myOrders = myOrders
    })
end

RegisterNUICallback('closeTablet', function(_, cb)
    tabletOpen = false
    SetNuiFocus(false, false)
    cb({})
end)

RegisterNUICallback('acceptOrder', function(data, cb)
    local result = lib.callback.await('phantom_mechanic:server:acceptOrder', false, data.orderId)
    if result.success then
        lib.notify({ description = 'Order accepted!', type = 'success' })
        currentOrder = result.order
    else
        lib.notify({ description = result.message, type = 'error' })
    end
    LoadTabletData()
    cb(result)
end)

RegisterNUICallback('addPart', function(data, cb)
    local result = lib.callback.await('phantom_mechanic:server:addPart', false, data.orderId, data.part)
    if result.success then
        lib.notify({ description = 'Part added!', type = 'success' })
    else
        lib.notify({ description = result.message, type = 'error' })
    end
    cb(result)
end)

RegisterNUICallback('completeOrder', function(data, cb)
    local result = lib.callback.await('phantom_mechanic:server:completeOrder', false, data.orderId)
    if result.success then
        lib.notify({ description = 'Order completed! Earned $' .. result.pay, type = 'success' })
        currentOrder = nil
    else
        lib.notify({ description = result.message, type = 'error' })
    end
    LoadTabletData()
    cb(result)
end)

RegisterNUICallback('cancelOrder', function(data, cb)
    local result = lib.callback.await('phantom_mechanic:server:cancelOrder', false, data.orderId)
    if result.success then
        lib.notify({ description = 'Order cancelled', type = 'info' })
    else
        lib.notify({ description = result.message, type = 'error' })
    end
    LoadTabletData()
    cb(result)
end)

RegisterNUICallback('getOrderDetails', function(data, cb)
    local order = lib.callback.await('phantom_mechanic:server:getOrder', false, data.orderId)
    cb(order)
end)

RegisterNetEvent('phantom_mechanic:client:newOrderNotification', function(data)
    lib.notify({
        title = data.title,
        description = data.message,
        type = 'info',
        duration = 8000,
        position = 'top-right'
    })
end)

RegisterNetEvent('phantom_mechanic:client:orderAccepted', function(data)
    lib.notify({
        title = 'Order Accepted',
        description = 'Mechanic ' .. data.mechanicName .. ' is working on your order #' .. data.orderId,
        type = 'success',
        duration = 8000
    })
end)

RegisterNetEvent('phantom_mechanic:client:orderCompleted', function(data)
    lib.notify({
        title = 'Order Complete!',
        description = data.message,
        type = 'success',
        duration = 10000
    })
end)

RegisterCommand('ordercustom', function()
    OpenOrderMenu()
end)

RegisterCommand('mechanictablet', function()
    OpenMechanicTablet()
end)

RegisterKeyMapping('mechanictablet', 'Open Mechanic Tablet', 'keyboard', 'F6')

-- ox_target at each mechanic shop (orders + tablet)
CreateThread(function()
    while GetResourceState('ox_target') ~= 'started' do
        Wait(500)
    end

    for i, shop in ipairs(Config.Shops) do
        exports.ox_target:addSphereZone({
            name = ('phantom_mechanic_shop_%s'):format(i),
            coords = shop.coords,
            radius = shop.radius or 4.0,
            debug = false,
            options = {
                {
                    name = ('phantom_order_%s'):format(i),
                    icon = 'fa-solid fa-clipboard-list',
                    label = 'Place Custom Order',
                    canInteract = function()
                        return IsPedInAnyVehicle(PlayerPedId(), false)
                    end,
                    onSelect = function()
                        OpenOrderMenu()
                    end,
                },
                {
                    name = ('phantom_tablet_%s'):format(i),
                    icon = 'fa-solid fa-tablet',
                    label = 'Mechanic Tablet (Orders)',
                    groups = Config.Job,
                    onSelect = function()
                        OpenMechanicTablet()
                    end,
                },
            },
        })
    end
end)

-- On-foot hint near shop for mechanics
CreateThread(function()
    for i, shop in ipairs(Config.Shops) do
        shopPoints[i] = lib.points.new({
            coords = shop.coords,
            distance = 25,
            nearby = function(self)
                if not isMechanic() then return end
                if self.currentDistance < 8.0 then
                    lib.showTextUI('[F6] Mechanic Tablet  |  Alt: ox_target options', { position = 'left-center' })
                end
            end,
            onExit = function()
                lib.hideTextUI()
            end,
        })
    end
end)

print('^2[Phantom Mechanic]^7 Client loaded')
