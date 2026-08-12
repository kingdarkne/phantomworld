#!/usr/bin/env bash
# FiveM egg install used entry=ash with a Debian installer image (no ash).
# Switch entry to bash so free/FiveM servers can finish installing.
set -euo pipefail
cd /var/www/pterodactyl
php <<'PHP'
<?php
require 'vendor/autoload.php';
$app = require 'bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;

$updated = DB::table('eggs')
    ->where('id', 16)
    ->orWhere('name', 'FiveM')
    ->update([
        'script_entry' => 'bash',
        'script_container' => 'ghcr.io/parkervcp/installers:debian',
        'updated_at' => now(),
    ]);

echo "fivem_egg_rows={$updated}\n";
foreach (DB::table('eggs')->where('id', 16)->orWhere('name', 'FiveM')->get() as $e) {
    echo "egg={$e->id}|{$e->name}|entry={$e->script_entry}|container={$e->script_container}\n";
}
PHP
