# Phantom Dashboard

Compact bottom-left HUD strip for **Phantom World** (player info, money, job, voice) plus a Discord bridge for server status and join/leave alerts.

Works alongside **tuff-hud** — it does not replace the main HUD.

## FiveM setup

1. Add to `server.cfg` (after `qbx_core`):

```cfg
ensure phantom_dashboard

# Optional Discord / API (never commit real values)
set phantom_dashboard:webhook "https://discord.com/api/webhooks/..."
set phantom_dashboard:apiToken "your-long-random-token"
set phantom_dashboard:alertMinPlayers 0
set phantom_dashboard:postStartup 1
```

2. Enable HTTP on the game server so the Discord bot can query status:

```cfg
set sv_endpointPrivacy false
# HTTP listens on your game port (default 30120)
```

3. Restart the resource or server:

```
ensure phantom_dashboard
```

## HTTP API

| Path | Description |
|------|-------------|
| `GET /phantom-dashboard/status` | JSON: serverName, serverTime, playerCount, maxPlayers |
| `GET /phantom-dashboard/players` | JSON: `{ players: [{ id, name }], count }` |

If `phantom_dashboard:apiToken` is set, send `Authorization: Bearer <token>` or header `X-Phantom-Token`.

## Discord webhooks (in-game)

Join/leave alerts and startup notifications use `phantom_dashboard:webhook`.

From Lua:

```lua
exports['phantom_dashboard']:SendDiscordAlert('Title', 'Message body', 5814783)
```

## UI position

Bottom-left, above the minimap (~22vh from bottom). Hides when pause menu or NUI menus have focus.

Toggle rank/job lines via existing convars:

```cfg
setr qbx_hud:showRank 1
setr qbx_hud:showJob 1
```

## Full bug / error reporting

Console `SCRIPT ERROR` and similar critical failures are:
1. Posted to Discord (webhook + bot relay)
2. If `phantom_dashboard:errorRestart 1`: players get an on-screen / chat warning that the server will restart and they will be kicked (rejoin after it is back)
3. After the countdown, everyone is kicked and FXServer restarts via the bot host endpoint

Soft noise (missing resources, version checks) is Discord-only and does **not** restart.

## Hourly restart

With `phantom_dashboard:hourlyRestart 1` the server restarts every **3600 seconds** (1 hour).
Players get a **5 minute** warning (chat + on-screen), then kick + restart. Discord is notified.

```cfg
set phantom_dashboard:hourlyRestart 1
set phantom_dashboard:hourlyRestartSeconds 3600
set phantom_dashboard:hourlyRestartWarnSeconds 300
```

Disable restart: `set phantom_dashboard:errorRestart 0`  
Disable hourly: `set phantom_dashboard:hourlyRestart 0`  
Test: console `phantom_testerror`, `phantom_testrestart`, or `phantom_testhourly`

## Stuck / bug assist

Players can run:
- `/unstuck` (or `/stuck`) — clears stuck NUI focus, unfreezes, soft reposition
- `/reportstuck` — sends a Discord alert to staff with coords + flags

Auto-detect (configurable):
- Holding move keys but not moving (~25s)
- NUI focus stuck (~120s)
- Black screen / fade stuck (~75s)

Disable: `set phantom_dashboard:stuckWatch 0`

