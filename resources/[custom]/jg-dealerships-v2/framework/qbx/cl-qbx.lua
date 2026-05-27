if (Config.Framework == "auto" and GetResourceState("qbx_core") == "started") or Config.Framework == "Qbox" then

  Globals.PlayerData = exports.qbx_core:GetPlayerData()

  RegisterNetEvent("QBCore:Client:OnPlayerLoaded")

  AddEventHandler("QBCore:Client:OnPlayerLoaded", function()

    DebugPrint("[QBX] OnPlayerLoaded fired")

    Globals.PlayerData = exports.qbx_core:GetPlayerData()

    LocalPlayer.state:set("isLoggedIn", true)

    Locations.Client.CreateAllInteractions()

    CreateThread(function()

      Wait(1000)

      lib.callback.await("jg-dealerships:server:exit-showroom", false)

    end)

  end)

  RegisterNetEvent("QBCore:Client:OnJobUpdate")

  AddEventHandler("QBCore:Client:OnJobUpdate", function(job)

    Globals.PlayerData.job = job

    Locations.Client.RecreatePermissionRestrictedInteractions()

  end)

  RegisterNetEvent("QBCore:Client:OnGangUpdate")

  AddEventHandler("QBCore:Client:OnGangUpdate", function(gang)

    Globals.PlayerData.gang = gang

    Locations.Client.RecreatePermissionRestrictedInteractions()

  end)

end
