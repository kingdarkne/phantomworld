local playerList = {}
local disconnectedPlayers = {}

local function toggleNuiFrame(shouldShow)
  SetNuiFocus(shouldShow, shouldShow)
  SendReactMessage('setVisible', shouldShow)
end

RegisterCommand('+playerlist', function()
  toggleNuiFrame(true)
  TriggerServerEvent('dr-playerlist:server:requestUpdate')
  exports['dr-playerlist']:DisplayPlayerID()
end)

RegisterKeyMapping('+playerlist', 'Open Player List', 'keyboard', 'U')

RegisterNetEvent('dr-playerlist:OpenUI')
AddEventHandler('dr-playerlist:OpenUI', function()
  toggleNuiFrame(true)
end)

RegisterNUICallback('hideFrame', function(_, cb)
  toggleNuiFrame(false)
  exports['dr-playerlist']:StopDisplayPlayerID()
  cb({})
end)

function SendData(data)
  SendNUIMessage(
    {
      action = 'SetPlayerList',
      data = {
        activePlayers = data.activePlayers,
        disconnectedPlayers = data.disconnectedPlayers
      }
    }
  )
end

RegisterNetEvent('dr-playerlist:client:updatePlayers')
AddEventHandler('dr-playerlist:client:updatePlayers', function(activePlayers, disconnected)
  playerList = activePlayers
  disconnectedPlayers = disconnected
  SendData({ activePlayers = activePlayers, disconnectedPlayers = disconnected })
end)

RegisterNUICallback('getData', function(data, cb)
  if data.variable == 'online' then
    cb({ players = playerList })
  elseif data.variable == 'disconnected' then
    cb({ players = disconnectedPlayers })
  end
end)
