# Host blocks console commands

You do **not** need txAdmin or a shell for **server alerts**.

## What still works (File Manager only)

1. **Pull/sync** your server files (panel File Manager or SFTP).
2. Edit **`/home/container/phantom_dashboard.secrets.cfg`** in File Manager:
   - `phantom_dashboard:webhook` — already set
   - `phantom_dashboard:ownerDiscordId` — your Discord user ID
   - `phantom_dashboard:botToken` — paste your **Discord bot token** (Developer Portal → Bot → Reset/Copy token)

3. **Restart** the game server with the panel **Restart** button (not txAdmin).

FiveM will:
- Post to your **Discord webhook channel** (with @mention)
- **DM you directly** via Discord API (no Node bot, no console)

You do **not** need `discord-bot` running on the host for alerts.

If you run the Node bot on your **PC** instead, set `phantom_dashboard:botToken` on the host and leave `botRelayUrl` empty (or rely on auto-skip when botToken is set). The console message `bot relay failed (0)` is harmless — it means nothing is listening on `127.0.0.1:3099` inside the game container.

## Optional: multipurpose bot (music, /gif, etc.)

That still needs Node somewhere:

| Option | Console needed? |
|--------|-----------------|
| Your PC (only when PC is on) | Yes locally |
| Free/cheap VPS (Oracle, etc.) | SSH on VPS |
| Second server slot from host | Depends on host |

On a restricted game host, use **webhook + botToken DMs** for alerts only.

## File Manager paths (your host)

| File | Purpose |
|------|---------|
| `/home/container/phantom_dashboard.secrets.cfg` | Webhook + bot token + your Discord ID |
| `/home/container/server.cfg` | Must `exec phantom_dashboard.secrets.cfg` |
| `/home/container/discord-bot/.env` | Only if you run Node bot elsewhere |

## After editing secrets

Use panel **Restart** / **Start** — wait until server shows online.

You should see:
- Message in webhook Discord channel
- DM from your bot

## If no DM / HTTP 401

- **401** = invalid `botToken` on the **host** (wrong token, placeholder, or deploy wiped it before we excluded secrets from deploy)
- Paste the **same** token that works in `discord-bot/.env` on your PC
- Bot token wrong or not saved in `phantom_dashboard.secrets.cfg`
- Bot not in your Discord server (invite link from Developer Portal)
- Discord → allow DMs from server members
