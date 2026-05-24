if (Config.Framework == "auto" and GetResourceState("es_extended") == "started") or Config.Framework == "ESX" then

  Globals.PlayerData = ESX.GetPlayerData()

  RegisterNetEvent("esx:playerLoaded")

  AddEventHandler("esx:playerLoaded", function(xPlayer)

    Globals.PlayerData = xPlayer

    LocalPlayer.state:set("isLoggedIn", true)

    Locations.Client.CreateAllInteractions()

    CreateThread(function()

      Wait(1000)

      lib.callback.await("jg-dealerships:server:exit-showroom", false)

    end)

  end)

  RegisterNetEvent("esx:setJob")

  AddEventHandler("esx:setJob", function(job)

    Globals.PlayerData.job = job

    Locations.Client.RecreatePermissionRestrictedInteractions()

  end)

end
