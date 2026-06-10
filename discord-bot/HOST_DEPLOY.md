# Host the Phantom Discord bot (same machine as FXServer)

The bot must run **on the game server host** so FiveM can POST alerts to `http://127.0.0.1:3099/events`.

## One-time setup on the host

1. **Install Node.js 18+** on the host (same OS as FXServer).

2. **Pull the repo** (or sync files) so you have `discord-bot/` and `phantom_dashboard.secrets.cfg`.

3. **Create the bot token file** (never committed):

```bash
cd discord-bot
echo DISCORD_BOT_TOKEN=your_bot_token_here > .env
```

`env.host` is already in the repo (guild ID, FiveM port, API token).

4. **Linux — run 24/7 in background:**

```bash
cd discord-bot
chmod +x start-host-background.sh stop-host.sh
./start-host-background.sh
```

5. **Windows host:**

```powershell
cd discord-bot
.\start-host-background.bat
```

Or foreground: `.\start-host.bat` / `.\start-host.ps1`

6. **Restart FXServer** (or `ensure phantom_dashboard`) so game events hit the relay.

## Verify

- `curl http://127.0.0.1:3099/health` → `{"ok":true,...}`
- Join the game → you get a DM
- Discord: `/phantomhelp`, `/status`, `/gif`, `/play` (in voice channel)

## Commands (multipurpose + host)

| Area | Commands |
|------|----------|
| Host | `/status` `/players` `/alert` |
| Fun | `/gif` `/joke` `/8ball` |
| Music | `/play` `/skip` `/stop` `/queue` |
| Help | `/phantomhelp` |

Optional: set `GIPHY_API_KEY` in `.env` for `/gif search:...`

## txAdmin / panel

Add a **secondary process** or scheduled task that runs `discord-bot/start-host-background.sh` on machine boot, separate from FXServer.
