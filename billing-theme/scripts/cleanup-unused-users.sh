#!/usr/bin/env bash
# Remove unused/test panel + billing accounts that have no important servers.
# Keeps: staff admins, owner, ericaxavier897, whiteflame122 (Phantom Backup),
# and the PHANTOM staff servers.
set -euo pipefail

PANEL_ROOT="${PANEL_ROOT:-/var/www/pterodactyl}"
BILLING_ROOT="${BILLING_ROOT:-/var/www/billing}"

KEEP_PANEL_EMAILS=(
  'admin@phantom-chicken.com'
  'owner@phantom-chicken.com'
  'ericaxavier897@gmail.com'
  'whiteflame122@gmail.com'
)

KEEP_BILLING_EMAILS=(
  'admin@phantom-chicken.com'
  'owner@phantom-chicken.com'
  'ericaxavier897@gmail.com'
  'whiteflame122@gmail.com'
)

# Test panel servers to delete first (so their owners become deletable)
DELETE_PANEL_SERVER_IDS=(4 5) # FreeTest6742, FreeFlow6857

cd "$PANEL_ROOT"
sudo -u www-data php <<'PHP'
<?php
require 'vendor/autoload.php';
$app = require 'bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$deleteServerIds = [4, 5];
$svc = app(\Pterodactyl\Services\Servers\ServerDeletionService::class);

foreach ($deleteServerIds as $sid) {
    $server = \Pterodactyl\Models\Server::find($sid);
    if (!$server) {
        echo "panel_server_already_gone id={$sid}\n";
        continue;
    }
    echo "deleting_panel_server id={$server->id} name={$server->name}\n";
    $svc->withForce(true)->handle($server);
    echo "deleted_panel_server id={$sid}\n";
}
PHP

cd "$PANEL_ROOT"
sudo -u www-data php <<'PHP'
<?php
require 'vendor/autoload.php';
$app = require 'bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$keep = array_map('strtolower', [
    'admin@phantom-chicken.com',
    'owner@phantom-chicken.com',
    'ericaxavier897@gmail.com',
    'whiteflame122@gmail.com',
]);

$userSvc = app(\Pterodactyl\Services\Users\UserDeletionService::class);

foreach (\Pterodactyl\Models\User::orderBy('id')->get() as $user) {
    $email = strtolower($user->email);
    if (in_array($email, $keep, true)) {
        echo "keep_panel_user id={$user->id} email={$email} root=" . ($user->root_admin ? 1 : 0) . "\n";
        continue;
    }
    if ($user->root_admin) {
        echo "skip_root_admin id={$user->id} email={$email}\n";
        continue;
    }
    $owned = \Pterodactyl\Models\Server::where('owner_id', $user->id)->count();
    if ($owned > 0) {
        echo "skip_panel_user_has_servers id={$user->id} email={$email} servers={$owned}\n";
        continue;
    }
    echo "deleting_panel_user id={$user->id} email={$email}\n";
    try {
        $userSvc->handle($user);
        echo "deleted_panel_user id={$user->id}\n";
    } catch (Throwable $e) {
        echo "fail_panel_user id={$user->id} err=" . $e->getMessage() . "\n";
    }
}
PHP

cd "$BILLING_ROOT"
sudo -u www-data php <<'PHP'
<?php
require 'vendor/autoload.php';
$app = require 'bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$keep = array_map('strtolower', [
    'admin@phantom-chicken.com',
    'owner@phantom-chicken.com',
    'ericaxavier897@gmail.com',
    'whiteflame122@gmail.com',
]);

foreach (App\Models\Client::orderBy('id')->get() as $client) {
    $email = strtolower($client->email);
    if (in_array($email, $keep, true)) {
        echo "keep_billing_client id={$client->id} email={$email} admin=" . ($client->is_admin ? 1 : 0) . "\n";
        continue;
    }

    $serverIds = DB::table('servers')->where('client_id', $client->id)->pluck('id');
    $invoiceIds = DB::table('invoices')->where('client_id', $client->id)->pluck('id');

    echo "deleting_billing_client id={$client->id} email={$email} servers=" . $serverIds->count() . " invoices=" . $invoiceIds->count() . "\n";

    // Best-effort related cleanup (tables may vary slightly by install).
    foreach (['invoice_items', 'invoice_item'] as $t) {
        if (Schema::hasTable($t) && $invoiceIds->count()) {
            DB::table($t)->whereIn('invoice_id', $invoiceIds)->delete();
        }
    }
    if (Schema::hasTable('used_coupons')) {
        DB::table('used_coupons')->where('client_id', $client->id)->delete();
    }
    if (Schema::hasTable('tickets')) {
        $ticketIds = DB::table('tickets')->where('client_id', $client->id)->pluck('id');
        if (Schema::hasTable('ticket_messages') && $ticketIds->count()) {
            DB::table('ticket_messages')->whereIn('ticket_id', $ticketIds)->delete();
        }
        DB::table('tickets')->where('client_id', $client->id)->delete();
    }
    if (Schema::hasTable('credits')) {
        DB::table('credits')->where('client_id', $client->id)->delete();
    }

    DB::table('servers')->where('client_id', $client->id)->delete();
    DB::table('invoices')->where('client_id', $client->id)->delete();
    $client->delete();
    echo "deleted_billing_client id={$client->id}\n";
}

echo "--- remaining panel users ---\n";
PHP

cd "$PANEL_ROOT"
sudo -u www-data php -r '
require "vendor/autoload.php";
$app=require "bootstrap/app.php";
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
foreach (Pterodactyl\Models\User::orderBy("id")->get() as $u) {
  $n = DB::table("servers")->where("owner_id", $u->id)->count();
  echo "panel id={$u->id} {$u->email} root=".($u->root_admin?1:0)." servers={$n}\n";
}
foreach (DB::table("servers")->orderBy("id")->get(["id","name","owner_id"]) as $s) {
  echo "server #{$s->id} {$s->name} owner={$s->owner_id}\n";
}
'

cd "$BILLING_ROOT"
sudo -u www-data php -r '
require "vendor/autoload.php";
$app=require "bootstrap/app.php";
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
foreach (App\Models\Client::orderBy("id")->get() as $c) {
  $n = DB::table("servers")->where("client_id", $c->id)->count();
  echo "billing id={$c->id} {$c->email} admin=".($c->is_admin?1:0)." servers={$n}\n";
}
'

echo "unused-user cleanup complete."
