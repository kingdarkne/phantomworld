--- Hard-grant in-game admin for the Phantom World owner account (alex lol / Erica).
--- ACE principals in server.cfg should already cover this; this also binds group.admin
--- to the live player session so oxoadmin / qbx commands work even if an identifier is missing.

local OWNER = {
    discord = '413173364216168449',
    fivem = '14311541',
    license = 'c814f9bdac0d39b88f8b8aef138f118718983593',
    citizenids = {
        BX1HSVP0 = true, -- alex lol
        EV5FEVIP = true, -- Alex Walker
    },
}

local function idMatches(src)
    local discord = GetPlayerIdentifierByType(src, 'discord')
    if discord and discord == ('discord:' .. OWNER.discord) then return true end

    local fivem = GetPlayerIdentifierByType(src, 'fivem')
    if fivem and fivem == ('fivem:' .. OWNER.fivem) then return true end

    local license = GetPlayerIdentifierByType(src, 'license')
    local license2 = GetPlayerIdentifierByType(src, 'license2')
    if license and license:find(OWNER.license, 1, true) then return true end
    if license2 and license2:find(OWNER.license, 1, true) then return true end

    return false
end

local function grantAdmin(src, reason)
    if not src or src <= 0 then return end
    if IsPlayerAceAllowed(src, 'admin') and IsPlayerAceAllowed(src, 'oxoadmin.menu') then
        return
    end

    local principal = ('player.%s'):format(src)
    ExecuteCommand(('add_principal %s group.admin'):format(principal))
    ExecuteCommand(('add_principal %s qbcore.god'):format(principal))

    pcall(function()
        exports.qbx_core:AddPermission(src, 'god')
    end)

    print(('[phantom_dashboard] owner admin granted to %s (%s) via %s'):format(
        GetPlayerName(src) or src,
        src,
        reason or 'match'
    ))
end

local function maybeGrant(src, reason)
    if idMatches(src) then
        grantAdmin(src, reason)
        return
    end

    local ok, player = pcall(function()
        return exports.qbx_core:GetPlayer(src)
    end)
    if ok and player and player.PlayerData and OWNER.citizenids[player.PlayerData.citizenid] then
        grantAdmin(src, reason .. '+citizenid')
    end
end

AddEventHandler('playerJoining', function()
    local src = source
    SetTimeout(1500, function()
        maybeGrant(src, 'playerJoining')
    end)
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    if not player or not player.PlayerData then return end
    local src = player.PlayerData.source
    if OWNER.citizenids[player.PlayerData.citizenid] or idMatches(src) then
        grantAdmin(src, 'PlayerLoaded')
        -- Keep admin duty opted-in for oxo/qbx admin commands.
        pcall(function()
            player.Functions.SetMetaData('optin', true)
        end)
    end
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, id in ipairs(GetPlayers()) do
        maybeGrant(tonumber(id), 'resourceStart')
    end
end)
