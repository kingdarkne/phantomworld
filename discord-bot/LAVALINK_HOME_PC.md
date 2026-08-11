# Run Lavalink on your PC (Phantom World bot on KataBump)

The **Discord bot** stays on KataBump (Node 18). **Lavalink** is Java — run it on your PC (or a VPS), not on the KataBump Node slot.

## 1. Start Lavalink on Windows

```powershell
cd "d:\New folder\discord-bot\lavalink"
.\start-lavalink.ps1
```

First run installs **Java 17** (winget) and downloads **Lavalink.jar**. Default password: `phantomworld` (edit `lavalink/application.yml`).

## 2. Expose to KataBump (required)

KataBump cannot reach `127.0.0.1` on your PC. Use a tunnel:

```powershell
cd "d:\New folder\discord-bot\lavalink"
.\start-tunnel.ps1
```

Copy the `https://xxxx.trycloudflare.com` hostname (no `https://`).

## 3. KataBump `.env`

```env
LAVALINK_HOST=xxxx.trycloudflare.com
LAVALINK_PORT=443
LAVALINK_PASSWORD=phantomworld
LAVALINK_SECURE=true
```

Restart the bot in the panel. Console should show Lavalink connected.

### Multiple nodes (optional JSON)

```env
LAVALINK_NODES=[{"identifier":"home","host":"xxxx.trycloudflare.com","port":443,"password":"phantomworld","secure":true}]
```

## 4. Song search list

`/music play <name>` shows up to **10 results** in a dropdown (Lavalink v4 fix). URLs still play directly.

## KataBump host?

The Node.js game panel cannot run Lavalink (no Java). Options: PC + tunnel (above), a cheap VPS, or keep a public Lavalink node in `.env`.

## Firewall

If you port-forward **2333** instead of a tunnel:

```env
LAVALINK_HOST=your.public.ip
LAVALINK_PORT=2333
LAVALINK_SECURE=false
```

Open TCP 2333 on your router and Windows Firewall.
