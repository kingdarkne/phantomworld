-- /admincar: toggle godmode car for yourself (admin only)
RegisterCommand('admincar', function(source)
    if source == 0 then return end
    if not IsPlayerAceAllowed(source, 'admin') then
        TriggerClientEvent('ox_lib:notify', source, { title = 'AdminCar', description = 'No permission.', type = 'error' })
        return
    end
    TriggerClientEvent('dr-admincar:toggle', source)
end, false)

