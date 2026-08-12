<?php

namespace App\Notifications;

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

class InvoicePaidNotif extends Notification implements ShouldQueue
{
    use Queueable;

    protected Invoice $invoice;

    public function __construct(Invoice $invoice)
    {
        $this->invoice = $invoice;
    }

    public function via($notifiable)
    {
        return ['mail'];
    }

    public function toMail($notifiable)
    {
        $server = Server::find($this->invoice->server_id);
        $name = 'Credits';
        $renewDate = null;
        $renewPrice = null;

        if ($server) {
            $plan = Plan::find($server->plan_id);
            $name = $plan->name ?? $name;
            $renewDate = $server->due_date;
            $cycle = PlanCycle::find($server->plan_cycle);
            if ($cycle) {
                $renewPrice = number_format((float) $cycle->renew_price, 2);
            }
        }

        $currency = Currency::where('default', true)->first();
        $symbol = $currency->symbol ?? '$';
        $currencyName = $currency->name ?? 'USD';
        $total = number_format((float) $this->invoice->total, 2);

        $details = [
            'Service' => $name,
            'Paid amount' => $symbol . $total . ' ' . $currencyName,
        ];
        if ($renewDate) {
            $details['Next renew / due'] = (string) $renewDate;
        }
        if ($renewPrice !== null) {
            $details['Renew price'] = $symbol . $renewPrice . ' ' . $currencyName;
        }

        return (new MailMessage)->subject('Payment received — ' . $name)->view('emails.notif', [
            'subject' => 'Payment received',
            'greeting_name' => CustomerName::greetingFor($notifiable),
            'body_message' => "Thank you — payment for {$name} was successful.\n\nYour game panel uses the same email. Watch for a separate message when the server finishes installing.",
            'body_action' => 'Open billing anytime for invoices; use the game panel for console and Start/Stop.',
            'details' => $details,
            'steps_title' => 'What to do next',
            'steps' => [
                'Billing dashboard: ' . EmailGuide::billingDashUrl(),
                'Game panel login: ' . EmailGuide::panelUrl() . ' (same email)',
                'When install finishes, open your server → Console → Start if needed',
            ],
            'button_text' => 'View Invoice',
            'button_url' => url()->route('client.invoice.show', ['id' => $this->invoice->id]),
            'notice' => 'You received this because you completed a payment with ' . EmailGuide::brand() . '.',
        ]);
    }

    public function toArray($notifiable)
    {
        return [];
    }
}
