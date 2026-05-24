lib.callback.register("jg-dealerships:server:get-display-vehicles", function(playerId, dealershipId)

  local displayVehicles = MySQL.query.await(

    "SELECT dispveh.*, vehicle.model, vehicle.brand FROM dealership_dispveh dispveh INNER JOIN dealership_vehicles vehicle ON dispveh.vehicle = vehicle.spawn_code WHERE dealership = ?",

    {dealershipId}

  )

  for index, vehicle in ipairs(displayVehicles) do

    displayVehicles[index].color = json.decode(vehicle.color)

  end

  return displayVehicles

end)

lib.callback.register("jg-dealerships:server:create-display-vehicle", function(playerId, dealershipId, spawnCode, color, coords)

  if type(color) == "table" then

    color = json.encode(color) or color

  end

  MySQL.query.await(

    "INSERT INTO dealership_dispveh (dealership,vehicle,color,coords) VALUES(?,?,?,?)",

    {dealershipId, spawnCode, color, json.encode(coords)}

  )

  TriggerClientEvent("jg-dealerships:client:spawn-display-vehicles", -1, dealershipId)

  return true

end)

lib.callback.register("jg-dealerships:server:edit-display-vehicle", function(playerId, dealershipId, displayVehicleId, newSpawnCode, newColor)

  if type(newColor) == "table" then

    newColor = json.encode(newColor) or newColor

  end

  MySQL.query.await(

    "UPDATE dealership_dispveh SET vehicle = ?, color = ? WHERE id = ?",

    {newSpawnCode, newColor, displayVehicleId}

  )

  TriggerClientEvent("jg-dealerships:client:spawn-display-vehicles", -1, dealershipId)

  return true

end)

lib.callback.register("jg-dealerships:server:delete-display-vehicle", function(playerId, dealershipId, displayVehicleId)

  MySQL.query.await(

    "DELETE FROM dealership_dispveh WHERE id = ?",

    {displayVehicleId}

  )

  TriggerClientEvent("jg-dealerships:client:spawn-display-vehicles", -1, dealershipId)

  return true

end)
