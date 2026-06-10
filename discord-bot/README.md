# Phantom World Discord Bot

Node.js bot for server status, player list, and manual alerts. Pairs with the `phantom_dashboard` FiveM resource HTTP API.

## Prerequisites

- Node.js 18+
- Discord application with bot token
- FiveM server running `phantom_dashboard` with HTTP enabled

## Setup

1. Copy env file:

```bash
cd discord-bot
cp .env.example .env
```

2. Fill in `.env`:

| Variable | Description |
|----------|-------------|
| `DISCORD_BOT_TOKEN` | Bot token from [Discord Developer Portal](https://discord.com/developers/applications) |
| `DISCORD_GUILD_ID` | Your Discord server ID |
| `DISCORD_STATUS_CHANNEL_ID` | Channel for optional auto status posts |
| `FIVEM_SERVER_URL` | e.g. `http://YOUR_SERVER_IP:30120` |
| `FIVEM_API_TOKEN` | Same value as `phantom_dashboard:apiToken` in server.cfg |
| `CFX_SERVER_ID` | Optional fallback (public listing ID) if HTTP is blocked |
| `STATUS_POLL_MINUTES` | Auto-post interval; `0` disables |

3. Install and run:

```bash
npm install
npm start
```

Slash commands register automatically on startup when `DISCORD_GUILD_ID` is set.

## Commands

| Command | Description |
|---------|-------------|
| `/status` | Server name, player count, time |
| `/players` | Online player list (when HTTP API reachable) |
| `/alert <message>` | Post alert embed (requires Manage Server) |

## Hosting

Run on the same machine as the game server (localhost URL) or any host that can reach the FiveM HTTP port. Use a process manager (pm2, systemd) for production.

**Do not commit `.env` or bot tokens.**

## FiveM side

In `server.cfg`:

```cfg
ensure phantom_dashboard
set phantom_dashboard:webhook "https://discord.com/api/webhooks/..."
set phantom_dashboard:apiToken "match-this-to-FIVEM_API_TOKEN"
```

Restart: `ensure phantom_dashboard` and restart the bot process.
