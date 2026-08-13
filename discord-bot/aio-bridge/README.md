# Phantom FiveM bridge for ALL-IN-ONE-Discord-Bot

Adds Phantom World FiveM status + event relay to [Uo1428/ALL-IN-ONE-Discord-Bot-](https://github.com/Uo1428/ALL-IN-ONE-Discord-Bot-) without replacing the whole AIO codebase.

## Copy into AIO project

```text
ALL-IN-ONE-Discord-Bot-/
  src/
    phantom-fivem/
      index.js          ← copy from this folder
      fivem-status.js   ← copy from this folder
```

## AIO `.env` additions

```env
# Already required by AIO
DISCORD_TOKEN=...
OWNER_ID=413173364216168449

# Phantom FiveM (optional)
FIVEM_SERVER_URL=http://135.148.136.32:50334
FIVEM_API_TOKEN=your_relay_token
BOT_RELAY_SECRET=your_relay_token
BOT_HTTP_PORT=3099
BOT_HTTP_BIND=0.0.0.0
DISCORD_GUILD_ID=1472275444257783984
CFX_SERVER_ID=3m87mo
```

## Hook into AIO

In `src/bot.js`, after `client` is created and before `client.login`, add:

```js
const setupPhantomFivem = require('./phantom-fivem/index.js');
client.once('ready', () => setupPhantomFivem(client));
```

Or append to an existing `ready` handler in `src/events/client/`.

## Gravelhost

Same as Phantom bot: `phantom_dashboard:botToken` for event DMs, or relay if your host exposes HTTP to this bot.

## RAM warning

AIO + Phantom bridge needs more than KataBump free (308 MiB). Use a VPS or paid bot plan.
