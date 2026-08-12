<?php

namespace App\Notifications;

use App\Models\Currency;
use App\Models\Plan;
use App\Models\PlanCycle;
use App\Models\Server;
use App\Support\CustomerName;
use App\Support\EmailGuide;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class RenewServerNotif extends Notification implements ShouldQueue
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
        $plan = Plan::find($this->server->plan_id);
        $planName = $plan->name ?? ('Server #' . $this->server->id);
        $due = $this->server->due_date ? (string) $this->server->due_date : 'soon';
        $serverLabel = $this->server->server_name ?: $planName;

        $cycle = PlanCycle::find($this->server->plan_cycle);
        $currency = Currency::where('default', true)->first();
        $symbol = $currency->symbol ?? '$';
        $currencyName = $currency->name ?? 'USD';
        $renewPrice = $cycle ? number_format((float) $cycle->renew_price, 2) : null;

        $details = [
            'Server' => $serverLabel,
            'Plan' => $planName,
            'Expires' => $due,
        ];
        if ($renewPrice !== null) {
            $details['Renewal price'] = $symbol . $renewPrice . ' ' . $currencyName;
        }

        return (new MailMessage)->subject('Renew soon — ' . $planName)->view('emails.notif', [
            'subject' => 'Renewal reminder',
            'greeting_name' => CustomerName::greetingFor($notifiable),
            'body_message' => "Your server \"{$serverLabel}\" ({$planName}) will expire on {$due}.\nPlease renew before the due date or the server may be suspended.",
            'body_action' => 'Renew from billing — the game panel does not take payments.',
            'details' => $details,
            'steps_title' => 'How to renew',
            'steps' => [
                'Tap Renew Server (or open ' . EmailGuide::billingUrl() . ' → Login)',
                'Open this server and complete the renewal payment',
                'Keep using the game panel at ' . EmailGuide::panelUrl() . ' as usual',
            ],
            'button_text' => 'Renew Server',
            'button_url' => url()->route('client.server.show', ['id' => $this->server->id]),
            'notice' => 'You received this because you have an active product with ' . EmailGuide::brand() . '.',
        ]);
    }

    public function toArray($notifiable)
    {
        return [];
    }
}
