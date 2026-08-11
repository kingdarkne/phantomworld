#!/usr/bin/env bash
# Keep a single default currency named USD and remap clients off "US Dollar".
set -euo pipefail
php <<'PHP'
<?php
require '/var/www/billing/vendor/autoload.php';
$app = require '/var/www/billing/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;

$usd = DB::table('currencies')->where('name', 'USD')->first();
if (!$usd) {
    $id = DB::table('currencies')->insertGetId([
        'name' => 'USD',
        'symbol' => '$',
        'rate' => 1,
        'precision' => 2,
        'default' => 1,
        'created_at' => now(),
        'updated_at' => now(),
    ]);
    $usd = (object) ['id' => $id];
    echo "created USD {$id}\n";
} else {
    DB::table('currencies')->where('id', $usd->id)->update([
        'symbol' => '$',
        'rate' => 1,
        'precision' => 2,
        'default' => 1,
        'updated_at' => now(),
    ]);
    echo "usd default {$usd->id}\n";
}

DB::table('currencies')->where('id', '!=', $usd->id)->update(['default' => 0, 'updated_at' => now()]);

foreach (DB::table('currencies')->where('name', 'US Dollar')->pluck('id') as $dupeId) {
    DB::table('clients')->whereIn('currency', ['US Dollar', (string) $dupeId, '1'])->update(['currency' => 'USD']);
    DB::table('currencies')->where('id', $dupeId)->delete();
    echo "deleted dupe {$dupeId}\n";
}

DB::table('clients')->whereIn('currency', ['US Dollar', '1'])->update(['currency' => 'USD']);

foreach (DB::table('currencies')->get() as $c) {
    echo "{$c->id}|{$c->name}|default={$c->default}\n";
}
PHP
