local displayIDs = true

function DisplayPlayerID()
    displayIDs = true
    Citizen.CreateThread(function()
        while displayIDs do
            Wait(0)

            for id = 0, 255 do
                if NetworkIsPlayerActive(id) then
                    local ped = GetPlayerPed(id)
                    local pedCoords = GetEntityCoords(ped)
                    local playerCoords = GetEntityCoords(PlayerPedId())
                    local distance = #(playerCoords - pedCoords)

                    if distance < 20.0 then
                        local serverId = GetPlayerServerId(id)
                        local color = {255, 255, 255, 255}

                        if NetworkIsPlayerTalking(id) then
                            color = {0, 0, 255, 255}
                        end

                        DrawText3D(pedCoords.x, pedCoords.y, pedCoords.z + 1.0, tostring(serverId), color)
                    end
                end
            end
        end
    end)
end

function StopDisplayPlayerID()
    displayIDs = false
end

function DrawText3D(x, y, z, text, color)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local p = GetGameplayCamCoords()
    local distance = GetDistanceBetweenCoords(p.x, p.y, p.z, x, y, z, 1)
    local scale = (1 / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    local scale = scale * fov

    if onScreen then
        SetTextScale(0.0 * scale, 0.55 * scale)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(color[1], color[2], color[3], color[4])
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

exports('DisplayPlayerID', DisplayPlayerID)
exports('StopDisplayPlayerID', StopDisplayPlayerID)