-- Phantom Cops vs Robbers - Main Client
local QBCore = exports['qbx_core']:GetCoreObject()
local arenaBlips = {}

-- Initialize
CreateThread(function()
    Wait(2000)
    CreateArenaBlips()
    print('^2[Phantom CVR]^7 Client initialized')
end)

-- Create arena blips
function CreateArenaBlips()
    for _, arena in ipairs(Config.Arenas) do
        local blip = AddBlipForCoord(arena.coords.x, arena.coords.y, arena.coords.z)
        SetBlipSprite(blip, 303) -- Skull icon
        SetBlipColour(blip, 1) -- Red
        SetBlipScale(blip, 0.9)
        SetBlipAsShortRange(blip, true)
        SetBlipDisplay(blip, 4)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName('⚔️ ' .. arena.name)
        EndTextCommandSetBlipName(blip)
        table.insert(arenaBlips, blip)
    end
end

-- Draw markers at arena entrances
CreateThread(function()
    while true do
        Wait(1000)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for _, arena in ipairs(Config.Arenas) do
            local dist = #(coords - arena.coords)
            if dist < 30.0 then
                DrawMarker(1, arena.coords.x, arena.coords.y, arena.coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 3.0, 3.0, 1.0, 255, 0, 0, 100, false, false, 2, false, nil, nil, false)
            end
            if dist < 5.0 then
                Draw3DText(arena.coords + vec3(0, 0, 1.0), '~r~[F5]~w~ Join Arena\n' .. arena.name, 0.4, 4)
            end
        end
    end
end)

function Draw3DText(coords, text, scale, font)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if onScreen then
        SetTextScale(scale, scale)
        SetTextFont(font)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry('STRING')
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

print('^2[Phantom CVR]^7 Client loaded')
