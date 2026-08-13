#!/usr/bin/env bash
# Apply FiveM console quieting fixes on the game host volume.
# Requires: SSHPASS/VPS_PASSWORD, sshpass, root@ game host.
set -euo pipefail
HOST="${FIVEM_HOST:-172.245.71.46}"
VOL="${FIVEM_VOLUME:-/var/lib/pterodactyl/volumes/5e6a18d6-d453-4130-b80c-f5f1d7dc82ef}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
export SSHPASS="${SSHPASS:-${VPS_PASSWORD:?set VPS_PASSWORD}}"
sshpass -e scp -o StrictHostKeyChecking=no \
  "$ROOT/resources/norse_awsome_admins/config/config.lua" \
  "$ROOT/resources/norse_awsome_admins/sql/players_jail_columns.sql" \
  "root@${HOST}:/tmp/"
sshpass -e scp -o StrictHostKeyChecking=no -r \
  "$ROOT/resources/[standalone]/phantom_dashboard/locales" \
  "root@${HOST}:/tmp/phantom_dashboard_locales"
sshpass -e ssh -o StrictHostKeyChecking=no "root@${HOST}" bash -s <<EOF
set -e
VOL="$VOL"
cp /tmp/config.lua "\$VOL/resources/norse_awsome_admins/config/config.lua"
cp /tmp/players_jail_columns.sql "\$VOL/resources/norse_awsome_admins/sql/"
mkdir -p "\$VOL/resources/[standalone]/phantom_dashboard/locales"
cp /tmp/phantom_dashboard_locales/* "\$VOL/resources/[standalone]/phantom_dashboard/locales/"
PASS=\$(grep -oP 'password=\K[^;]+' "\$VOL/server.cfg" | head -1)
mysql -h172.18.0.1 -ufivem -p"\$PASS" fivem < "\$VOL/resources/norse_awsome_admins/sql/players_jail_columns.sql" || true
echo "Applied norse/dashboard patches. Restart FiveM from the panel to reload server.cfg."
EOF
