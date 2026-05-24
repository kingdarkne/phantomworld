lib.callback.register("electus_bodyguards:getFriends", function(src)
    return GetFriends(src)
end)

function GetFriends(src)
    local player = GetPlayer(src)
    local identifier = GetPlayerIdentifier(player)

    local result = MySQL.Sync.fetchAll("SELECT * FROM electus_bodyguards_friends WHERE identifier = @identifier", {
        ['@identifier'] = identifier
    })

    for i=1, #result do
        local name = GetIdentifierName(result[i].friend)
        result[i].name = name
    end

    result[#result+1] = {
        identifier = identifier,
        name = GetIdentifierName(identifier),
        hide = true
    }

    return result
end

lib.callback.register("electus_bodyguards:addFriend", function(src, friend)
    local player = GetPlayer(src)
    local identifier = GetPlayerIdentifier(player)
    local isFriend = MySQL.Sync.fetchScalar("SELECT COUNT(*) FROM electus_bodyguards_friends WHERE identifier = @identifier AND friend = @friend", {
        ['@identifier'] = identifier,
        ['@friend'] = friend.identifier
    })

    if(isFriend > 0) then
        Notify(src, L("friends.already_friend"), "error")
        return
    end

    local added = MySQL.Async.execute("INSERT INTO electus_bodyguards_friends (identifier, friend) VALUES (@identifier, @friend)", {
        ['@identifier'] = identifier,
        ['@friend'] = friend.identifier
    })
    
    Notify(src, L("friends.added_new_friend"), "success")
    return added
end)

lib.callback.register("electus_bodyguards:removeFriend", function(src, friend)
    local player = GetPlayer(src)
    local identifier = GetPlayerIdentifier(player)

    local deleted = MySQL.Async.execute("DELETE FROM electus_bodyguards_friends WHERE identifier = @identifier AND friend = @friend", {
        ['@identifier'] = identifier,
        ['@friend'] = friend.friend
    })

    Notify(src, L("friends.removed_friend"), "success")
    return deleted
end)

lib.callback.register("electus_bodyguards:getPlayersInludingSrc", function(src)
    local players = {}
    for _, playerId in ipairs(GetPlayers()) do
        players[#players+1] = {
            id = playerId,
            name = GetPlayerName(playerId),
            identifier = GetPlayerIdentifier(GetPlayer(playerId))
        }
    end
    return players
end)

lib.callback.register("electus_bodyguards:getPlayers", function(src)
    local players = {}
    for _, playerId in ipairs(GetPlayers()) do
        if(tonumber(playerId) ~= tonumber(src)) then
            players[#players+1] = {
                id = playerId,
                name = GetPlayerName(playerId),
                identifier = GetPlayerIdentifier(GetPlayer(playerId))
            }
        end
    end
    return players
end)