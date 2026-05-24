-- Renzu Customs - Server Side

local QBCore = exports['qbx_core']:GetCoreObject()

-- Database initialization using oxmysql
exports['oxmysql']:executeSync([[CREATE TABLE IF NOT EXISTS `renzu_customs` (
    `plate` varchar(12) NOT NULL,
    `custom_turbo` varchar(50) DEFAULT NULL,
    `custom_engine` varchar(50) DEFAULT NULL,
    `custom_tires` varchar(50) DEFAULT NULL,
    `custom_paint` varchar(50) DEFAULT NULL,
    PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])

-- Orders database table
exports['oxmysql']:executeSync([[CREATE TABLE IF NOT EXISTS `renzu_customs_orders` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `player_id` varchar(50) NOT NULL,
    `player_name` varchar(100) NOT NULL,
    `plate` varchar(12) NOT NULL,
    `mod_type` varchar(50) NOT NULL,
    `mod_index` int(11) NOT NULL,
    `price` int(11) NOT NULL,
    `status` varchar(20) DEFAULT 'pending',
    `mechanic_id` varchar(50) DEFAULT NULL,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])

-- Check if mechanics are online
local function GetOnlineMechanics()
    local mechanics = {}
    local players = QBCore.Functions.GetPlayers()
    for _, src in ipairs(players) do
        local Player = QBCore.Functions.GetPlayer(src)
        if Player and Player.PlayerData.job.name == Config.job and Player.PlayerData.job.onduty then
            table.insert(mechanics, src)
        end
    end
    return mechanics
end

-- Check if player is admin or owner
local function IsAdminOrOwner(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    local groups = { 'admin', 'god' }
    for _, group in ipairs(groups) do
        if IsPlayerAceAllowed(src, 'command.' .. group) or QBCore.Functions.HasPermission(src, group) then
            return true
        end
    end
    return false
end

-- Vehicle repair
QBCore.Functions.CreateCallback('renzu_customs:server:getVehicleData', function(source, cb, plate)
    exports['oxmysql']:fetch('SELECT * FROM renzu_customs WHERE plate = ?', { plate }, function(result)
        if result and #result > 0 then
            cb(result[1])
        else
            cb(nil)
        end
    end)
end)

-- Repair vehicle
RegisterNetEvent('renzu_customs:server:repairVehicle', function(cost)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then return end

    if Player.Functions.RemoveMoney('bank', cost, 'vehicle-repair') then
        TriggerClientEvent('renzu_customs:client:repairVehicle', src)
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Vehicle repaired for $' .. cost })
    elseif Player.Functions.RemoveMoney('cash', cost, 'vehicle-repair') then
        TriggerClientEvent('renzu_customs:client:repairVehicle', src)
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Vehicle repaired for $' .. cost })
    else
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You don\'t have enough money' })
    end
end)

-- Install mod
RegisterNetEvent('renzu_customs:server:installMod', function(modType, modIndex)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local modPrices = {
        [11] = {15000, 25000, 35000, 45000, 55000}, -- Engine
        [12] = {5000, 10000, 15000, 20000}, -- Brakes
        [13] = {10000, 20000, 30000, 40000, 50000}, -- Transmission
        [15] = {5000, 10000, 15000, 20000, 25000, 30000}, -- Suspension
        [16] = {2500, 5000, 7500, 10000}, -- Armor
        [18] = 25000, -- Turbo
    }
    
    local prices = modPrices[modType]
    local price
    
    if type(prices) == 'table' then
        price = prices[modIndex + 1] or prices[#prices]
    else
        price = prices or 1000
    end
    
    -- Apply mechanic job discount if configured
    if Config.UseRenzu_jobs and Player.PlayerData.job.name == Config.job then
        -- Mechanic gets profit share
        local profit = price * Config.PayoutShare
        Player.Functions.AddMoney('bank', profit, 'mechanic-profit')
    end

-- Check if player can use customs (mechanic, admin/owner, or no mechanics online)
QBCore.Functions.CreateCallback('renzu_customs:server:canUseCustoms', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then cb(false); return end

    local isMechanic = Player.PlayerData.job.name == Config.job and Player.PlayerData.job.onduty
    local isAdmin = IsAdminOrOwner(src)
    local mechanicsOnline = #GetOnlineMechanics() > 0

    if isMechanic or isAdmin then
        cb(true, isMechanic, isAdmin)
    elseif not mechanicsOnline then
        cb(true, false, false) -- No mechanics online, player can do it themselves
    else
        cb(false, false, false) -- Mechanics online, player must place order
    end
end)

-- Place order for mechanic
RegisterNetEvent('renzu_customs:server:placeOrder', function(plate, modType, modIndex, price)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    exports['oxmysql']:execute('INSERT INTO renzu_customs_orders (player_id, player_name, plate, mod_type, mod_index, price) VALUES (?, ?, ?, ?, ?, ?)', {
        Player.PlayerData.citizenid,
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        plate,
        modType,
        modIndex,
        price
    }, function(result)
        if result then
            TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Order placed! A mechanic will fulfill it when available.' })
            -- Notify mechanics
            for _, mechSrc in ipairs(GetOnlineMechanics()) do
                TriggerClientEvent('ox_lib:notify', mechSrc, { type = 'inform', description = 'New customs order available!' })
            end
        end
    end)
end)

-- Get pending orders for mechanics
QBCore.Functions.CreateCallback('renzu_customs:server:getOrders', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or (Player.PlayerData.job.name ~= Config.job and not IsAdminOrOwner(src)) then
        cb({})
        return
    end

    exports['oxmysql']:fetch('SELECT * FROM renzu_customs_orders WHERE status = "pending" ORDER BY created_at ASC', {}, function(result)
        cb(result or {})
    end)
end)

-- Fulfill order (mechanic installs mod)
RegisterNetEvent('renzu_customs:server:fulfillOrder', function(orderId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or (Player.PlayerData.job.name ~= Config.job and not IsAdminOrOwner(src)) then return end

    exports['oxmysql']:fetch('SELECT * FROM renzu_customs_orders WHERE id = ?', { orderId }, function(result)
        if result and #result > 0 then
            local order = result[1]

            -- Update order status
            exports['oxmysql']:execute('UPDATE renzu_customs_orders SET status = "completed", mechanic_id = ? WHERE id = ?', {
                Player.PlayerData.citizenid,
                orderId
            })

            -- Notify player that order is complete
            local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(order.player_id)
            if targetPlayer then
                TriggerClientEvent('ox_lib:notify', targetPlayer.PlayerData.source, { type = 'success', description = 'Your customs order has been completed!' })
                TriggerClientEvent('renzu_customs:client:installMod', targetPlayer.PlayerData.source, true, order.mod_type, order.mod_index)
            end

            TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Order fulfilled!' })
        end
    end)
end)

-- Get player's own orders
QBCore.Functions.CreateCallback('renzu_customs:server:getMyOrders', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    exports['oxmysql']:fetch('SELECT * FROM renzu_customs_orders WHERE player_id = ? AND status = "pending" ORDER BY created_at ASC', {
        Player.PlayerData.citizenid
    }, function(result)
        cb(result or {})
    end)
end)

-- Cancel order
RegisterNetEvent('renzu_customs:server:cancelOrder', function(orderId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    exports['oxmysql']:fetch('SELECT * FROM renzu_customs_orders WHERE id = ?', { orderId }, function(result)
        if result and #result > 0 then
            local order = result[1]

            -- Only player who placed order or admin can cancel
            if order.player_id == Player.PlayerData.citizenid or IsAdminOrOwner(src) then
                exports['oxmysql']:execute('UPDATE renzu_customs_orders SET status = "cancelled" WHERE id = ?', { orderId })
                TriggerClientEvent('ox_lib:notify', src, { type = 'inform', description = 'Order cancelled.' })
            end
        end
    end)
end)
    
    -- Charge player
    if Player.Functions.RemoveMoney('bank', price, 'vehicle-mod') then
        TriggerClientEvent('renzu_customs:client:installMod', src, true)
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Mod installed for $' .. price })
    elseif Player.Functions.RemoveMoney('cash', price, 'vehicle-mod') then
        TriggerClientEvent('renzu_customs:client:installMod', src, true)
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = 'Mod installed for $' .. price })
    else
        TriggerClientEvent('renzu_customs:client:installMod', src, false)
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = 'You don\'t have enough money' })
    end
end)

-- Save custom vehicle data
RegisterNetEvent('renzu_customs:server:saveCustomData', function(plate, dataType, value)
    exports['oxmysql']:fetch('SELECT * FROM renzu_customs WHERE plate = ?', { plate }, function(result)
        if result and #result > 0 then
            exports['oxmysql']:execute('UPDATE renzu_customs SET ' .. dataType .. ' = ? WHERE plate = ?', { value, plate })
        else
            exports['oxmysql']:execute('INSERT INTO renzu_customs (plate, ' .. dataType .. ') VALUES (?, ?)', { plate, value })
        end
    end)
end)

-- Load custom vehicle data
QBCore.Functions.CreateCallback('renzu_customs:server:loadCustomData', function(source, cb, plate)
    exports['oxmysql']:fetch('SELECT * FROM renzu_customs WHERE plate = ?', { plate }, function(result)
        if result and #result > 0 then
            cb(result[1])
        else
            cb(nil)
        end
    end)
end)

-- Custom turbo installation
RegisterNetEvent('renzu_customs:server:installCustomTurbo', function(turboType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local turboConfig = Config.TurboConfig[turboType]
    if not turboConfig then return end
    
    local price = 15000 * (turboConfig.power / 10)
    
    if Player.Functions.RemoveMoney('bank', price, 'custom-turbo') then
        TriggerClientEvent('renzu_customs:client:installCustomTurbo', src, turboType, turboConfig)
        TriggerClientEvent('QBCore:Notify', src, 'Custom ' .. turboType .. ' turbo installed for $' .. price, 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'You don\'t have enough money', 'error')
    end
end)

-- Custom engine installation
RegisterNetEvent('renzu_customs:server:installCustomEngine', function(engineLevel)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local engineConfig = Config.EngineConfig[engineLevel]
    if not engineConfig then return end
    
    local price = 20000 * (engineConfig.power / 10)
    
    if Player.Functions.RemoveMoney('bank', price, 'custom-engine') then
        TriggerClientEvent('renzu_customs:client:installCustomEngine', src, engineLevel, engineConfig)
        TriggerClientEvent('QBCore:Notify', src, 'Custom ' .. engineConfig.label .. ' installed for $' .. price, 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'You don\'t have enough money', 'error')
    end
end)

-- Custom tire installation
RegisterNetEvent('renzu_customs:server:installCustomTires', function(tireType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local tireConfig = Config.TireConfig[tireType]
    if not tireConfig then return end
    
    local price = 5000 * (tireConfig.traction / 2)
    
    if Player.Functions.RemoveMoney('bank', price, 'custom-tires') then
        TriggerClientEvent('renzu_customs:client:installCustomTires', src, tireType, tireConfig)
        TriggerClientEvent('QBCore:Notify', src, 'Custom ' .. tireConfig.label .. ' installed for $' .. price, 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'You don\'t have enough money', 'error')
    end
end)

-- Stock room system
if Config.EnableStockRoom then
    -- Refresh stock room periodically
    CreateThread(function()
        while true do
            Wait(Config.StockRoomRefreshTime * 1000)
            -- Refresh stock room logic here
            print('[renzu_customs] Stock room refreshed')
        end
    end)
end

-- Exports for other resources
exports('GetVehicleCustomData', function(plate)
    local data = nil
    exports['oxmysql']:fetch('SELECT * FROM renzu_customs WHERE plate = ?', { plate }, function(result)
        if result and #result > 0 then
            data = result[1]
        end
    end)
    return data
end)

exports('SetVehicleCustomData', function(plate, dataType, value)
    exports['oxmysql']:fetch('SELECT * FROM renzu_customs WHERE plate = ?', { plate }, function(result)
        if result and #result > 0 then
            exports['oxmysql']:execute('UPDATE renzu_customs SET ' .. dataType .. ' = ? WHERE plate = ?', { value, plate })
        else
            exports['oxmysql']:execute('INSERT INTO renzu_customs (plate, ' .. dataType .. ') VALUES (?, ?)', { plate, value })
        end
    end)
end)
