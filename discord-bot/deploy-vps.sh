#!/usr/bin/env bash
# Run from repo root on a machine with SSH access to the VPS.
# Usage: VPS_PASSWORD='...' ./discord-bot/deploy-vps.sh
set -euo pipefail

HOST="${VPS_HOST:-172.245.71.46}"
USER="${VPS_USER:-root}"
PORT="${VPS_PORT:-22}"
REMOTE="${VPS_BOT_PATH:-/home/phantom_bot}"
SERVICE="${VPS_BOT_SERVICE:-phantom-bot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v sshpass >/dev/null 2>&1; then
  echo "Install sshpass first"
  exit 1
fi
: "${VPS_PASSWORD:?Set VPS_PASSWORD}"

export SSHPASS="$VPS_PASSWORD"
SSH_OPTS="-o StrictHostKeyChecking=no -p ${PORT}"

echo "Deploying to ${USER}@${HOST}:${REMOTE}"
sshpass -e rsync -avz --delete \
  -e "ssh ${SSH_OPTS}" \
  --exclude node_modules --exclude .env --exclude data --exclude logs \
  --exclude home --exclude .cache \
  --exclude src/config/webhooks.json --exclude src/env.js --exclude database.json \
  "${ROOT}/discord-bot/" "${USER}@${HOST}:${REMOTE}/"

sshpass -e ssh ${SSH_OPTS} "${USER}@${HOST}" bash -s <<'REMOTE_SCRIPT'
set -euo pipefail
cd /home/phantom_bot
npm install --omit=dev

# Point Rex + TTS at local Groq-backed API (remote 23.238 host is offline)
if grep -q '^REX_API_URL=' .env; then
  sed -i 's|^REX_API_URL=.*|REX_API_URL=http://127.0.0.1:5600|' .env
else
  echo 'REX_API_URL=http://127.0.0.1:5600' >> .env
fi
if grep -q '^TTS_API_URL=' .env; then
  sed -i 's|^TTS_API_URL=.*|TTS_API_URL=http://127.0.0.1:5600/synthesize|' .env
else
  echo 'TTS_API_URL=http://127.0.0.1:5600/synthesize' >> .env
fi
grep -q '^REX_LOCAL_PORT=' .env || echo 'REX_LOCAL_PORT=5600' >> .env
grep -q '^REX_PUBLIC_BASE=' .env || echo 'REX_PUBLIC_BASE=http://127.0.0.1:5600' >> .env

install -m 644 /home/phantom_bot/rex-ai-server/phantom-rex-ai.service /etc/systemd/system/phantom-rex-ai.service
systemctl daemon-reload
systemctl enable phantom-rex-ai
systemctl restart phantom-rex-ai
systemctl restart phantom-bot || systemctl restart phantom-discord-bot
sleep 2
curl -s http://127.0.0.1:5600/health || true
echo
curl -s http://127.0.0.1:3099/health || true
echo
REMOTE_SCRIPT

echo "Done. Bot health: curl http://${HOST}:3099/health  Rex: curl http://127.0.0.1:5600/health (on VPS)"

