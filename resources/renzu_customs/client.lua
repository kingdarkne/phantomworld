-- Renzu Customs - Client Side
local QBCore = exports['qbx_core']:GetCoreObject()
local lib = exports.ox_lib

local inShop = false
local currentShop = nil
local currentVehicle = nil
local carryingPart = nil

-- Framework detection
if Config.framework == 'ESX' then
    ESX = exports['es_extended']:getSharedObject()
elseif Config.framework == 'QBCORE' then
    QBCore = exports['qbx_core']:GetCoreObject()
end

-- Create shop markers
CreateThread(function()
    for _, shop in ipairs(Config.Shops) do
        -- Create marker
        if Config.showmarker then
            CreateThread(function()
                while true do
                    Wait(0)
                    local ped = PlayerPedId()
                    local coords = GetEntityCoords(ped)
                    local shopCoords = shop.coord
                    
                    if #(coords - vector3(shopCoords.x, shopCoords.y, shopCoords.z)) < 20.0 then
                        DrawMarker(
                            shop.marker.type,
                            shopCoords.x, shopCoords.y, shopCoords.z,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            shop.marker.scale.x, shop.marker.scale.y, shop.marker.scale.z,
                            shop.marker.color.r, shop.marker.color.g, shop.marker.color.b, shop.marker.color.a,
                            false, false, 2, false, nil, nil, false
                        )
                    end
                end
            end)
        end

        -- Create blip
        if shop.blip then
            local blip = AddBlipForCoord(shop.coord.x, shop.coord.y, shop.coord.z)
            SetBlipSprite(blip, shop.blip.sprite)
            SetBlipColour(blip, shop.blip.color)
            SetBlipScale(blip, shop.blip.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(shop.blip.label)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

-- Check if player is in shop zone
CreateThread(function()
    while true do
        Wait(500)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        
        inShop = false
        currentShop = nil
        
        for _, shop in ipairs(Config.Shops) do
            if #(coords - vector3(shop.coord.x, shop.coord.y, shop.coord.z)) < 5.0 then
                inShop = true
                currentShop = shop
                break
            end
        end
    end
end)

-- Open customs menu when in shop
CreateThread(function()
    while true do
        Wait(0)
        if inShop then
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            
            if vehicle ~= 0 then
                if IsControlJustPressed(0, 38) then -- E key
                    OpenCustomsMenu(vehicle)
                end
                
                -- Show help text
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName('Press ~INPUT_CONTEXT~ to open customs menu')
                EndTextCommandDisplayHelp(0, false, true, -1)
            end
        end
    end
end)

-- Open customs menu
function OpenCustomsMenu(vehicle)
    currentVehicle = vehicle
    local vehicleClass = GetVehicleClass(vehicle)
    
    local elements = {
        {label = 'Repair Vehicle', value = 'repair'},
        {label = 'Performance Upgrades', value = 'performance'},
        {label = 'Visual Upgrades', value = 'visual'},
        {label = 'Colors', value = 'colors'},
    }
    
    if Config.UseCustomTurboUpgrade then
        table.insert(elements, {label = 'Custom Turbo', value = 'turbo'})
    end
    
    if Config.UseCustomEngineUpgrade then
        table.insert(elements, {label = 'Custom Engine', value = 'engine'})
    end
    
    if Config.UseCustomTireUpgrade then
        table.insert(elements, {label = 'Custom Tires', value = 'tires'})
    end
    
    -- Open UI
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openMenu',
        elements = elements,
        vehicle = {
            model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)),
            class = vehicleClass,
        }
    })
end

-- NUI Callbacks
RegisterNUICallback('closeMenu', function(data, cb)
    SetNuiFocus(false, false)
    cb(1)
end)

RegisterNUICallback('selectOption', function(data, cb)
    local option = data.option
    local vehicle = currentVehicle
    
    if option == 'repair' then
        RepairVehicle(vehicle)
    elseif option == 'performance' then
        OpenPerformanceMenu(vehicle)
    elseif option == 'visual' then
        OpenVisualMenu(vehicle)
    elseif option == 'colors' then
        OpenColorsMenu(vehicle)
    elseif option == 'turbo' then
        OpenTurboMenu(vehicle)
    elseif option == 'engine' then
        OpenEngineMenu(vehicle)
    elseif option == 'tires' then
        OpenTiresMenu(vehicle)
    end
    
    cb(1)
end)

RegisterNUICallback('installMod', function(data, cb)
    local modType = data.modType
    local modIndex = data.modIndex
    local vehicle = currentVehicle

    if vehicle then
        -- Check if player can use customs directly
        QBCore.Functions.TriggerCallback('renzu_customs:server:canUseCustoms', function(canUse, isMechanic, isAdmin)
            if canUse then
                -- Player can do it directly (mechanic, admin, or no mechanics online)
                SetVehicleModKit(vehicle, 0)
                SetVehicleMod(vehicle, modType, modIndex, false)
                TriggerServerEvent('renzu_customs:server:installMod', modType, modIndex)
            else
                -- Mechanics online, place order
                local plate = GetVehicleNumberPlateText(vehicle)
                local modPrices = {
                    [11] = {15000, 25000, 35000, 45000, 55000},
                    [12] = {5000, 10000, 15000, 20000},
                    [13] = {10000, 20000, 30000, 40000, 50000},
                    [15] = {5000, 10000, 15000, 20000, 25000, 30000},
                    [16] = {2500, 5000, 7500, 10000},
                }
                -- Order placed logic would go here
                lib.notify({ description = 'Order placed! Mechanics will install the mod.', type = 'info' })
            end
        end)
    end
    cb(1)
end)

-- Install mod event (for order fulfillment)
RegisterNetEvent('renzu_customs:client:installMod', function(success, modType, modIndex)
    if success and currentVehicle then
        SetVehicleModKit(currentVehicle, 0)
        SetVehicleMod(currentVehicle, modType, modIndex, false)
    end
end)

-- Command for mechanics to view orders
RegisterCommand('customsorders', function()
    QBCore.Functions.TriggerCallback('renzu_customs:server:getOrders', function(orders)
        if #orders == 0 then
            lib.notify({ description = 'No pending orders', type = 'info' })
            return
        end

        local elements = {}
        for _, order in ipairs(orders) do
            table.insert(elements, {
                label = order.player_name .. ' - ' .. order.plate .. ' ($' .. order.price .. ')',
                value = order.id,
                description = 'Mod Type: ' .. order.mod_type .. ', Index: ' .. order.mod_index
            })
        end

        lib.showMenu('customs_orders', {
            id = 'customs_orders',
            title = 'Pending Customs Orders',
            options = elements,
            onSelect = function(selected)
                TriggerServerEvent('renzu_customs:server:fulfillOrder', selected.value)
            end
        })
    end)
end, false)

RegisterKeyMapping('customsorders', 'Open Customs Orders (Mechanic)', 'keyboard', 'F4')

-- Command to cancelown orders
RegisterCommand('cancelorder', function()
    QBCore.Functions.TriggerCallback('renzu_customs:server:getMyOrders', function(orders)
        if #orders == 0 then
            lib.notify({ description = 'No pending orders', type = 'info' })
            return
        end

        local elements = {}
        for _, order in ipairs(orders) do
            table.insert(elements, {
                label = 'Order #' .. order.id .. ' - ' .. order.plate .. ' ($' .. order.price .. ')',
                value = order.id,
                description = 'Mod Type: ' .. order.mod_type
            })
        end

        lib.showMenu('my_orders', {
            id = 'my_orders',
            title = 'My Orders',
            options = elements,
            onSelect = function(selected)
                    TriggerServerEvent('renzu_customs:server:cancelOrder', selected.value)
            end
        })
    end)
end, false)

-- Vehicle repair
function RepairVehicle(vehicle)
    local health = GetEntityHealth(vehicle)
    local maxHealth = GetEntityMaxHealth(vehicle)
    
    if health < maxHealth then
        TriggerServerEvent('renzu_customs:server:repairVehicle', Config.RepairCost)
    else
        lib.notify({ description = 'Vehicle is already fully repaired', type = 'info' })
    end
end

-- Open performance menu
function OpenPerformanceMenu(vehicle)
    local elements = {
        {label = 'Engine', value = 'engine', modType = 11},
        {label = 'Brakes', value = 'brakes', modType = 12},
        {label = 'Transmission', value = 'transmission', modType = 13},
        {label = 'Suspension', value = 'suspension', modType = 15},
        {label = 'Armor', value = 'armor', modType = 16},
        {label = 'Turbo', value = 'turbo', modType = 18},
    }
    
    SendNUIMessage({
        action = 'openSubMenu',
        elements = elements,
        title = 'Performance Upgrades'
    })
end

-- Open visual menu
function OpenVisualMenu(vehicle)
    local elements = {
        {label = 'Spoilers', value = 'spoiler', modType = 0},
        {label = 'Front Bumper', value = 'bumper_f', modType = 1},
        {label = 'Rear Bumper', value = 'bumper_r', modType = 2},
        {label = 'Side Skirts', value = 'skirt', modType = 3},
        {label = 'Exhaust', value = 'exhaust', modType = 4},
        {label = 'Frame', value = 'frame', modType = 5},
        {label = 'Grille', value = 'grille', modType = 6},
        {label = 'Hood', value = 'hood', modType = 7},
        {label = 'Fender', value = 'fender', modType = 8},
        {label = 'Right Fender', value = 'fender_r', modType = 9},
        {label = 'Roof', value = 'roof', modType = 10},
    }
    
    SendNUIMessage({
        action = 'openSubMenu',
        elements = elements,
        title = 'Visual Upgrades'
    })
end

-- Open colors menu
function OpenColorsMenu(vehicle)
    local elements = {
        {label = 'Primary Color', value = 'primary'},
        {label = 'Secondary Color', value = 'secondary'},
        {label = 'Pearlescent Color', value = 'pearlescent'},
        {label = 'Wheel Color', value = 'wheels'},
        {label = 'Window Tint', value = 'tint'},
    }
    
    if Config.EnableRGBPaint then
        table.insert(elements, {label = 'Custom RGB', value = 'rgb'})
    end
    
    if Config.EnableMattePaint then
        table.insert(elements, {label = 'Matte Finish', value = 'matte'})
    end
    
    SendNUIMessage({
        action = 'openSubMenu',
        elements = elements,
        title = 'Colors'
    })
end

-- Open turbo menu
function OpenTurboMenu(vehicle)
    local elements = {}
    
    for turboType, config in pairs(Config.TurboConfig) do
        table.insert(elements, {
            label = turboType .. ' Turbo',
            value = turboType,
            power = config.power,
            torque = config.torque
        })
    end
    
    SendNUIMessage({
        action = 'openSubMenu',
        elements = elements,
        title = 'Custom Turbo'
    })
end

-- Open engine menu
function OpenEngineMenu(vehicle)
    local elements = {}
    
    for engineLevel, config in pairs(Config.EngineConfig) do
        table.insert(elements, {
            label = config.label,
            value = engineLevel,
            power = config.power,
            torque = config.torque
        })
    end
    
    SendNUIMessage({
        action = 'openSubMenu',
        elements = elements,
        title = 'Custom Engine'
    })
end

-- Open tires menu
function OpenTiresMenu(vehicle)
    local elements = {}
    
    for tireType, config in pairs(Config.TireConfig) do
        table.insert(elements, {
            label = config.label,
            value = tireType,
            traction = config.traction,
            grip = config.grip
        })
    end
    
    SendNUIMessage({
        action = 'openSubMenu',
        elements = elements,
        title = 'Custom Tires'
    })
end

-- Server event handlers
RegisterNetEvent('renzu_customs:client:repairVehicle', function()
    if currentVehicle then
        SetVehicleFixed(currentVehicle)
        SetVehicleDeformationFixed(currentVehicle)
        SetVehicleUndriveable(currentVehicle, false)
        QBCore:Notify('Vehicle repaired successfully', 'success')
    end
end)

RegisterNetEvent('renzu_customs:client:installMod', function(success)
    if success then
        QBCore:Notify('Mod installed successfully', 'success')
    else
        QBCore:Notify('Failed to install mod', 'error')
    end
end)

-- Spray paint system
if Config.EnableSprayPaint then
    RegisterCommand('spraypaint', function()
        if inShop and currentVehicle then
            OpenSprayPaintMenu()
        else
            QBCore:Notify('You must be in a customs shop with a vehicle', 'error')
        end
    end)
    
    function OpenSprayPaintMenu()
        local elements = {}
        
        for _, color in ipairs(Config.SprayPaintColors) do
            table.insert(elements, {
                label = color.label,
                value = color.color
            })
        end
        
        SendNUIMessage({
            action = 'openSubMenu',
            elements = elements,
            title = 'Spray Paint'
        })
    end
end

-- Parts carrying system
if Config.EnablePartsInventory then
    RegisterCommand('carrypart', function(args)
        local partType = args[1]
        
        if Config.CarryableParts[partType] then
            local partConfig = Config.CarryableParts[partType]
            carryingPart = partType
            
            -- Attach prop to player
            local prop = CreateObject(GetHashKey(partConfig.prop), 0, 0, 0, true)
            AttachEntityToEntity(prop, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
            
            QBCore:Notify('Carrying ' .. partConfig.label, 'info')
        else
            QBCore:Notify('Invalid part type', 'error')
        end
    end)
end
