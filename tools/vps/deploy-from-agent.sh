#!/usr/bin/env bash
# Deploy Phantom World to VPS from Cloud Agent (requires VPS_SSH_* secrets in environment).
set -euo pipefail

: "${VPS_SSH_HOST:?VPS_SSH_HOST secret is required}"
: "${VPS_SSH_USER:?VPS_SSH_USER secret is required}"

PORT="${VPS_SSH_PORT:-22}"
BRANCH="${DEPLOY_BRANCH:-cursor/server-cleanup-playable-c3ea}"
REMOTE_DIR="${VPS_REMOTE_DIR:-/opt/fivem/phantomworld}"

SSH_OPTS=(-o StrictHostKeyChecking=accept-new -o ConnectTimeout=20 -p "$PORT")

run_ssh() {
  if [ -n "${VPS_SSH_PRIVATE_KEY:-}" ]; then
    local keyfile
    keyfile="$(mktemp)"
    trap 'rm -f "$keyfile"' RETURN
    printf '%s\n' "$VPS_SSH_PRIVATE_KEY" > "$keyfile"
    chmod 600 "$keyfile"
    ssh -i "$keyfile" "${SSH_OPTS[@]}" "$VPS_SSH_USER@$VPS_SSH_HOST" "$@"
  elif [ -n "${VPS_SSH_PASSWORD:-}" ]; then
    command -v sshpass >/dev/null || { echo "sshpass required for password auth"; exit 1; }
    SSHPASS="$VPS_SSH_PASSWORD" sshpass -e ssh "${SSH_OPTS[@]}" "$VPS_SSH_USER@$VPS_SSH_HOST" "$@"
  else
    echo "Set VPS_SSH_PASSWORD or VPS_SSH_PRIVATE_KEY"
    exit 1
  fi
}

run_scp() {
  local src="$1" dest="$2"
  if [ -n "${VPS_SSH_PRIVATE_KEY:-}" ]; then
    local keyfile
    keyfile="$(mktemp)"
    trap 'rm -f "$keyfile"' RETURN
    printf '%s\n' "$VPS_SSH_PRIVATE_KEY" > "$keyfile"
    chmod 600 "$keyfile"
    scp -i "$keyfile" "${SSH_OPTS[@]}" -r "$src" "$VPS_SSH_USER@$VPS_SSH_HOST:$dest"
  elif [ -n "${VPS_SSH_PASSWORD:-}" ]; then
    SSHPASS="$VPS_SSH_PASSWORD" sshpass -e scp "${SSH_OPTS[@]}" -r "$src" "$VPS_SSH_USER@$VPS_SSH_HOST:$dest"
  else
    echo "Set VPS_SSH_PASSWORD or VPS_SSH_PRIVATE_KEY"
    exit 1
  fi
}

echo "==> Testing SSH to $VPS_SSH_USER@$VPS_SSH_HOST:$PORT"
run_ssh "uname -a && free -h && df -h /"

echo "==> Running bootstrap on VPS"
run_ssh "curl -fsSL https://raw.githubusercontent.com/kingdarkne/phantomworld/$BRANCH/tools/vps/bootstrap-server.sh | INSTALL_DIR=/opt/fivem REPO_BRANCH=$BRANCH bash"

echo "==> Syncing local workspace (fast path for agent-tested branch)"
TMP_TAR="$(mktemp /tmp/phantomworld-XXXX.tar.gz)"
tar -czf "$TMP_TAR" \
  --exclude='.git' \
  --exclude='cache' \
  --exclude='tmp' \
  --exclude='_archive_resources' \
  --exclude='CFX-Developer-Tools' \
  -C /workspace .
run_scp "$TMP_TAR" "/tmp/phantomworld-sync.tar.gz"
run_ssh "mkdir -p $REMOTE_DIR && tar -xzf /tmp/phantomworld-sync.tar.gz -C $REMOTE_DIR && rm /tmp/phantomworld-sync.tar.gz"

echo "==> Starting FXServer in tmux (session: fivem-server)"
run_ssh "command -v tmux >/dev/null 2>&1 || apt-get update -qq && apt-get install -y -qq tmux; \
  tmux kill-session -t fivem-server 2>/dev/null || true; \
  tmux new-session -d -s fivem-server \"cd $REMOTE_DIR && bash start.sh 2>&1 | tee -a /tmp/fivem-console.log\""

sleep 15
echo "==> Recent console output"
run_ssh "tail -80 /tmp/fivem-console.log 2>/dev/null || echo 'Log not ready yet — server may still be starting'"

echo "==> Deploy complete. Monitor with: ssh ... 'tail -f /tmp/fivem-console.log'"
