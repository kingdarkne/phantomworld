-- Admin Menu Keybind Fix
-- Registers F12 key for opening admin menu

-- Wait for player to be fully loaded
CreateThread(function()
    while LocalPlayer.state.isLoggedIn ~= true do
        Wait(1000)
    end
    
    -- Small delay to ensure everything is loaded
    Wait(2000)
    
    -- Register key mapping for admin menu
    RegisterCommand('opennorseadmin', function()
        -- Check admin via QBX player metadata
        local QBCoreLocal = exports['qbx_core']:GetCoreObject()
        local PlayerData = QBCoreLocal and QBCoreLocal.Functions.GetPlayerData() or nil
        local hasPerm = PlayerData and PlayerData.metadata and (PlayerData.metadata['isadmin'] == true or PlayerData.metadata['admin'] == true) or false
        if hasPerm then
            -- Trigger the admin menu open event
            TriggerEvent('oxo-admin:client:openMenu')
        else
            lib.notify({ title = 'Access Denied', description = 'You do not have admin permissions', type = 'error' })
        end
    end, false)
    
    -- Register F12 key mapping
    RegisterKeyMapping('opennorseadmin', 'Open Admin Menu (Norse)', 'keyboard', 'HOME')
    
    print('[^2Norse Admin^7] HOME keybind registered for admin menu')
end)
