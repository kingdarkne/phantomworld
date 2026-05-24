if not Spawn then

  Spawn = {}

end

if not Spawn.Client then

  Spawn.Client = {}

end

local function GetVehicleType(model)

  local vehicleClass = GetVehicleClassFromName(model)

  if IsThisModelACar(model) then

    return "automobile"

  elseif IsThisModelABicycle(model) then

    return "bike"

  elseif IsThisModelABike(model) then

    return "bike"

  elseif IsThisModelABoat(model) then

    return "boat"

  elseif IsThisModelAHeli(model) then

    return "heli"

  elseif IsThisModelAPlane(model) then

    return "plane"

  elseif IsThisModelAQuadbike(model) then

    return "automobile"

  elseif IsThisModelATrain(model) then

    return "train"

  elseif vehicleClass == 5 then

    return "automobile"

  elseif vehicleClass == 14 then

    return "submarine"

  elseif vehicleClass == 16 then

    return "heli"

  else

    return "trailer"

  end

end

local function ApplyVehicleExtras(vehicle, extras)

  if extras and type(extras) == "table" then

    if extras.colour then

      Utils.Client.SetVehicleColourNew(vehicle, extras.colour)

    end

    if extras.plate then

      SetVehicleNumberPlateText(vehicle, extras.plate)

    end

  end

  Framework.Client.VehicleSetFuel(vehicle, 100.0)

  return not NetworkGetEntityIsNetworked(vehicle)

end

local function RequestVehicleModel(model, plate)

  local modelHash = ConvertModelToHash(model)

  local vehicleType = GetVehicleType(modelHash)

  if not IsModelInCdimage(modelHash) then

    Framework.Client.Notify(Locale.vehicleModelDoesNotExist, "error")

    print(string.format("^1Vehicle model %s does not exist", model))

    return false

  end

  local hasSeats = GetVehicleModelNumberOfSeats(modelHash) > 0

  if plate and plate ~= "" then

    if not IsValidGTAPlate(plate) then

      Framework.Client.Notify(Locale.vehiclePlateInvalid, "error")

      print(string.format("^1This vehicle is trying to spawn with the plate '%s' which is invalid for a GTA vehicle plate", plate:upper()))

      print("^1Vehicle plates must be 8 characters long maximum, and can contain ONLY numbers, letters and spaces")

      return false

    end

  end

  lib.requestModel(modelHash, 60000)

  if IsPedRagdoll(cache.ped) then

    Framework.Client.Notify(Locale.currentlyInRagdollState, "error")

    SetModelAsNoLongerNeeded(modelHash)

    return false

  end

  return modelHash, vehicleType, hasSeats

end

local function FinalizeVehicleSpawn(vehicle, vehicleId, modelHash, putInVehicle, plate, extras, financeData)

  if not vehicle or vehicle == 0 then

    Framework.Client.Notify(Locale.couldNotSpawnVehicle, "error")

    print("^1Vehicle does not exist (vehicle = 0)")

    return false

  end

  if IsPedRagdoll(cache.ped) then

    Framework.Client.Notify(Locale.currentlyInRagdollState, "error")

    SetModelAsNoLongerNeeded(modelHash)

    return false

  end

  if putInVehicle then

    ClearPedTasks(cache.ped)

    local success = pcall(function()

      lib.waitFor(function()

        if GetPedInVehicleSeat(vehicle, -1) == cache.ped then

          return true

        end

        TaskWarpPedIntoVehicle(cache.ped, vehicle, -1)

      end, nil, 5000)

    end)

    if not success then

      print("^1[ERROR] Could not warp you into the vehicle^0")

      return false

    end

  end

  if plate and plate ~= "" then

    SetVehicleNumberPlateText(vehicle, plate)

  end

  if extras and type(extras) == "table" then

    ApplyVehicleExtras(vehicle, extras)

  end

  if GetResourceState("brazzers-fakeplates") == "started" then

    local fakePlate = lib.callback.await("jg-dealerships:server:brazzers-get-fakeplate-from-plate", false, plate)

    if fakePlate then

      plate = fakePlate

      SetVehicleNumberPlateText(vehicle, fakePlate)

    end

  end

  if not plate or plate == "" then

    plate = Framework.Client.GetPlate(vehicle)

  end

  if not plate or plate == "" then

    print("^1[ERROR] The game thinks the vehicle has no plate - absolutely no idea how you've managed this")

    return false

  end

  Entity(vehicle).state:set("vehicleid", vehicleId, true)

  Framework.Client.VehicleGiveKeys(plate, vehicle, financeData)

  return true

end

local function HandleServerCreatedVehicle(networkId, teleportBackCoords, putInVehicle, modelHash, vehicleId, plate, extras, financeData)

  SetModelAsNoLongerNeeded(modelHash)

  if not networkId then

    Framework.Client.Notify(Locale.couldNotSpawnVehicle, "error")

    print("^1Server returned false for netId")

    return false

  end

  lib.waitFor(function()

    if NetworkDoesNetworkIdExist(networkId) and NetworkDoesEntityExistWithNetworkId(networkId) then

      return true

    end

    return nil

  end, "Timed out while waiting for a server-setter netId to exist on client", 10000)

  local vehicle = NetToVeh(networkId)

  lib.waitFor(function()

    return DoesEntityExist(vehicle) or nil

  end, "Timed out while waiting for a server-setter vehicle to exist on client", 10000)

  if teleportBackCoords then

    SetEntityCoords(cache.ped, teleportBackCoords.x, teleportBackCoords.y, teleportBackCoords.z, false, false, false, false)

  end

  local success = FinalizeVehicleSpawn(vehicle, vehicleId, modelHash, putInVehicle, plate, extras, financeData)

  if not success then

    DeleteEntity(vehicle)

    return false

  end

  return true

end

local function CreateVehicleClient(modelHash, coords, plate, isNetworked)

  lib.requestModel(modelHash, 60000)

  local vehicle = CreateVehicle(

    modelHash,

    coords.x,

    coords.y,

    coords.z,

    coords.w,

    isNetworked or false,

    isNetworked or false

  )

  lib.waitFor(function()

    return DoesEntityExist(vehicle) or nil

  end, "Timed out while trying to spawn in vehicle (client)", 10000)

  SetModelAsNoLongerNeeded(modelHash)

  if plate and plate ~= "" then

    SetVehicleNumberPlateText(vehicle, plate)

  end

  return vehicle

end

function Spawn.Client.Create(vehicleId, model, plate, coords, putInVehicle, extras, financeData)

  if Config.SpawnVehiclesWithServerSetter then

    print("^1This function is disabled as client spawning is enabled")

    return false

  end

  local modelHash, vehicleType, hasSeats = RequestVehicleModel(model, plate)

  if not modelHash then

    return false

  end

  local vehicle = CreateVehicleClient(modelHash, coords, plate, true)

  if not vehicle then

    return false

  end

  local success = FinalizeVehicleSpawn(

    vehicle,

    vehicleId,

    modelHash,

    hasSeats and putInVehicle or false,

    plate,

    extras,

    financeData

  )

  if not success then

    DeleteEntity(vehicle)

    return false

  end

  return vehicle

end

AddStateBagChangeHandler("vehInit", "", function(bagName, key, value)

  if not value then

    return

  end

  local vehicle = GetEntityFromStateBagName(bagName)

  if vehicle == 0 then

    return

  end

  lib.waitFor(function()

    return not IsEntityWaitingForWorldCollision(vehicle)

  end)

  local owner = NetworkGetEntityOwner(vehicle)

  if owner ~= cache.playerId then

    return

  end

  local state = Entity(vehicle).state

  SetVehicleOnGroundProperly(vehicle)

  SetTimeout(0, function()

    state:set("vehInit", nil, true)

  end)

end)

AddStateBagChangeHandler("dealershipVehCreatedApplyProps", "", function(bagName, key, props)

  if not props then

    return

  end

  local vehicle = GetEntityFromStateBagName(bagName)

  if vehicle == 0 then

    return

  end

  SetTimeout(0, function()

    local state = Entity(vehicle).state

    for i = 0, 9 do

      local owner = NetworkGetEntityOwner(vehicle)

      if owner == cache.playerId then

        local success = ApplyVehicleExtras(vehicle, props)

        if success then

          state:set("dealershipVehCreatedApplyProps", nil, true)

          break

        end

      end

      Wait(100)

    end

  end)

end)

lib.callback.register("jg-dealerships:client:req-vehicle-and-get-spawn-details", RequestVehicleModel)

lib.callback.register("jg-dealerships:client:on-server-vehicle-created", HandleServerCreatedVehicle)
