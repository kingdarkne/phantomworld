#!/usr/bin/env bash
# Ensure every billing plan targets Main Node (1:1) and lists all unique game/software eggs.
set -euo pipefail

PANEL_ROOT="${PANEL_ROOT:-/var/www/pterodactyl}"
BILLING_ROOT="${BILLING_ROOT:-/var/www/billing}"

cd "$PANEL_ROOT"
php -r "
require 'vendor/autoload.php';
\$app = require_once 'bootstrap/app.php';
\$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

\$node = DB::table('nodes')->where('id', 1)->first();
if (!\$node) { fwrite(STDERR, \"Main Node id=1 missing\\n\"); exit(1); }
echo \"main_node id={\$node->id} name={\$node->name} fqdn={\$node->fqdn} location={\$node->location_id}\\n\";

// Expand free allocations for common game ports if running low
\$free = DB::table('allocations')->where('node_id', 1)->whereNull('server_id')->count();
echo \"allocations_free=\$free\\n\";
\$ip = DB::table('allocations')->where('node_id', 1)->value('ip') ?: '172.245.71.46';
\$existing = DB::table('allocations')->where('node_id', 1)->pluck('port')->all();
\$want = [];
for (\$p = 25565; \$p <= 25580; \$p++) \$want[] = \$p;
for (\$p = 27015; \$p <= 27030; \$p++) \$want[] = \$p;
for (\$p = 30120; \$p <= 30130; \$p++) \$want[] = \$p;
foreach ([7777,7778,2456,2457,28015,19132,19133] as \$p) \$want[] = \$p;
\$added = 0;
foreach (array_unique(\$want) as \$port) {
    if (in_array(\$port, \$existing, true)) continue;
    DB::table('allocations')->insert([
        'node_id' => 1,
        'ip' => \$ip,
        'ip_alias' => null,
        'port' => \$port,
        'server_id' => null,
        'notes' => null,
        'created_at' => now(),
        'updated_at' => now(),
    ]);
    \$added++;
}
echo \"allocations_added=\$added\\n\";

// Unique eggs: skip empty nests + duplicate generics
\$skip = [15, 17, 18]; // old Node.js Generic x2 + duplicate FiveM
\$eggs = [];
foreach (DB::table('eggs')->orderBy('nest_id')->orderBy('id')->get(['id','nest_id','name']) as \$e) {
    if (in_array((int)\$e->id, \$skip, true)) continue;
    \$eggs[] = \$e->nest_id . ':' . \$e->id;
    echo \"egg {\$e->nest_id}:{\$e->id} {\$e->name}\\n\";
}
file_put_contents('/tmp/unique-eggs.json', json_encode(array_values(array_unique(\$eggs))));
file_put_contents('/tmp/main-node.json', json_encode(['1:1']));
"

cd "$BILLING_ROOT"
php -r "
require 'vendor/autoload.php';
\$app = require_once 'bootstrap/app.php';
\$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

\$eggsJson = file_get_contents('/tmp/unique-eggs.json');
\$nodesJson = file_get_contents('/tmp/main-node.json');
\$n = DB::table('plans')->update([
    'nests_eggs_id' => \$eggsJson,
    'locations_nodes_id' => \$nodesJson,
    'updated_at' => now(),
]);
echo \"plans_synced=\$n eggs=\" . count(json_decode(\$eggsJson, true)) . \" nodes=\$nodesJson\\n\";
"

sudo -u www-data php artisan cache:clear || true
if [[ -d /var/www/pterodactyl ]]; then
  sudo -u www-data php /var/www/pterodactyl/artisan cache:clear || true
fi
echo \"Main node + games sync complete.\"
