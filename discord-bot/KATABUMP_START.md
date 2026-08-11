# KataBump quick start

**4000 MB bot server (h):** [control panel](https://control.katabump.com/server/22de9d34)

| SFTP | Value |
|------|--------|
| Host | `sftp.fr-node-57.katabump.com:2022` |
| User | `28a4dfe9a9a84b2.22de9d34` |
| Password | Same as KataBump panel login |

```powershell
$env:KATABUMP_SFTP_HOST="sftp.fr-node-57.katabump.com"
$env:KATABUMP_SFTP_USER="28a4dfe9a9a84b2.22de9d34"
$env:KATABUMP_SFTP_PASS="your_panel_password"
cd discord-bot
node scripts/upload-katabump.cjs
```

Then **Restart** in Console. Stop the old small server (Kingbob575) so only one bot uses the token.

Files live at **server root** (`/home/container`): `index.js`, `package.json`, `env.host`, `.env`.

## Panel checklist

1. [control.katabump.com](https://control.katabump.com) → **Startup** → **JS FILE** = `index.js` → Save  
2. **Console** → **Start**  
3. Wait for `Logged in as …`  
4. Discord: **Phantom World Bot Online** DM + `/phantomhelp`  
5. Test: `/status` `/gif` `/play` (in voice) — Lavalink via `lavalink.jirayu.net:443`

## `.env` (secret — on server only)

```env
DISCORD_BOT_TOKEN=your_token
BOT_HTTP_BIND=0.0.0.0
```

`env.host` supplies guild, owner ID, FiveM URL, `CFX_SERVER_ID` (`load-env.js` loads both).

## Gravelhost (FiveM)

In `phantom_dashboard.secrets.cfg` on the game host:

- `botToken` = same app token as KataBump `.env` (event DMs)  
- `botRelayUrl` = empty (KataBump has no public relay)  
- `webhook` = channel alerts  

Restart FiveM from Gravelhost panel.

Full guide: [docs/KATABUMP_SETUP.md](../docs/KATABUMP_SETUP.md)
