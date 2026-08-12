#!/usr/bin/env bash
# Brand panel + billing mail as Phantom Hosting and fix placeholder customer names.
set -euo pipefail

PANEL_ROOT="${PANEL_ROOT:-/var/www/pterodactyl}"
BILLING_ROOT="${BILLING_ROOT:-/var/www/billing}"
OVERRIDES="${OVERRIDES:-/tmp/panel-email-overrides}"

# --- Panel app name / from name ---
if [[ -f "$PANEL_ROOT/.env" ]]; then
  if grep -q '^APP_NAME=' "$PANEL_ROOT/.env"; then
    sed -i 's/^APP_NAME=.*/APP_NAME="Phantom Hosting"/' "$PANEL_ROOT/.env"
  else
    echo 'APP_NAME="Phantom Hosting"' >> "$PANEL_ROOT/.env"
  fi
  sed -i 's/^MAIL_FROM_NAME=.*/MAIL_FROM_NAME="Phantom Hosting"/' "$PANEL_ROOT/.env" || true
fi

if [[ -f "$BILLING_ROOT/.env" ]]; then
  if grep -q '^APP_NAME=' "$BILLING_ROOT/.env"; then
    sed -i 's/^APP_NAME=.*/APP_NAME="Phantom Hosting"/' "$BILLING_ROOT/.env"
  else
    echo 'APP_NAME="Phantom Hosting"' >> "$BILLING_ROOT/.env"
  fi
  # company already Phantom Hosting in config; keep MAIL_FROM_NAME
  sed -i 's/^MAIL_FROM_NAME=.*/MAIL_FROM_NAME="Phantom Hosting"/' "$BILLING_ROOT/.env" || true
fi

# Billing config/app.php hardcodes HedystiaBilling — force brand name
if [[ -f "$BILLING_ROOT/config/app.php" ]]; then
  sed -i "s/'name' => 'HedystiaBilling'/'name' => env('APP_NAME', 'Phantom Hosting')/" "$BILLING_ROOT/config/app.php"
  sed -i "s/'name' => \"HedystiaBilling\"/'name' => env('APP_NAME', 'Phantom Hosting')/" "$BILLING_ROOT/config/app.php"
  echo "billing_config_name_patched"
fi

# --- Billing clients name columns ---
cd "$BILLING_ROOT"
php -r "
require 'vendor/autoload.php';
\$app = require_once 'bootstrap/app.php';
\$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
\$cols = collect(DB::select('SHOW COLUMNS FROM clients'))->pluck('Field');
if (!\$cols->contains('first_name')) {
    DB::statement('ALTER TABLE clients ADD COLUMN first_name VARCHAR(100) NULL AFTER email');
    echo \"added clients.first_name\\n\";
}
if (!\$cols->contains('last_name')) {
    DB::statement('ALTER TABLE clients ADD COLUMN last_name VARCHAR(100) NULL AFTER first_name');
    echo \"added clients.last_name\\n\";
}
"

# --- Panel notification overrides ---
if [[ -d "$OVERRIDES" ]]; then
  install -o www-data -g www-data -m 644 "$OVERRIDES/AccountCreated.php" "$PANEL_ROOT/app/Notifications/AccountCreated.php"
  mkdir -p "$PANEL_ROOT/resources/views/vendor/notifications"
  mkdir -p "$PANEL_ROOT/resources/views/emails"
  install -o www-data -g www-data -m 644 "$OVERRIDES/email.blade.php" "$PANEL_ROOT/resources/views/vendor/notifications/email.blade.php"
  if [[ -f "$OVERRIDES/phantom-notif.blade.php" ]]; then
    install -o www-data -g www-data -m 644 "$OVERRIDES/phantom-notif.blade.php" "$PANEL_ROOT/resources/views/emails/phantom.blade.php"
    echo "panel_phantom_email_template_installed"
  fi
  if [[ -f "$OVERRIDES/SendPasswordReset.php" ]]; then
    install -o www-data -g www-data -m 644 "$OVERRIDES/SendPasswordReset.php" "$PANEL_ROOT/app/Notifications/SendPasswordReset.php"
  fi
  if [[ -f "$OVERRIDES/ServerInstalled.php" ]]; then
    install -o www-data -g www-data -m 644 "$OVERRIDES/ServerInstalled.php" "$PANEL_ROOT/app/Notifications/ServerInstalled.php"
  fi
  if [[ -f "$OVERRIDES/UserCreationService.php" ]]; then
    install -o www-data -g www-data -m 644 "$OVERRIDES/UserCreationService.php" "$PANEL_ROOT/app/Services/Users/UserCreationService.php"
    echo "panel_user_creation_service_installed"
  fi
  echo "panel_email_overrides_installed"
fi

# Soft-fix panel users still named First/Last
cd "$PANEL_ROOT"
php -r "
require 'vendor/autoload.php';
\$app = require_once 'bootstrap/app.php';
\$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
\$fixed = 0;
foreach (DB::table('users')->where(function (\$q) {
    \$q->where('name_first', 'First')->orWhere('name_last', 'Last');
})->get() as \$u) {
    \$local = strstr(\$u->email, '@', true) ?: \$u->username;
    \$local = preg_replace('/^guest[_-]*/i', '', \$local);
    \$local = str_replace(['.', '_', '-', '+'], ' ', \$local);
    \$local = preg_replace('/\d+/', ' ', \$local);
    \$parts = array_values(array_filter(preg_split('/\s+/', trim(\$local)) ?: []));
    \$first = \$parts ? ucwords(strtolower(\$parts[0])) : 'Customer';
    \$last = isset(\$parts[1]) ? ucwords(strtolower(\$parts[1])) : 'Account';
    DB::table('users')->where('id', \$u->id)->update([
        'name_first' => \$first,
        'name_last' => \$last,
        'updated_at' => now(),
    ]);
    \$fixed++;
    echo \"fixed_user id={\$u->id} -> \$first \$last\\n\";
}
echo \"panel_names_fixed=\$fixed\\n\";
"

cd "$PANEL_ROOT"
sudo -u www-data php artisan config:clear || true
sudo -u www-data php artisan view:clear || true
sudo -u www-data php artisan cache:clear || true

cd "$BILLING_ROOT"
sudo -u www-data php artisan config:clear || true
sudo -u www-data php artisan view:clear || true
sudo -u www-data php artisan cache:clear || true

echo "Email branding patch complete."
