#!/usr/bin/env bash
# Separate customer billing accounts from panel root admins.
# Safe to re-run. Moves admin email off customer Gmail if needed, creates a
# normal panel user for the customer, and reassigns their purchased server(s).
set -euo pipefail

PANEL_ROOT="${PANEL_ROOT:-/var/www/pterodactyl}"
BILLING_ROOT="${BILLING_ROOT:-/var/www/billing}"
CUSTOMER_EMAIL="${CUSTOMER_EMAIL:-ericaxavier897@gmail.com}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@phantom-chicken.com}"

rm -f /tmp/fix-admin-link-customer-id.txt /tmp/fix-admin-link-panel-servers.txt

cd "$PANEL_ROOT"
sudo -u www-data env CUSTOMER_EMAIL="$CUSTOMER_EMAIL" ADMIN_EMAIL="$ADMIN_EMAIL" php <<'PHP'
<?php
require 'vendor/autoload.php';
$app = require 'bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$customerEmail = strtolower(trim(getenv('CUSTOMER_EMAIL') ?: 'ericaxavier897@gmail.com'));
$adminEmail = strtolower(trim(getenv('ADMIN_EMAIL') ?: 'admin@phantom-chicken.com'));

$admin = Pterodactyl\Models\User::whereRaw('LOWER(email) = ?', [$customerEmail])
    ->where('root_admin', 1)
    ->first();

if ($admin) {
    $taken = Pterodactyl\Models\User::whereRaw('LOWER(email) = ?', [$adminEmail])
        ->where('id', '!=', $admin->id)
        ->exists();
    if ($taken) {
        fwrite(STDERR, "admin_email_taken={$adminEmail}\n");
        exit(1);
    }
    $admin->email = $adminEmail;
    $admin->save();
    echo "moved_root_admin id={$admin->id} username={$admin->username} email={$adminEmail}\n";
} else {
    echo "root_admin_already_not_on_customer_email\n";
}

$customer = Pterodactyl\Models\User::whereRaw('LOWER(email) = ?', [$customerEmail])->first();
if (!$customer) {
    $local = preg_replace('/[^A-Za-z0-9]/', '', strstr($customerEmail, '@', true) ?: 'user');
    $username = $local . substr(bin2hex(random_bytes(2)), 0, 4);
    if (stripos($username, 'admin') === 0) {
        $username = 'user' . substr(bin2hex(random_bytes(4)), 0, 8);
    }
    $password = bin2hex(random_bytes(8));
    $customer = new Pterodactyl\Models\User();
    $customer->forceFill([
        'uuid' => (string) Ramsey\Uuid\Uuid::uuid4(),
        'username' => $username,
        'email' => $customerEmail,
        'name_first' => 'Erica',
        'name_last' => 'Xavier',
        'password' => Hash::make($password),
        'root_admin' => 0,
        'language' => 'en',
    ]);
    $customer->save();
    echo "created_customer_panel_user id={$customer->id} username={$username} password={$password}\n";
} else {
    if ($customer->root_admin) {
        fwrite(STDERR, "customer_email_still_root_admin id={$customer->id}\n");
        exit(1);
    }
    echo "customer_panel_user_exists id={$customer->id} username={$customer->username}\n";
}

file_put_contents('/tmp/fix-admin-link-customer-id.txt', (string) $customer->id);
PHP

CUSTOMER_PANEL_ID="$(cat /tmp/fix-admin-link-customer-id.txt)"

cd "$BILLING_ROOT"
sudo -u www-data env CUSTOMER_EMAIL="$CUSTOMER_EMAIL" CUSTOMER_PANEL_ID="$CUSTOMER_PANEL_ID" php <<'PHP'
<?php
require 'vendor/autoload.php';
$app = require 'bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$customerEmail = strtolower(trim(getenv('CUSTOMER_EMAIL') ?: 'ericaxavier897@gmail.com'));
$panelUserId = (int) (getenv('CUSTOMER_PANEL_ID') ?: 0);

$client = App\Models\Client::whereRaw('LOWER(email) = ?', [$customerEmail])->first();
if (!$client) {
    echo "billing_client_missing\n";
    exit(0);
}

$old = $client->user_id;
$client->user_id = $panelUserId;
$client->is_admin = 0;
$client->save();
echo "billing_client id={$client->id} user_id {$old} -> {$panelUserId} is_admin=0\n";

@unlink('/tmp/fix-admin-link-panel-servers.txt');
$servers = DB::table('servers')->where('client_id', $client->id)->get();
foreach ($servers as $s) {
    if (!empty($s->server_id)) {
        echo "billing_server id={$s->id} panel_server_id={$s->server_id} ident={$s->identifier}\n";
        file_put_contents('/tmp/fix-admin-link-panel-servers.txt', $s->server_id . PHP_EOL, FILE_APPEND);
    }
}
PHP

cd "$PANEL_ROOT"
sudo -u www-data env CUSTOMER_EMAIL="$CUSTOMER_EMAIL" php <<'PHP'
<?php
require 'vendor/autoload.php';
$app = require 'bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$customerEmail = strtolower(trim(getenv('CUSTOMER_EMAIL') ?: 'ericaxavier897@gmail.com'));
$customerId = (int) file_get_contents('/tmp/fix-admin-link-customer-id.txt');
$listFile = '/tmp/fix-admin-link-panel-servers.txt';
$ids = file_exists($listFile) ? array_filter(array_map('intval', file($listFile))) : [];

foreach ($ids as $sid) {
    $server = Pterodactyl\Models\Server::find($sid);
    if (!$server) {
        echo "panel_server_missing id={$sid}\n";
        continue;
    }
    $from = $server->owner_id;
    $server->owner_id = $customerId;
    $server->save();
    echo "reassigned_server id={$server->id} name={$server->name} owner {$from} -> {$customerId}\n";
}

$c = Pterodactyl\Models\User::find($customerId);
$a = Pterodactyl\Models\User::whereRaw('LOWER(email)=?', [$customerEmail])->first();
$admin1 = Pterodactyl\Models\User::find(1);
echo "sanity customer_id={$c->id} root_admin=" . ($c->root_admin ? 1 : 0) . " email={$c->email}\n";
echo "sanity gmail_user=" . ($a ? ('id=' . $a->id . ' root=' . ($a->root_admin ? 1 : 0)) : 'none') . "\n";
echo "sanity admin1_email=" . ($admin1->email ?? 'n/a') . " root=" . (($admin1->root_admin ?? false) ? 1 : 0) . "\n";
$stillAdminOwned = DB::table('servers')->where('owner_id', 1)->pluck('name')->all();
echo "admin_still_owns=" . json_encode($stillAdminOwned) . "\n";
$customerOwns = DB::table('servers')->where('owner_id', $customerId)->pluck('name')->all();
echo "customer_owns=" . json_encode($customerOwns) . "\n";
PHP

rm -f /tmp/fix-admin-link-customer-id.txt /tmp/fix-admin-link-panel-servers.txt
echo "fix-admin-customer-link complete."
