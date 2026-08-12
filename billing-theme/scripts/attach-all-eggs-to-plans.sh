#!/usr/bin/env bash
# Attach every panel egg to every billing plan (order page egg dropdown).
set -euo pipefail

BILLING_ROOT="${BILLING_ROOT:-/var/www/billing}"
PANEL_ROOT="${PANEL_ROOT:-/var/www/pterodactyl}"

if [[ ! -d "$BILLING_ROOT" || ! -d "$PANEL_ROOT" ]]; then
  echo "billing/panel missing — skip"
  exit 0
fi

php -r "
require '$PANEL_ROOT/vendor/autoload.php';
\$panel = require '$PANEL_ROOT/bootstrap/app.php';
\$panel->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

\$eggs = [];
foreach (DB::table('eggs')->orderBy('nest_id')->orderBy('id')->get(['id','nest_id','name']) as \$e) {
    // Prefer newer Discord/Node/Python eggs; still include everything
    \$eggs[] = \$e->nest_id . ':' . \$e->id;
    echo \"egg {\$e->nest_id}:{\$e->id} {\$e->name}\\n\";
}
\$eggsJson = json_encode(array_values(array_unique(\$eggs)));
file_put_contents('/tmp/all-eggs.json', \$eggsJson);
echo \"all_eggs=\$eggsJson\\n\";
"

cd "$BILLING_ROOT"
php -r "
require 'vendor/autoload.php';
\$app = require_once 'bootstrap/app.php';
\$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

\$eggsJson = file_get_contents('/tmp/all-eggs.json');
\$updated = DB::table('plans')->update([
    'nests_eggs_id' => \$eggsJson,
    'updated_at' => now(),
]);
echo \"plans_updated=\$updated\\n\";
foreach (DB::table('plans')->orderBy('id')->get(['id','name','nests_eggs_id']) as \$p) {
    \$count = count(json_decode(\$p->nests_eggs_id, true) ?: []);
    echo \"plan id=\$p->id name=\$p->name eggs=\$count\\n\";
}
"

sudo -u www-data php artisan cache:clear || true
echo "All eggs attached to all plans."
