# SECURITY

`src/env.js` previously contained live secrets and was committed by mistake.
That file is deleted and gitignored. Discord invalidates bot tokens pushed to public GitHub.

## Restore the bot after a leaked token

1. Open https://discord.com/developers/applications → your app → **Bot** → **Reset Token**
2. On the VPS, put the new token in `/home/phantom_bot/.env` only:
   ```bash
   DISCORD_BOT_TOKEN=...new token...
   DISCORD_TOKEN=...same...
   ```
3. Ensure `/home/phantom_bot/src/env.js` does **not** exist
4. `systemctl restart phantom-bot`

Also rotate anything that was in that file: MongoDB user password, Groq, Spotify, Giphy, webhook tokens, Lavalink/TTS/Rex keys, relay secret.
