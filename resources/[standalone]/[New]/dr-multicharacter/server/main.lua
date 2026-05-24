-- QBX-native: dr-multicharacter client uses qbx_core callbacks directly.
-- This server file intentionally stays minimal so we don't depend on qb-core/qb-inventory.

local function isAdmin(src)
    return IsPlayerAceAllowed(src, 'admin')
        or IsPlayerAceAllowed(src, 'command')
        or IsPlayerAceAllowed(src, 'group.admin')
end

RegisterNetEvent('dr-multicharacter:server:disconnect', function()
    DropPlayer(source, 'Disconnected')
end)

RegisterCommand('drmc_logout', function(source)
    if source == 0 then return end
    if not isAdmin(source) then return end
    TriggerClientEvent('dr-multicharacter:client:chooseChar', source)
end, false)

-- Backwards compatible commands used by some guides
RegisterCommand('logout', function(source)
    if source == 0 then return end
    if not isAdmin(source) then return end
    TriggerClientEvent('dr-multicharacter:client:chooseChar', source)
end, false)

RegisterCommand('closeNUI', function(source)
    if source == 0 then return end
    if not isAdmin(source) then return end
    TriggerClientEvent('dr-multicharacter:client:closeNUI', source)
end, false)