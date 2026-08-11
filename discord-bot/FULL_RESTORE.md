# Full backup restore + Phantom merge

Restored the Pterodactyl TRex/Phantom ALL-IN-ONE backup (~385 command modules, 44+ slash parents) as the live bot base, then merged Phantom extras from the slim rewrite:

| Feature | Status |
|---------|--------|
| Full command suites (mod, tickets, economy, casino, music, rex, …) | From backup |
| MongoDB models + loaders | From backup |
| FiveM `/events` relay + `/health` | Wired via `aio-bridge` (without wiping slash cmds) |
| `/phantomstatus` `/dminvite` `/serverinvite` `/statuslive` | Added |
| Live status channel + invite DM helpers | `src/lib/live-status-channel.js`, `server-invite-dm.js` |
| Default prefix | `$` (`COMMAND_PREFIX`) |
| HTTP bind | `127.0.0.1` by default |

Deploy: `VPS_PASSWORD=… ./discord-bot/deploy-vps.sh` (preserves remote `.env` + `data/`).
