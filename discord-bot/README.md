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

2. On the **game server host**, only `.env` needs the bot token (other vars are in `env.host`):

```env
DISCORD_BOT_TOKEN=your_bot_token_here
```

| Variable | Description |
|----------|-------------|
| `DISCORD_BOT_TOKEN` | Bot token (.env only — never commit) |
| `DISCORD_GUILD_ID` | In `env.host` |
| `DISCORD_OWNER_USER_ID` | Your Discord user ID — receives all event DMs |
| `DISCORD_STATUS_CHANNEL_ID` | Optional channel mirror (webhook channel works too) |
| `FIVEM_SERVER_URL` | `http://127.0.0.1:50334` on host |
| `FIVEM_API_TOKEN` | Matches `phantom_dashboard.secrets.cfg` |
| `BOT_RELAY_SECRET` | Same as API token; FiveM posts events to bot |
| `BOT_HTTP_PORT` | Default `3099` |

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
