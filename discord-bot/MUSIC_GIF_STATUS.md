# Music, GIFs, and status

| Feature | Command | Backend |
|---------|---------|---------|
| Server status | `/status` | CFX + FiveM HTTP |
| GIFs | `/gif` | Giphy or Reddit |
| Music | `/play` `/pause` `/resume` `/skip` `/stop` `/queue` | **Lavalink** via Shoukaku |

## Lavalink (music)

Configured in `env.host` / `.env`:

| Variable | Default |
|----------|---------|
| `LAVALINK_HOST` | `lavalink.jirayu.net` |
| `LAVALINK_PORT` | `443` |
| `LAVALINK_PASSWORD` | `youshallnotpass` |
| `LAVALINK_SECURE` | `true` (WSS) |

On start you should see: `Lavalink node "main" connected (wss://lavalink.jirayu.net:443)`.

## Bot permissions

- **Use Slash Commands**
- **Connect** + **Speak** (music)
- **Send Messages** + **Embed Links**

## If `/play` fails

1. Join a voice channel first.
2. Restart KataBump after deploy (`npm install` for `shoukaku`).
3. Wait until Lavalink shows connected in the console.
4. If the public node is down, change `LAVALINK_*` to another node.
