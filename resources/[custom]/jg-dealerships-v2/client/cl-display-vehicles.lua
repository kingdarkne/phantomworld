if not DisplayVehicles then

  DisplayVehicles = {}

end

if not DisplayVehicles.Client then

  DisplayVehicles.Client = {}

end

local displayVehiclesByLocation = {}
local locationSpawning = {}
local locationShouldRespawn = {}
local isCreatingDisplayVehicle = false
local function DeleteLocationDisplayVehicles(locationId)

  local vehicles = displayVehiclesByLocation[locationId]

  if vehicles and #vehicles > 0 then

    for _, vehicleData in ipairs(vehicles) do

      if vehicleData.streamingPoint then

        vehicleData.streamingPoint:remove()

      end

      if vehicleData.entity and DoesEntityExist(vehicleData.entity) then

        DeleteEntity(vehicleData.entity)

      end

    end

  end

  displayVehiclesByLocation[locationId] = {}

end

function DisplayVehicles.Client.DeleteAll()

  for locationId in pairs(displayVehiclesByLocation) do

    DeleteLocationDisplayVehicles(locationId)

  end

end

function DisplayVehicles.Client.DeleteLocation(locationId)

  DeleteLocationDisplayVehicles(locationId)

end

function DisplayVehicles.Client.SpawnAll(locationId)

  if locationSpawning[locationId] then

    locationShouldRespawn[locationId] = true

    return

  end

  locationSpawning[locationId] = true

  locationShouldRespawn[locationId] = false

  CreateThread(function()

    DeleteLocationDisplayVehicles(locationId)

    local displayVehicles = lib.callback.await("jg-dealerships:server:get-display-vehicles", false, locationId)

    if not displayVehicles then

      locationSpawning[locationId] = false

      if locationShouldRespawn[locationId] then

        DisplayVehicles.Client.SpawnAll(locationId)

      end

      return

    end

    local spawnedVehicles = {}

    for _, displayVehicle in ipairs(displayVehicles) do

      local spawnCode = displayVehicle.vehicle

      local coords = json.decode(displayVehicle.coords)

      local color = displayVehicle.color

      local prompt = Config.ViewInShowroomPrompt

      local drawTextType = Config.DrawText

      if drawTextType == "auto" then

        drawTextType = (GetResourceState("jg-textui") == "started") and "jg-textui" or Config.DrawText

      end

      if drawTextType == "jg-textui" then

        prompt = "<h4 style='margin-bottom:5px'>" .. 

                 (displayVehicle.brand or "") .. " " .. 

                 (displayVehicle.model or "") .. 

                 "</h4><p>" .. Config.ViewInShowroomPrompt .. "</p>"

      end

      local vehicleInteraction = Interactions.Client.Vehicle.Create(

        vector4(coords.x, coords.y, coords.z, coords.w),

        spawnCode,

        color,

        prompt,

        Config.ViewInShowroomKeyBind,

        function()

          if not isCreatingDisplayVehicle then

            Showroom.Client.Open(locationId, displayVehicle.vehicle, color)

          end

        end,

        function()

          return Locations.Client.HasShowroomAccess(locationId)

        end

      )

      if vehicleInteraction.entity and DoesEntityExist(vehicleInteraction.entity) then

        Entity(vehicleInteraction.entity).state:set("isDisplayVehicle", true, false)

        SetVehicleNumberPlateText(vehicleInteraction.entity, Config.DisplayVehiclesPlate)

      end

      table.insert(spawnedVehicles, vehicleInteraction)

    end

    displayVehiclesByLocation[locationId] = spawnedVehicles

    locationSpawning[locationId] = false

    if locationShouldRespawn[locationId] then

      DisplayVehicles.Client.SpawnAll(locationId)

    end

  end)

end

RegisterNetEvent("jg-dealerships:client:spawn-display-vehicles", function(locationId)

  DisplayVehicles.Client.SpawnAll(locationId)

end)

RegisterNUICallback("create-display-vehicle", function(data, cb)

  if isCreatingDisplayVehicle then

    return cb(false)

  end

  Framework.Client.HideTextUI()

  isCreatingDisplayVehicle = true

  local dealershipId = data.dealershipId

  local color = data.color

  local spawnCode = data.spawnCode

  local fromAdmin = data.fromAdmin

  SetNuiFocus(false, false)

  local coords = Interactions.Client.Vehicle.StartCreator(

    spawnCode,

    color,

    {

      locationId = dealershipId,

      errorMessage = Locale.displayVehicleOutsideZone

    }

  )

  SetNuiFocus(true, true)

  isCreatingDisplayVehicle = false

  if coords then

    lib.callback.await("jg-dealerships:server:create-display-vehicle", false, dealershipId, spawnCode, color, coords)

    DealershipManagement.Client.Open(dealershipId, "displayVehicles", fromAdmin)

    cb(true)

  else

    DealershipManagement.Client.Open(dealershipId, "displayVehicles", fromAdmin)

    cb(false)

  end

end)

RegisterNUICallback("edit-display-vehicle", function(data, cb)

  local id = data.id

  local dealershipId = data.dealershipId

  local spawnCode = data.spawnCode

  local color = data.color

  lib.callback.await("jg-dealerships:server:edit-display-vehicle", false, dealershipId, id, spawnCode, color)

  cb(true)

end)

RegisterNUICallback("delete-display-vehicle", function(data, cb)

  local id = data.id

  local dealershipId = data.dealershipId

  lib.callback.await("jg-dealerships:server:delete-display-vehicle", false, dealershipId, id)

  cb(true)

end)

RegisterNUICallback("reset-display-vehicles", function(data, cb)

  local dealershipId = data.dealershipId

  DisplayVehicles.Client.SpawnAll(dealershipId)

  cb(true)

end)

lib.onCache("vehicle", function(vehicle)

  if vehicle and Entity(vehicle).state.isDisplayVehicle then

    Framework.Client.Notify(Locale.vehicleSecurityBreachDetected, "warning")

    FreezeEntityPosition(vehicle, true)

    SetVehicleAlarm(vehicle, true)

    StartVehicleAlarm(vehicle)

  end

end)

AddEventHandler("onResourceStop", function(resourceName)

  if GetCurrentResourceName() == resourceName then

    DisplayVehicles.Client.DeleteAll()

  end

end)
