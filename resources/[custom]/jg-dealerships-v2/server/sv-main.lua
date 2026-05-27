if not Utils then

  Utils = {}

end

if not Utils.Server then

  Utils.Server = {}

end

math.randomseed(os.time())

function Utils.Server.GenerateUuid()

  local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"

  return string.gsub(template, "[xy]", function(char)

    local value = (char == "x") and math.random(0, 15) or math.random(8, 11)

    return string.format("%x", value)

  end)

end

function Utils.Server.GetNearbyPlayers(sourcePlayerId, coords, radius, includeSelf)

  local nearbyPlayers = lib.getNearbyPlayers(coords, radius)

  local result = {}

  for _, player in ipairs(nearbyPlayers) do

    if includeSelf or sourcePlayerId ~= player.id then

      local playerInfo = Framework.Server.GetPlayerInfo(player.id)

      table.insert(result, {

        id = player.id,

        identifier = Framework.Server.GetPlayerIdentifier(player.id),

        name = playerInfo and playerInfo.name or nil

      })

    end

  end

  DebugPrint(string.format("Found %s nearby players", #result), "debug", result)

  return result

end

lib.callback.register("jg-dealerships:server:get-nearby-players", function(source, dealershipId)

  local playerCoords = GetEntityCoords(GetPlayerPed(source))

  local nearbyPlayers = Utils.Server.GetNearbyPlayers(source, playerCoords, 10.0, false)

  if dealershipId then

    local isAdmin = Framework.Server.IsAdmin(source)

    if isAdmin then

      local identifier = Framework.Server.GetPlayerIdentifier(source)

      local isEmployee = MySQL.single.await(

        "SELECT identifier FROM dealership_employees WHERE identifier = ? AND dealership = ?",

        {identifier, dealershipId}

      )

      if not isEmployee then

        local playerInfo = Framework.Server.GetPlayerInfo(source)

        table.insert(nearbyPlayers, 1, {

          id = source,

          identifier = identifier,

          name = (playerInfo and playerInfo.name) or "Unknown",

          isSelf = true

        })

      end

    end

  end

  return nearbyPlayers

end)

RegisterNetEvent("jg-dealerships:server:notify-other-player", function(targetPlayerId, ...)

  TriggerClientEvent("jg-dealerships:client:notify", targetPlayerId, ...)

end)

AddEventHandler("onResourceStart", function(resourceName)

  if GetCurrentResourceName() ~= resourceName then

    return

  end

  InitSQL()

  CreateThread(function()

    Wait(5000)

    local ok, count = pcall(function()

      return MySQL.scalar.await("SELECT COUNT(*) FROM dealership_locations")

    end)

    if not ok or not count or count > 0 then

      return

    end

    if not DEFAULT_LOCATIONS or not Import or not Import.Server or not Import.Server.ImportV1Locations then

      return

    end

    print("^3[jg-dealerships-v2]^0 No dealership locations in database — importing default locations...")

    local result = Import.Server.ImportV1Locations(DEFAULT_LOCATIONS)

    if result and result.success and result.imported and #result.imported > 0 then

      print("^2[jg-dealerships-v2]^0 Imported " .. #result.imported .. " default dealership location(s).")

    else

      print("^1[jg-dealerships-v2]^0 Failed to import default dealership locations. Use /dealeradmin in-game or check server console.^0")

    end

  end)

end)
