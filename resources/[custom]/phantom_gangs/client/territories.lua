-- Territory drawing and interaction (handled in main.lua)
-- Additional territory-specific visual effects

CreateThread(function()
    while true do
        Wait(0)
        if LocalPlayer.state.isLoggedIn then
            -- Draw territory boundaries with red zone effect
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            for _, territory in ipairs(Config.Territories) do
                local dist = #(coords - territory.coords)
                if dist < territory.radius + 30.0 then
                    -- Draw red zone boundary line
                    DrawZoneCircle(territory.coords, territory.radius, { r = 255, g = 0, b = 0, a = 80 })
                end
            end
        end
    end
end)

function DrawZoneCircle(center, radius, color)
    -- Draw circle on ground
    local numPoints = 32
    for i = 0, numPoints do
        local angle1 = (i / numPoints) * math.pi * 2
        local angle2 = ((i + 1) / numPoints) * math.pi * 2
        local x1 = center.x + math.cos(angle1) * radius
        local y1 = center.y + math.sin(angle1) * radius
        local x2 = center.x + math.cos(angle2) * radius
        local y2 = center.y + math.sin(angle2) * radius
        DrawLine(x1, y1, center.z - 0.9, x2, y2, center.z - 0.9, color.r, color.g, color.b, color.a)
    end
end
