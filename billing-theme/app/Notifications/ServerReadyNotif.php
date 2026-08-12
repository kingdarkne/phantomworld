<?php

namespace App\Notifications;

use App\Models\Client;
use App\Models\Currency;
use App\Models\Invoice;
use App\Models\Plan;
use App\Models\PlanCycle;
use App\Models\Server;
use App\Support\CustomerName;
use App\Support\EmailGuide;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class ServerReadyNotif extends Notification implements ShouldQueue
{
    use Queueable;

    protected Server $server;

    public function __construct(Server $server)
    {
        $this->server = $server;
    }

    public function via($notifiable)
    {
        return ['mail'];
    }

    public function toMail($notifiable)
    {
        $panelUrl = EmailGuide::panelUrl();
        $plan = Plan::find($this->server->plan_id);
        $planName = $plan->name ?? ('Plan #' . $this->server->plan_id);
        $due = $this->server->due_date ? (string) $this->server->due_date : 'N/A';
        $serverLabel = $this->server->server_name ?: ('#' . $this->server->id);

        $invoice = Invoice::where('server_id', $this->server->id)->latest('id')->first();
        $amount = $invoice ? number_format((float) $invoice->total, 2) : null;
        $currency = session()->has('currency')
            ? session('currency')
            : Currency::where('default', true)->first();
        $symbol = $currency->symbol ?? '$';
        $currencyName = $currency->name ?? 'USD';

        $cycle = PlanCycle::find($this->server->plan_cycle);
        $renewPrice = $cycle ? number_format((float) $cycle->renew_price, 2) : null;

        $client = Client::find($this->server->client_id);
        $consoleUrl = $this->server->identifier
            ? ($panelUrl . '/server/' . $this->server->identifier)
            : $panelUrl;

        $details = [
            'Server' => $serverLabel,
            'Plan' => $planName,
            'Renew / due date' => $due,
            'Game panel' => $panelUrl,
        ];
        if ($amount !== null) {
            $details['Invoice amount'] = $symbol . $amount . ' ' . $currencyName;
        }
        if ($renewPrice !== null) {
            $details['Renew price'] = $symbol . $renewPrice . ' ' . $currencyName;
        }
        if ($client) {
            $details['Login email'] = $client->email;
        }

        return (new MailMessage)->subject('Your server is ready — ' . $planName)->view('emails.notif', [
            'subject' => 'Your server is ready',
            'greeting_name' => CustomerName::greetingFor($client),
            'body_message' => "\"{$serverLabel}\" finished provisioning and is ready on " . EmailGuide::brand() . '.',
            'body_action' => 'Use billing for invoices/renewals, and the game panel for console & Start/Stop.',
            'details' => $details,
            'steps_title' => 'How to open your server',
            'steps' => [
                'Billing: open ' . EmailGuide::billingUrl() . ' → Login → open this server from your dashboard',
                'Game panel: open ' . $panelUrl . ' → sign in with the same email',
                'Click the server name (or open ' . $consoleUrl . ' after login)',
                'Press Start if needed, then watch the Console while it boots',
            ],
            'button_text' => 'View Server in Billing',
            'button_url' => url()->route('client.server.show', ['id' => $this->server->id]),
            'notice' => 'You received this because your ' . EmailGuide::brand() . ' server finished provisioning.',
        ]);
    }

    public function toArray($notifiable)
    {
        return [];
    }
}
