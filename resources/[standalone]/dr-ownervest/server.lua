local OWNER_FIVEM_ID = 'fivem:14311541' -- your ID from server.cfg

local function isOwner(src)
    -- fallback: scan all identifiers
    for _, identifier in ipairs(GetPlayerIdentifiers(src)) do
        if identifier == OWNER_FIVEM_ID then
            return true
        end
    end
    return false
end

RegisterNetEvent('dr-ownervest:server:requestVest', function()
    local src = source
    if not isOwner(src) then
        return
    end
    TriggerClientEvent('dr-ownervest:client:applyVest', src)
end)

