<?php

namespace App\Jobs;

use App\Models\Addon;
use App\Models\Client;
use App\Models\Plan;
use App\Models\Server;
use App\Models\ServerAddon;
use App\Models\Setting;
use App\Notifications\ServerReadyNotif;
use App\Support\DiscordRelay;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class CreateServer implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected $server;

    protected $apiUrl;

    protected $apiKey;

    public function __construct(Server $server)
    {
        $this->server = $server;
        $this->apiKey = Setting::where('key', 'panel_app_api_key')->value('value');
        $this->apiUrl = rtrim((string) Setting::where('key', 'panel_url')->value('value'), '/');
    }

    public function handle()
    {
        $client = Client::find($this->server->client_id);
        $plan = Plan::find($this->server->plan_id);

        if (!$client || !$plan) {
            Log::error('[CreateServer] Missing client or plan for billing server ' . $this->server->id);

            return $this->fail();
        }

        // Panel user must exist before we can create a server (register jobs are async).
        if (empty($client->user_id)) {
            try {
                CreatePanelUser::dispatchSync($client);
            } catch (\Throwable $e) {
                Log::error('[CreateServer] CreatePanelUser failed: ' . $e->getMessage());
            }
            $client->refresh();
        }

        if (empty($client->user_id)) {
            $error = 'Client has no panel user account';
            Log::error('[CreateServer] ' . $error . ' (client_id=' . $client->id . ')');
            DiscordRelay::serverError($this->server, $client, $error);

            return $this->fail();
        }

        $cpu = $plan->cpu;
        $ram = $plan->ram;
        $swap = $plan->swap;
        $disk = $plan->disk;
        $io = $plan->io;
        $databases = $plan->databases;
        $backups = $plan->backups;
        $extra_ports = $plan->extra_ports;
        $dedi_ip = null;

        foreach (ServerAddon::where('server_id', $this->server->id)->get() as $server_addon) {
            $addon = Addon::find($server_addon->addon_id);
            switch ($addon->resource) {
                case 'ram': $ram += $addon->amount * $server_addon->value; break;
                case 'cpu': $cpu += $addon->amount * $server_addon->value; break;
                case 'disk': $disk += $addon->amount * $server_addon->value; break;
                case 'database': $databases += $addon->amount * $server_addon->value; break;
                case 'backup': $backups += $addon->amount * $server_addon->value; break;
                case 'extra_port': $extra_ports += $addon->amount * $server_addon->value; break;
                case 'dedicated_ip': $dedi_ip = $server_addon->value; break;
            }
        }

        $response = Http::withHeaders([
            'Authorization' => 'Bearer ' . $this->apiKey,
            'Accept' => 'application/json',
        ])->get("{$this->apiUrl}/api/application/nests/{$this->server->nest_id}/eggs/{$this->server->egg_id}?include=variables");

        if ($response->failed()) {
            $error = 'Failed to fetch egg details: ' . $response->body();
            Log::error('[CreateServer] ' . $error);
            DiscordRelay::serverError($this->server, $client, 'Failed to fetch egg details');

            return $this->fail();
        }

        $egg_res = $response->json();
        $egg = [
            'docker_image' => $egg_res['attributes']['docker_image'],
            'startup' => $egg_res['attributes']['startup'],
            'environment' => [],
        ];
        foreach ($egg_res['attributes']['relationships']['variables']['data'] as $var) {
            $egg['environment'][$var['attributes']['env_variable']] = $var['attributes']['default_value'];
        }

        $ips = Addon::dediIpList();
        $allocation_id = $this->getAllocationId($plan, $dedi_ip, $ips);

        if (is_null($allocation_id)) {
            $error = 'No available allocations on node';
            Log::error('[CreateServer] ' . $error);
            DiscordRelay::serverError($this->server, $client, $error);

            return $this->fail();
        }

        $createResponse = Http::withHeaders([
            'Authorization' => 'Bearer ' . $this->apiKey,
            'Accept' => 'application/json',
        ])->post("{$this->apiUrl}/api/application/servers", [
            'name' => $this->server->server_name,
            'user' => $client->user_id,
            'egg' => $this->server->egg_id,
            'docker_image' => $egg['docker_image'],
            'startup' => $egg['startup'],
            'environment' => $egg['environment'],
            'limits' => [
                'cpu' => $cpu,
                'memory' => $ram,
                'swap' => $swap,
                'disk' => $disk,
                'io' => $io,
            ],
            'feature_limits' => [
                'databases' => $databases,
                'backups' => $backups,
                'allocations' => $extra_ports + 1,
            ],
            'allocation' => [
                'default' => $allocation_id,
            ],
        ]);

        if ($createResponse->failed()) {
            $error = 'Failed to create server on panel: ' . $createResponse->body();
            Log::error('[CreateServer] ' . $error);
            DiscordRelay::serverError($this->server, $client, 'Failed to create server on panel');

            return $this->fail();
        }

        $server_attr = $createResponse->json()['attributes'];
        $this->server->server_id = $server_attr['id'];
        $this->server->identifier = $server_attr['identifier'];
        $this->server->status = 0;
        $this->server->save();

        try {
            $client->notify(new ServerReadyNotif($this->server));
        } catch (\Throwable $e) {
            Log::error('[CreateServer] ServerReady email failed: ' . $e->getMessage());
        }

        DiscordRelay::serverCreated($this->server, $client, $this->apiUrl);
    }

    private function getAllocationId($plan, $dedi_ip, $ips)
    {
        $page = $pages = 1;
        while ($page <= $pages) {
            $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . $this->apiKey,
                'Accept' => 'application/json',
            ])->get("{$this->apiUrl}/api/application/nodes/{$this->server->node_id}/allocations", [
                'page' => $page,
            ]);
            if ($response->failed()) {
                return null;
            }
            $allocation_res = $response->json();
            $pages = $allocation_res['meta']['pagination']['total_pages'];
            foreach ($allocation_res['data'] as $allocation) {
                if ($allocation['attributes']['assigned']) {
                    continue;
                }
                if ($dedi_ip && $allocation['attributes']['ip'] != $dedi_ip) {
                    continue;
                }
                if ($plan->min_port && $allocation['attributes']['port'] < $plan->min_port) {
                    continue;
                }
                if ($plan->max_port && $allocation['attributes']['port'] > $plan->max_port) {
                    continue;
                }
                if (is_null($dedi_ip) && in_array($allocation['attributes']['ip'], $ips)) {
                    continue;
                }

                return $allocation['attributes']['id'];
            }
            $page++;
        }

        return null;
    }
}
