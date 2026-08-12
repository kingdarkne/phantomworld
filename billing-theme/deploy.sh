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
upload "$ROOT/resources/views/store/order.blade.php" "/var/www/billing/resources/views/store/order.blade.php"
upload "$ROOT/resources/views/client/server/index.blade.php" "/var/www/billing/resources/views/client/server/index.blade.php"
upload "$ROOT/resources/views/client/server/show.blade.php" "/var/www/billing/resources/views/client/server/show.blade.php"
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
upload "$ROOT/app/Http/Controllers/Api/AuthController.php" "/var/www/billing/app/Http/Controllers/Api/AuthController.php"
upload "$ROOT/app/Models/Client.php" "/var/www/billing/app/Models/Client.php"
upload "$ROOT/app/Providers/AuthServiceProvider.php" "/var/www/billing/app/Providers/AuthServiceProvider.php"
upload "$ROOT/app/Providers/EventServiceProvider.php" "/var/www/billing/app/Providers/EventServiceProvider.php"
upload "$ROOT/routes/store.php" "/var/www/billing/routes/store.php"
upload "$ROOT/app/Support/CustomerName.php" "/var/www/billing/app/Support/CustomerName.php"
upload "$ROOT/app/Support/EmailGuide.php" "/var/www/billing/app/Support/EmailGuide.php"
upload "$ROOT/app/Jobs/CreatePanelUser.php" "/var/www/billing/app/Jobs/CreatePanelUser.php"
upload "$ROOT/app/Jobs/CreateServer.php" "/var/www/billing/app/Jobs/CreateServer.php"
upload "$ROOT/app/Notifications/AccountWelcomeNotif.php" "/var/www/billing/app/Notifications/AccountWelcomeNotif.php"
upload "$ROOT/app/Notifications/ServerReadyNotif.php" "/var/www/billing/app/Notifications/ServerReadyNotif.php"
upload "$ROOT/app/Notifications/PayInvoiceNotif.php" "/var/www/billing/app/Notifications/PayInvoiceNotif.php"
upload "$ROOT/app/Notifications/InvoicePaidNotif.php" "/var/www/billing/app/Notifications/InvoicePaidNotif.php"
upload "$ROOT/app/Notifications/RenewServerNotif.php" "/var/www/billing/app/Notifications/RenewServerNotif.php"
upload "$ROOT/app/Notifications/InvoiceDueNotif.php" "/var/www/billing/app/Notifications/InvoiceDueNotif.php"
upload "$ROOT/app/Notifications/ResetPasswordNotification.php" "/var/www/billing/app/Notifications/ResetPasswordNotification.php"
upload "$ROOT/resources/views/emails/notif.blade.php" "/var/www/billing/resources/views/emails/notif.blade.php"
upload "$ROOT/resources/views/layouts/store/modals.blade.php" "/var/www/billing/resources/views/layouts/store/modals.blade.php"
upload "$ROOT/scripts/brand-emails.sh" "/tmp/brand-billing-emails.sh"
sshpass -e ssh "${SSH_BASE[@]}" -p "$PORT" "${USER}@${HOST}" "mkdir -p /tmp/panel-email-overrides"
upload "$ROOT/panel-overrides/AccountCreated.php" "/tmp/panel-email-overrides/AccountCreated.php"
upload "$ROOT/panel-overrides/email.blade.php" "/tmp/panel-email-overrides/email.blade.php"
upload "$ROOT/panel-overrides/UserCreationService.php" "/tmp/panel-email-overrides/UserCreationService.php"
upload "$ROOT/panel-overrides/phantom-notif.blade.php" "/tmp/panel-email-overrides/phantom-notif.blade.php"
upload "$ROOT/panel-overrides/SendPasswordReset.php" "/tmp/panel-email-overrides/SendPasswordReset.php"
upload "$ROOT/panel-overrides/ServerInstalled.php" "/tmp/panel-email-overrides/ServerInstalled.php"
upload "$ROOT/panel-overrides/wrapper.blade.php" "/tmp/panel-email-overrides/wrapper.blade.php"
upload "$ROOT/panel-overrides/admin.blade.php" "/tmp/panel-email-overrides/admin.blade.php"
sshpass -e ssh "${SSH_BASE[@]}" -p "$PORT" "${USER}@${HOST}" "mkdir -p /tmp/panel-theme"
upload "$ROOT/panel-theme/phantom-panel.css" "/tmp/panel-theme/phantom-panel.css"
upload "$ROOT/scripts/install-panel-theme.sh" "/tmp/install-panel-theme.sh"
upload "$ROOT/resources/views/layouts/client/nav.blade.php" "/var/www/billing/resources/views/layouts/client/nav.blade.php"
upload "$ROOT/nginx-billing.conf" "/tmp/nginx-billing.conf"
upload "$ROOT/scripts/fix-currency.sh" "/tmp/fix-billing-currency.sh"
upload "$ROOT/scripts/fix-free-limit.sh" "/tmp/fix-billing-free-limit.sh"
upload "$ROOT/scripts/fix-fivem-egg.sh" "/tmp/fix-billing-fivem-egg.sh"
upload "$ROOT/scripts/install-discord-bot-eggs.sh" "/tmp/install-discord-bot-eggs.sh"
upload "$ROOT/scripts/attach-all-eggs-to-plans.sh" "/tmp/attach-all-eggs-to-plans.sh"
upload "$ROOT/scripts/ensure-main-node-and-games.sh" "/tmp/ensure-main-node-and-games.sh"
upload "$ROOT/scripts/fix-admin-customer-link.sh" "/tmp/fix-admin-customer-link.sh"
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
  resources/views/store/order.blade.php \
  resources/views/client/server/index.blade.php \
  resources/views/client/server/show.blade.php \
  resources/views/layouts/store/header.blade.php \
  resources/views/layouts/store/footer.blade.php \
  resources/views/layouts/store/nav.blade.php \
  resources/views/layouts/store/scripts.blade.php \
  resources/views/layouts/store/modals.blade.php \
  resources/views/layouts/styles.blade.php \
  resources/views/layouts/store.blade.php \
  resources/views/layouts/preloader.blade.php \
  resources/views/layouts/client/nav.blade.php \
  resources/views/emails/notif.blade.php \
  app/Http/Middleware/Store/SetDefaultSession.php \
  app/Http/Middleware/Store/CheckPlanOrder.php \
  app/Http/Controllers/Api/StoreController.php \
  app/Http/Controllers/Api/AuthController.php \
  app/Models/Client.php \
  app/Providers/AuthServiceProvider.php \
  app/Providers/EventServiceProvider.php \
  routes/store.php \
  app/Support/CustomerName.php \
  app/Support/EmailGuide.php \
  app/Jobs/CreatePanelUser.php \
  app/Jobs/CreateServer.php \
  app/Notifications/AccountWelcomeNotif.php \
  app/Notifications/ServerReadyNotif.php \
  app/Notifications/PayInvoiceNotif.php \
  app/Notifications/InvoicePaidNotif.php \
  app/Notifications/RenewServerNotif.php \
  app/Notifications/InvoiceDueNotif.php \
  app/Notifications/ResetPasswordNotification.php
sudo -u www-data php -l bootstrap/helpers.php
[ -f public/galaxy_bg.webp ] && chown www-data:www-data public/galaxy_bg.webp
chmod +x /tmp/fix-billing-currency.sh /tmp/fix-billing-free-limit.sh /tmp/fix-billing-fivem-egg.sh /tmp/install-discord-bot-eggs.sh /tmp/attach-all-eggs-to-plans.sh /tmp/ensure-main-node-and-games.sh /tmp/brand-billing-emails.sh /tmp/fix-admin-customer-link.sh /tmp/install-panel-theme.sh
bash /tmp/fix-billing-currency.sh
bash /tmp/fix-billing-free-limit.sh
bash /tmp/fix-billing-fivem-egg.sh || true
bash /tmp/install-discord-bot-eggs.sh || true
bash /tmp/attach-all-eggs-to-plans.sh || true
bash /tmp/ensure-main-node-and-games.sh || true
bash /tmp/fix-admin-customer-link.sh || true
OVERRIDES=/tmp/panel-email-overrides bash /tmp/brand-billing-emails.sh || true
OVERRIDES=/tmp/panel-email-overrides THEME_SRC=/tmp/panel-theme bash /tmp/install-panel-theme.sh || true
# Ensure owner gets purchase alerts
if ! grep -q '^OWNER_EMAIL=' /var/www/billing/.env; then
  echo 'OWNER_EMAIL=ericaxavier897@gmail.com' >> /var/www/billing/.env
else
  sed -i 's/^OWNER_EMAIL=.*/OWNER_EMAIL=ericaxavier897@gmail.com/' /var/www/billing/.env
fi
sudo -u www-data php artisan view:clear
sudo -u www-data php artisan cache:clear
sudo -u www-data php artisan config:clear || true
sudo -u www-data php artisan route:clear || true
# Panel cache so egg entry change is visible
if [ -d /var/www/pterodactyl ]; then
  sudo -u www-data php /var/www/pterodactyl/artisan cache:clear || true
  sudo -u www-data php -l /var/www/pterodactyl/app/Services/Users/UserCreationService.php
  systemctl restart pteroq || true
  supervisorctl restart pterodactyl-worker:* || true
fi
sudo -u www-data php -l app/Http/Controllers/Api/StoreController.php
sudo -u www-data php -l app/Http/Controllers/Api/AuthController.php
sudo -u www-data php -l app/Jobs/CreatePanelUser.php
sudo -u www-data php -l app/Jobs/CreateServer.php
sudo -u www-data php -l app/Support/CustomerName.php
sudo -u www-data php -l app/Support/EmailGuide.php
sudo -u www-data php -l app/Notifications/AccountWelcomeNotif.php
sudo -u www-data php -l /var/www/pterodactyl/app/Notifications/AccountCreated.php
sudo -u www-data php -l /var/www/pterodactyl/app/Notifications/SendPasswordReset.php
sudo -u www-data php -l /var/www/pterodactyl/app/Notifications/ServerInstalled.php
sudo -u www-data php -l app/Notifications/ServerReadyNotif.php
sudo -u www-data php -l app/Http/Middleware/Store/CheckPlanOrder.php
sudo -u www-data php -l app/Providers/EventServiceProvider.php
sudo -u www-data php -l routes/store.php
test -f /var/www/pterodactyl/resources/views/emails/phantom.blade.php && echo phantom_template_ok
systemctl is-active php8.3-fpm billing-worker nginx
echo "Billing theme deployed."
REMOTE

echo "Done. Check https://billing.phantom-chicken.com/"
