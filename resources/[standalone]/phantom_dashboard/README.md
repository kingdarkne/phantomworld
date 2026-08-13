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

## Stuck / bug assist

Players can run:
- `/unstuck` (or `/stuck`) — clears stuck NUI focus, unfreezes, soft reposition
- `/reportstuck` — sends a Discord alert to staff with coords + flags

Auto-detect (configurable):
- Holding move keys but not moving (~25s)
- NUI focus stuck (~120s)
- Black screen / fade stuck (~75s)

Disable: `set phantom_dashboard:stuckWatch 0`

