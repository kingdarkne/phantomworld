#!/usr/bin/env bash
# Import Discord.js + Discord.py eggs into Pterodactyl and wire billing bot plans.
# Usage: run on VPS with egg JSON paths available (deploy.sh uploads them to /tmp).
set -euo pipefail

PANEL_ROOT="${PANEL_ROOT:-/var/www/pterodactyl}"
BILLING_ROOT="${BILLING_ROOT:-/var/www/billing}"
EGG_DIR="${EGG_DIR:-/tmp/billing-eggs}"
NEST_NAME="Discord Bots"

if [[ ! -d "$PANEL_ROOT" ]]; then
  echo "Panel not found at $PANEL_ROOT — skip"
  exit 0
fi

cd "$PANEL_ROOT"

EGG_DIR="$EGG_DIR" NEST_NAME="$NEST_NAME" php -r "
require 'vendor/autoload.php';
\$app = require_once 'bootstrap/app.php';
\$kernel = \$app->make(Illuminate\Contracts\Console\Kernel::class);
\$kernel->bootstrap();

use Illuminate\Http\UploadedFile;
use Pterodactyl\Models\Egg;
use Pterodactyl\Models\EggVariable;
use Pterodactyl\Models\Nest;
use Pterodactyl\Services\Eggs\Sharing\EggImporterService;
use Pterodactyl\Services\Eggs\EggParserService;
use Illuminate\Support\Facades\DB;
use Ramsey\Uuid\Uuid;

\$eggDir = getenv('EGG_DIR') ?: '/tmp/billing-eggs';
\$nestName = getenv('NEST_NAME') ?: 'Discord Bots';

\$nest = Nest::query()->where('name', \$nestName)->first();
if (!\$nest) {
    \$nest = new Nest();
    \$nest->forceFill([
        'uuid' => Uuid::uuid4()->toString(),
        'author' => 'support@phantom-chicken.com',
        'name' => \$nestName,
        'description' => 'Discord bot runtimes: Discord.js (Node) and Discord.py (Python) with selectable versions.',
    ])->save();
    echo \"nest_created id={\$nest->id} name={\$nest->name}\\n\";
} else {
    echo \"nest_exists id={\$nest->id} name={\$nest->name}\\n\";
}

\$files = [
    'Discord.js' => \$eggDir . '/egg-discord-js.json',
    'Discord.py' => \$eggDir . '/egg-discord-py.json',
    'Node.js' => \$eggDir . '/egg-nodejs.json',
    'Python' => \$eggDir . '/egg-python.json',
];

\$importer = app(EggImporterService::class);
\$parser = app(EggParserService::class);
\$ids = [];

foreach (\$files as \$expectedName => \$path) {
    if (!is_file(\$path)) {
        echo \"missing_egg_file path=\$path\\n\";
        continue;
    }

    \$existing = Egg::query()->where('nest_id', \$nest->id)->where('name', \$expectedName)->first();
    if (!\$existing) {
        \$existing = Egg::query()->where('name', \$expectedName)->orderBy('id')->first();
    }

    \$upload = new UploadedFile(\$path, basename(\$path), 'application/json', null, true);
    \$parsed = \$parser->handle(\$upload);

    if (\$existing) {
        DB::transaction(function () use (\$existing, \$parsed, \$parser, \$nest) {
            \$existing->nest_id = \$nest->id;
            \$parser->fillFromParsed(\$existing, \$parsed);
            \$existing->save();
            EggVariable::query()->where('egg_id', \$existing->id)->delete();
            foreach (\$parsed['variables'] ?? [] as \$variable) {
                EggVariable::query()->forceCreate(array_merge(\$variable, ['egg_id' => \$existing->id]));
            }
        });
        \$egg = \$existing->fresh();
        echo \"egg_updated id={\$egg->id} name={\$egg->name} nest={\$egg->nest_id}\\n\";
    } else {
        \$egg = \$importer->handle(\$upload, \$nest->id);
        if (\$egg->name !== \$expectedName) {
            \$egg->name = \$expectedName;
            \$egg->save();
        }
        echo \"egg_created id={\$egg->id} name={\$egg->name} nest={\$egg->nest_id}\\n\";
    }

    \$ids[\$expectedName] = ['nest' => (int) \$egg->nest_id, 'egg' => (int) \$egg->id];
    \$images = is_array(\$egg->docker_images) ? array_keys(\$egg->docker_images) : array_keys(json_decode(\$egg->docker_images, true) ?: []);
    echo '  versions=' . implode(', ', \$images) . \"\\n\";
}

file_put_contents('/tmp/billing-discord-egg-ids.json', json_encode(\$ids, JSON_PRETTY_PRINT));
echo \"ids_written=/tmp/billing-discord-egg-ids.json\\n\";
"

# Wire billing bot plans to Discord.js + Discord.py eggs
if [[ -d "$BILLING_ROOT" && -f /tmp/billing-discord-egg-ids.json ]]; then
  cd "$BILLING_ROOT"
  php -r "
require 'vendor/autoload.php';
\$app = require_once 'bootstrap/app.php';
\$kernel = \$app->make(Illuminate\Contracts\Console\Kernel::class);
\$kernel->bootstrap();

\$ids = json_decode(file_get_contents('/tmp/billing-discord-egg-ids.json'), true);
if (empty(\$ids['Discord.js']) || empty(\$ids['Discord.py'])) {
    fwrite(STDERR, \"Missing Discord egg ids\\n\");
    exit(1);
}
\$djs = \$ids['Discord.js']['nest'] . ':' . \$ids['Discord.js']['egg'];
\$dpy = \$ids['Discord.py']['nest'] . ':' . \$ids['Discord.py']['egg'];
\$eggsJson = json_encode([\$djs, \$dpy]);

\$updated = DB::table('plans')->whereIn('id', [6, 7])->update([
    'nests_eggs_id' => \$eggsJson,
    'updated_at' => now(),
]);
DB::table('plans')->where('id', 6)->update([
    'description' => 'Host your Discord bot 24/7. Choose Discord.js (Node) or Discord.py (Python) with selectable runtime versions.',
    'name' => 'Bot Starter',
]);
DB::table('plans')->where('id', 7)->update([
    'description' => 'For larger Discord bots with databases and heavier usage. Discord.js + Discord.py eggs with selectable versions.',
    'name' => 'Bot Pro',
]);

// Software category: Node.js + Python plans
if (!empty(\$ids['Node.js'])) {
    \$node = \$ids['Node.js']['nest'] . ':' . \$ids['Node.js']['egg'];
    DB::table('plans')->where('id', 20)->update([
        'nests_eggs_id' => json_encode([\$node]),
        'description' => 'General Node.js application hosting with selectable Node versions (18/20/21).',
        'updated_at' => now(),
    ]);
}

\$pyPlan = DB::table('plans')->where('name', 'Python Hosting')->first();
if (!\$pyPlan && !empty(\$ids['Python'])) {
    \$py = \$ids['Python']['nest'] . ':' . \$ids['Python']['egg'];
    \$template = DB::table('plans')->where('id', 20)->first();
    \$planId = DB::table('plans')->insertGetId([
        'name' => 'Python Hosting',
        'description' => 'General Python application hosting with selectable Python versions (3.9–3.12). Great for discord.py bots and scripts.',
        'category_id' => 5,
        'ram' => \$template->ram ?? 512,
        'cpu' => \$template->cpu ?? 100,
        'disk' => \$template->disk ?? 3072,
        'swap' => \$template->swap ?? 0,
        'io' => \$template->io ?? 500,
        'databases' => \$template->databases ?? 1,
        'backups' => \$template->backups ?? 1,
        'extra_ports' => \$template->extra_ports ?? 1,
        'locations_nodes_id' => \$template->locations_nodes_id ?? json_encode(['1:1']),
        'min_port' => \$template->min_port,
        'max_port' => \$template->max_port,
        'nests_eggs_id' => json_encode([\$py]),
        'server_description' => 'Your Python application server.',
        'discount' => \$template->discount,
        'coupons' => \$template->coupons,
        'days_before_suspend' => \$template->days_before_suspend ?? 3,
        'days_before_delete' => \$template->days_before_delete ?? 7,
        'global_limit' => null,
        'per_client_limit' => null,
        'per_client_trial_limit' => null,
        'order' => 21,
        'created_at' => now(),
        'updated_at' => now(),
    ]);
    \$cycle = DB::table('plan_cycles')->where('plan_id', 20)->first();
    DB::table('plan_cycles')->insert([
        'plan_id' => \$planId,
        'cycle_length' => \$cycle->cycle_length ?? 1,
        'cycle_type' => \$cycle->cycle_type ?? 3,
        'init_price' => \$cycle->init_price ?? 5.000000,
        'renew_price' => \$cycle->renew_price ?? 5.000000,
        'setup_fee' => 0.000000,
        'late_fee' => 0.000000,
        'trial_length' => null,
        'trial_type' => null,
        'created_at' => now(),
        'updated_at' => now(),
    ]);
    echo \"python_plan_created id=\$planId eggs=\$py\\n\";
} elseif (\$pyPlan && !empty(\$ids['Python'])) {
    \$py = \$ids['Python']['nest'] . ':' . \$ids['Python']['egg'];
    DB::table('plans')->where('id', \$pyPlan->id)->update([
        'nests_eggs_id' => json_encode([\$py]),
        'description' => 'General Python application hosting with selectable Python versions (3.9–3.12). Great for discord.py bots and scripts.',
        'updated_at' => now(),
    ]);
    echo \"python_plan_updated id={\$pyPlan->id}\\n\";
}

echo \"bot_plans_updated=\$updated eggs=\$eggsJson\\n\";
foreach (DB::table('plans')->whereIn('id', [6, 7, 20])->orWhere('name', 'Python Hosting')->get(['id','name','nests_eggs_id','description']) as \$p) {
    echo \"plan id=\$p->id name=\$p->name eggs=\$p->nests_eggs_id\\n\";
}
"
fi

# Clear panel caches so new eggs show in API
cd "$PANEL_ROOT"
sudo -u www-data php artisan cache:clear || true
sudo -u www-data php artisan view:clear || true
echo "Discord bot eggs install complete."
