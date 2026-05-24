Admin = Admin or {}

Admin.Client = Admin.Client or {}

function Admin.Client.Open()

  local currencies = lib.callback.await("jg-dealerships:server:get-currencies", false)

  SetNuiFocus(true, true)

  SendNUIMessage({

    type = "showNewAdmin",

    locale = Locale,

    config = Config,

    currencies = currencies

  })

end

RegisterNetEvent("jg-dealerships:client:open-admin", function()

  Admin.Client.Open()

end)

RegisterNUICallback("fetch-all-locations-admin", function(data, cb)

  local result = lib.callback.await("jg-dealerships:server:fetch-all-locations-admin")

  cb(result)

end)

RegisterNUICallback("create-location", function(data, cb)

  local result = lib.callback.await("jg-dealerships:server:create-location", false, data)

  cb(result)

end)

RegisterNUICallback("update-location", function(data, cb)

  local result = lib.callback.await("jg-dealerships:server:update-location", false, data)

  cb(result)

end)

RegisterNUICallback("delete-location", function(data, cb)

  local result = lib.callback.await("jg-dealerships:server:delete-location", false, data)

  cb(result)

end)

RegisterNUICallback("toggle-location-disabled", function(data, cb)

  local result = lib.callback.await("jg-dealerships:server:toggle-location-disabled", false, data)

  cb(result)

end)

RegisterNUICallback("validate-job", function(data, cb)

  local result = lib.callback.await("jg-dealerships:server:validate-job", false, data)

  cb(result)

end)

RegisterNUICallback("validate-gang", function(data, cb)

  local result = lib.callback.await("jg-dealerships:server:validate-gang", false, data)

  cb(result)

end)

RegisterNUICallback("manage-location", function(data, cb)

  DealershipManagement.Client.Open(data, nil, true)

  cb(true)

end)

RegisterNUICallback("set-waypoint", function(data, cb)

  SetNewWaypoint(data.x, data.y)

  cb(true)

end)

RegisterNUICallback("fetch-all-vehicles-admin", function(data, cb)

  local result = lib.callback.await("jg-dealerships:server:fetch-all-vehicles-admin")

  cb(result)

end)

RegisterNUICallback("add-vehicle", function(data, cb)

  local result = lib.callback.await("jg-dealerships:server:add-vehicle", false, data)

  cb(result)

end)

RegisterNUICallback("update-vehicle", function(data, cb)

  local result = lib.callback.await("jg-dealerships:server:update-vehicle", false, data, data.updateDealerPrices)

  cb(result)

end)

RegisterNUICallback("delete-vehicle", function(data, cb)

  local result = lib.callback.await("jg-dealerships:server:delete-vehicle", false, data)

  cb(result)

end)

RegisterNUICallback("verify-spawn-code", function(spawnCode, cb)

  if not spawnCode then

    return cb(false)

  end

  local isValid = IsModelValid(joaat(spawnCode))

  cb(isValid)

end)

RegisterNUICallback("import-v1-locations", function(data, cb)

  local result = lib.callback.await("jg-dealerships:server:import-v1-locations", false, data)

  cb(result)

end)

RegisterNUICallback("preview-vehicles-data", function(data, cb)

  local result = lib.callback.await("jg-dealerships:server:preview-vehicles-data", false, data.source)

  cb(result)

end)

RegisterNUICallback("import-vehicles-data", function(data, cb)

  local result = lib.callback.await("jg-dealerships:server:import-vehicles-data", false, data.source, data.behaviour, data.stockMethod)

  cb(result)

end)
