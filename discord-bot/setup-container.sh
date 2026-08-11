#!/usr/bin/env bash
# Pterodactyl / game panel container — path: /home/container/discord-bot
set -euo pipefail

BOT_DIR="/home/container/discord-bot"
cd "$BOT_DIR"

if [[ ! -f .env ]]; then
  echo "=== Create .env first ==="
  echo "Run: nano .env"
  echo "Add one line: DISCORD_BOT_TOKEN=your_token_here"
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo "Node.js not found in this container. Enable Node in your panel or ask host to install Node 18+."
  exit 1
fi

echo "Node: $(node -v)"
if command -v yarn >/dev/null 2>&1; then
  echo "Installing deps with yarn…"
  yarn install --production
else
  echo "Installing deps with npm…"
  npm install --omit=dev
fi
mkdir -p logs

# Stop old instance if running
if [[ -f bot.pid ]] && kill -0 "$(cat bot.pid)" 2>/dev/null; then
  kill "$(cat bot.pid)" 2>/dev/null || true
  sleep 1
fi
pkill -f "discord-bot/index.js" 2>/dev/null || true
pkill -f "node index.js" 2>/dev/null || true
sleep 1

nohup node index.js >> logs/bot.log 2>&1 &
echo $! > bot.pid

sleep 2
if kill -0 "$(cat bot.pid)" 2>/dev/null; then
  echo "OK — bot running PID $(cat bot.pid)"
  echo "Log: tail -f $BOT_DIR/logs/bot.log"
  curl -s http://127.0.0.1:3099/health || echo "Relay starting… try: curl http://127.0.0.1:3099/health"
else
  echo "Bot failed to start. Check: tail -50 $BOT_DIR/logs/bot.log"
  exit 1
fi
