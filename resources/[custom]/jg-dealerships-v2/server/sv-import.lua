Import = Import or {}

Import.Server = Import.Server or {}

local function TableExists(tableName)

  local count = MySQL.scalar.await([[

    SELECT COUNT(*) FROM information_schema.tables

    WHERE table_schema = DATABASE() AND table_name = ?

  ]], { tableName })

  return count and count > 0

end

local function BuildZonePoint(coords, radius, blipData, markerData, hideBlip, hideMarkers)

  local markerSize = 0.3

  if markerData and markerData.size and markerData.size.x then

    markerSize = markerData.size.x

  end

  local markerColor = { r = 255, g = 255, b = 255, a = 120 }

  if markerData and markerData.color then

    markerColor = {

      r = markerData.color.r or 255,

      g = markerData.color.g or 255,

      b = markerData.color.b or 255,

      a = markerData.color.a or 120,

    }

  end

  local point = { type = "point" }

  point.coords = {

    {

      x = coords.x,

      y = coords.y,

      z = coords.z,

      w = coords.w or 0.0,

    }

  }

  point.radius    = radius or 5.0

  point.enableBlip = not hideBlip and blipData ~= nil

  point.blipIconId  = (blipData and blipData.id) or 326

  point.blipColourId = (blipData and blipData.color) or 2

  point.blipSize = (blipData and blipData.scale) or 0.6

  point.enableMarker = not hideMarkers

  point.markerId = (markerData and markerData.id) or 21

  point.markerSize      = markerSize

  point.markerColor     = markerColor

  point.markerBobUpAndDown = (markerData and markerData.bobUpAndDown) == 1 or (markerData and markerData.bobUpAndDown) or false

  point.markerFaceCamera   = (markerData and markerData.faceCamera)   == 1 or (markerData and markerData.faceCamera)   or false

  point.markerRotate       = (markerData and markerData.rotate)        == 1 or (markerData and markerData.rotate)       or false

  point.markerDrawOnEnts   = (markerData and markerData.drawOnEnts)    == 1 or (markerData and markerData.drawOnEnts)   or false

  return point

end

local function BuildSquareZone(center, halfSize)

  local z = center.z

  return {

    { x = center.x - halfSize, y = center.y - halfSize, z = z },

    { x = center.x + halfSize, y = center.y - halfSize, z = z },

    { x = center.x + halfSize, y = center.y + halfSize, z = z },

    { x = center.x - halfSize, y = center.y + halfSize, z = z },

  }

end

local function CopyCoords(coordsTable)

  return {

    x = coordsTable.x,

    y = coordsTable.y,

    z = coordsTable.z,

    w = coordsTable.w,

  }

end

local function GetJobRankMapping(jobName)

  local isValid, grades = Framework.Server.IsValidJob(jobName)

  if not isValid or not grades or #grades == 0 then

    return nil

  end

  local sortedGrades = {}

  for _, grade in ipairs(grades) do

    sortedGrades[#sortedGrades + 1] = grade

  end

  table.sort(sortedGrades, function(a, b) return a.rank > b.rank end)

  local permissionKeys = TableKeys(Config.EmployeePermissions or {})

  if not permissionKeys or #permissionKeys == 0 then

    permissionKeys = { "manager", "supervisor", "sales" }

  end

  local mapping = {}

  for i, permKey in ipairs(permissionKeys) do

    if sortedGrades[i] then

      mapping[permKey] = sortedGrades[i].rank

    elseif #sortedGrades > 0 then

      mapping[permKey] = sortedGrades[#sortedGrades].rank

    end

  end

  return mapping

end

local function ParseColourOptions(useRGB, optionsTable)

  local parsed = {}

  local errors = {}

  if not optionsTable or type(optionsTable) ~= "table" then

    return parsed, errors

  end

  for i, option in ipairs(optionsTable) do

    local optionId    = tostring(i) .. "-" .. (option.label or "Unknown")

    local colorValue  = nil

    if useRGB then

      if option.hex then

        local ok, r, g, b = pcall(lib.math.hextorgb, option.hex)

        if ok and r and g and b then

          colorValue = { r = r, g = g, b = b }

        else

          errors[#errors + 1] = ("Failed to convert hex '%s' for colour option '%s'"):format(

            option.hex or "nil", option.label or "Unknown"

          )

        end

      else

        errors[#errors + 1] = ("Missing hex value for colour option '%s'"):format(option.label or "Unknown")

      end

    else

      if option.index then

        colorValue = option.index

      else

        errors[#errors + 1] = ("Missing index value for colour option '%s'"):format(option.label or "Unknown")

      end

    end

    if colorValue then

      parsed[#parsed + 1] = { id = optionId, color = colorValue }

    end

  end

  return parsed, errors

end

local function GetCameraData(cameraCfg)

  if not cameraCfg then

    return {

      preset     = "Car",

      coords     = { x = 0, y = 0, z = 0, w = 0 },

      zoomLevels = { "5", "8", "12", "8" },

    }

  end

  local zoomLevels

  if cameraCfg.positions then

    zoomLevels = {}

    for _, pos in ipairs(cameraCfg.positions) do

      zoomLevels[#zoomLevels + 1] = tostring(pos)

    end

  else

    zoomLevels = { "5", "8", "12", "8" }

  end

  local coords = {

    x = (cameraCfg.coords and cameraCfg.coords.x) or 0,

    y = (cameraCfg.coords and cameraCfg.coords.y) or 0,

    z = (cameraCfg.coords and cameraCfg.coords.z) or 0,

    w = (cameraCfg.coords and cameraCfg.coords.w) or 0,

  }

  return {

    preset     = cameraCfg.name or "Car",

    coords     = coords,

    zoomLevels = zoomLevels,

  }

end

local function ParseLocationConfig(locationId, rawConfig, existingDbData)

  local errors  = {}

  local locData = { id = locationId }

  if rawConfig.label and rawConfig.label ~= "" then

    locData.name = rawConfig.label

  elseif existingDbData and existingDbData.label and existingDbData.label ~= "" then

    locData.name = existingDbData.label

  else

    locData.name = locationId

  end

  if rawConfig.type == "owned" then

    locData.type = "owned"

  elseif rawConfig.type == "self-service" then

    locData.type = "selfService"

  else

    locData.type = "selfService"

    errors[#errors + 1] = ("Unknown type '%s', defaulting to 'selfService'"):format(tostring(rawConfig.type))

  end

  if locData.type == "owned" and rawConfig.job then

    local isValid, _ = Framework.Server.IsValidJob(rawConfig.job)

    if isValid then

      locData.job_name        = rawConfig.job

      locData.job_rank_mapping = GetJobRankMapping(rawConfig.job)

      if not locData.job_rank_mapping then

        errors[#errors + 1] = ("Job '%s' is valid but could not build rank mapping"):format(rawConfig.job)

      end

    else

      errors[#errors + 1] = ("Invalid job '%s', skipping job configuration"):format(rawConfig.job)

    end

  end

  locData.job_rank_permissions = nil

  if existingDbData then

    locData.balance      = existingDbData.balance or 0

    locData.owner_id     = existingDbData.owner_id

    locData.owner_name   = existingDbData.owner_name

    locData.employee_commission = existingDbData.employee_commission or 10

  else

    locData.balance             = 0

    locData.employee_commission = 10

  end

  if rawConfig.zone then

    if type(rawConfig.zone) == "table" and #rawConfig.zone >= 3 then

      locData.dealership_zone = {}

      for _, pt in ipairs(rawConfig.zone) do

        locData.dealership_zone[#locData.dealership_zone + 1] = { x = pt.x, y = pt.y, z = pt.z }

      end

    end

  elseif rawConfig.openShowroom and rawConfig.openShowroom.coords then

    local distance = rawConfig.directSaleDistance or 50.0

    locData.dealership_zone = BuildSquareZone(rawConfig.openShowroom.coords, distance)

  else

    errors[#errors + 1] = "Missing zone or openShowroom.coords, cannot generate dealership_zone"

  end

  if rawConfig.openShowroom and rawConfig.openShowroom.coords then

    locData.showroom_coords = {

      BuildZonePoint(

        rawConfig.openShowroom.coords,

        rawConfig.openShowroom.size or 5,

        rawConfig.blip,

        rawConfig.markers,

        rawConfig.hideBlip,

        rawConfig.hideMarkers

      )

    }

  else

    errors[#errors + 1] = "Missing openShowroom configuration (required)"

  end

  if rawConfig.openManagement and rawConfig.openManagement.coords then

    locData.management_coords = {

      BuildZonePoint(

        rawConfig.openManagement.coords,

        rawConfig.openManagement.size or 5,

        rawConfig.blip,

        rawConfig.markers,

        rawConfig.hideBlip,

        rawConfig.hideMarkers

      )

    }

  end

  if rawConfig.purchaseSpawn then

    locData.purchase_vehicle_coords = CopyCoords(rawConfig.purchaseSpawn)

    locData.trucking_vehicle_coords  = CopyCoords(rawConfig.purchaseSpawn)

  else

    errors[#errors + 1] = "Missing purchaseSpawn configuration (required)"

  end

  locData.enable_finance     = rawConfig.enableFinance     == true

  locData.enable_sell_vehicle = rawConfig.enableSellVehicle == true

  if rawConfig.sellVehicle and rawConfig.sellVehicle.coords then

    locData.sell_vehicle_coords = {

      BuildZonePoint(

        rawConfig.sellVehicle.coords,

        rawConfig.sellVehicle.size or 5,

        rawConfig.blip,

        rawConfig.markers,

        rawConfig.hideBlip,

        rawConfig.hideMarkers

      )

    }

  end

  if rawConfig.sellVehiclePercent then

    locData.sell_vehicle_percent = math.floor(rawConfig.sellVehiclePercent * 100)

  else

    locData.sell_vehicle_percent = 60

  end

  locData.enable_test_drive = rawConfig.enableTestDrive == true

  if rawConfig.testDriveSpawn then

    locData.test_drive_coords = CopyCoords(rawConfig.testDriveSpawn)

  end

  if rawConfig.categories and type(rawConfig.categories) == "table" and #rawConfig.categories > 0 then

    locData.categories = rawConfig.categories

  else

    errors[#errors + 1] = "Missing or empty categories configuration (required)"

  end

  locData.camera_data = GetCameraData(rawConfig.camera)

  locData.colour_selection_type = "RGB"

  if Config.VehicleColourOptions and #Config.VehicleColourOptions > 0 then

    local useRGB = Config.UseRGBColors == true

    locData.colour_selection_type = useRGB and "RGBOPT" or "IDOPT"

    local colourOptions, colourErrors = ParseColourOptions(useRGB, Config.VehicleColourOptions)

    locData.colour_options = colourOptions

    for _, err in ipairs(colourErrors) do

      errors[#errors + 1] = err

    end

  end

  locData.enable_purchase = rawConfig.disableShowroomPurchase ~= true

  if rawConfig.showroomJobWhitelist and type(rawConfig.showroomJobWhitelist) == "table" then

    locData.showroom_job_whitelist = rawConfig.showroomJobWhitelist

  end

  if rawConfig.showroomGangWhitelist and type(rawConfig.showroomGangWhitelist) == "table" then

    locData.showroom_gang_whitelist = rawConfig.showroomGangWhitelist

  end

  if rawConfig.societyPurchaseJobWhitelist and type(rawConfig.societyPurchaseJobWhitelist) == "table" then

    locData.society_purchase_job_whitelist = rawConfig.societyPurchaseJobWhitelist

  end

  if rawConfig.societyPurchaseGangWhitelist and type(rawConfig.societyPurchaseGangWhitelist) == "table" then

    locData.society_purchase_gang_whitelist = rawConfig.societyPurchaseGangWhitelist

  end

  return { data = locData, errors = errors }

end

local function LocationExists(locationId)

  local count = MySQL.scalar.await(

    "SELECT COUNT(*) FROM dealership_locations WHERE id = ?",

    { locationId }

  )

  return count and count > 0

end

local function InsertLocation(locData)

  local ok, err = pcall(function()

    MySQL.insert.await([[

      INSERT INTO dealership_locations (

        id, name, type, job_name, job_rank_permissions, job_rank_mapping,

        balance, owner_id, owner_name, employee_commission,

        dealership_zone, showroom_coords, management_coords,

        purchase_vehicle_coords, trucking_vehicle_coords,

        enable_finance, enable_sell_vehicle, sell_vehicle_coords, sell_vehicle_percent,

        enable_test_drive, test_drive_coords, categories, camera_data,

        colour_selection_type, colour_options, enable_purchase,

        showroom_job_whitelist, showroom_gang_whitelist,

        society_purchase_job_whitelist, society_purchase_gang_whitelist

      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)

    ]], {

      locData.id,

      locData.name,

      locData.type,

      locData.job_name,

      locData.job_rank_permissions and json.encode(locData.job_rank_permissions) or nil,

      locData.job_rank_mapping      and json.encode(locData.job_rank_mapping)     or nil,

      locData.balance or 0,

      locData.owner_id,

      locData.owner_name,

      locData.employee_commission or 10,

      locData.dealership_zone   and json.encode(locData.dealership_zone)   or nil,

      json.encode(locData.showroom_coords),

      locData.management_coords  and json.encode(locData.management_coords) or nil,

      json.encode(locData.purchase_vehicle_coords),

      locData.trucking_vehicle_coords and json.encode(locData.trucking_vehicle_coords) or nil,

      locData.enable_finance      and 1 or 0,

      locData.enable_sell_vehicle and 1 or 0,

      locData.sell_vehicle_coords  and json.encode(locData.sell_vehicle_coords) or nil,

      locData.sell_vehicle_percent,

      locData.enable_test_drive   and 1 or 0,

      locData.test_drive_coords    and json.encode(locData.test_drive_coords)  or nil,

      json.encode(locData.categories),

      json.encode(locData.camera_data),

      locData.colour_selection_type,

      locData.colour_options and json.encode(locData.colour_options) or nil,

      locData.enable_purchase and 1 or 0,

      locData.showroom_job_whitelist             and json.encode(locData.showroom_job_whitelist)             or nil,

      locData.showroom_gang_whitelist            and json.encode(locData.showroom_gang_whitelist)            or nil,

      locData.society_purchase_job_whitelist     and json.encode(locData.society_purchase_job_whitelist)     or nil,

      locData.society_purchase_gang_whitelist    and json.encode(locData.society_purchase_gang_whitelist)    or nil,

    })

  end)

  if not ok then

    return false, tostring(err)

  end

  return true, nil

end

function Import.Server.ImportV1Locations(locationsTable)

  if not locationsTable then

    locationsTable = Config.DealershipLocations

  end

  local result = {

    success  = true,

    imported = {},

    skipped  = {},

    errors   = {},

  }

  if not TableExists("dealership_locations") then

    result.success = false

    result.errors._global = { "Database table 'dealership_locations' does not exist. Please run the v2 migration SQL first." }

    return result

  end

  if not locationsTable or type(locationsTable) ~= "table" then

    result.success = false

    result.errors._global = { "No locations provided and Config.DealershipLocations is not a valid table." }

    return result

  end

  local legacyData = {}

  if TableExists("dealership_data") then

    local rows = MySQL.query.await("SELECT * FROM dealership_data")

    if rows then

      for _, row in ipairs(rows) do

        legacyData[row.name] = row

      end

    end

  end

  local parsedLocations = {}

  local hasBlockingErrors = false

  for locId, rawCfg in pairs(locationsTable) do

    if LocationExists(locId) then

      result.skipped[#result.skipped + 1] = locId

    else

      local parsed = ParseLocationConfig(locId, rawCfg, legacyData[locId])

      parsedLocations[locId] = parsed

      local blockingErrs = {}

      for _, errMsg in ipairs(parsed.errors) do

        if errMsg:find("%(required%)") then

          blockingErrs[#blockingErrs + 1] = errMsg

          hasBlockingErrors = true

        end

      end

      if #parsed.errors > 0 then

        result.errors[locId] = parsed.errors

      end

    end

  end

  if hasBlockingErrors then

    result.success = false

    result.errors._global = result.errors._global or {}

    result.errors._global[#result.errors._global + 1] = "Blocking errors found. Fix the issues above before importing."

    return result

  end

  for locId, parsed in pairs(parsedLocations) do

    local ok, dbErr = InsertLocation(parsed.data)

    if ok then

      result.imported[#result.imported + 1] = locId

    else

      result.success = false

      result.errors[locId] = result.errors[locId] or {}

      result.errors[locId][#result.errors[locId] + 1] = "Database insert failed: " .. (dbErr or "Unknown error")

    end

  end

  if #result.imported > 0 then

    TriggerClientEvent("jg-dealerships:client:create-dealership-locations", -1, nil, true)

  end

  return result

end

lib.callback.register("jg-dealerships:server:import-v1-locations",

  function(source, params)

    if not Framework.Server.IsAdmin(source) then

      Framework.Server.Notify(source, Locale.insufficientPermissions, "error")

      DebugPrint("Player " .. source .. " tried to import locations without permission", "warning")

      return {

        success  = false,

        imported = {},

        skipped  = {},

        errors   = { _global = { "Insufficient permissions" } },

      }

    end

    local locations = (params.source == "default") and DEFAULT_LOCATIONS or Config.DealershipLocations

    local result    = Import.Server.ImportV1Locations(locations)

    if result.success and #result.imported > 0 and params.syncStock then

      local totalAdded = 0

      for _, locId in ipairs(result.imported) do

        local loc = Locations.Server.GetById(locId, true)

        if loc and loc.categories and #loc.categories > 0 then

          local syncResult = Locations.Server.SyncStockByCategories(locId, loc.categories, {}, false)

          totalAdded = totalAdded + syncResult.added

        end

      end

      if totalAdded > 0 then

        Framework.Server.Notify(source, ("Stock sync: %d vehicles added"):format(totalAdded), "success")

      end

    end

    if result.success and #result.imported > 0 then

      local skippedStr = #result.skipped > 0 and table.concat(result.skipped, ", ") or "None"

      SendWebhook(source, Webhooks.Admin, "Admin: Imported Locations", "success", {

        { key = "Source",     value = (params.source == "default") and "Default Locations" or "Config.lua" },

        { key = "Imported",   value = table.concat(result.imported, ", ") },

        { key = "Skipped",    value = skippedStr },

        { key = "Stock Sync", value = params.syncStock and "Yes" or "No" },

      })

    end

    return result

  end

)

local function ClearAllVehicleData()

  MySQL.query.await("DELETE FROM dealership_dispveh")

  MySQL.query.await("DELETE FROM dealership_orders")

  MySQL.query.await("DELETE FROM dealership_sales")

  MySQL.query.await("DELETE FROM dealership_stock")

  MySQL.query.await("DELETE FROM dealership_vehicles")

end

local function GetExistingVehicleSpawnCodes()

  local rows = MySQL.query.await("SELECT spawn_code FROM dealership_vehicles")

  local existing = {}

  if rows then

    for _, row in ipairs(rows) do

      existing[row.spawn_code] = true

    end

  end

  return existing

end

local function GetLocationCategoryMap()

  local allLocations = Locations.Server.GetAll(true)

  local categoryMap  = {}

  for _, loc in ipairs(allLocations) do

    categoryMap[loc.id] = loc.categories or {}

  end

  return categoryMap

end

local function ArrayContains(arr, value)

  if not arr or #arr == 0 then return true end
  for _, v in ipairs(arr) do

    if v == value then return true end

  end

  return false

end

local function GetQBCoreVehicles()

  if Config.Framework ~= "QBCore" then

    return nil, false

  end

  local vehicles = QBCore and QBCore.Shared and QBCore.Shared.Vehicles

  if not vehicles then

    return nil, false

  end

  local hasShopData = false

  for _, veh in pairs(vehicles) do

    if veh.shop then

      hasShopData = true

      break

    end

  end

  return vehicles, hasShopData

end

local function GetQBoxVehicles()

  if Config.Framework ~= "Qbox" then

    return nil, false

  end

  local ok, vehicles = pcall(function()

    return exports.qbx_core:GetVehiclesByHash()

  end)

  if not ok or not vehicles then

    return nil, false

  end

  local hasShopData = false

  for _, veh in pairs(vehicles) do

    if veh.shop then

      hasShopData = true

      break

    end

  end

  return vehicles, hasShopData

end

local function GetESXVehicles()

  if Config.Framework ~= "ESX" then

    return nil, false

  end

  local rows = MySQL.query.await("SELECT * FROM vehicles ORDER BY name DESC")

  if not rows then

    return nil, false

  end

  return rows, false

end

Import.Server.PreviewVehiclesData = function(source)

  local vehicles, hasShopData

  if source == "qbshared" then

    vehicles, hasShopData = GetQBCoreVehicles()

    if not vehicles then

      return { available = false, count = 0, hasShopData = false,

               error = "QBCore.Shared.Vehicles not available (wrong framework or not loaded)" }

    end

  elseif source == "qbx_shared" then

    vehicles, hasShopData = GetQBoxVehicles()

    if not vehicles then

      return { available = false, count = 0, hasShopData = false,

               error = "exports.qbx_core:GetVehiclesByHash() not available (wrong framework or not loaded)" }

    end

  elseif source == "esxdb" then

    vehicles, hasShopData = GetESXVehicles()

    if not vehicles then

      return { available = false, count = 0, hasShopData = false,

               error = "ESX vehicles table not found or empty" }

    end

  else

    return { available = false, count = 0, hasShopData = false, error = "Unknown import source" }

  end

  local count = 0

  for _ in pairs(vehicles) do count = count + 1 end

  return { available = true, count = count, hasShopData = hasShopData }

end

lib.callback.register("jg-dealerships:server:preview-vehicles-data",

  function(source, requestedSource)

    if not Framework.Server.IsAdmin(source) then

      return { available = false, count = 0, hasShopData = false, error = "INSUFFICIENT_PERMISSIONS" }

    end

    return Import.Server.PreviewVehiclesData(requestedSource)

  end

)

local function AddVehicleToDb(spawnCode, hashKey, brand, model, category, price,

                               shop, locationCategoryMap, stockMethod)

  MySQL.query.await([[

    INSERT IGNORE INTO dealership_vehicles (spawn_code, hashkey, brand, model, category, price)

    VALUES(?, ?, ?, ?, ?, ?)

  ]], { spawnCode, hashKey, brand, model, category, price })

  local shopFilter = {}

  if stockMethod == "byShop" and shop then

    if type(shop) == "string" then

      shopFilter[shop] = true

    elseif type(shop) == "table" then

      for _, s in ipairs(shop) do

        shopFilter[s] = true

      end

    end

    for shopName in pairs(shopFilter) do

      if locationCategoryMap[shopName] then

        MySQL.query.await([[

          INSERT IGNORE INTO dealership_stock (vehicle, dealership, stock, price)

          VALUES(?, ?, ?, ?)

        ]], { spawnCode, shopName, 0, price })

      end

    end

  else

    for locId, categories in pairs(locationCategoryMap) do

      if ArrayContains(categories, category) then

        MySQL.query.await([[

          INSERT IGNORE INTO dealership_stock (vehicle, dealership, stock, price)

          VALUES(?, ?, ?, ?)

        ]], { spawnCode, locId, 0, price })

      end

    end

  end

end

local function ImportQBCoreVehicles(behaviour, stockMethod)

  local vehicles = GetQBCoreVehicles()

  if not vehicles then

    return { success = false, count = 0, imported = 0,

             error = "QBCore.Shared.Vehicles not found" }

  end

  if behaviour == "Overwrite" then ClearAllVehicleData() end

  local existing = (behaviour == "Append") and GetExistingVehicleSpawnCodes() or {}

  local locationCategoryMap = GetLocationCategoryMap()

  local importedCount = 0

  for spawnCode, vehData in pairs(vehicles) do

    local trimmedCode = Trim(spawnCode)

    if behaviour == "Append" and existing[trimmedCode] then

    else

      AddVehicleToDb(

        trimmedCode,

        joaat(spawnCode),

        vehData.brand,

        vehData.name,

        vehData.category,

        vehData.price,

        vehData.shop,

        locationCategoryMap,

        stockMethod

      )

      importedCount = importedCount + 1

    end

  end

  Showroom.Server.ClearVehicleCache()

  local totalCount = MySQL.scalar.await("SELECT COUNT(*) FROM dealership_vehicles") or 0

  return { success = true, count = totalCount, imported = importedCount }

end

local function ImportQBoxVehicles(behaviour, stockMethod)

  local vehicles = GetQBoxVehicles()

  if not vehicles then

    return { success = false, count = 0, imported = 0,

             error = "exports.qbx_core:GetVehiclesByHash() returned nil" }

  end

  if behaviour == "Overwrite" then ClearAllVehicleData() end

  local existing = (behaviour == "Append") and GetExistingVehicleSpawnCodes() or {}

  local locationCategoryMap = GetLocationCategoryMap()

  local importedCount = 0

  for hashKey, vehData in pairs(vehicles) do

    local trimmedCode = Trim(vehData.model)

    if behaviour == "Append" and existing[trimmedCode] then

    else

      AddVehicleToDb(

        trimmedCode,

        hashKey,
        vehData.brand,

        vehData.name,

        vehData.category,

        vehData.price,

        vehData.shop,

        locationCategoryMap,

        stockMethod

      )

      importedCount = importedCount + 1

    end

  end

  Showroom.Server.ClearVehicleCache()

  local totalCount = MySQL.scalar.await("SELECT COUNT(*) FROM dealership_vehicles") or 0

  return { success = true, count = totalCount, imported = importedCount }

end

local function ImportESXVehicles(behaviour, stockMethod)

  local vehicles = GetESXVehicles()

  if not vehicles then

    return { success = false, count = 0, imported = 0,

             error = "Could not query ESX vehicles table" }

  end

  if behaviour == "Overwrite" then ClearAllVehicleData() end

  local existing = (behaviour == "Append") and GetExistingVehicleSpawnCodes() or {}

  local locationCategoryMap = GetLocationCategoryMap()

  local importedCount = 0

  for _, vehData in pairs(vehicles) do

    local trimmedCode = Trim(vehData.model)

    if behaviour == "Append" and existing[trimmedCode] then

    else

      AddVehicleToDb(

        trimmedCode,

        joaat(vehData.model),

        nil,
        vehData.name,

        vehData.category,

        vehData.price,

        nil,
        locationCategoryMap,

        stockMethod

      )

      importedCount = importedCount + 1

    end

  end

  Showroom.Server.ClearVehicleCache()

  local totalCount = MySQL.scalar.await("SELECT COUNT(*) FROM dealership_vehicles") or 0

  return { success = true, count = totalCount, imported = importedCount }

end

function Import.Server.ImportVehiclesData(source, behaviour, stockMethod)

  behaviour   = behaviour  or "Append"

  stockMethod = stockMethod or "byCategory"

  if source == "qbshared" then

    return ImportQBCoreVehicles(behaviour, stockMethod)

  elseif source == "qbx_shared" then

    return ImportQBoxVehicles(behaviour, stockMethod)

  elseif source == "esxdb" then

    return ImportESXVehicles(behaviour, stockMethod)

  end

  return { success = false, count = 0, imported = 0, error = "UNSUPPORTED_SOURCE" }

end

lib.callback.register("jg-dealerships:server:import-vehicles-data",

  function(source, requestedSource, behaviour, stockMethod)

    if not Framework.Server.IsAdmin(source) then

      Framework.Server.Notify(source, Locale.insufficientPermissions, "error")

      DebugPrint("Player " .. source .. " tried to import vehicles without permission", "warning")

      return { success = false, count = 0, error = "INSUFFICIENT_PERMISSIONS" }

    end

    local result = Import.Server.ImportVehiclesData(requestedSource, behaviour, stockMethod)

    if result.success then

      local imported = result.imported or result.count

      Framework.Server.Notify(source,

        ("Import successful! %d vehicles imported (%d total)"):format(imported, result.count),

        "success"

      )

      local sourceLabels = {

        qbshared    = "QBCore Shared",

        qbx_shared  = "QBox Shared",

        esxdb       = "ESX Database",

      }

      SendWebhook(source, Webhooks.Admin, "Admin: Vehicles Imported", "success", {

        { key = "Method",           value = sourceLabels[requestedSource] or requestedSource },

        { key = "Behaviour",        value = behaviour },

        { key = "Stock Method",     value = stockMethod },

        { key = "Vehicles Imported", value = imported },

        { key = "Total Vehicles",   value = result.count },

      })

    else

      Framework.Server.Notify(source,

        string.gsub(Locale.importFailed, "%%{value}", result.error or "Unknown error"),

        "error"

      )

    end

    return result

  end

)
