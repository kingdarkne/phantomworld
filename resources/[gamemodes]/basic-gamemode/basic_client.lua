-- QBX: qbx_core + qbx_spawn own spawn/multichar. Do not forceRespawn here or players load as freeroam NPCs.
-- Gametype must stay started so default map resources (gameTypes = basic-gamemode) load; stopping basic-gamemode caused endless black loadscreen.
AddEventHandler('onClientMapStart', function()
  pcall(function()
    exports.spawnmanager:setAutoSpawn(false)
  end)
end)
