#!/usr/bin/env bash
# Cap Free Plan at 2 servers per customer account.
set -euo pipefail
php <<'PHP'
<?php
require '/var/www/billing/vendor/autoload.php';
$app = require '/var/www/billing/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;

$updated = DB::table('plans')
    ->where(function ($q) {
        $q->where('name', 'Free Plan')
            ->orWhere('id', 22);
    })
    ->update([
        'per_client_limit' => 2,
        'updated_at' => now(),
    ]);

echo "free_plan_limit_rows={$updated}\n";

foreach (DB::table('plans')->where('name', 'Free Plan')->orWhere('id', 22)->get() as $p) {
    echo "plan={$p->id}|{$p->name}|per_client_limit={$p->per_client_limit}\n";
}
PHP
