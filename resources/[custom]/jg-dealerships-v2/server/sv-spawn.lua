if not Spawn then

  Spawn = {}

end

if not Spawn.Server then

  Spawn.Server = {}

end

local spawnRetries = {}

local MAX_TELEPORT_DISTANCE = 10.0

local MAX_PROP_SET_RETRIES = 3

local function SpawnVehicleWithServerSetter(source, model, modelType, plate, coords, putInVehicle, props)

  if spawnRetries[source] then

    if spawnRetries[source] == MAX_PROP_SET_RETRIES then

      print("^3[WARNING] Vehicle props failed to set after trying several times. First check if the plate within the vehicle props JSON does not match the plate column. If they match, and you see this message regularly, try setting Config.SpawnVehiclesWithServerSetter = false")

      spawnRetries[source] = 0

      return false

    end

  end

  spawnRetries[source] = (spawnRetries[source] or 0) + 1

  local vehicle = CreateVehicleServerSetter(model, modelType, coords.x, coords.y, coords.z, coords.w)

  lib.waitFor(function()

    return DoesEntityExist(vehicle) or nil

  end, "Timed out while trying to spawn in vehicle (server)", 10000)

  lib.waitFor(function()

    return GetVehicleNumberPlateText(vehicle) ~= "" or nil

  end, "Vehicle number plate text is nil", 5000)

  SetEntityRoutingBucket(vehicle, GetPlayerRoutingBucket(source))

  if SetEntityOrphanMode then

    SetEntityOrphanMode(vehicle, 2)

  end

  for seatIndex = -1, 6 do

    local ped = GetPedInVehicleSeat(vehicle, seatIndex)

    if ped ~= 0 then

      DeleteEntity(ped)

    end

  end

  if putInVehicle then

    local playerPed = GetPlayerPed(source)

    pcall(function()

      lib.waitFor(function()

        if GetPedInVehicleSeat(vehicle, -1) == playerPed then

          return true

        end

        SetPedIntoVehicle(playerPed, vehicle, -1)

      end, nil, 1000)

    end)

  end

  lib.waitFor(function()

    return NetworkGetEntityOwner(vehicle) ~= -1 or nil

  end, "Timed out waiting for server-setter entity to have an owner (owner is -1)", 5000)

  Entity(vehicle).state:set("vehInit", true, true)

  if props and type(props) == "table" then

    Entity(vehicle).state:set("dealershipVehCreatedApplyProps", props, true)

  end

  local propsApplied = pcall(function()

    lib.waitFor(function()

      if not Entity(vehicle).state.dealershipVehCreatedApplyProps then

        if plate and plate ~= "" then

          if Framework.Server.GetPlate(vehicle) == plate then

            return true

          end

        else

          return true

        end

      end

    end, nil, 2000)

  end)

  if not propsApplied then

    DeleteEntity(vehicle)

    JGDeleteVehicle(vehicle)

    return SpawnVehicleWithServerSetter(source, model, modelType, plate, coords, putInVehicle, props)

  end

  spawnRetries[source] = 0

  return NetworkGetNetworkIdFromEntity(vehicle), vehicle

end

function Spawn.Server.Create(source, vehicleData, spawnType, plate, coords, putInVehicle, props, financeData)

  local model, modelType, shouldPutInVehicle = lib.callback.await(

    "jg-dealerships:client:req-vehicle-and-get-spawn-details", 

    source, 

    spawnType

  )

  if not model then

    return false

  end

  local playerPed = GetPlayerPed(source)

  local playerCoords = GetEntityCoords(playerPed)

  local wasTeleported = false

  if #(playerCoords - coords.xyz) > MAX_TELEPORT_DISTANCE then

    SetEntityCoords(playerPed, coords.x + 3.0, coords.y + 3.0, coords.z, false, false, false, false)

    wasTeleported = true

  end

  local networkId, vehicle = SpawnVehicleWithServerSetter(

    source,

    model,

    modelType,

    plate,

    coords,

    shouldPutInVehicle or putInVehicle,

    props

  )

  if not networkId or not vehicle then

    return false

  end

  local clientSuccess = lib.callback.await(

    "jg-dealerships:client:on-server-vehicle-created",

    source,

    networkId,

    wasTeleported and playerCoords or nil,

    shouldPutInVehicle or putInVehicle,

    model,

    vehicleData,

    plate,

    props,

    financeData

  )

  if not clientSuccess then

    if DoesEntityExist(vehicle) then

      DeleteEntity(vehicle)

      DebugPrint("Failed to create vehicle, deleted entity.", "warning", networkId)

    end

    return false

  end

  return networkId, vehicle

end
