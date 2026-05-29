-- Phantom Core - Shop System
-- High-quality shop system with categories and discounts

local shops = {
    { id = 'general', coords = vec3(25.7, -1347.3, 29.5), name = '24/7 General Store', categories = {'Food', 'Drinks', 'Electronics'} },
    { id = 'liquor', coords = vec3(1135.8, -982.3, 46.4), name = 'Liquor Store', categories = {'Drinks', 'Food'} },
    { id = 'police', coords = vec3(452.3, -979.7, 30.7), name = 'Police Armory', categories = {'Medical', 'Electronics'} },
    { id = 'gas', coords = vec3(47.63, -1748.95, 29.33), name = 'Gas Station Shop', categories = {'Food', 'Drinks'} },
}

local shopItems = {
    Food = {
        { name = 'bread', label = 'Bread', price = 5 },
        { name = 'water', label = 'Water', price = 3 },
        { name = 'apple', label = 'Apple', price = 2 },
        { name = 'sandwich', label = 'Sandwich', price = 8 },
        { name = 'burger', label = 'Burger', price = 12 },
    },
    Drinks = {
        { name = 'cola', label = 'Cola', price = 4 },
        { name = 'coffee', label = 'Coffee', price = 5 },
        { name = 'beer', label = 'Beer', price = 7 },
        { name = 'wine', label = 'Wine', price = 15 },
    },
    Medical = {
        { name = 'bandage', label = 'Bandage', price = 25 },
        { name = 'medkit', label = 'Medkit', price = 100 },
        { name = 'painkillers', label = 'Painkillers', price = 50 },
    },
    Electronics = {
        { name = 'phone', label = 'Phone', price = 500 },
        { name = 'radio', label = 'Radio', price = 150 },
        { name = 'camera', label = 'Camera', price = 300 },
    },
    Clothing = {
        { name = 'tshirt', label = 'T-Shirt', price = 25 },
        { name = 'pants', label = 'Pants', price = 35 },
        { name = 'shoes', label = 'Shoes', price = 45 },
    },
}

local currentShop = nil
local cart = {}

-- Open shop menu
function OpenShopMenu(shopId)
    local shop = shops[shopId]
    if not shop then return end
    
    currentShop = shop
    cart = {}
    
    local options = {}
    
    -- Add categories
    for _, category in ipairs(shop.categories) do
        local categoryIcon = nil
        for _, cat in ipairs(Config.Economy.Shops.Categories) do
            if cat.name == category then
                categoryIcon = cat.icon
                break
            end
        end
        
        table.insert(options, {
            label = category,
            description = 'Browse ' .. category .. ' items',
            icon = categoryIcon or '🛒',
            args = { type = 'category', name = category }
        })
    end
    
    -- Add cart option
    table.insert(options, {
        label = 'Cart (' .. #cart .. ' items)',
        description = 'View your cart',
        icon = '🛒',
        args = { type = 'cart' }
    })
    
    ShowMenu({
        title = shop.name,
        options = options
    })
end

-- Open category menu
function OpenCategoryMenu(categoryName)
    local options = {}
    local categoryItems = shopItems[categoryName] or {}
    
    for _, item in ipairs(categoryItems) do
        table.insert(options, {
            label = item.label,
            description = FormatMoney(item.price),
            icon = '📦',
            args = { type = 'add', item = item }
        })
    end
    
    -- Add back button
    table.insert(options, {
        label = '← Back',
        description = 'Return to shop',
        icon = '⬅️',
        args = { type = 'back' }
    })
    
    ShowMenu({
        title = categoryName,
        options = options
    })
end

-- Add item to cart
function AddToCart(item)
    -- Check if item already in cart
    for _, cartItem in ipairs(cart) do
        if cartItem.name == item.name then
            cartItem.quantity = cartItem.quantity + 1
            SendNotification({
                notificationType = 'info',
                message = item.label .. ' added to cart (' .. cartItem.quantity .. ')'
            })
            return
        end
    end
    
    table.insert(cart, {
        name = item.name,
        label = item.label,
        price = item.price,
        quantity = 1
    })
    
    SendNotification({
        notificationType = 'info',
        message = item.label .. ' added to cart'
    })
end

-- View cart
function ViewCart()
    local options = {}
    local total = 0
    
    if #cart == 0 then
        table.insert(options, {
            label = 'Cart is empty',
            description = 'Add items to your cart',
            icon = '🛒',
            disabled = true
        })
    else
        for i, item in ipairs(cart) do
            local itemTotal = item.price * item.quantity
            total = total + itemTotal
            
            table.insert(options, {
                label = item.label .. ' x' .. item.quantity,
                description = FormatMoney(itemTotal),
                icon = '📦',
                args = { type = 'remove', index = i }
            })
        end
        
        -- Add total
        table.insert(options, {
            label = 'Total: ' .. FormatMoney(total),
            description = 'Including ' .. (Config.Economy.Shops.TaxRate * 100) .. '% tax',
            icon = '💰',
            disabled = true
        })
        
        -- Add checkout option
        table.insert(options, {
            label = 'Checkout',
            description = 'Complete your purchase',
            icon = '✅',
            args = { type = 'checkout' }
        })
    end
    
    -- Add back button
    table.insert(options, {
        label = '← Back',
        description = 'Return to shop',
        icon = '⬅️',
        args = { type = 'back' }
    })
    
    ShowMenu({
        title = 'Shopping Cart',
        options = options
    })
end

-- Remove item from cart
function RemoveFromCart(index)
    table.remove(cart, index)
    ViewCart()
end

-- Checkout
function Checkout()
    local total = 0
    for _, item in ipairs(cart) do
        total = total + (item.price * item.quantity)
    end
    
    local tax = total * Config.Economy.Shops.TaxRate
    local grandTotal = total + tax
    
    ShowConfirmDialog({
        title = 'Confirm Purchase',
        message = 'Total: ' .. FormatMoney(grandTotal) .. ' (incl. tax)',
        confirmText = 'Pay',
        cancelText = 'Cancel',
        callback = function(values, confirmed)
            if confirmed then
                -- Check if player has enough money
                local playerData = GetPlayerData()
                local cash = playerData.money.cash or 0
                
                if grandTotal > cash then
                    SendNotification({
                        notificationType = 'error',
                        message = 'Insufficient cash'
                    })
                    return
                end
                
                -- Process purchase
                TriggerServerEvent('phantom:server:purchaseItems', cart, grandTotal, currentShop.id)
                
                cart = {}
                SendNotification({
                    notificationType = 'success',
                    message = 'Purchase completed!'
                })
                CloseMenu()
            end
        end
    })
end

-- Handle menu selection
RegisterNUICallback('menuItemSelected', function(data, cb)
    if data.args.type == 'category' then
        OpenCategoryMenu(data.args.name)
    elseif data.args.type == 'add' then
        AddToCart(data.args.item)
    elseif data.args.type == 'cart' then
        ViewCart()
    elseif data.args.type == 'remove' then
        RemoveFromCart(data.args.index)
    elseif data.args.type == 'checkout' then
        Checkout()
    elseif data.args.type == 'back' then
        OpenShopMenu(currentShop.id)
    end
    cb({})
end)

-- Shop interaction thread
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        
        for i, shop in ipairs(shops) do
            local distance = #(coords - shop.coords)
            
            if distance < 5.0 then
                DrawMarker(36, shop.coords, vec3(0.5, 0.5, 0.5), {r = 0, g = 200, b = 100, a = 100})
                
                if distance < 2.0 then
                    Draw3DText(shop.coords, '[E] ' .. shop.name, 0.5, 4)
                    
                    if IsControlJustPressed(0, 38) then -- E key
                        OpenShopMenu(i)
                    end
                end
            end
        end
        
        Wait(0)
    end
end)

-- Register command
RegisterCommand('shop', function()
    -- Find nearest shop
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local nearestShop = nil
    local nearestDistance = 9999.0
    
    for i, shop in ipairs(shops) do
        local distance = #(coords - shop.coords)
        if distance < nearestDistance then
            nearestDistance = distance
            nearestShop = i
        end
    end
    
    if nearestShop and nearestDistance < 50.0 then
        OpenShopMenu(nearestShop)
    else
        SendNotification({
            notificationType = 'error',
            message = 'No shop nearby'
        })
    end
end)

-- Server event
RegisterNetEvent('phantom:client:purchaseComplete', function()
    SendNotification({
        notificationType = 'success',
        message = 'Items added to your inventory'
    })
end)

-- Export functions
exports('OpenShopMenu', OpenShopMenu)

DebugPrint('Shop system loaded')
