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

sshpass -e ssh ${SSH_OPTS} "${USER}@${HOST}" "cd ${REMOTE} && npm install --omit=dev && systemctl restart ${SERVICE} || systemctl restart phantom-discord-bot"
echo "Done. Health: curl http://${HOST}:3099/health"
