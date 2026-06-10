#!/usr/bin/env bash
# Start bot in background on Linux host (survives SSH disconnect).
set -euo pipefail
cd "$(dirname "$0")"

if [[ ! -f .env ]]; then
  echo "Create discord-bot/.env with DISCORD_BOT_TOKEN=..."
  exit 1
fi

npm install --omit=dev
mkdir -p logs

if [[ -f bot.pid ]] && kill -0 "$(cat bot.pid)" 2>/dev/null; then
  echo "Bot already running (PID $(cat bot.pid)). Stop with: kill \$(cat bot.pid)"
  exit 1
fi

nohup node index.js >> logs/bot.log 2>&1 &
echo $! > bot.pid
echo "Phantom bot started PID $(cat bot.pid). Log: discord-bot/logs/bot.log"
