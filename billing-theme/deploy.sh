#!/usr/bin/env bash
# Deploy billing theme files to the VPS.
# Usage: VPS_PASSWORD='...' ./billing-theme/deploy.sh
set -euo pipefail

HOST="${VPS_HOST:-172.245.71.46}"
USER="${VPS_USER:-root}"
PORT="${VPS_PORT:-22}"
ROOT="$(cd "$(dirname "$0")" && pwd)"

: "${VPS_PASSWORD:?Set VPS_PASSWORD}"
command -v sshpass >/dev/null || { echo "Install sshpass first"; exit 1; }

export SSHPASS="$VPS_PASSWORD"
SSH_BASE=(-o StrictHostKeyChecking=no)

echo "Uploading theme files to ${USER}@${HOST}…"

upload() {
  local src="$1" dest="$2"
  sshpass -e scp "${SSH_BASE[@]}" -P "$PORT" "$src" "${USER}@${HOST}:${dest}"
}

upload "$ROOT/public/dist/css/phantom-theme.css" "/var/www/billing/public/dist/css/phantom-theme.css"
upload "$ROOT/resources/views/store/pages.blade.php" "/var/www/billing/resources/views/store/pages.blade.php"
upload "$ROOT/resources/views/store/checkout.blade.php" "/var/www/billing/resources/views/store/checkout.blade.php"
upload "$ROOT/resources/views/layouts/store/header.blade.php" "/var/www/billing/resources/views/layouts/store/header.blade.php"
upload "$ROOT/resources/views/layouts/store/footer.blade.php" "/var/www/billing/resources/views/layouts/store/footer.blade.php"
upload "$ROOT/resources/views/layouts/store/nav.blade.php" "/var/www/billing/resources/views/layouts/store/nav.blade.php"
upload "$ROOT/resources/views/layouts/styles.blade.php" "/var/www/billing/resources/views/layouts/styles.blade.php"
upload "$ROOT/resources/views/layouts/store.blade.php" "/var/www/billing/resources/views/layouts/store.blade.php"
upload "$ROOT/resources/views/layouts/preloader.blade.php" "/var/www/billing/resources/views/layouts/preloader.blade.php"
upload "$ROOT/app/Http/Middleware/Store/SetDefaultSession.php" "/var/www/billing/app/Http/Middleware/Store/SetDefaultSession.php"
upload "$ROOT/nginx-billing.conf" "/tmp/nginx-billing.conf"
upload "$ROOT/scripts/fix-currency.sh" "/tmp/fix-billing-currency.sh"

if [ -f "$ROOT/public/galaxy_bg.webp" ]; then
  upload "$ROOT/public/galaxy_bg.webp" "/var/www/billing/public/galaxy_bg.webp"
fi

sshpass -e ssh "${SSH_BASE[@]}" -p "$PORT" "${USER}@${HOST}" bash -s <<'REMOTE'
set -euo pipefail
install -o root -g root -m 644 /tmp/nginx-billing.conf /etc/nginx/sites-enabled/billing
nginx -t
systemctl reload nginx
systemctl restart php8.3-fpm billing-worker
cd /var/www/billing
chown www-data:www-data \
  public/dist/css/phantom-theme.css \
  resources/views/store/pages.blade.php \
  resources/views/store/checkout.blade.php \
  resources/views/layouts/store/header.blade.php \
  resources/views/layouts/store/footer.blade.php \
  resources/views/layouts/store/nav.blade.php \
  resources/views/layouts/styles.blade.php \
  resources/views/layouts/store.blade.php \
  resources/views/layouts/preloader.blade.php \
  app/Http/Middleware/Store/SetDefaultSession.php
[ -f public/galaxy_bg.webp ] && chown www-data:www-data public/galaxy_bg.webp
chmod +x /tmp/fix-billing-currency.sh
bash /tmp/fix-billing-currency.sh
sudo -u www-data php artisan view:clear
sudo -u www-data php artisan cache:clear
systemctl is-active php8.3-fpm billing-worker nginx
echo "Billing theme deployed."
REMOTE

echo "Done. Check https://billing.phantom-chicken.com/"
