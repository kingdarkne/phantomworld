ESX = exports["es_extended"]:getSharedObject()

-- Put your own notify trigger event
function ShowNotification(msg)
    ESX.ShowNotification(msg)
end

function GiveCarKey()
    -- Put your own car key event
end

exports.ox_target:addSphereZone({
    coords = vector3(732.8123, -1388.04, 27.286),
    radius = 1,
    debug = drawZones,
    options = {
        {
            name = 'sphere',
            event = 'kvl-truck:openmenu',
            label = '🚚 • Look at the jobs',
            canInteract = function(entity, distance, coords, name)
                return true
            end
        }
    }
})

RegisterNetEvent('kvl-truck:openmenu', function()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "open",
    })
 end)