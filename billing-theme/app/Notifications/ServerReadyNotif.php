<?php

namespace App\Notifications;

use App\Models\Client;
use App\Models\Currency;
use App\Models\Invoice;
use App\Models\Plan;
use App\Models\PlanCycle;
use App\Models\Server;
use App\Models\Setting;
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
        $panelUrl = rtrim((string) Setting::where('key', 'panel_url')->value('value'), '/') ?: 'https://panel.phantom-chicken.com';
        $plan = Plan::find($this->server->plan_id);
        $planName = $plan->name ?? ('Plan #' . $this->server->plan_id);
        $due = $this->server->due_date ? (string) $this->server->due_date : 'N/A';

        $invoice = Invoice::where('server_id', $this->server->id)->latest('id')->first();
        $amount = $invoice ? number_format((float) $invoice->total, 2) : null;
        $currency = session()->has('currency')
            ? session('currency')
            : Currency::where('default', true)->first();
        $symbol = $currency->symbol ?? '$';
        $currencyName = $currency->name ?? 'USD';

        $cycle = PlanCycle::find($this->server->plan_cycle);
        $renewPrice = $cycle ? number_format((float) $cycle->renew_price, 2) : null;

        $lines = [
            'Your server "' . ($this->server->server_name ?: ('#' . $this->server->id)) . '" is ready.',
            'Plan: ' . $planName,
            'Panel server ID: ' . ($this->server->identifier ?: 'pending'),
            'Renew / next due date: ' . $due,
        ];

        if ($amount !== null) {
            $lines[] = 'Amount charged / due on this invoice: ' . $symbol . $amount . ' ' . $currencyName;
        }
        if ($renewPrice !== null) {
            $lines[] = 'Recurring renew price: ' . $symbol . $renewPrice . ' ' . $currencyName;
        }

        $lines[] = '';
        $lines[] = 'Log into the game panel with the account email you used at checkout:';
        $lines[] = $panelUrl;
        if ($this->server->identifier) {
            $lines[] = 'Direct console (after login): ' . $panelUrl . '/server/' . $this->server->identifier;
        }

        $client = Client::find($this->server->client_id);
        if ($client) {
            $lines[] = 'Panel / billing email: ' . $client->email;
        }

        return (new MailMessage)->subject('Your server is ready — ' . $planName)->view('emails.notif', [
            'subject' => 'Your server is ready',
            'greeting_name' => \App\Support\CustomerName::greetingFor($client ?? null),
            'body_message' => implode("\n", $lines),
            'body_action' => 'Manage renewals and invoices in the billing client area.',
            'button_text' => 'View Server in Billing',
            'button_url' => url()->route('client.server.show', ['id' => $this->server->id]),
            'notice' => 'You received this email because your Phantom Hosting server finished provisioning.',
        ]);
    }

    public function toArray($notifiable)
    {
        return [];
    }
}
