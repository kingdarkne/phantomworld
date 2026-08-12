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
upload "$ROOT/bootstrap/helpers.php" "/var/www/billing/bootstrap/helpers.php"
upload "$ROOT/resources/views/store/pages.blade.php" "/var/www/billing/resources/views/store/pages.blade.php"
upload "$ROOT/resources/views/store/checkout.blade.php" "/var/www/billing/resources/views/store/checkout.blade.php"
upload "$ROOT/resources/views/layouts/store/header.blade.php" "/var/www/billing/resources/views/layouts/store/header.blade.php"
upload "$ROOT/resources/views/layouts/store/footer.blade.php" "/var/www/billing/resources/views/layouts/store/footer.blade.php"
upload "$ROOT/resources/views/layouts/store/nav.blade.php" "/var/www/billing/resources/views/layouts/store/nav.blade.php"
upload "$ROOT/resources/views/layouts/store/scripts.blade.php" "/var/www/billing/resources/views/layouts/store/scripts.blade.php"
upload "$ROOT/resources/views/layouts/styles.blade.php" "/var/www/billing/resources/views/layouts/styles.blade.php"
upload "$ROOT/resources/views/layouts/store.blade.php" "/var/www/billing/resources/views/layouts/store.blade.php"
upload "$ROOT/resources/views/layouts/preloader.blade.php" "/var/www/billing/resources/views/layouts/preloader.blade.php"
upload "$ROOT/app/Http/Middleware/Store/SetDefaultSession.php" "/var/www/billing/app/Http/Middleware/Store/SetDefaultSession.php"
upload "$ROOT/app/Http/Middleware/Store/CheckPlanOrder.php" "/var/www/billing/app/Http/Middleware/Store/CheckPlanOrder.php"
upload "$ROOT/app/Http/Controllers/Api/StoreController.php" "/var/www/billing/app/Http/Controllers/Api/StoreController.php"
upload "$ROOT/app/Jobs/CreatePanelUser.php" "/var/www/billing/app/Jobs/CreatePanelUser.php"
upload "$ROOT/app/Jobs/CreateServer.php" "/var/www/billing/app/Jobs/CreateServer.php"
upload "$ROOT/app/Notifications/AccountWelcomeNotif.php" "/var/www/billing/app/Notifications/AccountWelcomeNotif.php"
upload "$ROOT/app/Notifications/ServerReadyNotif.php" "/var/www/billing/app/Notifications/ServerReadyNotif.php"
upload "$ROOT/app/Notifications/PayInvoiceNotif.php" "/var/www/billing/app/Notifications/PayInvoiceNotif.php"
upload "$ROOT/app/Notifications/InvoicePaidNotif.php" "/var/www/billing/app/Notifications/InvoicePaidNotif.php"
upload "$ROOT/app/Notifications/RenewServerNotif.php" "/var/www/billing/app/Notifications/RenewServerNotif.php"
upload "$ROOT/app/Notifications/InvoiceDueNotif.php" "/var/www/billing/app/Notifications/InvoiceDueNotif.php"
upload "$ROOT/resources/views/emails/notif.blade.php" "/var/www/billing/resources/views/emails/notif.blade.php"
upload "$ROOT/resources/views/layouts/client/nav.blade.php" "/var/www/billing/resources/views/layouts/client/nav.blade.php"
upload "$ROOT/nginx-billing.conf" "/tmp/nginx-billing.conf"
upload "$ROOT/scripts/fix-currency.sh" "/tmp/fix-billing-currency.sh"
upload "$ROOT/scripts/fix-free-limit.sh" "/tmp/fix-billing-free-limit.sh"
upload "$ROOT/scripts/fix-fivem-egg.sh" "/tmp/fix-billing-fivem-egg.sh"
upload "$ROOT/scripts/install-discord-bot-eggs.sh" "/tmp/install-discord-bot-eggs.sh"
upload "$ROOT/scripts/attach-all-eggs-to-plans.sh" "/tmp/attach-all-eggs-to-plans.sh"
sshpass -e ssh "${SSH_BASE[@]}" -p "$PORT" "${USER}@${HOST}" "mkdir -p /tmp/billing-eggs"
upload "$ROOT/eggs/egg-discord-js.json" "/tmp/billing-eggs/egg-discord-js.json"
upload "$ROOT/eggs/egg-discord-py.json" "/tmp/billing-eggs/egg-discord-py.json"
upload "$ROOT/eggs/egg-nodejs.json" "/tmp/billing-eggs/egg-nodejs.json"
upload "$ROOT/eggs/egg-python.json" "/tmp/billing-eggs/egg-python.json"

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
  bootstrap/helpers.php \
  resources/views/store/pages.blade.php \
  resources/views/store/checkout.blade.php \
  resources/views/layouts/store/header.blade.php \
  resources/views/layouts/store/footer.blade.php \
  resources/views/layouts/store/nav.blade.php \
  resources/views/layouts/store/scripts.blade.php \
  resources/views/layouts/styles.blade.php \
  resources/views/layouts/store.blade.php \
  resources/views/layouts/preloader.blade.php \
  resources/views/layouts/client/nav.blade.php \
  app/Http/Middleware/Store/SetDefaultSession.php \
  app/Http/Middleware/Store/CheckPlanOrder.php \
  app/Http/Controllers/Api/StoreController.php \
  app/Jobs/CreatePanelUser.php \
  app/Jobs/CreateServer.php \
  app/Notifications/AccountWelcomeNotif.php \
  app/Notifications/ServerReadyNotif.php \
  app/Notifications/PayInvoiceNotif.php \
  app/Notifications/InvoicePaidNotif.php \
  app/Notifications/RenewServerNotif.php \
  app/Notifications/InvoiceDueNotif.php \
  resources/views/emails/notif.blade.php
sudo -u www-data php -l bootstrap/helpers.php
[ -f public/galaxy_bg.webp ] && chown www-data:www-data public/galaxy_bg.webp
chmod +x /tmp/fix-billing-currency.sh /tmp/fix-billing-free-limit.sh /tmp/fix-billing-fivem-egg.sh /tmp/install-discord-bot-eggs.sh /tmp/attach-all-eggs-to-plans.sh
bash /tmp/fix-billing-currency.sh
bash /tmp/fix-billing-free-limit.sh
bash /tmp/fix-billing-fivem-egg.sh || true
bash /tmp/install-discord-bot-eggs.sh || true
bash /tmp/attach-all-eggs-to-plans.sh || true
# Ensure owner gets purchase alerts
if ! grep -q '^OWNER_EMAIL=' /var/www/billing/.env; then
  echo 'OWNER_EMAIL=ericaxavier897@gmail.com' >> /var/www/billing/.env
else
  sed -i 's/^OWNER_EMAIL=.*/OWNER_EMAIL=ericaxavier897@gmail.com/' /var/www/billing/.env
fi
sudo -u www-data php artisan view:clear
sudo -u www-data php artisan cache:clear
sudo -u www-data php artisan config:clear || true
# Panel cache so egg entry change is visible
if [ -d /var/www/pterodactyl ]; then
  sudo -u www-data php /var/www/pterodactyl/artisan cache:clear || true
fi
sudo -u www-data php -l app/Http/Controllers/Api/StoreController.php
sudo -u www-data php -l app/Jobs/CreatePanelUser.php
sudo -u www-data php -l app/Jobs/CreateServer.php
sudo -u www-data php -l app/Notifications/AccountWelcomeNotif.php
sudo -u www-data php -l app/Notifications/ServerReadyNotif.php
sudo -u www-data php -l app/Http/Middleware/Store/CheckPlanOrder.php
systemctl is-active php8.3-fpm billing-worker nginx
echo "Billing theme deployed."
REMOTE

echo "Done. Check https://billing.phantom-chicken.com/"
