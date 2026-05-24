Locations = Locations or {}

Locations.Server = Locations.Server or {}

local locationsCache = {}

function Locations.Server.ClearCache()

  locationsCache = {}

end

local function ParseLocation(location)

  if not location or type(location) ~= "table" then

    error("location must be a table")

  end

  location.showroom_coords = json.decode(location.showroom_coords)

  location.management_coords = json.decode(location.management_coords)

  location.dealership_zone = json.decode(location.dealership_zone)

  location.purchase_vehicle_coords = json.decode(location.purchase_vehicle_coords)

  location.trucking_vehicle_coords = json.decode(location.trucking_vehicle_coords)

  location.categories = json.decode(location.categories)

  location.sell_vehicle_coords = json.decode(location.sell_vehicle_coords)

  location.test_drive_coords = json.decode(location.test_drive_coords)

  location.camera_data = json.decode(location.camera_data)

  location.blip_data = json.decode(location.blip_data)

  location.marker_data = json.decode(location.marker_data)

  location.colour_options = json.decode(location.colour_options)

  location.showroom_job_whitelist = json.decode(location.showroom_job_whitelist)

  location.showroom_gang_whitelist = json.decode(location.showroom_gang_whitelist)

  location.society_purchase_job_whitelist = json.decode(location.society_purchase_job_whitelist)

  location.society_purchase_gang_whitelist = json.decode(location.society_purchase_gang_whitelist)

  location.job_rank_permissions = json.decode(location.job_rank_permissions)

  location.job_rank_mapping = json.decode(location.job_rank_mapping)

  local paymentMethods = json.decode(location.payment_methods)

  if not paymentMethods then

    paymentMethods = {"bank", "cash"}

  end

  location.payment_methods = paymentMethods

  return location

end

function Locations.Server.GetAll(includeDisabled)

  if type(locationsCache) == "table" and next(locationsCache) then

    if includeDisabled then

      return TableValues(locationsCache)

    end

    local filtered = {}

    for _, location in pairs(locationsCache) do

      if not location.disabled or location.disabled == 0 then

        filtered[#filtered + 1] = location

      end

    end

    return filtered

  end

  local results = MySQL.query.await("SELECT * FROM dealership_locations")

  for _, location in ipairs(results) do

    locationsCache[location.id] = ParseLocation(location)

  end

  if includeDisabled then

    return TableValues(locationsCache)

  end

  local filtered = {}

  for _, location in pairs(locationsCache) do

    if not location.disabled or location.disabled == 0 then

      filtered[#filtered + 1] = location

    end

  end

  return filtered

end

function Locations.Server.GetAllIdAndNameOnly()

  if not (type(locationsCache) == "table" and next(locationsCache)) then

    Locations.Server.GetAll()

  end

  local simplified = {}

  for _, location in pairs(locationsCache) do

    simplified[#simplified + 1] = {

      id = location.id,

      name = location.name

    }

  end

  return simplified

end

function Locations.Server.GetAllPublic(source)

  local locations = MySQL.query.await([[

    SELECT id, name, type, owner_id, job_name,

    dealership_zone, showroom_coords, management_coords,

    purchase_vehicle_coords, enable_sell_vehicle,

    sell_vehicle_coords, sell_vehicle_percent, enable_test_drive,

    test_drive_coords, colour_selection_type, colour_options,

    showroom_job_whitelist, showroom_gang_whitelist

    FROM dealership_locations

    WHERE disabled = 0

  ]])

  local playerJob = Framework.Server.GetPlayerJob(source)

  local playerGang = Framework.Server.GetPlayerGang(source)

  for i, location in ipairs(locations) do

    locations[i].dealership_zone = json.decode(location.dealership_zone or "{}")

    locations[i].showroom_coords = json.decode(location.showroom_coords or "{}")

    locations[i].management_coords = json.decode(location.management_coords or "{}")

    locations[i].purchase_vehicle_coords = json.decode(location.purchase_vehicle_coords or "{}")

    locations[i].sell_vehicle_coords = json.decode(location.sell_vehicle_coords or "{}")

    locations[i].test_drive_coords = json.decode(location.test_drive_coords or "{}")

    locations[i].blip_data = json.decode(location.blip_data or "{}")

    locations[i].colour_options = json.decode(location.colour_options or "{}")

    locations[i].marker_data = json.decode(location.marker_data or "{}")

    locations[i].showroom_job_whitelist = json.decode(location.showroom_job_whitelist or "{}")

    locations[i].showroom_gang_whitelist = json.decode(location.showroom_gang_whitelist or "{}")

    local hasJobWhitelist = locations[i].showroom_job_whitelist and next(locations[i].showroom_job_whitelist)

    local hasGangWhitelist = locations[i].showroom_gang_whitelist and next(locations[i].showroom_gang_whitelist)

    if not hasJobWhitelist and not hasGangWhitelist then

      locations[i].playerCanAccessShowroom = true

    else

      local passesJobCheck = false

      if hasJobWhitelist then

        passesJobCheck = CheckJobGangWhitelist(

          locations[i].showroom_job_whitelist,

          playerJob.name,

          playerJob.grade

        )

      end

      local passesGangCheck = false

      if hasGangWhitelist then

        passesGangCheck = CheckJobGangWhitelist(

          locations[i].showroom_gang_whitelist,

          playerGang.name,

          playerGang.grade

        )

      end

      locations[i].playerCanAccessShowroom = passesJobCheck or passesGangCheck

    end

    if location.type == "owned" then

      local isEmployee = Employees.Server.IsEmployee(source, location.id, nil, false)

      locations[i].playerIsEmployee = isEmployee and true or false

    else

      locations[i].playerIsEmployee = false

    end

    locations[i].showroom_job_whitelist = nil

    locations[i].showroom_gang_whitelist = nil

  end

  return locations

end

function Locations.Server.GetById(locationId, includeDisabled)

  if locationsCache[locationId] then

    local location = locationsCache[locationId]

    if not includeDisabled then

      if location.disabled and location.disabled == 1 then

        return false

      end

    end

    return location

  end

  local location = MySQL.single.await(

    "SELECT * FROM dealership_locations WHERE id = ?",

    {locationId}

  )

  if not location then

    return false

  end

  locationsCache[location.id] = ParseLocation(location)

  if not includeDisabled then

    if location.disabled and location.disabled == 1 then

      return false

    end

  end

  return locationsCache[location.id]

end

function Locations.Server.Create(data)

  local locationId = Utils.Server.GenerateUuid()

  local retries = 10

  while true do

    local exists = MySQL.scalar.await(

      "SELECT id FROM dealership_locations WHERE id = ?",

      {locationId}

    )

    if not (exists and retries > 0) then

      break

    end

    DebugPrint("uuid not available, trying again...")

    locationId = Utils.Server.GenerateUuid()

    retries = retries - 1

  end

  local paymentMethods = data.payment_methods and json.encode(data.payment_methods) or json.encode({"bank", "cash"})

  MySQL.insert.await([[

    INSERT INTO dealership_locations

    (id, name, type, job_name, job_rank_permissions, job_rank_mapping, dealership_zone, showroom_coords, management_coords, purchase_vehicle_coords,

    trucking_vehicle_coords, categories, enable_finance, enable_sell_vehicle, sell_vehicle_coords,

    sell_vehicle_percent, enable_test_drive, test_drive_coords, camera_data, colour_selection_type,

    colour_options, enable_purchase, showroom_job_whitelist, showroom_gang_whitelist,

    society_purchase_job_whitelist, society_purchase_gang_whitelist, payment_methods)

    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)

  ]], {

    locationId,

    data.name,

    data.type,

    data.job_name,

    data.job_rank_permissions and json.encode(data.job_rank_permissions),

    data.job_rank_mapping and json.encode(data.job_rank_mapping),

    data.dealership_zone and json.encode(data.dealership_zone),

    data.showroom_coords and json.encode(data.showroom_coords),

    data.management_coords and json.encode(data.management_coords),

    data.purchase_vehicle_coords and json.encode(data.purchase_vehicle_coords),

    data.trucking_vehicle_coords and json.encode(data.trucking_vehicle_coords),

    data.categories and json.encode(data.categories),

    data.enable_finance,

    data.enable_sell_vehicle,

    data.sell_vehicle_coords and json.encode(data.sell_vehicle_coords),

    data.sell_vehicle_percent,

    data.enable_test_drive,

    data.test_drive_coords and json.encode(data.test_drive_coords),

    data.camera_data and json.encode(data.camera_data),

    data.colour_selection_type,

    data.colour_options and json.encode(data.colour_options),

    data.enable_purchase,

    data.showroom_job_whitelist and json.encode(data.showroom_job_whitelist),

    data.showroom_gang_whitelist and json.encode(data.showroom_gang_whitelist),

    data.society_purchase_job_whitelist and json.encode(data.society_purchase_job_whitelist),

    data.society_purchase_gang_whitelist and json.encode(data.society_purchase_gang_whitelist),

    paymentMethods

  })

  data.id = locationId

  locationsCache[locationId] = data

  local locations = Locations.Server.GetAll(false)

  return locations, locationId

end

function Locations.Server.Update(locationId, data)

  local paymentMethods = data.payment_methods and json.encode(data.payment_methods) or json.encode({"bank", "cash"})

  MySQL.update.await([[

    UPDATE dealership_locations SET name = ?, type = ?, job_name = ?, job_rank_permissions = ?, job_rank_mapping = ?,

    dealership_zone = ?, showroom_coords = ?, management_coords = ?, purchase_vehicle_coords = ?, trucking_vehicle_coords = ?,

    categories = ?, enable_finance = ?,

    enable_sell_vehicle = ?, sell_vehicle_coords = ?, sell_vehicle_percent = ?,

    enable_test_drive = ?, test_drive_coords = ?, camera_data = ?,

    colour_selection_type = ?, colour_options = ?, enable_purchase = ?,

    showroom_job_whitelist = ?, showroom_gang_whitelist = ?,

    society_purchase_job_whitelist = ?, society_purchase_gang_whitelist = ?, payment_methods = ?

    WHERE id = ?

  ]], {

    data.name,

    data.type,

    data.job_name,

    data.job_rank_permissions and json.encode(data.job_rank_permissions),

    data.job_rank_mapping and json.encode(data.job_rank_mapping),

    data.dealership_zone and json.encode(data.dealership_zone),

    data.showroom_coords and json.encode(data.showroom_coords),

    data.management_coords and json.encode(data.management_coords),

    data.purchase_vehicle_coords and json.encode(data.purchase_vehicle_coords),

    data.trucking_vehicle_coords and json.encode(data.trucking_vehicle_coords),

    data.categories and json.encode(data.categories),

    data.enable_finance,

    data.enable_sell_vehicle,

    data.sell_vehicle_coords and json.encode(data.sell_vehicle_coords),

    data.sell_vehicle_percent,

    data.enable_test_drive,

    data.test_drive_coords and json.encode(data.test_drive_coords),

    data.camera_data and json.encode(data.camera_data),

    data.colour_selection_type,

    data.colour_options and json.encode(data.colour_options),

    data.enable_purchase,

    data.showroom_job_whitelist and json.encode(data.showroom_job_whitelist),

    data.showroom_gang_whitelist and json.encode(data.showroom_gang_whitelist),

    data.society_purchase_job_whitelist and json.encode(data.society_purchase_job_whitelist),

    data.society_purchase_gang_whitelist and json.encode(data.society_purchase_gang_whitelist),

    paymentMethods,

    locationId

  })

  data.id = locationId

  locationsCache[locationId] = data

  return Locations.Server.GetAll(false)

end

function Locations.Server.Delete(locationId)

  local coupons = MySQL.query.await(

    "SELECT id FROM dealership_coupons WHERE dealership_id = ?",

    {locationId}

  )

  for _, coupon in ipairs(coupons or {}) do

    MySQL.query.await(

      "DELETE FROM dealership_coupon_usage WHERE coupon_id = ?",

      {coupon.id}

    )

  end

  MySQL.query.await(

    "DELETE FROM dealership_coupons WHERE dealership_id = ?",

    {locationId}

  )

  MySQL.query.await(

    "DELETE FROM dealership_employees WHERE dealership = ?",

    {locationId}

  )

  MySQL.query.await(

    "DELETE FROM dealership_stock WHERE dealership = ?",

    {locationId}

  )

  MySQL.query.await(

    "DELETE FROM dealership_locations WHERE id = ?",

    {locationId}

  )

  locationsCache[locationId] = nil

  return Locations.Server.GetAll(false)

end

function Locations.Server.SetDisabled(locationId, disabled)

  local disabledValue = disabled and 1 or 0

  MySQL.update.await(

    "UPDATE dealership_locations SET disabled = ? WHERE id = ?",

    {disabledValue, locationId}

  )

  local location = MySQL.single.await(

    "SELECT * FROM dealership_locations WHERE id = ?",

    {locationId}

  )

  if location then

    locationsCache[locationId] = ParseLocation(location)

  end

  return true

end

function Locations.Server.RefreshLocation(locationId)

  local location = MySQL.single.await(

    "SELECT * FROM dealership_locations WHERE id = ?",

    {locationId}

  )

  if location then

    locationsCache[locationId] = ParseLocation(location)

    return locationsCache[locationId]

  end

  return nil

end

function Locations.Server.SyncStockByCategories(locationId, categoriesToAdd, categoriesToRemove, allowRemoval)

  local result = {

    added = 0,

    removed = 0

  }

  if categoriesToAdd and #categoriesToAdd > 0 then

    local vehicles = MySQL.query.await([[

      SELECT spawn_code, price FROM dealership_vehicles

      WHERE category IN (?)

    ]], {categoriesToAdd})

    if vehicles then

      for _, vehicle in ipairs(vehicles) do

        local insertId = MySQL.insert.await([[

          INSERT IGNORE INTO dealership_stock (vehicle, dealership, stock, price)

          VALUES (?, ?, 0, ?)

        ]], {

          vehicle.spawn_code,

          locationId,

          vehicle.price

        })

        if insertId then

          result.added = result.added + 1

        end

      end

    end

  end

  if allowRemoval and categoriesToRemove and #categoriesToRemove > 0 then

    local vehicles = MySQL.query.await([[

      SELECT spawn_code FROM dealership_vehicles

      WHERE category IN (?)

    ]], {categoriesToRemove})

    if vehicles then

      for _, vehicle in ipairs(vehicles) do

        local deleteResult = MySQL.query.await([[

          DELETE FROM dealership_stock

          WHERE vehicle = ? AND dealership = ?

        ]], {

          vehicle.spawn_code,

          locationId

        })

        if deleteResult and deleteResult.affectedRows and deleteResult.affectedRows > 0 then

          result.removed = result.removed + deleteResult.affectedRows

        end

      end

    end

  end

  if result.added > 0 or result.removed > 0 then

    Showroom.Server.ClearVehicleCache()

  end

  return result

end

lib.callback.register("jg-dealerships:server:get-all-locations", Locations.Server.GetAllPublic)
