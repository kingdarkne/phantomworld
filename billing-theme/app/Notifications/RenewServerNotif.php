<?php

namespace App\Notifications;

use App\Models\Currency;
use App\Models\Plan;
use App\Models\PlanCycle;
use App\Models\Server;
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

        $cycle = PlanCycle::find($this->server->plan_cycle);
        $currency = Currency::where('default', true)->first();
        $symbol = $currency->symbol ?? '$';
        $currencyName = $currency->name ?? 'USD';
        $renewPrice = $cycle ? number_format((float) $cycle->renew_price, 2) : null;

        $body = "Your server \"{$this->server->server_name}\" ({$planName}) will expire on {$due}.\n";
        if ($renewPrice !== null) {
            $body .= "Renewal price: {$symbol}{$renewPrice} {$currencyName}\n";
        }
        $body .= 'Please renew before the due date or the server may be suspended.';

        return (new MailMessage)->subject('Renew soon — ' . $planName)->view('emails.notif', [
            'subject' => 'Renewal reminder',
            'greeting_name' => \App\Support\CustomerName::greetingFor($notifiable),
            'body_message' => $body,
            'body_action' => 'Open your server page to renew and keep the service online.',
            'button_text' => 'Renew Server',
            'button_url' => url()->route('client.server.show', ['id' => $this->server->id]),
            'notice' => 'You received this email because you have an active product with Phantom Hosting.',
        ]);
    }

    public function toArray($notifiable)
    {
        return [];
    }
}
