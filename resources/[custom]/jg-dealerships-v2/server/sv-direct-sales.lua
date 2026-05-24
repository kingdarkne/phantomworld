DirectSales = DirectSales or {}

DirectSales.Server = DirectSales.Server or {}

local pendingSales = {}

local function CreatePendingSale(dealershipId, dealerPlayerId, playerId, model, colour, price, finance, noOfPayments, downPayment, couponCode, appliedCoupon)

    local uuid = Utils.Server.GenerateUuid()

    local attempts = 0

    while pendingSales[uuid] and attempts < 10 do

        attempts = attempts + 1

        uuid = Utils.Server.GenerateUuid()

    end

    pendingSales[uuid] = {

        dealershipId  = dealershipId,

        dealerPlayerId = dealerPlayerId,

        playerId      = playerId,

        model         = model,

        colour        = colour,

        price         = price,

        finance       = finance,

        noOfPayments  = noOfPayments,

        downPayment   = downPayment,

        couponCode    = couponCode,

        appliedCoupon = appliedCoupon,

    }

    return uuid

end

local function RemovePendingSale(uuid)

    if pendingSales[uuid] then

        pendingSales[uuid] = nil

    end

end

function DirectSales.Server.GetPending(uuid)

    return pendingSales[uuid] or false

end

lib.callback.register("jg-dealerships:server:get-direct-sale-data", function(source, dealershipId)

    local employeeRole = Employees.Server.IsEmployee(source, dealershipId, "SELL", false)

    if not employeeRole then

        employeeRole = Employees.Server.IsEmployee(source, dealershipId, "SELL", true)

        if not employeeRole then

            Framework.Server.Notify(source, Locale.employeePermissionsError, "error")

            return false

        end

    end

    local location = Locations.Server.GetById(dealershipId)

    if not location then return false end

    if location.type == "selfService" then return false end

    local employeeInfo  = Framework.Server.GetPlayerInfo(source)

    local vehicles      = Showroom.Server.GetVehicles(dealershipId)

    local playerPed     = GetPlayerPed(source)

    local playerCoords  = GetEntityCoords(playerPed)

    local nearbyPlayers = Utils.Server.GetNearbyPlayers(source, playerCoords, 10.0, false)

    local colourSelectionType = location.colour_selection_type or "RGB"

    local colourOptions       = location.colour_options or {}

    local commission          = (location.employee_commission or 10) / 100

    local dealershipLabel     = location.name or dealershipId

    local employeeName        = (employeeInfo and employeeInfo.name) or ""

    return {

        vehicles            = vehicles,

        categories          = location.categories,

        enableFinance       = location.enable_finance,

        commission          = commission,

        nearbyPlayers       = nearbyPlayers,

        colourSelectionType = colourSelectionType,

        colourOptions       = colourOptions,

        employeeName        = employeeName,

        employeeRole        = employeeRole,

        dealershipLabel     = dealershipLabel,

    }

end)

lib.callback.register("jg-dealerships:server:send-direct-sale-request", function(source, dealershipId, saleData)

    if not dealershipId then return false end

    local hasPermission = Employees.Server.IsEmployee(source, dealershipId, "SELL")

    if not hasPermission then

        Framework.Server.Notify(source, Locale.employeePermissionsError, "error")

        return false

    end

    local dealerInfo  = Framework.Server.GetPlayerInfo(source)

    local dealerName  = dealerInfo and dealerInfo.name

    local playerId    = saleData.playerId

    local playerIdent = Framework.Server.GetPlayerIdentifier(playerId)

    local model       = saleData.model

    local colour      = saleData.colour

    local finance     = saleData.finance

    local noOfPayments = saleData.financePayments

    local downPayment  = saleData.financeDownPayment

    local couponCode   = saleData.couponCode

    local appliedCoupon = saleData.appliedCoupon

    if couponCode and couponCode ~= "" then

        if Coupons and Coupons.Server and Coupons.Server.ValidateAndApplyCoupon then

            local vehicleData = Showroom.Server.GetVehicle(dealershipId, model)

            if vehicleData then

                local couponResult = Coupons.Server.ValidateAndApplyCoupon(

                    source, dealershipId, couponCode, model,

                    vehicleData.category, finance, vehicleData.price, playerId

                )

                if couponResult.valid then

                    appliedCoupon = couponResult

                else

                    Framework.Server.Notify(

                        source,

                        string.gsub(Locale.invalidCoupon, "%%{value}", couponResult.message or "Unknown error"),

                        "error"

                    )

                    return false

                end

            end

        end

    end

    if finance then

        local financeCount = MySQL.query.await(

            "SELECT COUNT(*) as total FROM " .. Framework.VehiclesTable .. " WHERE financed = 1 AND " .. Framework.PlayerId .. " = ?",

            { playerIdent }

        )

        local total = financeCount[1].total

        local maxFinanced = Config.MaxFinancedVehiclesPerPlayer or 999999

        if total >= maxFinanced then

            Framework.Server.Notify(source, Locale.playerTooManyFinancedVehicles, "error")

            return false

        end

    end

    local location = Locations.Server.GetById(dealershipId)

    if not location then return false end

    local vehicleData = Showroom.Server.GetVehicle(dealershipId, model)

    if not vehicleData then return false end

    local uuid = CreatePendingSale(

        dealershipId, source, playerId,

        model, colour, vehicleData.price,

        finance, noOfPayments, downPayment,

        couponCode, appliedCoupon

    )

    TriggerClientEvent("jg-dealerships:client:show-direct-sale-request", playerId, uuid, source, {

        dealerName      = dealerName,

        dealershipId    = dealershipId,

        dealershipLabel = location.name or location.id,

        vehicle         = vehicleData,

        colour          = colour,

        financed        = finance,

        downPayment     = downPayment,

        noOfPayments    = noOfPayments,

        couponCode      = couponCode,

        appliedCoupon   = appliedCoupon,

    })

    return true, uuid

end)

lib.callback.register("jg-dealerships:server:cancel-direct-sale-request", function(source, uuid)

    local sale = pendingSales[uuid]

    if not sale then return false end

    if source ~= sale.dealerPlayerId then return false end

    TriggerClientEvent("jg-dealerships:client:direct-sale-cancelled", sale.playerId)

    RemovePendingSale(uuid)

    return true

end)

lib.callback.register("jg-dealerships:server:direct-sale-request-accepted", function(source, uuid, acceptData)

    local sale = pendingSales[uuid]

    if not sale then return false end

    if source ~= sale.playerId then return false end

    local totalPrice = sale.finance

        and (sale.price * (1 + Config.FinanceInterest))

        or  sale.price

    local dealershipId = sale.dealershipId

    local dealerPlayerId = sale.dealerPlayerId

    local location = Locations.Server.GetById(dealershipId)

    if not location then return false end

    local commissionRate = (location.employee_commission or 10) / 100

    local commissionAmount = Round(totalPrice * commissionRate)

    DealershipBalance.Server.Remove(dealershipId, commissionAmount)

    Framework.Server.PlayerAddMoney(dealerPlayerId, commissionAmount, "bank")

    local vehicleCoords = (acceptData and acceptData.coords) or location.purchase_vehicle_coords

    TriggerClientEvent("jg-dealerships:client:direct-sale-response", dealerPlayerId, uuid, "accepted", vehicleCoords)

    RemovePendingSale(uuid)

    return true, vehicleCoords

end)

lib.callback.register("jg-dealerships:server:direct-sale-request-denied", function(source, uuid)

    local sale = pendingSales[uuid]

    if not sale then return false end

    if source ~= sale.playerId then return false end

    TriggerClientEvent("jg-dealerships:client:direct-sale-response", sale.dealerPlayerId, uuid, "declined")

    RemovePendingSale(uuid)

    return true

end)
