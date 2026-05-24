local function BroadcastAddLocation(locationId)

  TriggerClientEvent("jg-dealerships:client:add-location", -1, locationId)

end

local function BroadcastUpdateLocation(location)

  if not location then return end

  local players = GetPlayers()

  for _, playerId in ipairs(players) do

    local source = tonumber(playerId)

    if source then

      local playerJob = Framework.Server.GetPlayerJob(source)

      local playerGang = Framework.Server.GetPlayerGang(source)

      local playerLocation = {}

      for k, v in pairs(location) do

        playerLocation[k] = v

      end

      local showroomJobWhitelist = type(location.showroom_job_whitelist) == "string" 

        and json.decode(location.showroom_job_whitelist) 

        or location.showroom_job_whitelist

      local showroomGangWhitelist = type(location.showroom_gang_whitelist) == "string" 

        and json.decode(location.showroom_gang_whitelist) 

        or location.showroom_gang_whitelist

      local hasJobWhitelist = showroomJobWhitelist and next(showroomJobWhitelist)

      local hasGangWhitelist = showroomGangWhitelist and next(showroomGangWhitelist)

      if not hasJobWhitelist and not hasGangWhitelist then

        playerLocation.playerCanAccessShowroom = true

      else

        local passesJobCheck = false

        if hasJobWhitelist then

          passesJobCheck = CheckJobGangWhitelist(showroomJobWhitelist, playerJob.name, playerJob.grade)

        end

        local passesGangCheck = false

        if hasGangWhitelist then

          passesGangCheck = CheckJobGangWhitelist(showroomGangWhitelist, playerGang.name, playerGang.grade)

        end

        playerLocation.playerCanAccessShowroom = passesJobCheck or passesGangCheck

      end

      if location.type == "owned" then

        local isEmployee = Employees.Server.IsEmployee(source, location.id, nil, false)

        playerLocation.playerIsEmployee = isEmployee and true or false

      else

        playerLocation.playerIsEmployee = false

      end

      TriggerClientEvent("jg-dealerships:client:update-location", source, playerLocation)

    end

  end

end

local function BroadcastDeleteLocation(locationId)

  TriggerClientEvent("jg-dealerships:client:delete-location", -1, locationId)

end

lib.callback.register("jg-dealerships:server:fetch-all-locations-admin", function(source)

  if not Framework.Server.IsAdmin(source) then

    Framework.Server.Notify(source, Locale.insufficientPermissions, "error")

    DebugPrint("Player " .. source .. " tried to create a new dealership location without permission", "warning")

    return { error = true }

  end

  Locations.Server.ClearCache()

  return Locations.Server.GetAll(true)

end)

lib.callback.register("jg-dealerships:server:toggle-location-disabled", function(source, data)

  if not Framework.Server.IsAdmin(source) then

    Framework.Server.Notify(source, Locale.insufficientPermissions, "error")

    DebugPrint("Player " .. source .. " tried to toggle location disabled without permission", "warning")

    return { error = true }

  end

  Locations.Server.SetDisabled(data.id, data.disabled)

  if data.disabled then

    BroadcastDeleteLocation(data.id)

  else

    local location = Locations.Server.GetById(data.id, false)

    if location then

      BroadcastAddLocation(location)

    end

  end

  return true

end)

lib.callback.register("jg-dealerships:server:create-location", function(source, data)

  if not Framework.Server.IsAdmin(source) then

    Framework.Server.Notify(source, Locale.insufficientPermissions, "error")

    DebugPrint("Player " .. source .. " tried to create a new dealership location without permission", "warning")

    return { error = true }

  end

  local stockSync = data.stockSync

  data.stockSync = nil

  local success, locationId = Locations.Server.Create(data)

  if stockSync and locationId then

    local syncResult = Locations.Server.SyncStockByCategories(

      locationId,

      stockSync.addedCategories or {},

      stockSync.removedCategories or {},

      stockSync.removeStock or false

    )

    if syncResult.added > 0 or syncResult.removed > 0 then

      local message = string.format("Stock sync: %d added, %d removed", syncResult.added, syncResult.removed)

      Framework.Server.Notify(source, message, "success")

    end

  end

  local location = Locations.Server.GetById(locationId, false)

  if location then

    BroadcastAddLocation(location)

  end

  return locationId

end)

lib.callback.register("jg-dealerships:server:update-location", function(source, requestData)

  local locationId = requestData.id

  local data = requestData.data

  local stockSync = requestData.stockSync

  if not Framework.Server.IsAdmin(source) then

    Framework.Server.Notify(source, Locale.insufficientPermissions, "error")

    DebugPrint("Player " .. source .. " tried to update a dealership location without permission", "warning")

    return { error = true }

  end

  Locations.Server.Update(locationId, data)

  if stockSync and locationId then

    local syncResult = Locations.Server.SyncStockByCategories(

      locationId,

      stockSync.addedCategories or {},

      stockSync.removedCategories or {},

      stockSync.removeStock or false

    )

    if syncResult.added > 0 or syncResult.removed > 0 then

      local message = string.format("Stock sync: %d added, %d removed", syncResult.added, syncResult.removed)

      Framework.Server.Notify(source, message, "success")

    end

  end

  local location = Locations.Server.GetById(locationId, false)

  if location then

    BroadcastUpdateLocation(location)

  end

  return true

end)

lib.callback.register("jg-dealerships:server:delete-location", function(source, locationId)

  if not Framework.Server.IsAdmin(source) then

    Framework.Server.Notify(source, Locale.insufficientPermissions, "error")

    DebugPrint("Player " .. source .. " tried to delete a dealership location without permission", "warning")

    return { error = true }

  end

  Locations.Server.Delete(locationId)

  BroadcastDeleteLocation(locationId)

  return true

end)

lib.callback.register("jg-dealerships:server:fetch-all-vehicles-admin", function(source)

  if not Framework.Server.IsAdmin(source) then

    Framework.Server.Notify(source, Locale.insufficientPermissions, "error")

    DebugPrint("Player " .. source .. " tried to get admin data without permission", "warning")

    return { error = true }

  end

  return {

    vehicles = Vehicles.Server.GetAll(),

    locations = Locations.Server.GetAllIdAndNameOnly()

  }

end)

lib.callback.register("jg-dealerships:server:add-vehicle", function(source, data)

  if not Framework.Server.IsAdmin(source) then

    Framework.Server.Notify(source, Locale.insufficientPermissions, "error")

    DebugPrint("Player " .. source .. " tried to add a vehicle without permission", "warning")

    return { error = true }

  end

  local success = Vehicles.Server.Create(data)

  if not success then

    return { error = true }

  end

  SendWebhook(source, Webhooks.Admin, "Admin: Add Vehicle", "success", {

    { key = "Vehicle", value = data.spawn_code },

    { key = "Name", value = data.brand .. " " .. data.model },

    { key = "Category", value = data.category },

    { key = "Price", value = data.price },

    { key = "Dealerships", value = #data.locations .. " dealership(s)" }

  })

  return true

end)

lib.callback.register("jg-dealerships:server:update-vehicle", function(source, data, updateDealerPrices)

  if not Framework.Server.IsAdmin(source) then

    Framework.Server.Notify(source, Locale.insufficientPermissions, "error")

    DebugPrint("Player " .. source .. " tried to update a vehicle without permission", "warning")

    return { error = true }

  end

  local success = Vehicles.Server.Update(data.spawn_code, data, updateDealerPrices)

  if not success then

    return { error = true }

  end

  SendWebhook(source, Webhooks.Admin, "Admin: Vehicle Updated", nil, {

    { key = "Vehicle", value = data.spawn_code },

    { key = "Name", value = data.brand .. " " .. data.model },

    { key = "Category", value = data.category },

    { key = "Price", value = data.price },

    { key = "Dealerships", value = #data.locations .. " dealership(s)" }

  })

  return true

end)

lib.callback.register("jg-dealerships:server:delete-vehicle", function(source, spawnCode)

  if not Framework.Server.IsAdmin(source) then

    Framework.Server.Notify(source, Locale.insufficientPermissions, "error")

    DebugPrint("Player " .. source .. " tried to delete a vehicle without permission", "warning")

    return { error = true }

  end

  local success = Vehicles.Server.Delete(spawnCode)

  if not success then

    return { error = true }

  end

  SendWebhook(source, Webhooks.Admin, "Admin: Vehicle Deleted", "danger", {

    { key = "Vehicle", value = spawnCode }

  })

  return true

end)
