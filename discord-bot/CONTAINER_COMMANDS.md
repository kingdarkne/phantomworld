# Commands for `/home/container/discord-bot` (Pterodactyl / panel host)

SSH into your server, then copy-paste these blocks.

## 1) One-time — bot token

```bash
cd /home/container/discord-bot
nano .env
```

Paste **only** this line (replace with your real token):

```
DISCORD_BOT_TOKEN=paste_your_bot_token_here
```

Save: `Ctrl+O`, Enter, `Ctrl+X`

## 2) Install + start bot (stays running in background)

```bash
cd /home/container/discord-bot
chmod +x setup-container.sh start-host-background.sh stop-host.sh
./setup-container.sh
```

## 3) Check it’s working

```bash
curl http://127.0.0.1:3099/health
tail -f /home/container/discord-bot/logs/bot.log
```

You should get a Discord DM: **Phantom World Bot Online**.

## 4) Stop / restart bot

```bash
cd /home/container/discord-bot
./stop-host.sh
./setup-container.sh
```

Or:

```bash
kill $(cat /home/container/discord-bot/bot.pid)
```

## 5) After every `git pull`

```bash
cd /home/container/discord-bot
./setup-container.sh
```

## 6) FiveM must use same machine

FXServer alerts go to `127.0.0.1:3099` **inside this container**.  
Confirm secrets exist:

```bash
cat /home/container/phantom_dashboard.secrets.cfg
```

Restart FiveM from txAdmin/panel after pull.

## 7) Wrong FiveM port?

If `/status` fails in Discord, edit `env.host`:

```bash
nano /home/container/discord-bot/env.host
```

Set `FIVEM_SERVER_URL` to your game port (check `server.cfg` `endpoint_add` line).

## 8) Auto-start bot when container boots (optional)

In panel **Startup Command** or a small script, append:

```bash
cd /home/container/discord-bot && ./setup-container.sh
```
