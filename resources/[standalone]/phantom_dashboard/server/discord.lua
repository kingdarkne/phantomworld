--- Webhook helpers kept for compatibility; alerts.lua owns event routing.

exports('SendDiscordAlert', function(title, message, color)
    PhantomDashboardEmit('export', title, message, color)
end)
