<?php

namespace App\Jobs;

use App\Models\Client;
use App\Models\Setting;
use App\Notifications\AccountWelcomeNotif;
use App\Support\DiscordRelay;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class CreatePanelUser implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected $client;

    protected $apiKey;

    protected $apiUrl;

    /** Optional billing-portal password to include in the welcome email (guests). */
    protected ?string $billingPassword;

    public function __construct(Client $client, ?string $billingPassword = null)
    {
        $this->client = $client;
        $this->billingPassword = $billingPassword;
        $this->apiKey = Setting::where('key', 'panel_app_api_key')->value('value');
        $this->apiUrl = Setting::where('key', 'panel_url')->value('value');
    }

    public function handle()
    {
        if (empty($this->apiKey) || empty($this->apiUrl)) {
            Log::error('[CreatePanelUser] Panel URL or API key is not configured.');

            return $this->fail();
        }

        $response = Http::withHeaders([
            'Authorization' => 'Bearer ' . $this->apiKey,
            'Accept' => 'application/json',
        ])->get(rtrim($this->apiUrl, '/') . '/api/application/users', [
            'filter[email]' => $this->client->email,
        ]);

        if ($response->failed()) {
            Log::error('[CreatePanelUser] Failed to fetch user from panel: ' . $response->body());

            foreach ($response->json('errors', []) as $error) {
                Log::error($error['detail'] ?? json_encode($error));
            }

            return $this->fail();
        }

        $data = $response->json();
        if (!empty($data['data'])) {
            $user_obj = $data['data'][0];
            if ($user_obj['attributes']['email'] == $this->client->email
                && Client::where('user_id', $user_obj['attributes']['id'])->count() == 0) {
                $this->client->user_id = $user_obj['attributes']['id'];
                $this->client->save();

                $this->sendWelcome(
                    (string) $user_obj['attributes']['username'],
                    null
                );

                return;
            }
        }

        $local = strstr($this->client->email, '@', true) ?: 'user';
        $username = preg_replace('/[^A-Za-z0-9]/', '', $local . Str::random(4));
        if ($username === '') {
            $username = 'user' . Str::random(6);
        }

        $panelPassword = Str::random(16);

        $create_response = Http::withHeaders([
            'Authorization' => 'Bearer ' . $this->apiKey,
            'Accept' => 'application/json',
            'Content-Type' => 'application/json',
        ])->post(rtrim($this->apiUrl, '/') . '/api/application/users', [
            'username' => $username,
            'email' => $this->client->email,
            'first_name' => 'First',
            'last_name' => 'Last',
            'password' => $panelPassword,
        ]);

        if ($create_response->failed()) {
            Log::error('[CreatePanelUser] Failed to create user on panel: ' . $create_response->body());

            foreach ($create_response->json('errors', []) as $error) {
                Log::error($error['detail'] ?? json_encode($error));
            }

            return $this->fail();
        }

        $user_data = $create_response->json()['attributes'];
        $this->client->user_id = $user_data['id'];
        $this->client->save();

        $this->sendWelcome((string) ($user_data['username'] ?? $username), $panelPassword);

        try {
            DiscordRelay::panelUserCreated($this->client, (string) $this->apiUrl);
        } catch (\Throwable $e) {
            Log::warning('[CreatePanelUser] DiscordRelay failed: ' . $e->getMessage());
        }
    }

    private function sendWelcome(string $panelUsername, ?string $panelPassword): void
    {
        // Skip disposable guest_*@phantom-chicken.com leftovers from older checkouts
        if (preg_match('/^guest_/i', (string) $this->client->email)
            && str_ends_with(strtolower((string) $this->client->email), '@phantom-chicken.com')) {
            Log::info('[CreatePanelUser] Skipping welcome email for legacy guest address ' . $this->client->email);

            return;
        }

        try {
            $this->client->notify(new AccountWelcomeNotif(
                $this->client,
                $panelUsername,
                $panelPassword,
                $this->billingPassword
            ));
        } catch (\Throwable $e) {
            Log::error('[CreatePanelUser] Welcome email failed: ' . $e->getMessage());
        }
    }
}
