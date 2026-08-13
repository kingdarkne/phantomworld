#!/usr/bin/env bash
# Put Wings behind nginx :443 so the panel websocket works for all clients.
set -euo pipefail

PANEL_ROOT="${PANEL_ROOT:-/var/www/pterodactyl}"
WINGS_CONF="${WINGS_CONF:-/etc/pterodactyl/config.yml}"
NGINX_SRC="${NGINX_SRC:-/tmp/nginx-wings.conf}"

if [[ -f "$NGINX_SRC" ]]; then
  install -o root -g root -m 644 "$NGINX_SRC" /etc/nginx/sites-available/wings
  ln -sfn /etc/nginx/sites-available/wings /etc/nginx/sites-enabled/wings
  nginx -t
  systemctl reload nginx
  echo "nginx_wings_proxy_installed"
fi

# Wings: local HTTP only (nginx terminates TLS)
python3 - <<'PY'
from pathlib import Path
import re
p = Path("/etc/pterodactyl/config.yml")
text = p.read_text()
lines = text.splitlines(True)
out = []
in_api = False
in_ssl = False
i = 0
while i < len(lines):
    line = lines[i]
    if re.match(r'^api:\s*$', line):
        in_api = True
        out.append(line)
        i += 1
        continue
    if in_api and re.match(r'^[a-z]', line):
        in_api = False
        in_ssl = False
    if in_api and re.match(r'^\s+host:\s*', line):
        out.append("  host: 127.0.0.1\n")
        i += 1
        continue
    if in_api and re.match(r'^\s+ssl:\s*$', line):
        in_ssl = True
        out.append(line)
        i += 1
        continue
    if in_ssl and re.match(r'^\s+enabled:\s*', line):
        out.append("    enabled: false\n")
        i += 1
        continue
    if in_api and re.match(r'^\s+trusted_proxies:\s*', line):
        out.append("  trusted_proxies:\n")
        out.append("  - 127.0.0.1\n")
        out.append("  - ::1\n")
        i += 1
        while i < len(lines) and re.match(r'^\s+-\s+', lines[i]):
            i += 1
        continue
    out.append(line)
    i += 1
p.write_text("".join(out))
print("wings_config_patched")
PY

systemctl restart wings
sleep 1
systemctl is-active wings

cd "$PANEL_ROOT"
sudo -u www-data php -r '
require "vendor/autoload.php";
$app = require "bootstrap/app.php";
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
$n = Pterodactyl\Models\Node::find(1);
if (!$n) { fwrite(STDERR, "node_missing\n"); exit(1); }
$n->scheme = "https";
$n->fqdn = "wings.phantom-chicken.com";
$n->daemonListen = 443;
$n->behind_proxy = true;
$n->save();
echo "node_port={$n->daemonListen} behind=1\n";
'
sudo -u www-data php artisan cache:clear || true
echo "wings proxy fix complete."
