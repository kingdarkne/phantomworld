if not DealershipManagement then

    DealershipManagement = {}

end

if not DealershipManagement.Client then

    DealershipManagement.Client = {}

end

function DealershipManagement.Client.Open(dealershipId, defaultPage, fromAdmin)

    local location = Locations.Client.GetLocationById(dealershipId)

    if not location then

        return false

    end

    local employeeCheck = lib.callback.await("jg-dealerships:server:is-employee", false, dealershipId, fromAdmin == true)

    if not employeeCheck or not employeeCheck.isEmployee then

        Framework.Client.Notify(Locale.notAnEmployee, "error")

        return false

    end

    local balance = lib.callback.await("jg-dealerships:server:dealership-balance:get", false, dealershipId)

    SetNuiFocus(true, true)

    SendNUIMessage({

        type = "showDealershipManagement",

        defaultPage = defaultPage,

        shopType = location.type,

        dealershipId = dealershipId,

        name = location.name or dealershipId,

        balance = balance or 0,

        employeeName = employeeCheck.employeeName,

        employeeRole = employeeCheck.employeeRole,

        permissions = employeeCheck.permissions,

        commission = location.employee_commission or 10,

        fromAdmin = fromAdmin or false,

        nearbyPlayers = {},

        playerBalance = {

            bank = Framework.Client.GetBalance("bank"),

            cash = Framework.Client.GetBalance("cash")

        },

        roles = {"CEO", "Owner", "Employee"},

        colourSelectionType = location.colour_selection_type or "RGB",

        colourOptions = location.colour_options or {},

        locale = Locale,

        config = Config

    })

end

local function CalculateDeliveryInfo(orderId, dealershipId)

    local deliveryData = lib.callback.await("jg-dealerships:server:get-delivery-info", false, orderId, dealershipId)

    if not deliveryData or not deliveryData.pickupCoords then

        return false

    end

    local playerCoords = GetEntityCoords(cache.ped)

    local pickupCoords = deliveryData.pickupCoords

    local travelDistance = CalculateTravelDistanceBetweenPoints(

        playerCoords.x, playerCoords.y, playerCoords.z,

        pickupCoords.x, pickupCoords.y, pickupCoords.z

    )

    local pickupVec = vector3(pickupCoords.x, pickupCoords.y, pickupCoords.z)

    local straightDistance = #(playerCoords - pickupVec)

    local windingFactor = travelDistance / math.max(straightDistance, 1)

    local adjustedFactor = math.min(windingFactor - 1.0, 1.0)

    local averageSpeed = 22.22 - (adjustedFactor * 13.89)

    local travelTime = travelDistance / averageSpeed

    local estimatedTime = math.ceil(travelTime * 1.3)

    return {

        pickupLocation = deliveryData.pickupLocation,

        distance = travelDistance,

        estimatedTime = estimatedTime

    }

end

RegisterNUICallback("management-return-to-admin", function(data, cb)

    Admin.Client.Open()

    cb(true)

end)

RegisterNUICallback("get-dealership-balance", function(data, cb)

    cb(lib.callback.await("jg-dealerships:server:get-dealership-balance", false, data.dealership))

end)

RegisterNUICallback("get-dealership-vehicles", function(data, cb)

    cb(lib.callback.await("jg-dealerships:server:get-dealership-vehicles", false, data))

end)

RegisterNUICallback("get-dealership-display-vehicles", function(data, cb)

    cb(lib.callback.await("jg-dealerships:server:get-dealership-display-vehicles", false, data))

end)

RegisterNUICallback("get-dealership-orders", function(data, cb)

    cb(lib.callback.await("jg-dealerships:server:get-dealership-orders", false, data))

end)

RegisterNUICallback("get-dealership-sales", function(data, cb)

    cb(lib.callback.await("jg-dealerships:server:get-dealership-sales", false, data))

end)

RegisterNUICallback("get-dealership-employees", function(data, cb)

    cb(lib.callback.await("jg-dealerships:server:get-dealership-employees", false, data))

end)

RegisterNUICallback("get-dealership-homepage-stats", function(data, cb)

    cb(lib.callback.await("jg-dealerships:server:get-dealership-homepage-stats", false, data))

end)

RegisterNUICallback("get-dealership-graph-data", function(data, cb)

    cb(lib.callback.await("jg-dealerships:server:get-dealership-graph-data", false, data))

end)

RegisterNUICallback("order-vehicle", function(data, cb)

    local sizeCategory = nil

    if TrailerAttachment and TrailerAttachment.Client and TrailerAttachment.Client.GetVehicleSizeCategory then

        sizeCategory = TrailerAttachment.Client.GetVehicleSizeCategory(data.spawnCode)

    end

    cb(lib.callback.await("jg-dealerships:server:order-vehicle", false, data.dealership, data.spawnCode, data.quantity, sizeCategory))

end)

RegisterNUICallback("cancel-vehicle-order", function(data, cb)

    cb(lib.callback.await("jg-dealerships:server:cancel-vehicle-order", false, data.orderId))

end)

RegisterNUICallback("get-delivery-info", function(data, cb)

    cb(CalculateDeliveryInfo(data.orderId, data.dealershipId))

end)

RegisterNUICallback("deliver-vehicle", function(data, cb)

    cb(lib.callback.await("jg-dealerships:server:deliver-vehicle", false, data.orderId, data.dealershipId))

end)

RegisterNUICallback("generate-delivery-config", function(data, cb)

    local success, errorMsg, config = lib.callback.await(

        "jg-dealerships:server:generate-delivery-config",

        false,

        data.dealershipId,

        data.trailerType,

        data.orderIds,

        data.quantities

    )

    cb({

        success = success,

        errorMsg = errorMsg,

        config = config

    })

end)

RegisterNUICallback("start-multi-delivery", function(data, cb)

    SetNuiFocus(false, false)

    local config = lib.callback.await("jg-dealerships:server:get-pending-delivery-config", false)

    if not config then

        Framework.Client.Notify("No pending delivery configuration found", "error")

        cb({ success = false, error = "No pending configuration" })

        return

    end

    local success, errorMsg = TruckingMission.Client.Start(

        data.dealershipId,

        config.trailerType,

        config.orderIds,

        config.quantities,

        data.configHash

    )

    if not success then

        Framework.Client.Notify(errorMsg or "Failed to start delivery", "error")

        cb({ success = false, error = errorMsg })

        return

    end

    Framework.Client.Notify("Delivery mission started", "success")

    cb({ success = true })

end)

RegisterNUICallback("update-dealership-balance", function(data, cb)

    if data.action == "deposit" then

        return cb(lib.callback.await("jg-dealerships:server:dealership-deposit", false, data.dealership, data.source, data.amount))

    elseif data.action == "withdraw" then

        return cb(lib.callback.await("jg-dealerships:server:dealership-withdraw", false, data.dealership, data.amount))

    end

    cb({ error = true })

end)

RegisterNUICallback("update-vehicle-price", function(data, cb)

    cb(lib.callback.await("jg-dealerships:server:update-vehicle-price", false, data))

end)

RegisterNUICallback("admin-set-stock", function(data, cb)

    cb(lib.callback.await("jg-dealerships:server:admin-set-stock", false, data))

end)

RegisterNUICallback("update-dealership-settings", function(data, cb)

    cb(lib.callback.await("jg-dealerships:server:update-dealership-settings", false, data))

end)
