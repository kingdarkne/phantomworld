#!/usr/bin/env bash
# Patch-deploy live multipurpose bot without wiping /home/phantom_bot
# Usage: VPS_PASSWORD='...' ./discord-bot/deploy-bot-patches.sh
set -euo pipefail
HOST="${VPS_HOST:-172.245.71.46}"
USER="${VPS_USER:-root}"
BOT_PATH="${VPS_BOT_PATH:-/home/phantom_bot}"
ROOT="$(cd "$(dirname "$0")" && pwd)"
: "${VPS_PASSWORD:?Set VPS_PASSWORD}"
export SSHPASS="$VPS_PASSWORD"
SSH=(sshpass -e ssh -o StrictHostKeyChecking=no)
RSYNC=(sshpass -e rsync -avz -e "ssh -o StrictHostKeyChecking=no")

"${RSYNC[@]}" "${ROOT}/src/interactions/" "${USER}@${HOST}:${BOT_PATH}/src/interactions/"
"${RSYNC[@]}" "${ROOT}/src/commands/" "${USER}@${HOST}:${BOT_PATH}/src/commands/"
"${RSYNC[@]}" "${ROOT}/aio-bridge/" "${USER}@${HOST}:${BOT_PATH}/aio-bridge/"
sshpass -e scp -o StrictHostKeyChecking=no \
  "${ROOT}/src/handlers/components/embed.js" \
  "${ROOT}/src/handlers/loaders/event.js" \
  "${ROOT}/src/handlers/functions/functions.js" \
  "${ROOT}/src/events/client/interactionCreate.js" \
  "${ROOT}/src/events/guild/guildMemberAdd.js" \
  "${ROOT}/src/lib/rex-listen.cjs" \
  "${ROOT}/rex-ai-server/server.js" \
  "${USER}@${HOST}:/tmp/bot-patches/"

"${SSH[@]}" "${USER}@${HOST}" "mkdir -p /tmp/bot-patches && \
  install -m 644 /tmp/bot-patches/embed.js ${BOT_PATH}/src/handlers/components/embed.js && \
  install -m 644 /tmp/bot-patches/event.js ${BOT_PATH}/src/handlers/loaders/event.js && \
  install -m 644 /tmp/bot-patches/functions.js ${BOT_PATH}/src/handlers/functions/functions.js && \
  install -m 644 /tmp/bot-patches/interactionCreate.js ${BOT_PATH}/src/events/client/interactionCreate.js && \
  install -m 644 /tmp/bot-patches/guildMemberAdd.js ${BOT_PATH}/src/events/guild/guildMemberAdd.js && \
  install -m 644 /tmp/bot-patches/rex-listen.cjs ${BOT_PATH}/src/lib/rex-listen.cjs && \
  install -m 644 /tmp/bot-patches/server.js ${BOT_PATH}/rex-ai-server/server.js && \
  systemctl restart phantom-rex-ai phantom-bot && systemctl is-active phantom-bot phantom-rex-ai"
echo "Patched live bot on ${HOST}"
