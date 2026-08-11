#!/usr/bin/env bash
# First-time FiveM + txAdmin bootstrap for Ubuntu 22.04/24.04 (run ON the VPS as root).
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-/opt/fivem}"
REPO_URL="${REPO_URL:-https://github.com/kingdarkne/phantomworld.git}"
REPO_BRANCH="${REPO_BRANCH:-cursor/server-cleanup-playable-c3ea}"
GAME_PORT="${GAME_PORT:-30120}"
TXADMIN_PORT="${TXADMIN_PORT:-40120}"

echo "==> Installing system dependencies"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq git curl wget xz-utils tar ca-certificates mariadb-client

echo "==> Creating install directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

if [ ! -d phantomworld/.git ]; then
  echo "==> Cloning Phantom World ($REPO_BRANCH)"
  git clone --branch "$REPO_BRANCH" --depth 1 "$REPO_URL" phantomworld
else
  echo "==> Updating existing clone"
  cd phantomworld
  git fetch origin "$REPO_BRANCH"
  git checkout "$REPO_BRANCH"
  git pull origin "$REPO_BRANCH"
  cd ..
fi

cd phantomworld

if [ ! -f alpine/opt/cfx-server/FXServer ]; then
  echo "==> Downloading latest FXServer Linux artifact"
  mkdir -p /tmp/fxserver && cd /tmp/fxserver
  curl -sSL https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/ -o index.html
  BUILD=$(grep -oP 'href="\K[0-9]+-[a-f0-9]+' index.html | tail -1)
  curl -sSL "https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/${BUILD}/fx.tar.xz" -o fx.tar.xz
  tar -xf fx.tar.xz -C "$INSTALL_DIR/phantomworld"
  cd "$INSTALL_DIR/phantomworld"
fi

echo "==> FXServer binary present"
test -f alpine/opt/cfx-server/FXServer

cat <<EOF

Bootstrap complete.

Next steps:
1. Edit server.cfg MySQL connection if using local MariaDB
2. Import SQL: resources/npwd/import.sql, jobs_creator/basjobs.sql
3. Upload gitignored assets via SFTP: [vehicles], cars2, [clothing], [defaultmaps], [Graphics]
4. Start server:
   cd $INSTALL_DIR/phantomworld
   bash start.sh

txAdmin (if enabled): http://YOUR_VPS_IP:$TXADMIN_PORT
Game port: $GAME_PORT TCP/UDP

EOF
