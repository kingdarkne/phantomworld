local entityPayPhoneCoords = nil

local function toggleNuiFrame(shouldShow)
  SetNuiFocus(shouldShow, shouldShow)
  SendReactMessage('setVisible', shouldShow)
end

local function endPhoneCall()
  toggleNuiFrame(false)
  ClearPedTasks(PlayerPedId())
  entityPayPhoneCoords = nil
end

RegisterNetEvent('payphones:openUI', function()
  toggleNuiFrame(true)
end)

RegisterNUICallback('hideFrame', function(_, cb)
  endPhoneCall()
  cb({})
end)

RegisterNUICallback('payphoneInput', function(data, cb)
  cb({ data = {}, meta = { ok = true, message = '' } })
  local PhoneNumber = data.phoneNumber
  if PhoneNumber ~= nil then
    lib.notify({ description = ('Calling %s…'):format(PhoneNumber), type = 'inform' })
    TriggerServerEvent('phone:callStart', PhoneNumber, true)
    CreateThread(function()
      while entityPayPhoneCoords do
        if #(GetEntityCoords(PlayerPedId()) - entityPayPhoneCoords) > 2.0 then
          entityPayPhoneCoords = nil
          endPhoneCall()
        end
        Wait(500)
      end
    end)
  end
end)

local payphoneModels = {
  `p_phonebox_02_s`,
  `prop_phonebox_03`,
  `prop_phonebox_02`,
  `prop_phonebox_04`,
  `prop_phonebox_01c`,
  `prop_phonebox_01a`,
  `prop_phonebox_01b`,
  `p_phonebox_01b_s`,
}

AddEventHandler('np-phone:startPayPhoneCall', function(_, pEntity)
  if not pEntity or pEntity == 0 then return end
  entityPayPhoneCoords = GetEntityCoords(pEntity)
  TaskStartScenarioInPlace(PlayerPedId(), 'PROP_HUMAN_ATM', 0, true)
  TriggerEvent('payphones:openUI')
end)

RegisterNetEvent('payphones:client:npwdDial', function(phoneNumber)
  if GetResourceState('npwd') ~= 'started' then return end
  pcall(function()
    exports.npwd:setPhoneVisible(true)
  end)
  lib.notify({
    description = ('Number %s — Phone app opened; finish the call in NPWD.'):format(tostring(phoneNumber)),
    type = 'inform',
    duration = 6500,
  })
end)

CreateThread(function()
  if GetResourceState('ox_target') ~= 'started' then return end
  exports.ox_target:addModel(payphoneModels, {
    {
      name = 'payphone_use',
      icon = 'fa-solid fa-phone',
      label = 'Use payphone',
      distance = 2.0,
      onSelect = function(data)
        local ent = data.entity
        if ent and ent ~= 0 then
          TriggerEvent('np-phone:startPayPhoneCall', nil, ent)
        end
      end,
    },
  })
end)
