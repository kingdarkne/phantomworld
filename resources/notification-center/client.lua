local QBCore = exports['qbx_core']:GetCoreObject()

-- Override all notification systems to use center top position

-- Override QBCore.Functions.Notify
local originalNotify = QBCore.Functions.Notify
QBCore.Functions.Notify = function(message, type, duration)
    -- Use ox_lib notify with center position
    if lib and lib.notify then
        lib.notify({
            title = 'Notification',
            description = message,
            type = type or 'info',
            duration = duration or 5000,
            position = 'top-center'
        })
    else
        -- Fallback to original notify
        originalNotify(message, type, duration)
    end
end

-- Override ox_lib notify
if lib and lib.notify then
    local originalLibNotify = lib.notify
    lib.notify = function(data)
        if type(data) == 'string' then
            data = { description = data }
        end
        
        -- Force center position
        data.position = 'top-center'
        
        return originalLibNotify(data)
    end
end

-- Override QBCore client events
RegisterNetEvent('QBCore:Notify', function(message, type, duration)
    QBCore.Functions.Notify(message, type, duration)
end)

-- Override any other common notification systems
RegisterNetEvent('client:Notify', function(message, type, duration)
    QBCore.Functions.Notify(message, type, duration)
end)

RegisterNetEvent('chat:addMessage', function(source, message, type)
    if source == 0 or source == '' then
        QBCore.Functions.Notify(message, type or 'info', 5000)
    end
end)

-- Override any custom notification exports
if GetResourceState('ps-ui') == 'started' then
    exports['ps-ui'].Notify = function(message, type, duration)
        QBCore.Functions.Notify(message, type, duration)
    end
end

-- Override jomidar-ui notifications if they exist
if GetResourceState('jomidar-ui') == 'started' then
    local originalJomidarNotify = nil
    -- Hook into jomidar-ui notification system
    CreateThread(function()
        while true do
            Wait(1000)
            if not originalJomidarNotify then
                pcall(function()
                    local fn = exports['jomidar-ui'].Notify
                    if fn then
                        originalJomidarNotify = fn
                        exports['jomidar-ui'].Notify = function(message, type, duration)
                            QBCore.Functions.Notify(message, type, duration)
                        end
                    end
                end)
            end
        end
    end)
end

-- Override any other notification systems
local notificationOverrides = {
    'esx:showNotification',
    'chat:addMessage',
    'mythic_notify:client:SendAlert',
    't-notify:client:Notify',
    'okokNotify:Alert',
    'nd-notify'
}

for _, event in ipairs(notificationOverrides) do
    RegisterNetEvent(event, function(message, type, duration)
        QBCore.Functions.Notify(message, type, duration)
    end)
end

-- Override any global notification functions
_G.Notify = function(message, type, duration)
    QBCore.Functions.Notify(message, type, duration)
end

_G.TriggerNotification = function(message, type, duration)
    QBCore.Functions.Notify(message, type, duration)
end

print('[Notification Center] All notifications moved to center top position')
