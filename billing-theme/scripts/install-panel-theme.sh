#!/usr/bin/env bash
# Install Phantom Hosting premium theme on the game panel (client + admin).
set -euo pipefail

PANEL_ROOT="${PANEL_ROOT:-/var/www/pterodactyl}"
BILLING_ROOT="${BILLING_ROOT:-/var/www/billing}"
OVERRIDES="${OVERRIDES:-/tmp/panel-email-overrides}"
THEME_SRC="${THEME_SRC:-/tmp/panel-theme}"

mkdir -p "$PANEL_ROOT/public/themes/phantom"
mkdir -p "$PANEL_ROOT/public/img"

if [[ -f "$THEME_SRC/phantom-panel.css" ]]; then
  install -o www-data -g www-data -m 644 "$THEME_SRC/phantom-panel.css" \
    "$PANEL_ROOT/public/themes/phantom/phantom-panel.css"
  echo "panel_theme_css_installed"
fi

# Prefer billing webp background; fall back to existing jpg
if [[ -f "$BILLING_ROOT/public/galaxy_bg.webp" ]]; then
  install -o www-data -g www-data -m 644 "$BILLING_ROOT/public/galaxy_bg.webp" \
    "$PANEL_ROOT/public/galaxy_bg.webp"
elif [[ -f "$THEME_SRC/galaxy_bg.webp" ]]; then
  install -o www-data -g www-data -m 644 "$THEME_SRC/galaxy_bg.webp" \
    "$PANEL_ROOT/public/galaxy_bg.webp"
fi

if [[ -f "$BILLING_ROOT/public/img/icon.webp" ]]; then
  install -o www-data -g www-data -m 644 "$BILLING_ROOT/public/img/icon.webp" \
    "$PANEL_ROOT/public/img/icon.webp"
fi

if [[ -f "$BILLING_ROOT/public/img/phantom_logo.png" ]]; then
  install -o www-data -g www-data -m 644 "$BILLING_ROOT/public/img/phantom_logo.png" \
    "$PANEL_ROOT/public/phantom_logo.png"
elif [[ -f "$BILLING_ROOT/public/img/icon.webp" ]] && [[ ! -f "$PANEL_ROOT/public/phantom_logo.png" ]]; then
  # keep existing logo if present
  true
fi

if [[ -d "$OVERRIDES" ]]; then
  if [[ -f "$OVERRIDES/wrapper.blade.php" ]]; then
    install -o www-data -g www-data -m 644 "$OVERRIDES/wrapper.blade.php" \
      "$PANEL_ROOT/resources/views/templates/wrapper.blade.php"
    echo "panel_wrapper_installed"
  fi
  if [[ -f "$OVERRIDES/admin.blade.php" ]]; then
    install -o www-data -g www-data -m 644 "$OVERRIDES/admin.blade.php" \
      "$PANEL_ROOT/resources/views/layouts/admin.blade.php"
    echo "panel_admin_layout_installed"
  fi
fi

cd "$PANEL_ROOT"
sudo -u www-data php artisan view:clear || true
sudo -u www-data php artisan cache:clear || true
sudo -u www-data php artisan config:clear || true

echo "Phantom panel theme install complete."
