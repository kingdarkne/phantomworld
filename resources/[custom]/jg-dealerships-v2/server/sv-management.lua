local function FulfillOrder(order)

  MySQL.update.await("UPDATE dealership_orders SET fulfilled = ? WHERE id = ?", {1, order.id})

  if order.cost and order.cost > 0 then

    DealershipBalance.Server.Remove(order.dealership, order.cost)

    DebugPrint("Order cost deducted from dealership balance: $" .. order.cost, "debug", order)

  end

  MySQL.update.await("UPDATE dealership_stock SET stock = stock + ? WHERE dealership = ? AND vehicle = ?", 

    {order.quantity, order.dealership, order.vehicle})

  Showroom.Server.UpdateVehicleCache(order.vehicle, order.dealership)

  DebugPrint("Order fulfilled: " .. order.id, "debug", order)

end

lib.callback.register("jg-dealerships:server:get-dealership-balance", function(playerId, dealershipId)

  if not Employees.Server.IsEmployee(playerId, dealershipId, "MANAGE_FINANCES") then

    Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")

    return {error = true}

  end

  local balance = DealershipBalance.Server.GetBalance(dealershipId)

  if balance == nil then

    return {error = true}

  end

  return {balance = balance}

end)

lib.callback.register("jg-dealerships:server:get-dealership-vehicles", function(playerId, data)

  local dealershipId = data.dealershipId

  if not Employees.Server.IsEmployee(playerId, dealershipId, "MANAGE_INVENTORY") then

    Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")

    return {error = true}

  end

  return MySQL.rawExecute.await([[

    SELECT vehicle.*, 

           stock.stock as stock, 

           stock.price as list_price,

           COALESCE((SELECT SUM(quantity) FROM dealership_orders WHERE dealership_orders.vehicle = vehicle.spawn_code), 0) AS global_stock_ordered

    FROM dealership_vehicles vehicle 

    INNER JOIN dealership_stock stock ON vehicle.spawn_code = stock.vehicle 

    WHERE stock.dealership = ? 

    ORDER BY vehicle.spawn_code ASC

  ]], {dealershipId})

end)

lib.callback.register("jg-dealerships:server:get-dealership-display-vehicles", function(playerId, data)

  local dealershipId = data.dealershipId

  if not Employees.Server.IsEmployee(playerId, dealershipId, "MANAGE_INVENTORY") then

    Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")

    return {error = true}

  end

  local displayVehicles = MySQL.query.await(

    "SELECT dispveh.*, vehicle.brand, vehicle.model FROM dealership_dispveh dispveh INNER JOIN dealership_vehicles vehicle ON vehicle.spawn_code = dispveh.vehicle WHERE dispveh.dealership = ?;",

    {dealershipId}

  )

  for index, vehicle in ipairs(displayVehicles) do

    displayVehicles[index].color = json.decode(vehicle.color)

  end

  return displayVehicles

end)

lib.callback.register("jg-dealerships:server:get-dealership-orders", function(playerId, data)

  local dealershipId = data.dealershipId

  local page = data.page or 0

  local limit = data.limit or 10

  local searchQuery = data.searchQuery or ""

  local isEmployee = Employees.Server.IsEmployee(playerId, dealershipId, {"VIEW_RECORDS", "DELIVER"})

  if not isEmployee then

    Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")

    return {error = true}

  end

  local searchCondition = ""

  local searchParams = {}

  if searchQuery and searchQuery ~= "" then

    searchCondition, searchParams = SearchHelpers.BuildSearchConditions(

      searchQuery,

      {"orders.vehicle", "vehicle.brand", "vehicle.model"},

      "orders.order_created",

      {{"vehicle.brand", "vehicle.model"}}

    )

  end

  local baseQuery = "SELECT orders.*, vehicle.brand, vehicle.model FROM dealership_orders orders INNER JOIN dealership_vehicles vehicle ON orders.vehicle = vehicle.spawn_code WHERE orders.dealership = ?"

  local countQuery = "SELECT COUNT(*) FROM dealership_orders orders INNER JOIN dealership_vehicles vehicle ON orders.vehicle = vehicle.spawn_code WHERE orders.dealership = ?"

  local queryParams = {dealershipId}

  local countParams = {dealershipId}

  if searchCondition ~= "" then

    baseQuery = baseQuery .. " AND " .. searchCondition

    countQuery = countQuery .. " AND " .. searchCondition

    for _, param in ipairs(searchParams) do

      table.insert(queryParams, param)

      table.insert(countParams, param)

    end

  end

  baseQuery = baseQuery .. " ORDER BY orders.order_created DESC LIMIT ? OFFSET ?"

  table.insert(queryParams, limit)

  table.insert(queryParams, page * limit)

  local orders = MySQL.query.await(baseQuery, queryParams) or {}

  for index, order in ipairs(orders) do

    orders[index].time_remaining = order.delivery_time - os.time()

    orders[index].hasActiveDelivery = false

    orders[index].inTransitQuantity = 0

    if TruckingMission and TruckingMission.Server and TruckingMission.Server.IsOrderBeingDelivered then

      local isBeingDelivered, inTransitQty = TruckingMission.Server.IsOrderBeingDelivered(order.id)

      orders[index].hasActiveDelivery = isBeingDelivered

      orders[index].inTransitQuantity = inTransitQty or 0

      if orders[index].hasActiveDelivery and TruckingMission.Server.GetActiveDeliveryInfo then

        local deliveryInfo = TruckingMission.Server.GetActiveDeliveryInfo(order.id)

        if deliveryInfo then

          orders[index].active_delivery_started_at = deliveryInfo.startedAt

          orders[index].active_delivery_started_by = deliveryInfo.startedByName

          orders[index].delivery_pickup_location = deliveryInfo.pickupLocation

        end

      end

    end

    if order.fulfilled and order.delivered_by then

      local delivererInfo = Framework.Server.GetPlayerInfoFromIdentifier(order.delivered_by)

      orders[index].delivered_by_name = (delivererInfo and delivererInfo.name) or order.delivered_by

    end

    if order.ordered_by then

      local ordererInfo = Framework.Server.GetPlayerInfoFromIdentifier(order.ordered_by)

      orders[index].ordered_by_name = (ordererInfo and ordererInfo.name) or order.ordered_by

    end

  end

  local total = MySQL.scalar.await(countQuery, countParams)

  return {

    orders = orders,

    total = total

  }

end)

lib.callback.register("jg-dealerships:server:get-dealership-sales", function(playerId, data)

  local dealershipId = data.dealershipId

  local page = data.page or 0

  local limit = data.limit or 10

  local searchQuery = data.searchQuery or ""

  local purchaseTypeFilter = data.purchaseTypeFilter

  local isEmployee = Employees.Server.IsEmployee(playerId, dealershipId, "VIEW_RECORDS")

  if not isEmployee then

    Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")

    return {error = true}

  end

  local searchCondition = ""

  local searchParams = {}

  if searchQuery and searchQuery ~= "" then

    local playerNameExpression = Framework.Server.GetPlayerNameSearchExpression("sales.player")

    local sellerNameExpression = Framework.Server.GetPlayerNameSearchExpression("sales.seller")

    searchCondition, searchParams = SearchHelpers.BuildSearchConditions(

      searchQuery,

      {"sales.vehicle", "vehicle.brand", "vehicle.model", playerNameExpression, sellerNameExpression},

      "sales.created_at",

      {{"vehicle.brand", "vehicle.model"}}

    )

  end

  local baseQuery = "SELECT sales.*, vehicle.brand, vehicle.model FROM dealership_sales sales INNER JOIN dealership_vehicles vehicle ON sales.vehicle = vehicle.spawn_code WHERE sales.dealership = ?"

  local countQuery = "SELECT COUNT(*) FROM dealership_sales sales INNER JOIN dealership_vehicles vehicle ON sales.vehicle = vehicle.spawn_code WHERE sales.dealership = ?"

  local queryParams = {dealershipId}

  local countParams = {dealershipId}

  if purchaseTypeFilter and purchaseTypeFilter ~= "all" then

    baseQuery = baseQuery .. " AND sales.purchase_type = ?"

    countQuery = countQuery .. " AND sales.purchase_type = ?"

    table.insert(queryParams, purchaseTypeFilter)

    table.insert(countParams, purchaseTypeFilter)

  end

  if searchCondition ~= "" then

    baseQuery = baseQuery .. " AND " .. searchCondition

    countQuery = countQuery .. " AND " .. searchCondition

    for _, param in ipairs(searchParams) do

      table.insert(queryParams, param)

      table.insert(countParams, param)

    end

  end

  baseQuery = baseQuery .. " ORDER BY sales.created_at DESC LIMIT ? OFFSET ?"

  table.insert(queryParams, limit)

  table.insert(queryParams, page * limit)

  local sales = MySQL.query.await(baseQuery, queryParams) or {}

  for index, sale in ipairs(sales) do

    local playerInfo = Framework.Server.GetPlayerInfoFromIdentifier(sale.player)

    sales[index].player_name = (playerInfo and playerInfo.name) or "-"

    local sellerInfo = Framework.Server.GetPlayerInfoFromIdentifier(sale.seller)

    sales[index].seller_name = (sellerInfo and sellerInfo.name) or "-"

  end

  local total = MySQL.scalar.await(countQuery, countParams)

  return {

    sales = sales,

    total = total

  }

end)

lib.callback.register("jg-dealerships:server:get-dealership-homepage-stats", function(playerId, data)

  local dealershipId = data.dealershipId

  local isEmployee = Employees.Server.IsEmployee(playerId, dealershipId, "VIEW_RECORDS")

  if not isEmployee then

    Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")

    return {error = true}

  end

  local stats = MySQL.single.await([[

    SELECT 

      COALESCE(SUM(CASE WHEN DATE(created_at) = CURDATE() THEN paid ELSE 0 END), 0) as today_total,

      COUNT(CASE WHEN DATE(created_at) = CURDATE() THEN 1 END) as today_count,

      COALESCE(SUM(CASE WHEN DATE(created_at) = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN paid ELSE 0 END), 0) as yesterday_total,

      COUNT(CASE WHEN DATE(created_at) = DATE_SUB(CURDATE(), INTERVAL 1 DAY) THEN 1 END) as yesterday_count,

      COALESCE(SUM(CASE WHEN YEAR(created_at) = YEAR(CURDATE()) AND MONTH(created_at) = MONTH(CURDATE()) THEN paid ELSE 0 END), 0) as this_month_total,

      COUNT(CASE WHEN YEAR(created_at) = YEAR(CURDATE()) AND MONTH(created_at) = MONTH(CURDATE()) THEN 1 END) as this_month_count,

      COALESCE(SUM(CASE WHEN YEAR(created_at) = YEAR(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) AND MONTH(created_at) = MONTH(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) THEN paid ELSE 0 END), 0) as last_month_total,

      COUNT(CASE WHEN YEAR(created_at) = YEAR(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) AND MONTH(created_at) = MONTH(DATE_SUB(CURDATE(), INTERVAL 1 MONTH)) THEN 1 END) as last_month_count,

      COALESCE(SUM(paid), 0) as all_time_total,

      COUNT(*) as all_time_count

    FROM dealership_sales 

    WHERE dealership = ?

  ]], {dealershipId})

  local recentSales = MySQL.query.await([[

    SELECT 

      sales.vehicle as model,

      sales.paid as price,

      sales.purchase_type as purchase_type,

      vehicle.brand,

      vehicle.model as vehicle_name

    FROM dealership_sales sales

    INNER JOIN dealership_vehicles vehicle ON sales.vehicle = vehicle.spawn_code

    WHERE sales.dealership = ?

    ORDER BY sales.created_at DESC

    LIMIT 5

  ]], {dealershipId})

  if not stats then

    stats = {

      today_total = 0,

      today_count = 0,

      yesterday_total = 0,

      yesterday_count = 0,

      this_month_total = 0,

      this_month_count = 0,

      last_month_total = 0,

      last_month_count = 0,

      all_time_total = 0,

      all_time_count = 0

    }

  end

  local yesterdayComparison = 0

  if stats.yesterday_count > 0 then

    yesterdayComparison = ((stats.today_count - stats.yesterday_count) / stats.yesterday_count) * 100

  elseif stats.today_count > 0 then

    yesterdayComparison = 100

  end

  local lastMonthComparison = 0

  if stats.last_month_count > 0 then

    lastMonthComparison = ((stats.this_month_count - stats.last_month_count) / stats.last_month_count) * 100

  elseif stats.this_month_count > 0 then

    lastMonthComparison = 100

  end

  return {

    today = {

      amount = stats.today_total,

      count = stats.today_count

    },

    yesterdayComparison = yesterdayComparison,

    thisMonth = {

      amount = stats.this_month_total,

      count = stats.this_month_count

    },

    lastMonthComparison = lastMonthComparison,

    allTime = {

      amount = stats.all_time_total,

      count = stats.all_time_count

    },

    recentSales = recentSales

  }

end)

lib.callback.register("jg-dealerships:server:get-dealership-graph-data", function(playerId, data)

  local dealershipId = data.dealershipId

  local dateRange = data.dateRange

  local metric = data.metric

  local isEmployee = Employees.Server.IsEmployee(playerId, dealershipId, "VIEW_RECORDS")

  if not isEmployee then

    Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")

    return {error = true}

  end

  local graphData = {}

  local aggregateFunc = (metric == "volume") and "SUM(sales.paid)" or "COUNT(sales.id)"

  if dateRange == "7days" then

    graphData = MySQL.query.await([[

      WITH RECURSIVE dates AS (

        SELECT DATE_SUB(CURDATE(), INTERVAL 6 DAY) as date

        UNION ALL

        SELECT DATE_ADD(date, INTERVAL 1 DAY)

        FROM dates

        WHERE date < CURDATE()

      )

      SELECT 

        CAST(DATE_FORMAT(dates.date, '%Y-%m-%d') AS CHAR) as date,

        COALESCE(]] .. aggregateFunc .. [[, 0) as value

      FROM dates

      LEFT JOIN dealership_sales sales 

        ON DATE(sales.created_at) = dates.date 

        AND sales.dealership = ?

      GROUP BY dates.date

      ORDER BY dates.date ASC

    ]], {dealershipId})

  elseif dateRange == "month" then

    graphData = MySQL.query.await([[

      WITH RECURSIVE dates AS (

        SELECT DATE_SUB(CURDATE(), INTERVAL 29 DAY) as date

        UNION ALL

        SELECT DATE_ADD(date, INTERVAL 1 DAY)

        FROM dates

        WHERE date < CURDATE()

      )

      SELECT 

        CAST(DATE_FORMAT(dates.date, '%Y-%m-%d') AS CHAR) as date,

        COALESCE(]] .. aggregateFunc .. [[, 0) as value

      FROM dates

      LEFT JOIN dealership_sales sales 

        ON DATE(sales.created_at) = dates.date 

        AND sales.dealership = ?

      GROUP BY dates.date

      ORDER BY dates.date ASC

    ]], {dealershipId})

  elseif dateRange == "6months" then

    graphData = MySQL.query.await([[

      WITH RECURSIVE months AS (

        SELECT 0 as n, DATE_SUB(DATE_FORMAT(CURDATE(), '%Y-%m-01'), INTERVAL 5 MONTH) as month_start

        UNION ALL

        SELECT n + 1, DATE_ADD(month_start, INTERVAL 1 MONTH)

        FROM months

        WHERE n < 5

      )

      SELECT 

        CAST(DATE_FORMAT(months.month_start, '%Y-%m') AS CHAR) as date,

        COALESCE(]] .. aggregateFunc .. [[, 0) as value

      FROM months

      LEFT JOIN dealership_sales sales 

        ON DATE_FORMAT(sales.created_at, '%Y-%m') = DATE_FORMAT(months.month_start, '%Y-%m')

        AND sales.dealership = ?

      GROUP BY DATE_FORMAT(months.month_start, '%Y-%m'), months.n

      ORDER BY months.n ASC

    ]], {dealershipId})

  elseif dateRange == "year" then

    graphData = MySQL.query.await([[

      WITH RECURSIVE months AS (

        SELECT 0 as n, DATE_SUB(DATE_FORMAT(CURDATE(), '%Y-%m-01'), INTERVAL 11 MONTH) as month_start

        UNION ALL

        SELECT n + 1, DATE_ADD(month_start, INTERVAL 1 MONTH)

        FROM months

        WHERE n < 11

      )

      SELECT 

        CAST(DATE_FORMAT(months.month_start, '%Y-%m') AS CHAR) as date,

        COALESCE(]] .. aggregateFunc .. [[, 0) as value

      FROM months

      LEFT JOIN dealership_sales sales 

        ON DATE_FORMAT(sales.created_at, '%Y-%m') = DATE_FORMAT(months.month_start, '%Y-%m')

        AND sales.dealership = ?

      GROUP BY DATE_FORMAT(months.month_start, '%Y-%m'), months.n

      ORDER BY months.n ASC

    ]], {dealershipId})

  else

    return {

      error = true,

      message = "Invalid date range"

    }

  end

  return {

    data = graphData or {},

    dateRange = dateRange,

    metric = metric

  }

end)

lib.callback.register("jg-dealerships:server:order-vehicle", function(playerId, dealershipId, vehicle, quantity, sizeCategory)

  print("^3========== [ORDER DEBUG] START ==========^0")

  print("^3[ORDER DEBUG] Parameters received:^0")

  print("^3[ORDER DEBUG]   - playerId: " .. tostring(playerId) .. "^0")

  print("^3[ORDER DEBUG]   - dealershipId: " .. tostring(dealershipId) .. "^0")

  print("^3[ORDER DEBUG]   - vehicle: " .. tostring(vehicle) .. "^0")

  print("^3[ORDER DEBUG]   - quantity: " .. tostring(quantity) .. "^0")

  print("^3[ORDER DEBUG]   - sizeCategory: " .. tostring(sizeCategory) .. "^0")

  print("^3[ORDER DEBUG] Checking employee permissions for MANAGE_INVENTORY...^0")

  local isEmployee = Employees.Server.IsEmployee(playerId, dealershipId, "MANAGE_INVENTORY")

  print("^3[ORDER DEBUG] isEmployee result: " .. tostring(isEmployee) .. "^0")

  if not isEmployee then

    print("^1[ORDER DEBUG] FAILED - Not an employee or no MANAGE_INVENTORY permission^0")

    Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")

    return {error = true}

  end

  print("^2[ORDER DEBUG] ✓ Employee permission check passed^0")

  print("^3[ORDER DEBUG] Fetching vehicle data from database...^0")

  local vehicleData = MySQL.single.await(

    "SELECT price, unlimited_stock, global_stock_limit FROM dealership_vehicles WHERE spawn_code = ?",

    {vehicle}

  )

  print("^3[ORDER DEBUG] Vehicle data: " .. json.encode(vehicleData or {}) .. "^0")

  if not vehicleData then

    print("^1[ORDER DEBUG] FAILED - Vehicle not found in database^0")

    return {error = true}

  end

  print("^2[ORDER DEBUG] ✓ Vehicle data retrieved^0")

  if not sizeCategory or (sizeCategory ~= "small" and sizeCategory ~= "medium" and sizeCategory ~= "large") then

    sizeCategory = "medium"

  end

  if not vehicleData.unlimited_stock or vehicleData.unlimited_stock == 0 then

    local orderedStock = MySQL.scalar.await(

      "SELECT COALESCE(SUM(quantity), 0) FROM dealership_orders WHERE vehicle = ?",

      {vehicle}

    )

    local globalStockLimit = vehicleData.global_stock_limit or 0

    local remainingStock = globalStockLimit - orderedStock

    if remainingStock <= 0 then

      Framework.Server.Notify(playerId, Locale.globalStockLimitReached, "error")

      return {

        error = true,

        stockLimitReached = true

      }

    end

    if quantity > remainingStock then

      Framework.Server.Notify(playerId, string.gsub(Locale.globalStockLimitExceeded, "%%{value}", remainingStock), "error")

      return {

        error = true,

        stockLimitReached = true,

        remainingStock = remainingStock

      }

    end

  end

  local totalCost = vehicleData.price * Config.DealerPurchasePrice * quantity

  local deliveryTime = os.time() + (Config.VehicleOrderTime * 60)

  print("^3[ORDER DEBUG] Cost calculation:^0")

  print("^3[ORDER DEBUG]   - Vehicle price: $" .. vehicleData.price .. "^0")

  print("^3[ORDER DEBUG]   - Purchase multiplier: " .. Config.DealerPurchasePrice .. "^0")

  print("^3[ORDER DEBUG]   - Quantity: " .. quantity .. "^0")

  print("^3[ORDER DEBUG]   - Total cost: $" .. totalCost .. "^0")

  print("^3[ORDER DEBUG] Checking dealership balance...^0")

  local hasFunds, currentBalance = DealershipBalance.Server.HasFunds(dealershipId, totalCost)

  print("^3[ORDER DEBUG] Balance check result: hasFunds=" .. tostring(hasFunds) .. ", currentBalance=$" .. tostring(currentBalance) .. "^0")

  DebugPrint("Order vehicle - Balance check", "debug", {

    dealership = dealershipId,

    vehicle = vehicle,

    quantity = quantity,

    totalCost = totalCost,

    currentBalance = currentBalance,

    hasFunds = hasFunds

  })

  if not hasFunds then

    print("^1[ORDER DEBUG] FAILED - Insufficient funds (required: $" .. totalCost .. ", available: $" .. tostring(currentBalance) .. ")^0")

    Framework.Server.Notify(playerId, Locale.dealershipNotEnoughFunds, "error")

    DebugPrint("Order failed - Insufficient funds", "warning", {

      dealership = dealershipId,

      required = totalCost,

      available = currentBalance

    })

    return {error = true, insufficientFunds = true}

  end

  print("^2[ORDER DEBUG] ✓ Dealership has sufficient funds^0")

  print("^3[ORDER DEBUG] Removing $" .. totalCost .. " from dealership balance...^0")

  local success, errorMsg = DealershipBalance.Server.Remove(dealershipId, totalCost)

  print("^3[ORDER DEBUG] Remove funds result: success=" .. tostring(success) .. ", error=" .. tostring(errorMsg) .. "^0")

  if not success then

    print("^1[ORDER DEBUG] FAILED - Could not remove funds from dealership^0")

    Framework.Server.Notify(playerId, errorMsg or Locale.dealershipNotEnoughFunds, "error")

    DebugPrint("Order failed - Could not remove funds", "warning", {

      dealership = dealershipId,

      amount = totalCost,

      error = errorMsg

    })

    return {error = true}

  end

  print("^2[ORDER DEBUG] ✓ Funds removed successfully^0")

  local identifier = Framework.Server.GetPlayerIdentifier(playerId)

  print("^3[ORDER DEBUG] Player identifier: " .. tostring(identifier) .. "^0")

  print("^3[ORDER DEBUG] Inserting order into database...^0")

  local orderId = MySQL.insert.await(

    "INSERT INTO dealership_orders (vehicle, dealership, quantity, cost, delivery_time, ordered_by, size_category) VALUES(?, ?, ?, ?, ?, ?, ?)",

    {vehicle, dealershipId, quantity, totalCost, deliveryTime, identifier, sizeCategory}

  )

  print("^3[ORDER DEBUG] Database insert result: orderId=" .. tostring(orderId) .. "^0")

  if not orderId then

    print("^1[ORDER DEBUG] FAILED - Database insert returned nil, refunding dealership^0")

    DealershipBalance.Server.Add(dealershipId, totalCost)

    Framework.Server.Notify(playerId, "Failed to create order - database error", "error")

    DebugPrint("Order creation failed - Database insert returned nil", "warning", {

      dealership = dealershipId,

      vehicle = vehicle,

      quantity = quantity

    })

    return {error = true, databaseError = true}

  end

  print("^2[ORDER DEBUG] ✓ Order inserted into database with ID: " .. orderId .. "^0")

  DebugPrint("Order created successfully", "debug", {

    orderId = orderId,

    vehicle = vehicle,

    quantity = quantity,

    cost = totalCost

  })

  DealershipBalance.Server.Add(dealershipId, totalCost)

  Framework.Server.Notify(playerId, Locale.dealershipVehiclesOrdered, "success")

  SendWebhook(playerId, Webhooks.Dealership, "Dealership: Vehicle(s) Ordered", "success", {

    {key = "Dealership", value = dealershipId},

    {key = "Vehicle", value = vehicle},

    {key = "Quantity", value = quantity},

    {key = "Total Price", value = totalCost}

  })

  if Config.VehicleOrderTime == 0 then

    FulfillOrder({

      id = orderId,

      quantity = quantity,

      dealership = dealershipId,

      vehicle = vehicle

    })

  end

  local createdOrder = MySQL.single.await(

    "SELECT orders.*, vehicle.brand, vehicle.model FROM dealership_orders orders INNER JOIN dealership_vehicles vehicle ON orders.vehicle = vehicle.spawn_code WHERE orders.id = ?",

    {orderId}

  )

  if not createdOrder then

    DebugPrint("Warning: Order created but couldn't retrieve order data", "warning", {

      orderId = orderId,

      dealership = dealershipId

    })

    return {

      error = false,

      orderId = orderId,

      message = "Order created but couldn't fetch details"

    }

  end

  DebugPrint("Order retrieval successful", "debug", {

    orderId = orderId,

    vehicle = createdOrder.vehicle

  })

  print("^2========== [ORDER DEBUG] SUCCESS - Order #" .. orderId .. " created ==========^0")

  return createdOrder

end)

lib.callback.register("jg-dealerships:server:cancel-vehicle-order", function(playerId, data)

  local orderId = type(data) == "table" and data.orderId or data

  local order = MySQL.single.await("SELECT * FROM dealership_orders WHERE id = ?", {orderId})

  if not order then

    return {error = true}

  end

  local isEmployee = Employees.Server.IsEmployee(playerId, order.dealership, "MANAGE_INVENTORY")

  if not isEmployee then

    Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")

    return {error = true}

  end

  MySQL.query.await("DELETE FROM dealership_orders WHERE id = ?", {orderId})

  DealershipBalance.Server.Add(order.dealership, order.cost)

  Framework.Server.Notify(playerId, Locale.dealershipOrderCancelled, "success")

  SendWebhook(playerId, Webhooks.Dealership, "Dealership: Order Cancelled", "danger", {

    {key = "Dealership", value = order.dealership},

    {key = "Vehicle", value = order.vehicle},

    {key = "Quantity", value = order.quantity},

    {key = "Amount Refunded", value = order.cost}

  })

  return true

end)

lib.callback.register("jg-dealerships:server:get-delivery-info", function(playerId, data)

  local orderId = data.orderId

  local dealershipId = data.dealershipId

  if not Employees.Server.IsEmployee(playerId, dealershipId, "DELIVER") then

    Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")

    return false

  end

  local success, errorMsg, deliveryInfo = TruckingMission.Server.GetDeliveryInfo(orderId, dealershipId)

  if not success or not deliveryInfo then

    Framework.Server.Notify(playerId, errorMsg or Locale.failedToPrepareDelivery, "error")

    return false

  end

  return {

    pickupLocation = deliveryInfo.name,

    pickupCoords = deliveryInfo.coords

  }

end)

lib.callback.register("jg-dealerships:server:deliver-vehicle", function(playerId, data)

  local orderId = data.orderId

  local dealershipId = data.dealershipId

  if not Employees.Server.IsEmployee(playerId, dealershipId, "DELIVER") then

    Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")

    return false

  end

  local order = MySQL.single.await(

    "SELECT * FROM dealership_orders WHERE id = ? AND dealership = ? AND fulfilled = 0",

    {orderId, dealershipId}

  )

  if not order then

    Framework.Server.Notify(playerId, Locale.orderNotFoundOrFulfilled, "error")

    return false

  end

  local remainingQuantity = order.quantity - (order.delivered or 0)

  local sizeCategory = order.size_category or "medium"

  local deliveryType = (sizeCategory == "large") and "container" or "car"

  local success, errorMsg, deliveryConfig = TruckingMission.Server.StartDelivery(

    playerId,

    dealershipId,

    deliveryType,

    {orderId},

    {[orderId] = remainingQuantity}

  )

  if not success or not deliveryConfig then

    Framework.Server.Notify(playerId, errorMsg or Locale.failedToPrepareDelivery, "error")

    return false

  end

  if not TruckingMission.Server.RegisterDelivery(playerId, dealershipId, deliveryConfig.configHash) then

    return false

  end

  SendWebhook(playerId, Webhooks.Dealership, "Dealership: Delivery Started", "info", {

    {key = "Dealership", value = dealershipId},

    {key = "Order ID", value = orderId},

    {key = "Vehicle", value = order.vehicle},

    {key = "Quantity", value = remainingQuantity}

  })

  return true

end)

lib.callback.register("jg-dealerships:server:generate-delivery-config", function(playerId, dealershipId, trailerType, orderIds, quantities)

  if not Employees.Server.IsEmployee(playerId, dealershipId, "DELIVER") then

    Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")

    return false, "Permission denied", nil

  end

  return TruckingMission.Server.GenerateDeliveryConfiguration(playerId, dealershipId, trailerType, orderIds, quantities)

end)

lib.callback.register("jg-dealerships:server:get-pending-delivery-config", function(playerId)

  local config = TruckingMission.Server.GetPendingConfiguration(playerId)

  return config

end)

lib.callback.register("jg-dealerships:server:start-trucking-mission", function(playerId, dealershipId, trailerType, orderIds, quantities, configHash)

  if not Employees.Server.IsEmployee(playerId, dealershipId, "DELIVER") then

    Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")

    return { success = false, error = "Permission denied" }

  end

  local success, errorMsg, missionData = TruckingMission.Server.StartDeliveryMission(playerId, dealershipId, trailerType, orderIds, quantities, configHash)

  if not success then

    return { success = false, error = errorMsg }

  end

  SendWebhook(playerId, Webhooks.Dealership, "Dealership: Multi-Order Delivery Started", "info", {

    {key = "Dealership", value = dealershipId}

  })

  return { success = true, data = missionData }

end)

lib.callback.register("jg-dealerships:server:dealership-deposit", function(playerId, dealershipId, currency, amount)

  print("[DEBUG] dealership-deposit called - dealershipId:", dealershipId, "currency:", currency, "amount:", amount)

  if not amount or type(amount) ~= "number" then

    Framework.Server.Notify(playerId, "Invalid amount provided", "error")

    return {error = true}

  end

  local isEmployee = Employees.Server.IsEmployee(playerId, dealershipId, "MANAGE_FINANCES")

  if not isEmployee then

    Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")

    return {error = true}

  end

  if amount < 0 then

    Framework.Server.Notify(playerId, Locale.exploitAttemptDetected, "error")

    return false

  end

  local playerBalance = Framework.Server.GetPlayerBalance(playerId, currency)

  if amount > playerBalance then

    Framework.Server.Notify(playerId, Locale.errorNotEnoughMoney, "error")

    return {error = true}

  end

  Framework.Server.PlayerRemoveMoney(playerId, amount, currency)

  local success, errorMsg = DealershipBalance.Server.Add(dealershipId, amount)

  if not success then

    Framework.Server.PlayerAddMoney(playerId, amount, currency)

    Framework.Server.Notify(playerId, errorMsg or Locale.failedToPrepareDelivery, "error")

    return {error = true}

  end

  Framework.Server.Notify(playerId, Locale.depositSuccess, "success")

  SendWebhook(playerId, Webhooks.Dealership, "Dealership: Money Deposited", nil, {

    {key = "Dealership", value = dealershipId},

    {key = "Amount", value = amount}

  })

  return true

end)

lib.callback.register("jg-dealerships:server:dealership-withdraw", function(playerId, dealershipId, amount)

  print("[DEBUG] dealership-withdraw called - dealershipId:", dealershipId, "amount:", amount)

  if not amount or type(amount) ~= "number" then

    Framework.Server.Notify(playerId, "Invalid amount provided", "error")

    return {error = true}

  end

  local isEmployee = Employees.Server.IsEmployee(playerId, dealershipId, "MANAGE_FINANCES")

  if not isEmployee then

    Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")

    return {error = true}

  end

  if amount < 0 then

    Framework.Server.Notify(playerId, Locale.exploitAttemptDetected, "error")

    return false

  end

  local success, errorMsg = DealershipBalance.Server.Remove(dealershipId, amount)

  print("[DEBUG] DealershipBalance.Server.Remove returned - success:", success, "errorMsg:", errorMsg)

  if not success then

    if errorMsg == "Dealership has no job configured" then

      Framework.Server.Notify(playerId, Locale.dealershipNoJobConfigured or "Dealership doesn't have job configuration", "error")

    else

      Framework.Server.Notify(playerId, errorMsg or Locale.dealershipNotEnoughFunds, "error")

    end

    return {error = true}

  end

  Framework.Server.PlayerAddMoney(playerId, amount, "bank")

  Framework.Server.Notify(playerId, Locale.withdrawSuccess, "success")

  SendWebhook(playerId, Webhooks.Dealership, "Dealership: Money Withdraw", nil, {

    {key = "Dealership", value = dealershipId},

    {key = "Amount", value = amount}

  })

  return true

end)

lib.callback.register("jg-dealerships:server:update-vehicle-price", function(playerId, data)

  local dealershipId = data.dealershipId

  local vehicle = data.vehicle

  local newPrice = data.newPrice

  local isEmployee = Employees.Server.IsEmployee(playerId, dealershipId, "MANAGE_INVENTORY")

  if not isEmployee then

    Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")

    return {error = true}

  end

  local vehicleData = MySQL.single.await(

    "SELECT price_limits_enabled, min_price, max_price FROM dealership_vehicles WHERE spawn_code = ?",

    {vehicle}

  )

  if vehicleData and vehicleData.price_limits_enabled == 1 then

    local minPrice = vehicleData.min_price

    local maxPrice = vehicleData.max_price

    if minPrice and newPrice < minPrice then

      Framework.Server.Notify(playerId, string.gsub(Locale.priceBelowMinimum, "%%{value}", minPrice), "error")

      return {error = true}

    end

    if maxPrice and newPrice > maxPrice then

      Framework.Server.Notify(playerId, string.gsub(Locale.priceAboveMaximum, "%%{value}", maxPrice), "error")

      return {error = true}

    end

  end

  MySQL.query.await(

    "UPDATE dealership_stock SET price = ? WHERE vehicle = ? AND dealership = ?",

    {newPrice, vehicle, dealershipId}

  )

  Showroom.Server.UpdateVehicleCache(vehicle, dealershipId)

  SendWebhook(playerId, Webhooks.Dealership, "Dealership: Vehicle Price Updated", nil, {

    {key = "Dealership", value = dealershipId},

    {key = "Vehicle", value = vehicle},

    {key = "New Price", value = newPrice}

  })

  return true

end)

lib.callback.register("jg-dealerships:server:admin-set-stock", function(playerId, data)

  local dealershipId = data.dealershipId

  local vehicle = data.vehicle

  local stock = data.stock

  if not Framework.Server.IsAdmin(playerId) then

    Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")

    return {error = true}

  end

  if type(stock) ~= "number" or stock < 0 then

    return {

      error = true,

      message = "Invalid stock value"

    }

  end

  MySQL.query.await(

    "UPDATE dealership_stock SET stock = ? WHERE vehicle = ? AND dealership = ?",

    {stock, vehicle, dealershipId}

  )

  Showroom.Server.UpdateVehicleCache(vehicle, dealershipId)

  Framework.Server.Notify(playerId, Locale.stockUpdated, "success")

  SendWebhook(playerId, Webhooks.Dealership, "Admin: Stock Quantity Set", nil, {

    {key = "Dealership", value = dealershipId},

    {key = "Vehicle", value = vehicle},

    {key = "New Stock", value = stock}

  })

  return {success = true}

end)

lib.callback.register("jg-dealerships:server:update-dealership-settings", function(playerId, data)

  local dealershipId = data.dealership or data.dealershipId

  local name = data.name

  local employeeCommission = data.employee_commission

  local isEmployee = Employees.Server.IsEmployee(playerId, dealershipId, "MANAGE_FINANCES")

  if not isEmployee then

    Framework.Server.Notify(playerId, Locale.employeePermissionsError, "error")

    return {error = true}

  end

  local location = Locations.Server.GetById(dealershipId)

  if not location then

    return {error = true, message = "Dealership not found"}

  end

  if name then

    location.name = name

  end

  if employeeCommission then

    location.employee_commission = employeeCommission

  end

  Locations.Server.Update(dealershipId, location)

  local updatedLocation = Locations.Server.GetById(dealershipId)

  TriggerClientEvent("jg-dealerships:client:update-location", -1, updatedLocation)

  Framework.Server.Notify(playerId, Locale.changesSaved, "success")

  SendWebhook(playerId, Webhooks.Dealership, "Dealership: Settings Updated", nil, {

    {key = "Dealership", value = dealershipId},

    {key = "New name", value = name}

  })

  return {success = true}

end)

if not Config.TruckingMissionForOrderDeliveries then

  lib.cron.new("* * * * *", function()

    local orders = MySQL.query.await(

      "SELECT * FROM dealership_orders WHERE delivery_time < UNIX_TIMESTAMP() AND fulfilled = 0"

    )

    for _, order in ipairs(orders) do

      FulfillOrder(order)

      Wait(250)

    end

  end)

end
