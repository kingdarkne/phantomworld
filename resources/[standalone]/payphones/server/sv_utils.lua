local CodeID = {
  codeName = 'Payphones',
  version = '1.0.0'
}

CreateThread(function()
  print('[' .. CodeID.codeName .. '] v' .. CodeID.version .. ' started!')
end)

RegisterNetEvent('phone:callStart', function(phoneNumber, _fromPayphone)
  local src = source
  phoneNumber = phoneNumber and tostring(phoneNumber) or '?'
  if GetResourceState('npwd') ~= 'started' then
    TriggerClientEvent('ox_lib:notify', src, {
      description = 'NPWD is not running — check server.cfg (ensure npwd, ensure qbx_npwd).',
      type = 'error',
    })
    return
  end
  TriggerClientEvent('payphones:client:npwdDial', src, phoneNumber)
end)
