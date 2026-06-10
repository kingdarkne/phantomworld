# Run the bot on the GAME SERVER (not your PC)

## Why your PC bot did not get server restart alerts

FiveM posts alerts to `http://127.0.0.1:3099` on **the machine running FXServer**.

| Where bot runs | Gets server restart DMs? |
|----------------|--------------------------|
| Your gaming PC | ❌ No — FXServer is on the host |
| Same machine as FXServer | ✅ Yes |

Webhook channel posts can work from the host without the bot, but **owner DMs require the bot on the host**.

## Quick setup (Linux game host)

```bash
cd /path/to/phantomworld
git pull

# One-time: bot token only
cd discord-bot
echo 'DISCORD_BOT_TOKEN=your_token' > .env

# Install as systemd service (stays on after SSH disconnect / PC off)
chmod +x install-on-game-host.sh
./install-on-game-host.sh
```

Then **restart FXServer** (txAdmin or panel).

## Windows game host

```powershell
cd discord-bot
echo DISCORD_BOT_TOKEN=your_token > .env
.\start-host-background.bat
```

Use Task Scheduler to run `start-host-background.bat` at boot.

## GitHub push alerts

Git pushes are **not** sent by FiveM. Add GitHub secret `DISCORD_WEBHOOK` — see `docs/GITHUB_DISCORD_ALERTS.md`.

## Multipurpose + FiveM (one bot)

This repo bot includes typical multipurpose features (music, GIFs, jokes, polls, games) **plus** FiveM host alerts. No second bot needed.

Commands: `/phantomhelp`

## Verify

```bash
curl http://127.0.0.1:3099/health
```

Restart FXServer → Discord webhook channel + your DM (if bot on host).
