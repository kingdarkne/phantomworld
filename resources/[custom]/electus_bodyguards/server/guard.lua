local guards = {}

function SpawnBodyguardGuard(src, index)
    local guard = guards[index]
    local model = guard.model
    local weapon = guard.weapon
    local coords = guard.coords
    local radius = guard.radius
    local netId = guard.netId

    local ped = CreatePed(0, model, coords, 0.0, true)

    while(not DoesEntityExist(ped) or NetworkGetNetworkIdFromEntity(ped) == 0) do
        Wait(1)
    end

    SetEntityIgnoreRequestControlFilter(ped, true)

    guards[index].netId = NetworkGetNetworkIdFromEntity(ped)
    guards[index].owner = src

    TriggerClientEvent("electus_bodyguards:spawnedGuardPed", src, guards[index])
    TriggerClientEvent("electus_bodyguards:updateGuardPeds", -1, guards)
end

lib.callback.register("electus_bodyguards:spawnGuardPeds", function(src, index)
    if(NetworkGetEntityFromNetworkId(guards[index].netId) == 0) then
        SpawnBodyguardGuard(src, index)
    end
end)

local function getGuardIndexFromNetId(netId)
    for i=1, #guards do
        if(guards[i].netId == netId) then
            return i
        end
    end
end

lib.callback.register("electus_bodyguards:disableBoyguardGuard", function(src, bodyguard)
    local index = getGuardIndexFromNetId(bodyguard.netId)
    SetEntityIgnoreRequestControlFilter(NetworkGetEntityFromNetworkId(bodyguard.netId), false)
    table.remove(guards, index)
    TriggerClientEvent("electus_bodyguards:updateGuardPeds", -1, guards)
    return true
end)

RegisterNetEvent("electus_bodyguards:setBodyguardToGuard", function(bodyguard)
    local src = source
    local index = #guards+1
    guards[index] = bodyguard
    guards[index].attacking = false
    guards[index].originalOwner = src
    guards[index].friends = GetFriends(src)
    guards[index].owner = src

    SetEntityIgnoreRequestControlFilter(NetworkGetEntityFromNetworkId(bodyguard.netId), true)

    TriggerClientEvent("electus_bodyguards:updateGuardPeds", -1, guards)

end)

RegisterNetEvent("electus_bodyguards:finishAttacking", function(guard)
    local index = getGuardIndexFromNetId(guard.netId)
    guards[index].attacking = false
end)

function IsTargetFriend(target, friendList)
    local found = false

    for k, v in pairs(GetPlayers()) do
        local player = GetPlayer(v)
        local identifier = GetPlayerIdentifier(player)

        for j=1, #friendList do
            if(friendList and friendList[j].friend == identifier and GetPlayerPed(v) == target) then
                found = true
                break
            end
        end
    end

    return found
end

RegisterNetEvent("electus_bodyguards:stopAttack", function(guard)
    local src = source
    local index = getGuardIndexFromNetId(guard.netId)
    local target = NetworkGetEntityFromNetworkId(guard.netId)
    guards[index].attacking = false
    local owner = NetworkGetEntityOwner(target)

    TriggerClientEvent("electus_bodyguards:stopAttack", owner, guard)

end)
RegisterNetEvent("electus_bodyguards:attackNetId", function(guard, targetNetId)
    local src = source
    local index = getGuardIndexFromNetId(guard.netId)
    
    if(guards[index].originalOwner == src or guards[index].attacking) then
        return
    end

    local target = NetworkGetEntityFromNetworkId(targetNetId)
    local owner = NetworkGetEntityOwner(NetworkGetEntityFromNetworkId(guard.netId))

    guard.owner = owner
    guards[index].owner = owner
    
    if(GetPlayerName(owner) and not guards[index].attacking and not IsTargetFriend(target, guards[index].friends)) then
        guards[index].attacking = true
        GiveWeaponToPed(NetworkGetEntityFromNetworkId(guard.netId), guard.weapon, 999, false, true)
        SetCurrentPedWeapon(NetworkGetEntityFromNetworkId(guard.netId), guard.weapon, true)

        TriggerClientEvent("electus_bodyguards:attackNetId", owner, guard, targetNetId)
    elseif(not GetPlayerName(owner)) then
        guards[index].owner = nil

        for i=1, #guards do
            if(guards[i].netId == guard.netId) then
                DeleteEntity(NetworkGetEntityFromNetworkId(guard.netId))
                break
            end
        end
    end
end)