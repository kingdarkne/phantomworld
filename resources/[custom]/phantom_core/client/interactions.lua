-- Phantom Core - Global Interaction System
-- Ensures all phantom resources have consistent interaction prompts

local interactionPrompts = {}

-- Draw 3D text helper (available to all phantom resources)
function PhantomDraw3DText(coords, text, scale, font, r, g, b, a)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if onScreen then
        SetTextScale(scale, scale)
        SetTextFont(font or 4)
        SetTextProportional(1)
        SetTextColour(r or 255, g or 255, b or 255, a or 215)
        SetTextEntry('STRING')
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- Draw floating help text
function PhantomShowHelpText(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, 5000)
end

-- Show notification with icon
function PhantomShowNotification(title, message, type, duration)
    lib.notify({
        title = title,
        description = message,
        type = type or 'info',
        duration = duration or 5000,
        position = 'top-right'
    })
end

-- Interaction key prompt
function PhantomShowInteractionPrompt(coords, key, text)
    PhantomDraw3DText(coords, '~' .. key .. '~ ' .. text, 0.35, 4, 255, 255, 255, 255, true)
end

-- Exports for other resources
exports('Draw3DText', PhantomDraw3DText)
exports('ShowHelpText', PhantomShowHelpText)
exports('ShowNotification', PhantomShowNotification)
exports('ShowInteractionPrompt', PhantomShowInteractionPrompt)

print('^2[Phantom Core]^7 Interaction system loaded')
