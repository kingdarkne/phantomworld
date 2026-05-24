Locations = Locations or {}

Locations.Client = Locations.Client or {}

local cachedLocations = {}

local locationInteractions = {}

local employeeStatusCache = {}
local showroomPermissionCache = {}
local isCreatingInteractions = false
local hasInitiallyLoaded = false
local interactionTypeConfigs = {

  showroom_coords = {

    getKeybind = function() return Config.OpenShowroomKeyBind end,

    getPrompt = function() return Config.OpenShowroomPrompt end,

    condition = function() return true end,

    canInteract = function(location)

      return showroomPermissionCache[location.id] ~= false

    end,

    hasPermissionRestriction = true,

    callback = function(location) Showroom.Client.Open(location.id) end

  },

  management_coords = {

    getKeybind = function() return Config.OpenManagementKeyBind end,

    getPrompt = function() return Config.OpenManagementPrompt end,

    condition = function(location) return location.type == "owned" end,

    canInteract = function(location)

      return employeeStatusCache[location.id] == true

    end,

    hasPermissionRestriction = true,

    callback = function(location) DealershipManagement.Client.Open(location.id) end

  },

  sell_vehicle_coords = {

    getKeybind = function() return Config.SellVehicleKeyBind end,

    getPrompt = function() return Config.SellVehiclePrompt end,

    condition = function(location) return location.enable_sell_vehicle end,

    canInteract = function(location)

      return showroomPermissionCache[location.id] ~= false

    end,

    hasPermissionRestriction = true,

    callback = function(location) SellVehicle.Client.Request(location.id) end

  }

}

function Locations.Client.IsEmployeeAtLocation(locationId)

  return employeeStatusCache[locationId] == true

end

function Locations.Client.HasShowroomAccess(locationId)

  return showroomPermissionCache[locationId] ~= false

end

function Locations.Client.RefreshEmployeeStatusCache(locations, forceServerCheck)

  locations = locations or cachedLocations or {}

  for _, location in pairs(locations) do

    Locations.Client.RefreshSingleLocationCache(location, forceServerCheck)

  end

end

function Locations.Client.RefreshSingleLocationCache(location, forceServerCheck)

  if not location then return end

  if forceServerCheck then

    local showroomAllowed = lib.callback.await("jg-dealerships:server:check-showroom-whitelist", false, location.id)

    showroomPermissionCache[location.id] = showroomAllowed

    if location.type == "owned" then

      local result = lib.callback.await("jg-dealerships:server:is-employee", false, location.id, false)

      employeeStatusCache[location.id] = result and result.isEmployee or false

    end

  else

    showroomPermissionCache[location.id] = location.playerCanAccessShowroom ~= false

    employeeStatusCache[location.id] = location.playerIsEmployee == true

  end

  DebugPrint("[RefreshCache] Location: " .. location.id .. " (" .. location.name .. ") showroom: " .. tostring(showroomPermissionCache[location.id]) .. ", employee: " .. tostring(employeeStatusCache[location.id]), "debug")

end

local function createInteraction(location, interactionType, customCoords)

  if not location then return false end

  local config = interactionTypeConfigs[interactionType]

  if not config then return false end

  if not config.condition(location) then return false end

  local coords = customCoords or location[interactionType]

  if not coords or (type(coords) == "table" and #coords == 0) then return false end

  if not locationInteractions[location.id] then

    locationInteractions[location.id] = {}

  end

  if locationInteractions[location.id][interactionType] then

    Interactions.Client.Remove(locationInteractions[location.id][interactionType])

  end

  local canInteract = config.canInteract and function() return config.canInteract(location) end or nil

  local blipName = location.name

  if Config.BlipNameFormat then

    blipName = Config.BlipNameFormat:format(location.name)

  end

  locationInteractions[location.id][interactionType] = Interactions.Client.Create(

    coords,

    config.getKeybind(),

    config.getPrompt(),

    function() config.callback(location) end,

    blipName,

    canInteract

  )

  return true

end

function Locations.Client.GetAllInteractionData()

  return locationInteractions

end

function Locations.Client.GetLocations(ignoreCache)

  if cachedLocations and #cachedLocations > 0 and not ignoreCache then

    return cachedLocations

  end

  cachedLocations = lib.callback.await("jg-dealerships:server:get-all-locations", false)

  return cachedLocations

end

function Locations.Client.GetLocationById(id)

  local locations = Locations.Client.GetLocations()

  for _, location in ipairs(locations) do

    if location.id == id then

      return location

    end

  end

  return false

end

function Locations.Client.RemoveAllInteractions()

  for _, interactionTypes in pairs(locationInteractions) do

    for _, interactions in pairs(interactionTypes) do

      Interactions.Client.Remove(interactions)

    end

  end

  locationInteractions = {}

  hasInitiallyLoaded = false

end

function Locations.Client.RemoveLocationInteractions(locationId)

  if not locationId then return end

  if not locationInteractions[locationId] then return end

  for _, interactions in pairs(locationInteractions[locationId]) do

    Interactions.Client.Remove(interactions)

  end

  locationInteractions[locationId] = nil

end

function Locations.Client.RemoveInteractionType(locationId, interactionType)

  if not locationId or not interactionType then return end

  if not locationInteractions[locationId] then return end

  if not locationInteractions[locationId][interactionType] then return end

  Interactions.Client.Remove(locationInteractions[locationId][interactionType])

  locationInteractions[locationId][interactionType] = nil

end

function Locations.Client.RecreateInteractionType(locationId, interactionType)

  if not locationId or not interactionType then return end

  local location = Locations.Client.GetLocationById(locationId)

  if not location then return end

  createInteraction(location, interactionType)

end

function Locations.Client.RecreateInteractionTypeFromData(locationId, interactionType, interactions)

  if not locationId or not interactionType then return end

  if not interactions or #interactions == 0 then return end

  local location = Locations.Client.GetLocationById(locationId)

  if not location then return end

  createInteraction(location, interactionType, interactions)

end

function Locations.Client.RecreatePermissionRestrictedInteractions()

  if not hasInitiallyLoaded then

    DebugPrint("[RecreatePermissionRestrictedInteractions] Skipping - initial load not complete", "debug")

    return

  end

  if isCreatingInteractions then

    DebugPrint("[RecreatePermissionRestrictedInteractions] Skipping - already creating interactions", "debug")

    return

  end

  isCreatingInteractions = true

  local locations = Locations.Client.GetLocations()

  Locations.Client.RefreshEmployeeStatusCache(locations, true)

  for _, location in pairs(locations) do

    for interactionType, config in pairs(interactionTypeConfigs) do

      if config.hasPermissionRestriction then

        createInteraction(location, interactionType)

      end

    end

  end

  isCreatingInteractions = false

end

function Locations.Client.RecreatePermissionRestrictedInteractionsForLocation(dealershipId)

  if not hasInitiallyLoaded then

    DebugPrint("[RecreatePermissionRestrictedInteractionsForLocation] Skipping - initial load not complete", "debug")

    return

  end

  local location = Locations.Client.GetLocationById(dealershipId)

  if not location then

    DebugPrint("[RecreatePermissionRestrictedInteractionsForLocation] Location not found: " .. tostring(dealershipId), "debug")

    return

  end

  Locations.Client.RefreshSingleLocationCache(location, true)

  for interactionType, config in pairs(interactionTypeConfigs) do

    if config.hasPermissionRestriction then

      createInteraction(location, interactionType)

    end

  end

end

function Locations.Client.CreateAllInteractions(locations, ignoreCache)

  if isCreatingInteractions then

    DebugPrint("[CreateAllInteractions] Skipping - already creating interactions", "debug")

    return

  end

  isCreatingInteractions = true

  Locations.Client.RemoveAllInteractions()

  if DealershipZones and DealershipZones.Client and DealershipZones.Client.RemoveAllZones then

    DealershipZones.Client.RemoveAllZones()

  end

  DisplayVehicles.Client.DeleteAll()

  locations = locations or Locations.Client.GetLocations(ignoreCache) or {}

  cachedLocations = locations

  Locations.Client.RefreshEmployeeStatusCache(locations, false)

  for _, location in pairs(locations) do

    for interactionType in pairs(interactionTypeConfigs) do

      createInteraction(location, interactionType)

    end

    DisplayVehicles.Client.SpawnAll(location.id)

    if DealershipZones and DealershipZones.Client and DealershipZones.Client.CreateZone then

      if location.dealership_zone then

        local zoneData = location.dealership_zone

        if type(zoneData) == "table" then

          if zoneData[1] and zoneData[1].x then

            local convertedPoints = {}

            for i, point in ipairs(zoneData) do

              convertedPoints[i] = vec3(point.x, point.y, point.z)

            end

            zoneData = { points = convertedPoints }

          end

          if zoneData.points then

            DealershipZones.Client.CreateZone(location.id, zoneData)

          end

        end

      end

    end

  end

  isCreatingInteractions = false

  hasInitiallyLoaded = true

end

local function createLocationInteractions(location)

  if not location then return end

  DebugPrint(string.format("[CreateLocationInteractions] Location: %s, playerCanAccessShowroom: %s, playerIsEmployee: %s, type: %s", 

    location.id or "nil", 

    tostring(location.playerCanAccessShowroom), 

    tostring(location.playerIsEmployee),

    tostring(location.type)), "debug")

  if location.playerCanAccessShowroom ~= nil then

    showroomPermissionCache[location.id] = location.playerCanAccessShowroom

    employeeStatusCache[location.id] = location.playerIsEmployee == true

    DebugPrint(string.format("[CreateLocationInteractions] Using cached permissions - showroom: %s, employee: %s", 

      tostring(showroomPermissionCache[location.id]), 

      tostring(employeeStatusCache[location.id])), "debug")

  else

    DebugPrint("[CreateLocationInteractions] No cached permissions, fetching from server...", "debug")

    local showroomAllowed = lib.callback.await("jg-dealerships:server:check-showroom-whitelist", false, location.id)

    showroomPermissionCache[location.id] = showroomAllowed

    if location.type == "owned" then

      local result = lib.callback.await("jg-dealerships:server:is-employee", false, location.id, false)

      employeeStatusCache[location.id] = result and result.isEmployee or false

      DebugPrint(string.format("[CreateLocationInteractions] Server returned employee status: %s", 

        tostring(employeeStatusCache[location.id])), "debug")

    end

  end

  for interactionType in pairs(interactionTypeConfigs) do

    createInteraction(location, interactionType)

  end

  DisplayVehicles.Client.SpawnAll(location.id)

  if location.dealership_zone then

    local zoneData = location.dealership_zone

    if type(zoneData) == "table" then

      if zoneData[1] and zoneData[1].x then

        local convertedPoints = {}

        for i, point in ipairs(zoneData) do

          convertedPoints[i] = vec3(point.x, point.y, point.z)

        end

        zoneData = { points = convertedPoints }

      end

      if zoneData.points then

        DealershipZones.Client.CreateZone(location.id, zoneData)

      end

    end

  end

end

function Locations.Client.AddLocation(location)

  if not location or not location.id then return end

  cachedLocations[#cachedLocations + 1] = location

  createLocationInteractions(location)

end

function Locations.Client.UpdateLocation(location)

  if not location or not location.id then return end

  Locations.Client.RemoveLocationInteractions(location.id)

  DealershipZones.Client.RemoveZone(location.id)

  DisplayVehicles.Client.DeleteLocation(location.id)

  for i, loc in ipairs(cachedLocations) do

    if loc.id == location.id then

      cachedLocations[i] = location

      break

    end

  end

  createLocationInteractions(location)

end

function Locations.Client.RefreshLocationInteractions(locationId)

  if not locationId then return end

  local location = Locations.Client.GetLocationById(locationId)

  if not location then return end

  DebugPrint("[RefreshLocationInteractions] Refreshing interactions for: " .. locationId, "debug")

  Locations.Client.RemoveLocationInteractions(locationId)

  for interactionType in pairs(interactionTypeConfigs) do

    createInteraction(location, interactionType)

  end

  DisplayVehicles.Client.DeleteLocation(locationId)

  DisplayVehicles.Client.SpawnAll(locationId)

end

RegisterNetEvent("jg-dealerships:client:update-location", function(location)

  if not location then return end

  DebugPrint("[Client Event] Updating location: " .. tostring(location.id), "debug")

  Locations.Client.UpdateLocation(location)

end)

RegisterNetEvent("jg-dealerships:client:add-location", function(location)

  if not location then return end

  DebugPrint("[Client Event] Adding location: " .. tostring(location.id), "debug")

  Locations.Client.AddLocation(location)

end)

function Locations.Client.DeleteLocation(locationId)

  if not locationId then return end

  Locations.Client.RemoveLocationInteractions(locationId)

  DealershipZones.Client.RemoveZone(locationId)

  DisplayVehicles.Client.DeleteLocation(locationId)

  for i, loc in ipairs(cachedLocations) do

    if loc.id == locationId then

      table.remove(cachedLocations, i)

      break

    end

  end

  employeeStatusCache[locationId] = nil

  showroomPermissionCache[locationId] = nil

end

RegisterNetEvent("jg-dealerships:client:create-dealership-locations", function(locations, ignoreCache)

  if isCreatingInteractions then

    DebugPrint("[create-dealership-locations] Skipping - already creating interactions", "debug")

    return

  end

  isCreatingInteractions = true

  Locations.Client.RemoveAllInteractions()

  DealershipZones.Client.RemoveAllZones()

  DisplayVehicles.Client.DeleteAll()

  Wait(500)

  isCreatingInteractions = false

  Locations.Client.CreateAllInteractions(locations, ignoreCache)

end)

RegisterNetEvent("jg-dealerships:client:add-location", function(location)

  Locations.Client.AddLocation(location)

end)

RegisterNetEvent("jg-dealerships:client:update-location", function(location)

  Locations.Client.UpdateLocation(location)

end)

RegisterNetEvent("jg-dealerships:client:delete-location", function(locationId)

  Locations.Client.DeleteLocation(locationId)

end)

RegisterNetEvent("jg-dealerships:client:employee-status-changed", function(dealershipId)

  if dealershipId then

    Locations.Client.RecreatePermissionRestrictedInteractionsForLocation(dealershipId)

  else

    Locations.Client.RecreatePermissionRestrictedInteractions()

  end

end)

CreateThread(function()

  Wait(1000)

  if LocalPlayer.state.isLoggedIn and not hasInitiallyLoaded then

    Locations.Client.CreateAllInteractions()

  end

end)

AddEventHandler("onResourceStop", function(resourceName)

  if GetCurrentResourceName() ~= resourceName then return end

  Locations.Client.RemoveAllInteractions()

  if DealershipZones and DealershipZones.Client and DealershipZones.Client.RemoveAllZones then

    DealershipZones.Client.RemoveAllZones()

  end

end)
