local OWNER_IDS = {
    ['fivem:14311541'] = true,
    ['fivem:13816790'] = true,
    ['discord:413173364216168449'] = true,
    ['discord:769964740008083526'] = true,
    ['license:5d42954dcf1e1e2444564e7f456d89ebc6c8ca76'] = true,
    ['license2:5d42954dcf1e1e2444564e7f456d89ebc6c8ca76'] = true,
}

local function isOwner(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if OWNER_IDS[id] then return true end
    end
    return IsPlayerAceAllowed(src, 'qbcore.god') or IsPlayerAceAllowed(src, 'group.superadmin')
end

local function isAdmin(src)
    return IsPlayerAceAllowed(src, 'group.admin')
        or IsPlayerAceAllowed(src, 'easyadmin')
        or IsPlayerAceAllowed(src, 'qbcore.admin')
        or IsPlayerAceAllowed(src, 'oxoadmin.menu')
end

local function displayName(src)
    local name = GetPlayerName(src) or ('ID %s'):format(src)
    if GetResourceState('qbx_core') == 'started' then
        local ok, Player = pcall(function()
            return exports.qbx_core:GetPlayer(src)
        end)
        if ok and Player and Player.PlayerData and Player.PlayerData.charinfo then
            local c = Player.PlayerData.charinfo
            local full = ((c.firstname or '') .. ' ' .. (c.lastname or '')):gsub('^%s+', ''):gsub('%s+$', '')
            if full ~= '' then name = full end
        end
    end
    return name
end

CreateThread(function()
    while GetResourceState('chat') ~= 'started' do
        Wait(200)
    end

    -- Register colored templates once
    pcall(function()
        exports.chat:registerMessageHook(function(source, outMessage, hookRef)
            if not source or source <= 0 then return end
            local tag, color
            if isOwner(source) then
                tag, color = 'OWNER', { 255, 215, 0 }
            elseif isAdmin(source) then
                tag, color = 'ADMIN', { 80, 180, 255 }
            else
                return
            end

            local author = displayName(source)
            local args = outMessage.args or {}
            local msg = args[2] or args[1] or ''
            if type(msg) ~= 'string' then msg = tostring(msg) end

            hookRef.updateMessage({
                template = '<div style="padding:0.15vw;margin:0.15vw 0;"><b style="color:rgb({0},{1},{2})">[{3}]</b> <b>{4}</b>: {5}</div>',
                args = { color[1], color[2], color[3], tag, author, msg },
            })
        end)
    end)
end)
