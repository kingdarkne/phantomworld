Config = {}

--- UI toggles (also overridable via convars qbx_hud:showRank / qbx_hud:showJob)
Config.ShowRank = true
Config.ShowJob = true
Config.ShowGang = true
Config.ShowStreet = true
Config.ShowMoney = true
Config.ShowVoice = true

--- Position: bottom-left, above minimap / below chat safe zone
Config.Position = {
    left = '1.15vw',
    bottom = '22vh',
    maxWidth = 'min(320px, 42vw)',
}

--- Discord / HTTP bridge (secrets via server.cfg convars — never commit tokens)
Config.Discord = {
    --- Webhook URL for join/leave alerts (set phantom_dashboard:webhook in server.cfg)
    Webhook = GetConvar('phantom_dashboard:webhook', ''),
    --- Bearer token for HTTP API (set phantom_dashboard:apiToken in server.cfg)
    ApiToken = GetConvar('phantom_dashboard:apiToken', ''),
    --- Minimum players before posting join/leave (reduces spam on dev restarts)
    AlertMinPlayers = tonumber(GetConvar('phantom_dashboard:alertMinPlayers', '0')) or 0,
    --- Post server online embed on resource start
    PostStartup = GetConvarInt('phantom_dashboard:postStartup', 1) == 1,
    --- Node relay URL (phantom_dashboard:botRelayUrl). Empty = use botToken for direct DMs.
    BotRelayUrl = GetConvar('phantom_dashboard:botRelayUrl', ''),
    --- Owner Discord user id for webhook mentions (phantom_dashboard:ownerDiscordId)
    OwnerDiscordId = GetConvar('phantom_dashboard:ownerDiscordId', ''),
    --- Post join/leave/resource/txAdmin/combat alerts
    AlertAllEvents = GetConvarInt('phantom_dashboard:alertAllEvents', 1) == 1,
    --- DM owner on routine join/leave/connect (0 = channel only — recommended)
    DmOwnerOnEvents = GetConvarInt('phantom_dashboard:dmOwnerOnEvents', 0) == 1,
    --- Append <@owner> ping on routine webhooks (0 = no pings — recommended)
    PingOwnerOnWebhook = GetConvarInt('phantom_dashboard:pingOwnerOnWebhook', 0) == 1,
    --- Optional dedicated webhook for SCRIPT ERROR / console failures
    ErrorWebhook = GetConvar('phantom_dashboard:errorWebhook', ''),
    --- Capture FX console errors and post to Discord (1/0)
    ErrorReporting = GetConvarInt('phantom_dashboard:errorReporting', 1) == 1,
    --- On critical SCRIPT ERROR: warn players, Discord alert, kick, restart (1/0)
    ErrorRestart = GetConvarInt('phantom_dashboard:errorRestart', 1) == 1,
    --- Automatic restart every N seconds (default 1 hour)
    HourlyRestart = GetConvarInt('phantom_dashboard:hourlyRestart', 1) == 1,
    --- Watch for stuck players / likely client bugs (1/0)
    StuckWatch = GetConvarInt('phantom_dashboard:stuckWatch', 1) == 1,
    --- Auto Discord reports from heuristics (0=prompts only, recommended)
    StuckAutoReport = GetConvarInt('phantom_dashboard:stuckAutoReport', 0) == 1,
}
