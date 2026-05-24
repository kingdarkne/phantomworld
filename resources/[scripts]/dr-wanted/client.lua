local wantedLevel = 0
local wantedPoints = 0

RegisterNetEvent('dr-wanted:client:update', function(level, points)
    wantedLevel = level or 0
    wantedPoints = points or 0
end)

local function DrawTextSimple(x, y, scale, text, r, g, b, a)
    SetTextFont(4)
    SetTextProportional(0)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 205)
    SetTextOutline()
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(x, y)
end

CreateThread(function()
    while true do
        Wait(0)
        if wantedLevel > 0 then
            local txt = ('Wanted: %d ⭐ (%d pts)'):format(wantedLevel, wantedPoints)
            DrawTextSimple(0.80, 0.05, 0.4, txt, 255, 60, 60, 255)
        end
    end
end)

-- Automatic wanted: detect shots fired

CreateThread(function()
    while true do
        local sleep = 250
        local ped = PlayerPedId()
        if IsPedArmed(ped, 6) and IsPedShooting(ped) then
            sleep = 1000 -- basic rate limiting
            TriggerServerEvent('dr-wanted:server:shotsFired')
        end
        Wait(sleep)
    end
end)

-- Automatic wanted: when we damage or kill another player

local function GetClosestPlayer(maxDistance)
    local players = GetActivePlayers()
    local ped = PlayerPedId()
    local myCoords = GetEntityCoords(ped)
    local closestPlayer, closestDist
    maxDistance = maxDistance or 25.0

    for _, ply in ipairs(players) do
        local tgtPed = GetPlayerPed(ply)
        if tgtPed ~= ped then
            local dist = #(GetEntityCoords(tgtPed) - myCoords)
            if dist <= maxDistance and (not closestDist or dist < closestDist) then
                closestDist = dist
                closestPlayer = GetPlayerServerId(ply)
            end
        end
    end

    return closestPlayer, closestDist or maxDistance + 1.0
end

CreateThread(function()
    local lastHealth = GetEntityHealth(PlayerPedId())

    while true do
        Wait(500)
        local ped = PlayerPedId()
        local health = GetEntityHealth(ped)

        if health <= 0 and lastHealth > 0 then
            -- we died: try to attribute to nearest player (very rough)
            local killerId, dist = GetClosestPlayer(25.0)
            if killerId and dist <= 10.0 then
                TriggerServerEvent('dr-wanted:server:playerHit', killerId, true)
            end
        end

        lastHealth = health
    end
end)

