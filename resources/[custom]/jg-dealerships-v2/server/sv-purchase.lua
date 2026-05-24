local function purchaseVehicle(src, purchaseData)

  DebugPrint("=== PURCHASE VEHICLE ===", "debug")

  DebugPrint("Player: " .. tostring(src), "debug")

  DebugPrint("Dealership: " .. tostring(purchaseData.dealershipId), "debug")

  DebugPrint("Vehicle: " .. tostring(purchaseData.model), "debug")

  DebugPrint("Payment Method: " .. tostring(purchaseData.paymentMethod), "debug")

  DebugPrint("Finance: " .. tostring(purchaseData.finance), "debug")

  DebugPrint("Coupon: " .. tostring(purchaseData.couponCode or "none"), "debug")

  DebugPrint("========================", "debug")

  local dealership = Locations.Server.GetById(purchaseData.dealershipId)

  if not dealership then 

    DebugPrint("Dealership not found: " .. tostring(purchaseData.dealershipId), "warning")

    return false 

  end

  local pendingSale, sellerPlayer, sellerPlayerName = nil, nil, nil

  if purchaseData.directSaleUuid then

    pendingSale = DirectSales.Server.GetPending(purchaseData.directSaleUuid)

    if not pendingSale then return false end

    if src ~= pendingSale.playerId then return false end

    if pendingSale.dealerPlayerId then

      sellerPlayer = Framework.Server.GetPlayerIdentifier(pendingSale.dealerPlayerId)

      sellerPlayerName = Framework.Server.GetPlayerInfo(pendingSale.dealerPlayerId)

      sellerPlayerName = sellerPlayerName and sellerPlayerName.name or nil

    end

    purchaseData.finance = pendingSale.finance
  end

  if not dealership.enable_purchase and not purchaseData.directSaleUuid then

    DebugPrint(("Player %s attempted to purchase at dealership %s but purchases are disabled"):format(tostring(src), tostring(purchaseData.dealershipId)), "warning")

    return false

  end

  if not dealership.enable_finance and purchaseData.finance then return false end

  local dealershipPaymentMethods = dealership.payment_methods or {"bank", "cash"}

  local isValidPaymentMethod = lib.table.contains(dealershipPaymentMethods, purchaseData.paymentMethod) or purchaseData.paymentMethod == "societyFund"

  local currency = Currencies.Server.Get(purchaseData.paymentMethod)

  if not isValidPaymentMethod or (purchaseData.paymentMethod ~= "societyFund" and not currency) then

    Framework.Server.Notify(src, Locale.invalidPaymentMethod, "error")

    DebugPrint(("%s attempted to purchase a vehicle with an invalid payment method: %s"):format(tostring(src), purchaseData.paymentMethod), "warning")

    return false

  end

  if purchaseData.finance and purchaseData.paymentMethod ~= "societyFund" then

    if not Currencies.Server.AllowsFinance(purchaseData.paymentMethod) then

      Framework.Server.Notify(src, Locale.paymentMethodNoFinance, "error")

      DebugPrint(("%s attempted to finance with a payment method that doesn't support financing: %s"):format(tostring(src), purchaseData.paymentMethod), "warning")

      return false

    end

  end

  local plate = Framework.Server.VehicleGeneratePlate(Config.PlateFormat, true)

  if not plate then

    Framework.Server.Notify(src, Locale.couldNotGeneratePlate, "error")

    return false

  end

  local vehicleData = MySQL.single.await("SELECT * FROM dealership_stock WHERE vehicle = ? AND dealership = ?", {purchaseData.model, purchaseData.dealershipId})

  if not vehicleData then

    DebugPrint("Vehicle not found in dealership(" .. purchaseData.dealershipId .. ") stock: " .. purchaseData.model, "warning")

    return false

  end

  local vehicleStock = vehicleData.stock

  if dealership.type == "owned" and vehicleStock < 1 then

    Framework.Server.Notify(src, Locale.errorVehicleOutOfStock, "error")

    return false

  end

  local player = Framework.Server.GetPlayerIdentifier(src)

  local financeData = nil

  local basePriceToPay = Round(vehicleData.price)

  -- Starter vehicle check: make starter vehicles free for players who haven't claimed one yet
  local starterCars = { sultan = true, buffalo = true, blista = true, futo = true, elegy = true, kuruma = true, banshee = true, granger = true }
  if starterCars[tostring(purchaseData.model):lower()] then
    local qbPlayer = GetResourceState('qbx_core') == 'started' and exports.qbx_core:GetPlayer(src) or nil
    if qbPlayer then
      local meta = qbPlayer.PlayerData.metadata or {}
      if meta.starterpack_car ~= true then
        basePriceToPay = 0
        qbPlayer.Functions.SetMetaData('starterpack_car', true)
        TriggerClientEvent('ox_lib:notify', src, {
          title = 'Starter Car',
          description = 'You claimed your starter car for free!',
          type = 'success',
          duration = 6000
        })
      end
    end
  end

  local couponDiscount = 0

  local validatedCoupon = nil

  if purchaseData.couponCode and purchaseData.couponCode ~= "" and Coupons.Server.ValidateAndApplyCoupon then

    DebugPrint(("Validating coupon: %s"):format(purchaseData.couponCode), "debug")

    local couponResult = Coupons.Server.ValidateAndApplyCoupon(src, purchaseData.dealershipId, purchaseData.couponCode, purchaseData.model, vehicleData.category, purchaseData.finance, vehicleData.price)

    if couponResult.valid then

      couponDiscount = couponResult.discount

      validatedCoupon = couponResult.coupon

      basePriceToPay = Round(vehicleData.price - couponDiscount)

      DebugPrint(("Coupon applied - Discount: %s, New price: %s"):format(couponDiscount, basePriceToPay), "debug")

    else

      DebugPrint(("Coupon validation failed: %s"):format(couponResult.message or "Unknown error"), "warning")

      Framework.Server.Notify(src, string.gsub(Locale.invalidCoupon, '%%{value}', couponResult.message or "Unknown error"), "error")

      return false

    end

  elseif purchaseData.couponCode and purchaseData.couponCode ~= "" then

    DebugPrint("Coupon system not available but coupon code provided", "warning")

  end

  local currencyAmountToPay = Currencies.Server.ConvertFromBase(basePriceToPay, purchaseData.paymentMethod)

  currencyAmountToPay = Round(currencyAmountToPay)

  local accountBalance = Framework.Server.GetPlayerBalance(src, purchaseData.paymentMethod)

  local paymentType, paid, owed = "full", basePriceToPay, 0

  local downPayment, noOfPayments = Config.FinanceDownPayment, Config.FinancePayments

  if purchaseData.purchaseType == "society" and purchaseData.paymentMethod == "societyFund" then

    accountBalance = Framework.Server.GetSocietyBalance(purchaseData.society, purchaseData.societyType)

    currencyAmountToPay = basePriceToPay
  end

  if purchaseData.finance and purchaseData.purchaseType == "personal" then

    local discountedPrice = vehicleData.price - couponDiscount

    local baseDownPayment = Round(discountedPrice * (1 + Config.FinanceInterest) * downPayment)
    if pendingSale then

      downPayment, noOfPayments = pendingSale.downPayment, pendingSale.noOfPayments

      baseDownPayment = Round(discountedPrice * (1 + Config.FinanceInterest) * downPayment)

    end

    financeData = {

      total = Round(discountedPrice * (1 + Config.FinanceInterest)),

      paid = baseDownPayment,

      recurring_payment = Round((discountedPrice * (1 + Config.FinanceInterest) * (1 - downPayment)) / noOfPayments),

      payments_complete = 0,

      total_payments = noOfPayments,

      payment_interval = Config.FinancePaymentInterval,

      payment_failed = false,

      seconds_to_next_payment = Config.FinancePaymentInterval * 3600,

      seconds_to_repo = 0,

      dealership_id = purchaseData.dealershipId,

      vehicle = purchaseData.model,

      currency = purchaseData.paymentMethod
    }

    basePriceToPay = baseDownPayment

    currencyAmountToPay = Currencies.Server.ConvertFromBase(baseDownPayment, purchaseData.paymentMethod)

    currencyAmountToPay = Round(currencyAmountToPay)

    local vehiclesOnFinance = MySQL.scalar.await("SELECT COUNT(*) as total FROM " .. Framework.VehiclesTable .. " WHERE financed = 1 AND " .. Framework.PlayerId .. " = ?", {player})

    if vehiclesOnFinance >= (Config.MaxFinancedVehiclesPerPlayer or 999999) then

      Framework.Server.Notify(src, Locale.tooManyFinancedVehicles, "error")

      return false

    end

    paymentType = "finance"

    paid = financeData.paid

    owed = financeData.total - financeData.paid

  end

  if currencyAmountToPay > accountBalance then

    DebugPrint(("Insufficient funds - Required: %s, Available: %s (currency: %s)"):format(currencyAmountToPay, accountBalance, purchaseData.paymentMethod), "debug")

    Framework.Server.Notify(src, Locale.errorCannotAffordVehicle, "error")

    return false

  end

  DebugPrint(("Pre-check - Base Amount: %s, Currency Amount: %s, Payment: %s, Financed: %s"):format(basePriceToPay, currencyAmountToPay, purchaseData.paymentMethod, tostring(purchaseData.finance)), "debug")

  if not PurchaseVehiclePreCheck(src, purchaseData.dealershipId, plate, purchaseData.model, purchaseData.purchaseType, basePriceToPay, purchaseData.paymentMethod, purchaseData.society, purchaseData.societyType, purchaseData.finance, noOfPayments, downPayment, (not not purchaseData.directSaleUuid), pendingSale and pendingSale.dealerPlayerId or nil) then

    DebugPrint(("PurchaseVehiclePreCheck failed for player %s"):format(tostring(src)), "warning")

    return false

  end

  DebugPrint("Pre-check passed, processing payment", "debug")

  if purchaseData.purchaseType == "society" and purchaseData.paymentMethod == "societyFund" then

    Framework.Server.RemoveFromSocietyFund(purchaseData.society, purchaseData.societyType, basePriceToPay)

  else

    Framework.Server.PlayerRemoveMoney(src, currencyAmountToPay, purchaseData.paymentMethod)

  end

  if dealership.type == "owned" then

    MySQL.update.await("UPDATE dealership_stock SET stock = stock - 1 WHERE vehicle = ? AND dealership = ?", {purchaseData.model, purchaseData.dealershipId})

    DealershipBalance.Server.Add(purchaseData.dealershipId, basePriceToPay)
  end

  MySQL.insert.await("INSERT INTO dealership_sales (dealership, vehicle, plate, player, seller, purchase_type, paid, owed) VALUES(?, ?, ?, ?, ?, ?, ?, ?)", {purchaseData.dealershipId, purchaseData.model, plate, player, sellerPlayer, paymentType, paid, owed})

  DebugPrint(("Vehicle saved to database - Plate: %s"):format(plate), "debug")

  local vehicleId = Framework.Server.SaveVehicleToGarage(src, purchaseData.purchaseType, purchaseData.society, purchaseData.societyType, purchaseData.model, plate, purchaseData.finance, financeData)

  DebugPrint(("Vehicle saved to garage - ID: %s"):format(tostring(vehicleId)), "debug")

  local netId = nil

  if Config.SpawnVehiclesWithServerSetter then

    local isDirectSale = purchaseData.directSaleUuid ~= nil

    local warp = not Config.DoNotSpawnInsideVehicle and not isDirectSale

    local properties = {

      plate = plate,

      colour = purchaseData.colour

    }

    netId = Spawn.Server.Create(src, vehicleId or 0, purchaseData.model, plate, purchaseData.coords, warp, properties, "purchase")

    if not netId or netId == 0 then

      Framework.Server.Notify(src, Locale.couldNotSpawnVehicle, "error") 

      DebugPrint("Could not spawn vehicle with Config.SpawnVehiclesWithServerSetter", "warning")

      return false

    end

  end

  if validatedCoupon then

    DebugPrint(("Recording coupon usage - Coupon ID: %s"):format(validatedCoupon.id), "debug")

    Coupons.Server.RecordCouponUsage(validatedCoupon.id, player, purchaseData.model, tostring(purchaseData.purchaseType), purchaseData.finance, couponDiscount)

    DebugPrint("Coupon usage recorded successfully", "debug")

  end

  local webhookFields = {

    { key = "Vehicle", value = purchaseData.model },

    { key = "Plate", value = plate },

    { key = "Financed", value = purchaseData.finance and "Yes" or "No" },

    { key = "Amount Paid", value = currencyAmountToPay },

    { key = "Payment method", value = purchaseData.paymentMethod },

    { key = "Dealership", value = purchaseData.dealershipId },

    { key = "Seller Name", value = sellerPlayerName or "-" }

  }

  if validatedCoupon then

    table.insert(webhookFields, { key = "Coupon Used", value = purchaseData.couponCode })

    table.insert(webhookFields, { key = "Discount Applied", value = couponDiscount })

  end

  SendWebhook(src, Webhooks.Purchase, "New Vehicle Purchase", "success", webhookFields)

  Showroom.Server.UpdateVehicleCache(purchaseData.model, purchaseData.dealershipId)

  Framework.Server.Notify(src, Locale.purchaseSuccess, "success")

  DebugPrint(("Purchase completed successfully - Player: %s, Vehicle: %s, Plate: %s"):format(tostring(src), purchaseData.model, plate), "debug")

  return true, netId, vehicleId, plate, currencyAmountToPay

end

lib.callback.register("jg-dealerships:server:purchase-vehicle", function(src, data)

  return purchaseVehicle(src, data)

end)

lib.callback.register("jg-dealerships:server:validate-coupon", function(src, data)

  local dealershipId, code, vehicleModel, finance = data.dealershipId, data.code, data.vehicleModel, data.isFinanced

  local vehicleData = MySQL.single.await("SELECT * FROM dealership_stock WHERE vehicle = ? AND dealership = ?", {vehicleModel, dealershipId})

  if not vehicleData then

    return { success = false, error = "Vehicle not found" }

  end

  return Coupons.Server.ValidateAndApplyCoupon(src, dealershipId, code, vehicleModel, vehicleData.category, finance, vehicleData.price)

end)

RegisterNetEvent("jg-dealerships:server:update-purchased-vehicle-props", function(purchaseType, society, plate, props)

  local src = source

  local identifier = purchaseType == "society" and society or Framework.Server.GetPlayerIdentifier(src)

  MySQL.update.await("UPDATE " .. Framework.VehiclesTable .. " SET " .. Framework.VehProps .. " = ? WHERE plate = ? AND " .. Framework.PlayerId .. " = ?", {

    json.encode(props), plate, identifier

  })

end)
