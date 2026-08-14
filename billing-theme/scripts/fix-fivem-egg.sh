#!/usr/bin/env bash
# FiveM egg: use bash installer + ensure required env variables exist.
set -euo pipefail
cd /var/www/pterodactyl
php <<'PHP'
<?php
require 'vendor/autoload.php';
$app = require 'bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;

$updated = DB::table('eggs')
    ->where('name', 'FiveM')
    ->update([
        'script_entry' => 'bash',
        'script_container' => 'ghcr.io/parkervcp/installers:debian',
        'updated_at' => now(),
    ]);
echo "fivem_egg_rows={$updated}\n";

$vars = [
    ['name' => 'FiveM License Key', 'description' => 'CFX license key from https://keymaster.fivem.net', 'env_variable' => 'FIVEM_LICENSE', 'default_value' => '', 'user_viewable' => 1, 'user_editable' => 1, 'rules' => 'required|string|max:64'],
    ['name' => 'Steam Web API Key', 'description' => 'Optional Steam Web API key', 'env_variable' => 'STEAM_WEBAPIKEY', 'default_value' => 'none', 'user_viewable' => 1, 'user_editable' => 1, 'rules' => 'nullable|string|max:64'],
    ['name' => 'Max Players', 'description' => 'Maximum players', 'env_variable' => 'MAX_PLAYERS', 'default_value' => '48', 'user_viewable' => 1, 'user_editable' => 1, 'rules' => 'required|integer|between:1,128'],
    ['name' => 'txAdmin Port', 'description' => 'txAdmin listen port', 'env_variable' => 'TXADMIN_PORT', 'default_value' => '40120', 'user_viewable' => 1, 'user_editable' => 0, 'rules' => 'required|integer|between:1024,65535'],
    ['name' => 'Enable txAdmin', 'description' => '1 enables txAdmin UI', 'env_variable' => 'TXADMIN_ENABLE', 'default_value' => '0', 'user_viewable' => 1, 'user_editable' => 1, 'rules' => 'required|boolean'],
];

foreach (DB::table('eggs')->where('name', 'FiveM')->pluck('id') as $eggId) {
    foreach ($vars as $v) {
        $exists = DB::table('egg_variables')->where('egg_id', $eggId)->where('env_variable', $v['env_variable'])->exists();
        if ($exists) {
            echo "egg {$eggId} has {$v['env_variable']}\n";
            continue;
        }
        DB::table('egg_variables')->insert(array_merge($v, [
            'egg_id' => $eggId,
            'created_at' => now(),
            'updated_at' => now(),
        ]));
        echo "egg {$eggId} added {$v['env_variable']}\n";
    }

    // Backfill any FiveM servers missing these variables
    foreach (DB::table('servers')->where('egg_id', $eggId)->get() as $s) {
        foreach (DB::table('egg_variables')->where('egg_id', $eggId)->get() as $ev) {
            $has = DB::table('server_variables')->where('server_id', $s->id)->where('variable_id', $ev->id)->exists();
            if ($has) {
                continue;
            }
            DB::table('server_variables')->insert([
                'server_id' => $s->id,
                'variable_id' => $ev->id,
                'variable_value' => $ev->default_value,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
            echo "server {$s->id} {$s->name} got {$ev->env_variable}\n";
        }
    }
}
PHP
