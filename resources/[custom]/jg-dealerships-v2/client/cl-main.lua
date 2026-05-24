if not Utils then

  Utils = {}

end

if not Utils.Client then

  Utils.Client = {}

end

DoScreenFadeIn(0)

function Utils.Client.SetVehicleColourNew(vehicle, color)

  if not vehicle then

    return false

  end

  if type(color) == "table" then

    local r, g, b = color.r, color.g, color.b

    SetVehicleModColor_1(vehicle, 1, 0, 0)

    SetVehicleCustomPrimaryColour(vehicle, r, g, b)

    SetVehicleModColor_2(vehicle, 1, 0)

    SetVehicleCustomSecondaryColour(vehicle, r, g, b)

  elseif type(color) == "number" then

    ClearVehicleCustomPrimaryColour(vehicle)

    ClearVehicleCustomSecondaryColour(vehicle)

    SetVehicleColours(vehicle, color, color)

  end

  SetVehicleExtraColours(vehicle, 0, nil)

  SetVehicleDirtLevel(vehicle, 0.0)

  return true

end

function Utils.Client.GetPolygonCenter(points)

  local sumX, sumY, sumZ = 0, 0, 0

  local count = #points

  for _, point in ipairs(points) do

    sumX = sumX + point.x

    sumY = sumY + point.y

    sumZ = sumZ + point.z

  end

  return vec3(sumX / count, sumY / count, sumZ / count)

end

function Utils.Client.DrawMarkerOnFrame(markerType, pos, scale, color, rotation, direction, bobUpAndDown, faceCamera, rotate, drawOnEnts)

  rotation = rotation or vec3(0, 0, 0)

  direction = direction or vec3(0, 0, 0)

  bobUpAndDown = bobUpAndDown or false

  faceCamera = faceCamera or false

  rotate = rotate or false

  drawOnEnts = drawOnEnts or false

  local scaleX, scaleY, scaleZ

  if type(scale) == "table" then

    scaleX = scale.x or scale[1] or 1.0

    scaleY = scale.y or scale[2] or 1.0

    scaleZ = scale.z or scale[3] or 1.0

  else

    scaleX = scale

    scaleY = scale

    scaleZ = scale

  end

  DrawMarker(

    markerType,

    pos.x, pos.y, pos.z,

    direction.x, direction.y, direction.z,

    rotation.x, rotation.y, rotation.z,

    scaleX, scaleY, scaleZ,

    color.r, color.g, color.b, math.floor((color.a or 1) * 255),

    bobUpAndDown, faceCamera, 2, rotate, nil, nil, drawOnEnts

  )

end

function Utils.Client.ConvertToVec3(coords)

  return vector3(coords.x, coords.y, coords.z)

end

function Utils.Client.ConvertToVec4(coords)

  return vector4(coords.x, coords.y, coords.z, coords.w)

end

function Utils.Client.FindAvailableSpawnCoords(coords)

  if type(coords) == "table" and type(coords) ~= "vector4" and type(coords) ~= "vector3" then

    for _, coord in pairs(coords) do

      if not lib.getClosestVehicle(coord.xyz, 2.5) then

        return coord

      end

    end

    return Utils.Client.FindAvailableSpawnCoords(coords[1])

  end

  local currentCoords = coords.xyzw

  for attempt = 1, 10 do

    if not lib.getClosestVehicle(currentCoords.xyz, 2.5) then

      return currentCoords

    end

    local x, y = currentCoords.x, currentCoords.y

    local heading = currentCoords.w

    if (heading >= 0 and heading <= 45) or (heading >= 315 and heading <= 360) then

      y = y + 5

    end

    if heading >= 46 and heading <= 135 then

      x = x - 5

    end

    if heading >= 136 and heading <= 225 then

      y = y - 5

    end

    if heading >= 226 and heading <= 314 then

      x = x + 5

    end

    currentCoords = vector4(x, y, currentCoords.z, currentCoords.w)

  end

  return currentCoords

end

function GetVehicleTypeFromClass(vehicleClass)

  if vehicleClass == 14 then

    return "sea"

  elseif vehicleClass == 15 or vehicleClass == 16 then

    return "air"

  else

    return "car"

  end

end

function PlayTabletAnim()

  local animDict = "amb@code_human_in_bus_passenger_idles@female@tablet@base"

  local animName = "base"

  local tabletModel = -1585232418

  local boneIndex = 60309

  local attachOffset = vector3(0.03, 0.002, 0.0)

  local attachRotation = vector3(10.0, 160.0, 0.0)

  Citizen.CreateThread(function()

    lib.requestAnimDict(animDict)

    lib.requestModel(tabletModel)

    local ped = cache.ped

    Globals.HoldingTablet = CreateObject(tabletModel, 0.0, 0.0, 0.0, true, true, false)

    local handBone = GetPedBoneIndex(ped, boneIndex)

    SetCurrentPedWeapon(ped, -1569615261, true)

    AttachEntityToEntity(

      Globals.HoldingTablet, ped, handBone,

      attachOffset.x, attachOffset.y, attachOffset.z,

      attachRotation.x, attachRotation.y, attachRotation.z,

      true, false, false, false, 2, true

    )

    SetModelAsNoLongerNeeded(tabletModel)

    if not IsEntityPlayingAnim(ped, animDict, animName, 3) then

      TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 50, 0, false, false, false)

    end

    while Globals.HoldingTablet do

      ped = cache.ped

      if not IsEntityPlayingAnim(ped, animDict, animName, 3) then

        TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 50, 0, false, false, false)

      end

      Wait(1000)

    end

    if HasAnimDictLoaded(animDict) then

      RemoveAnimDict(animDict)

    end

  end)

end

function StopTabletAnim()

  if not Globals.HoldingTablet then

    return

  end

  local tablet = Globals.HoldingTablet

  Globals.HoldingTablet = nil

  ClearPedTasks(cache.ped)

  if tablet and DoesEntityExist(tablet) then

    DetachEntity(tablet, true, false)

    DeleteEntity(tablet)

  end

end

function GetPlayerBalances()

  local balances = lib.callback.await("jg-dealerships:server:get-player-balances", false)

  return balances or {}

end

RegisterNUICallback("get-player-balances", function(data, cb)

  cb(GetPlayerBalances())

end)

RegisterNUICallback("close", function(data, cb)

  SetNuiFocus(false, false)

  StopTabletAnim()

  cb(true)

end)

RegisterNUICallback("get-nearby-players", function(data, cb)

  local players = lib.callback.await("jg-dealerships:server:get-nearby-players", false, data.dealershipId)

  cb(players or {})

end)

lib.callback.register("jg-dealerships:client:open-direct-sale-tablet", function()

  local currentZone = DealershipZones.Client.GetCurrentZone()

  if not currentZone then

    Framework.Client.Notify("You must be at a dealership to use this command", "error")

    return false

  end

  local isEmployee = Locations.Client.IsEmployeeAtLocation(currentZone)

  if not isEmployee then

    Framework.Client.Notify("You are not an employee of this dealership", "error")

    return false

  end

  return DirectSales.Client.ShowDirectSaleTablet(currentZone)

end)
