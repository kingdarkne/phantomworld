#!/usr/bin/env bash
# Run ON THE GAME SERVER (Linux), not your gaming PC.
set -euo pipefail

BOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVICE_NAME="phantom-discord-bot"
SERVICE_USER="${SUDO_USER:-$USER}"

echo "=== Phantom Discord Bot — game host install ==="
echo "Directory: $BOT_DIR"

if ! command -v node >/dev/null 2>&1; then
  echo "Install Node.js 18+ first, e.g.: curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt install -y nodejs"
  exit 1
fi

if [[ ! -f "$BOT_DIR/.env" ]]; then
  echo "Create $BOT_DIR/.env with:"
  echo "DISCORD_BOT_TOKEN=your_bot_token"
  exit 1
fi

cd "$BOT_DIR"
npm install --omit=dev

if command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg OK (music)"
else
  echo "Tip: install ffmpeg for /play music: sudo apt install -y ffmpeg"
fi

UNIT="/etc/systemd/system/${SERVICE_NAME}.service"
sudo tee "$UNIT" > /dev/null <<EOF
[Unit]
Description=Phantom World Discord Bot
After=network.target

[Service]
Type=simple
User=${SERVICE_USER}
WorkingDirectory=${BOT_DIR}
ExecStart=$(command -v node) index.js
Restart=always
RestartSec=15
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable "${SERVICE_NAME}"
sudo systemctl restart "${SERVICE_NAME}"
sudo systemctl status "${SERVICE_NAME}" --no-pager

echo ""
echo "Bot should stay online when your PC is off."
echo "Health: curl http://127.0.0.1:3099/health"
echo "Logs:   journalctl -u ${SERVICE_NAME} -f"
