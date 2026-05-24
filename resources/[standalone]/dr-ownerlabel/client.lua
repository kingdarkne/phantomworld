local Owners = {} -- [serverId] = { name = 'First Last' }

local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local camCoords = GetGameplayCamCoords()
    local dist = #(vector3(x, y, z) - camCoords)

    if not onScreen or dist > 100.0 then
        return
    end

    local scale = Config.TextScale
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov

    SetTextScale(0.0 * scale, 0.55 * scale)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(Config.TextColor.r, Config.TextColor.g, Config.TextColor.b, Config.TextColor.a)
    SetTextCentre(true)
    if Config.TextOutline then
        SetTextOutline()
    end

    SetDrawOrigin(x, y, z, 0)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

RegisterNetEvent('dr-ownerlabel:client:updateOwners', function(list)
    Owners = {}
    if type(list) ~= 'table' then return end
    for _, entry in ipairs(list) do
        if entry.id and entry.name then
            Owners[entry.id] = {
                name = entry.name
            }
        end
    end
end)

CreateThread(function()
    -- Ask server for current owner list when this resource starts
    TriggerServerEvent('dr-ownerlabel:server:requestOwners')

    while true do
        Wait(0)

        if next(Owners) ~= nil then
            for serverId, data in pairs(Owners) do
                local player = GetPlayerFromServerId(serverId)
                if player ~= -1 then
                    local ped = GetPlayerPed(player)
                    if DoesEntityExist(ped) then
                        local coords = GetEntityCoords(ped)
                        local label = Config.LabelTemplate:gsub('{name}', data.name or '')
                        DrawText3D(coords.x, coords.y, coords.z + Config.TextOffsetZ, label)
                    end
                end
            end
        end
    end
end)

