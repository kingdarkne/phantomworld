# Phantom World ALL-IN-ONE Bot — KataBump 4000 MB server

Developed by **Phantom World**. Based on the open-source multipurpose bot stack, rebranded and patched for Phantom World RP.

## Before first start

1. **Discord token** — paste `DISCORD_BOT_TOKEN` (or `DISCORD_TOKEN`) in `.env` on the server.
2. **MongoDB Atlas** (free tier) — create a cluster, get connection string, set `MONGO_TOKEN` in `.env`. The bot **cannot run** without MongoDB.
3. Copy `env.host` values or merge into `.env` (FiveM, Lavalink, guild ID).

## KataBump (4000 MB server)

| Setting | Value |
|---------|--------|
| Panel | https://control.katabump.com/server/22de9d34 |
| SFTP host | `sftp.fr-node-57.katabump.com:2022` |
| SFTP user | `28a4dfe9a9a84b2.22de9d34` |
| Startup file | `index.js` |
| Node | 24 |

Upload (from `discord-bot/`):

```powershell
$env:KATABUMP_SFTP_HOST="sftp.fr-node-57.katabump.com"
$env:KATABUMP_SFTP_USER="28a4dfe9a9a84b2.22de9d34"
$env:KATABUMP_SFTP_PASS="your-panel-password"
node scripts/upload-katabump.cjs
```

Then **Restart** in the KataBump console (SSH restart does not work).

## Commands

- Full AIO slash commands: `/help`, `/music`, `/setup`, etc.
- Phantom FiveM: `/phantomstatus`
- Event relay: `POST /events` on `BOT_HTTP_PORT` (default 3099)

## Invite bot

https://discord.com/api/oauth2/authorize?client_id=849173210838466561&permissions=2147567616&scope=bot%20applications.commands

## Support

https://discord.gg/zZSvmdUx
