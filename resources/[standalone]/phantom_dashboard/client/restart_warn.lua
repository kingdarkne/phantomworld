--- Full-screen style warning when critical error triggers a restart.

local showing = false

RegisterNetEvent('phantom_dashboard:client:restartWarn', function(data)
    data = type(data) == 'table' and data or { message = tostring(data) }
    local msg = data.message or 'Server restarting soon due to a critical error.'
    local seconds = data.seconds

    if lib and lib.notify then
        lib.notify({
            title = seconds and ('Restart in %ss'):format(seconds) or 'Server Warning',
            description = msg,
            type = 'error',
            duration = 8000,
        })
    end

    -- Brief scaleform-style help text spam for visibility
    if showing then return end
    showing = true
    CreateThread(function()
        local untilAt = GetGameTimer() + 6000
        while GetGameTimer() < untilAt do
            SetTextFont(4)
            SetTextScale(0.55, 0.55)
            SetTextColour(255, 70, 70, 255)
            SetTextCentre(true)
            SetTextOutline()
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName(seconds and ('~r~SERVER RESTART IN %s SECONDS'):format(seconds) or '~r~CRITICAL ERROR — SERVER RESTARTING')
            EndTextCommandDisplayText(0.5, 0.12)

            SetTextFont(4)
            SetTextScale(0.38, 0.38)
            SetTextColour(255, 220, 220, 255)
            SetTextCentre(true)
            SetTextOutline()
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName('You will be kicked — please rejoin once the server is back')
            EndTextCommandDisplayText(0.5, 0.165)
            Wait(0)
        end
        showing = false
    end)
end)
