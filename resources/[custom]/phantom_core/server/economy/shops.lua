-- Phantom Core - Shop System (Server)
-- Server-side shop logic
local Shops = {
    general = { categories = { 'Food', 'Drinks', 'Electronics' } },
    liquor = { categories = { 'Drinks', 'Food' } },
    police = { categories = { 'Medical', 'Electronics' } },
    gas = { categories = { 'Food', 'Drinks' } },
}

local ShopItems = {
    Food = {
        bread = 5,
        water = 3,
        apple = 2,
        sandwich = 8,
        burger = 12,
    },
    Drinks = {
        cola = 4,
        coffee = 5,
        beer = 7,
        wine = 15,
    },
    Medical = {
        bandage = 25,
        medkit = 100,
        painkillers = 50,
    },
    Electronics = {
        phone = 500,
        radio = 150,
        camera = 300,
    },
    Clothing = {
        tshirt = 25,
        pants = 35,
        shoes = 45,
    },
}

local function shopCatalog(shopId)
    local shop = Shops[shopId]
    if not shop then return nil end

    local catalog = {}
    for _, category in ipairs(shop.categories) do
        for itemName, price in pairs(ShopItems[category] or {}) do
            catalog[itemName] = price
        end
    end
    return catalog
end

local function processPurchase(source, cart, shopId)
    local citizenid = GetCitizenId(source)
    if not citizenid then return { success = false, message = 'Player data not found' } end

    local catalog = shopCatalog(shopId)
    if not catalog or type(cart) ~= 'table' then
        return { success = false, message = 'Invalid shop' }
    end

    local playerData = GetPlayerDataByCitizenId(citizenid)
    if not playerData then return { success = false, message = 'Player data not found' } end

    local sanitizedCart = {}
    local subtotal = 0
    for _, item in ipairs(cart) do
        local name = type(item) == 'table' and item.name
        local price = name and catalog[name]
        local quantity = math.floor(tonumber(item and item.quantity) or 0)
        if not price or quantity < 1 or quantity > 100 then
            return { success = false, message = 'Invalid cart item' }
        end

        subtotal = subtotal + (price * quantity)
        sanitizedCart[#sanitizedCart + 1] = {
            name = name,
            price = price,
            quantity = quantity,
        }
    end

    if subtotal <= 0 then
        return { success = false, message = 'Cart is empty' }
    end

    local total = math.ceil(subtotal * (1 + Config.Economy.Shops.TaxRate))
    local cash = playerData.money.cash or 0

    if total > cash then
        return { success = false, message = 'Insufficient cash' }
    end

    -- Deduct money
    local newCash = cash - total

    MySQL.query([[
        UPDATE players 
        SET money = JSON_SET(money, '$.cash', ?)
        WHERE citizenid = ?
    ]], { newCash, citizenid })

    -- Add items to inventory (would integrate with ox_inventory)
    for _, item in ipairs(sanitizedCart) do
        for i = 1, item.quantity do
            -- This would call ox_inventory to add item
            -- exports.ox_inventory:AddItem(source, item.name, 1)
        end
    end
    
    -- Record purchase
    MySQL.query([[
        INSERT INTO phantom_purchases (citizenid, shop_id, items, total)
        VALUES (?, ?, ?, ?)
    ]], { citizenid, shopId, json.encode(sanitizedCart), total })

    TriggerClientEvent('phantom:client:purchaseComplete', source)

    return { success = true, cash = newCash }
end

-- Process purchase
RegisterNetEvent('phantom:server:purchaseItems', function(cart, _total, shopId)
    processPurchase(source, cart, shopId)
end)

lib.callback.register('phantom:server:purchaseItems', function(source, cart, _total, shopId)
    return processPurchase(source, cart, shopId)
end)

DebugPrint('Shop server loaded')
