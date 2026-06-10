#!/usr/bin/env bash
# Run on the FXServer host (Linux). Keeps bot in foreground — use start-host-background.sh for 24/7.
set -euo pipefail
cd "$(dirname "$0")"

if [[ ! -f .env ]]; then
  echo "Create discord-bot/.env with: DISCORD_BOT_TOKEN=your_token"
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo "Install Node.js 18+ on the host first."
  exit 1
fi

npm install --omit=dev
echo "Starting Phantom World Discord bot (relay 127.0.0.1:3099)..."
exec node index.js
