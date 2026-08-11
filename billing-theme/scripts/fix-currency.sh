#!/usr/bin/env bash
# One-shot currency cleanup for HedystiaBilling.
# Keeps a single default currency named USD (ISO code) and remaps clients.
set -euo pipefail
cd /var/www/billing

sudo -u www-data php artisan tinker --execute="
\$usd = DB::table('currencies')->where('name', 'USD')->first();
if (!\$usd) {
  \$id = DB::table('currencies')->insertGetId([
    'name' => 'USD',
    'symbol' => '\$',
    'rate' => 1,
    'precision' => 2,
    'default' => 1,
    'created_at' => now(),
    'updated_at' => now(),
  ]);
  \$usd = (object) ['id' => \$id, 'name' => 'USD'];
  echo \"Created USD currency id={\$id}\\n\";
} else {
  DB::table('currencies')->where('id', \$usd->id)->update([
    'symbol' => '\$',
    'rate' => 1,
    'precision' => 2,
    'default' => 1,
    'updated_at' => now(),
  ]);
  echo \"USD id={\$usd->id} set as default\\n\";
}

DB::table('currencies')->where('id', '!=', \$usd->id)->update(['default' => 0, 'updated_at' => now()]);

\$dupes = DB::table('currencies')->where('name', 'US Dollar')->pluck('id');
foreach (\$dupes as \$dupeId) {
  DB::table('clients')->where('currency', 'US Dollar')->update(['currency' => 'USD']);
  DB::table('clients')->where('currency', (string) \$dupeId)->update(['currency' => 'USD']);
  DB::table('clients')->where('currency', '1')->update(['currency' => 'USD']);
  DB::table('currencies')->where('id', \$dupeId)->delete();
  echo \"Removed duplicate currency id={\$dupeId} (US Dollar)\\n\";
}

DB::table('clients')->whereIn('currency', ['US Dollar', '1'])->update(['currency' => 'USD']);

echo \"Currencies now:\\n\";
foreach (DB::table('currencies')->get() as \$c) {
  echo \"{\$c->id} | {\$c->name} default={\$c->default}\\n\";
}
"
