local markerPeds = {}
local spawnQueue = {}

RegisterNetEvent("electus_bodyguards:spawnMarkerPed", function(i)
    local src = source
    if(spawnQueue[i]) then
        return
    end

    if(not markerPeds[i] or NetworkGetEntityFromNetworkId(markerPeds[i].ped) == 0) then
        spawnQueue[i] = src
    end
end)

CreateThread(function()
    while true do
        Wait(1000)

        for i,v in pairs(spawnQueue) do
            if(spawnQueue[i]) then
                SpawnMarkerPed(i, v)
                spawnQueue[i] = nil
            end
        end
    end
end)

function SpawnMarkerPed(i, src)
    local coords = Config.coords[i].coords
    local heading = Config.coords[i].heading

    local ped = CreatePed(26, Config.coords[i].model, coords.x, coords.y, coords.z, heading, true, false)
    
    -- Wait until the shop NPC is fully spawned
    while not DoesEntityExist(ped) or NetworkGetNetworkIdFromEntity(ped) == 0 do
        Wait(1)
    end
    
    if(SetEntityOrphanMode) then
        SetEntityOrphanMode(ped, 2)
    end

    local netId = NetworkGetNetworkIdFromEntity(ped)
    SetEntityIgnoreRequestControlFilter(ped, true)
    markerPeds[i] = {ped = netId, type = Config.coords[i].type}

    TriggerClientEvent("electus_bodyguards:spawnedMarkerPed", src, netId, Config.coords[i].type)
    TriggerClientEvent("electus_bodyguards:updateMarkerPeds", -1, markerPeds)
end

RegisterNetEvent("onResourceStop", function (resource)
    if resource == GetCurrentResourceName() then
        for i, v in pairs(markerPeds) do
            local ped = NetworkGetEntityFromNetworkId(markerPeds[i].ped)
            DeleteEntity(ped)
        end
    end
end)

lib.callback.register("electus_bodyguards:getMarkerPeds", function(src)
    for i, v in pairs(markerPeds) do
        if(not NetworkGetEntityFromNetworkId(markerPeds[i].ped)) then
            SpawnMarkerPed(i)
       end
    end
    
    return markerPeds
end)