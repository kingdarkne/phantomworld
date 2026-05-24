-- Phantom Mechanic - Server
-- Order management and mechanic tablet backend

local activeOrders = {}
local completedOrders = {}
local orderCounter = 0

-- Get player data helper
local function GetPlayerData(source)
    local Player = exports.qbx_core:GetPlayer(source)
    if Player then
        return {
            citizenid = Player.PlayerData.citizenid,
            name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
            job = Player.PlayerData.job.name,
            money = Player.PlayerData.money
        }
    end
    return nil
end

-- Create new order
lib.callback.register('phantom_mechanic:server:createOrder', function(source, orderData)
    local player = GetPlayerData(source)
    if not player then return { success = false, message = 'Player not found' } end

    orderCounter = orderCounter + 1
    local orderId = 'ORD-' .. os.time() .. '-' .. orderCounter

    local newOrder = {
        id = orderId,
        citizenid = player.citizenid,
        customerName = player.name,
        plate = orderData.plate,
        vehicleModel = orderData.vehicleModel,
        upgrades = orderData.upgrades,
        description = orderData.description or '',
        totalPrice = orderData.totalPrice,
        status = 'pending',
        mechanicId = nil,
        mechanicName = nil,
        createdAt = os.time(),
        completedAt = nil,
        partsInstalled = {}
    }

    activeOrders[orderId] = newOrder

    -- Save to database
    MySQL.insert('INSERT INTO phantom_mechanic_orders (order_id, citizenid, customer_name, plate, vehicle_model, upgrades, description, total_price, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        newOrder.id,
        newOrder.citizenid,
        newOrder.customerName,
        newOrder.plate,
        newOrder.vehicleModel,
        json.encode(newOrder.upgrades),
        newOrder.description,
        newOrder.totalPrice,
        newOrder.status,
        newOrder.createdAt
    })

    -- Notify all online mechanics
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local pData = GetPlayerData(tonumber(playerId))
        if pData and pData.job == 'mechanic' then
            TriggerClientEvent('phantom_mechanic:client:newOrderNotification', tonumber(playerId), {
                title = 'New Custom Order',
                message = player.name .. ' placed an order for ' .. orderData.vehicleModel .. ' ($' .. orderData.totalPrice .. ')',
                orderId = orderId
            })
        end
    end

    return { success = true, orderId = orderId }
end)

-- Get all pending orders
lib.callback.register('phantom_mechanic:server:getPendingOrders', function(source)
    local player = GetPlayerData(source)
    if not player then return {} end

    local orders = {}
    for _, order in pairs(activeOrders) do
        if order.status == 'pending' then
            table.insert(orders, order)
        end
    end

    -- Sort by creation time (newest first)
    table.sort(orders, function(a, b) return a.createdAt > b.createdAt end)
    return orders
end)

-- Get my orders (customer)
lib.callback.register('phantom_mechanic:server:getMyOrders', function(source)
    local player = GetPlayerData(source)
    if not player then return {} end

    local orders = {}
    for _, order in pairs(activeOrders) do
        if order.citizenid == player.citizenid then
            table.insert(orders, order)
        end
    end

    -- Also check completed orders
    local dbOrders = MySQL.query.await('SELECT * FROM phantom_mechanic_orders WHERE citizenid = ? ORDER BY created_at DESC', { player.citizenid })
    for _, dbOrder in ipairs(dbOrders) do
        dbOrder.upgrades = json.decode(dbOrder.upgrades)
        dbOrder.partsInstalled = json.decode(dbOrder.parts_installed or '[]')
        table.insert(orders, dbOrder)
    end

    return orders
end)

-- Accept order (mechanic)
lib.callback.register('phantom_mechanic:server:acceptOrder', function(source, orderId)
    local player = GetPlayerData(source)
    if not player then return { success = false, message = 'Player not found' } end
    if player.job ~= 'mechanic' then return { success = false, message = 'You are not a mechanic' } end

    local order = activeOrders[orderId]
    if not order then return { success = false, message = 'Order not found' } end
    if order.status ~= 'pending' then return { success = false, message = 'Order already accepted' } end

    order.status = 'in_progress'
    order.mechanicId = player.citizenid
    order.mechanicName = player.name
    order.acceptedAt = os.time()

    MySQL.update('UPDATE phantom_mechanic_orders SET status = ?, mechanic_id = ?, mechanic_name = ?, accepted_at = ? WHERE order_id = ?', {
        'in_progress',
        player.citizenid,
        player.name,
        order.acceptedAt,
        orderId
    })

    -- Notify customer
    local customerSource = nil
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local pData = GetPlayerData(tonumber(playerId))
        if pData and pData.citizenid == order.citizenid then
            customerSource = tonumber(playerId)
            break
        end
    end

    if customerSource then
        TriggerClientEvent('phantom_mechanic:client:orderAccepted', customerSource, {
            orderId = orderId,
            mechanicName = player.name
        })
    end

    return { success = true, order = order }
end)

-- Add part to order
lib.callback.register('phantom_mechanic:server:addPart', function(source, orderId, partData)
    local player = GetPlayerData(source)
    if not player then return { success = false, message = 'Player not found' } end
    if player.job ~= 'mechanic' then return { success = false, message = 'You are not a mechanic' } end

    local order = activeOrders[orderId]
    if not order then return { success = false, message = 'Order not found' } end
    if order.status ~= 'in_progress' then return { success = false, message = 'Order not in progress' } end
    if order.mechanicId ~= player.citizenid then return { success = false, message = 'You did not accept this order' } end

    table.insert(order.partsInstalled, {
        name = partData.name,
        label = partData.label,
        price = partData.price,
        installedAt = os.time()
    })

    -- Update in database
    MySQL.update('UPDATE phantom_mechanic_orders SET parts_installed = ? WHERE order_id = ?', {
        json.encode(order.partsInstalled),
        orderId
    })

    return { success = true, parts = order.partsInstalled }
end)

-- Complete order
lib.callback.register('phantom_mechanic:server:completeOrder', function(source, orderId)
    local player = GetPlayerData(source)
    if not player then return { success = false, message = 'Player not found' } end
    if player.job ~= 'mechanic' then return { success = false, message = 'You are not a mechanic' } end

    local order = activeOrders[orderId]
    if not order then return { success = false, message = 'Order not found' } end
    if order.status ~= 'in_progress' then return { success = false, message = 'Order not in progress' } end
    if order.mechanicId ~= player.citizenid then return { success = false, message = 'You did not accept this order' } end

    order.status = 'completed'
    order.completedAt = os.time()

    MySQL.update('UPDATE phantom_mechanic_orders SET status = ?, completed_at = ? WHERE order_id = ?', {
        'completed',
        order.completedAt,
        orderId
    })

    -- Move to completed
    completedOrders[orderId] = order
    activeOrders[orderId] = nil

    -- Pay mechanic (50% of total)
    local mechanicPay = math.floor(order.totalPrice * 0.5)
    local currentBank = player.money.bank
    local newBank = currentBank + mechanicPay

    -- Update player bank
    local Player = exports.qbx_core:GetPlayer(source)
    if Player then
        Player.Functions.AddMoney('bank', mechanicPay, 'mechanic-order')
    end

    -- Notify customer
    local customerSource = nil
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local pData = GetPlayerData(tonumber(playerId))
        if pData and pData.citizenid == order.citizenid then
            customerSource = tonumber(playerId)
            break
        end
    end

    if customerSource then
        TriggerClientEvent('phantom_mechanic:client:orderCompleted', customerSource, {
            orderId = orderId,
            mechanicName = player.name,
            message = 'Your order is complete! Pick up your vehicle.'
        })
    end

    return { success = true, pay = mechanicPay }
end)

-- Cancel order
lib.callback.register('phantom_mechanic:server:cancelOrder', function(source, orderId)
    local player = GetPlayerData(source)
    if not player then return { success = false, message = 'Player not found' } end

    local order = activeOrders[orderId]
    if not order then return { success = false, message = 'Order not found' } end

    -- Only customer or admin can cancel
    if order.citizenid ~= player.citizenid and not IsPlayerAceAllowed(source, 'command') then
        return { success = false, message = 'Not authorized' }
    end

    order.status = 'cancelled'
    MySQL.update('UPDATE phantom_mechanic_orders SET status = ? WHERE order_id = ?', { 'cancelled', orderId })

    activeOrders[orderId] = nil
    return { success = true }
end)

-- Get order by ID
lib.callback.register('phantom_mechanic:server:getOrder', function(source, orderId)
    return activeOrders[orderId] or completedOrders[orderId] or nil
end)

-- Create database tables on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS phantom_mechanic_orders (
                id INT AUTO_INCREMENT PRIMARY KEY,
                order_id VARCHAR(50) NOT NULL UNIQUE,
                citizenid VARCHAR(50) NOT NULL,
                customer_name VARCHAR(100),
                plate VARCHAR(20),
                vehicle_model VARCHAR(100),
                upgrades TEXT,
                description TEXT,
                total_price INT DEFAULT 0,
                status VARCHAR(20) DEFAULT 'pending',
                mechanic_id VARCHAR(50),
                mechanic_name VARCHAR(100),
                parts_installed TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                accepted_at TIMESTAMP NULL,
                completed_at TIMESTAMP NULL,
                INDEX idx_citizenid (citizenid),
                INDEX idx_status (status),
                INDEX idx_mechanic (mechanic_id)
            )
        ]])

        -- Load existing active orders from DB
        local dbOrders = MySQL.query.await("SELECT * FROM phantom_mechanic_orders WHERE status IN ('pending', 'in_progress')")
        if dbOrders then
            for _, order in ipairs(dbOrders) do
                order.upgrades = json.decode(order.upgrades)
                order.partsInstalled = json.decode(order.parts_installed or '[]')
                activeOrders[order.order_id] = order
            end
        end

        print('^2[Phantom Mechanic]^7 Server loaded. Active orders: ' .. #dbOrders)
    end
end)
