--[[
    dr-serverinfo: Opens a menu with server info, keybinds, and how-to.
    Command: /serverinfo or /help or /about
]]

local isOpen = false

local function openServerInfo()
    if isOpen then return end
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
end

local function closeServerInfo()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterCommand('serverinfo', openServerInfo, false)
RegisterCommand('help', openServerInfo, false)
RegisterCommand('about', openServerInfo, false)
RegisterKeyMapping('serverinfo', 'Open Server Info / Help', 'keyboard', 'F1')

RegisterNUICallback('close', function(_, cb)
    closeServerInfo()
    cb('ok')
end)

-- Close with Escape when menu is open
CreateThread(function()
    while true do
        if isOpen then
            if IsControlJustReleased(0, 322) then closeServerInfo() end
            Wait(0)
        else
            Wait(500)
        end
    end
end)
