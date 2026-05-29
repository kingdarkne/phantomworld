-- Phantom Core - UI Notification System
-- High-quality notification system with animations and multiple types

local activeNotifications = {}
local notificationId = 0

-- Notification types with colors and icons
local NotificationTypes = {
    info = { color = '#3b82f6', icon = 'ℹ️' },
    success = { color = '#22c55e', icon = '✅' },
    warning = { color = '#f59e0b', icon = '⚠️' },
    error = { color = '#ef4444', icon = '❌' },
    money = { color = '#10b981', icon = '💰' },
    vehicle = { color = '#8b5cf6', icon = '🚗' },
}

-- Send notification to UI
function SendNotification(options)
    if not options then return end
    
    notificationId = notificationId + 1
    local id = notificationId
    
    -- Set defaults
    local notificationType = options.notificationType or options.type or 'info'
    local message = options.message or ''
    local duration = options.duration or Config.UI.Notifications.DefaultDuration
    local position = options.position or Config.UI.Notifications.DefaultPosition
    
    -- Validate type
    if not NotificationTypes[notificationType] then
        notificationType = 'info'
    end
    
    -- Check max visible notifications
    while #activeNotifications >= Config.UI.Notifications.MaxVisible do
        local oldest = table.remove(activeNotifications, 1)
        SendNUIMessage({
            action = 'removeNotification',
            id = oldest.id
        })
    end
    
    -- Add to active notifications
    table.insert(activeNotifications, {
        id = id,
        type = notificationType,
        message = message,
        duration = duration,
        position = position,
        timestamp = GetGameTimer()
    })
    
    -- Send to NUI
    SendNUIMessage({
        action = 'addNotification',
        id = id,
        type = notificationType,
        message = message,
        duration = duration,
        position = position,
        config = NotificationTypes[notificationType]
    })
    
    -- Auto-remove after duration
    SetTimeout(duration, function()
        RemoveNotification(id)
    end)
    
    return id
end

-- Remove notification by ID
function RemoveNotification(id)
    for i, notif in ipairs(activeNotifications) do
        if notif.id == id then
            table.remove(activeNotifications, i)
            SendNUIMessage({
                action = 'removeNotification',
                id = id
            })
            return true
        end
    end
    return false
end

-- Clear all notifications
function ClearNotifications()
    for _, notif in ipairs(activeNotifications) do
        SendNUIMessage({
            action = 'removeNotification',
            id = notif.id
        })
    end
    activeNotifications = {}
end

-- Export functions
exports('SendNotification', SendNotification)
exports('RemoveNotification', RemoveNotification)
exports('ClearNotifications', ClearNotifications)

-- Debug commands
if Config.Debug then
    RegisterCommand('testnotifs', function()
        SendNotification({ notificationType = 'info', message = 'This is an info notification' })
        Wait(500)
        SendNotification({ notificationType = 'success', message = 'This is a success notification' })
        Wait(500)
        SendNotification({ notificationType = 'warning', message = 'This is a warning notification' })
        Wait(500)
        SendNotification({ notificationType = 'error', message = 'This is an error notification' })
        Wait(500)
        SendNotification({ notificationType = 'money', message = 'You received $1,000' })
        Wait(500)
        SendNotification({ notificationType = 'vehicle', message = 'Vehicle spawned successfully' })
    end)
end

DebugPrint('Notification system loaded')
