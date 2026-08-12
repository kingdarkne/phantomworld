<?php

namespace App\Notifications;

use App\Models\Currency;
use App\Models\Invoice;
use App\Models\Plan;
use App\Models\PlanCycle;
use App\Models\Server;
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

        $body = "Thank you — payment for {$name} was successful.\n"
            . "Paid amount: {$symbol}{$total} {$currencyName}\n";

        if ($renewDate) {
            $body .= 'Next renew / due date: ' . $renewDate . "\n";
        }
        if ($renewPrice !== null) {
            $body .= "Recurring renew price: {$symbol}{$renewPrice} {$currencyName}\n";
        }

        $body .= "\nYour game panel account uses this same email. Watch for a separate email when the server finishes installing.";

        return (new MailMessage)->subject('Payment received — ' . $name)->view('emails.notif', [
            'subject' => 'Product Paid',
            'body_message' => $body,
            'body_action' => 'View the invoice and server details in your client area.',
            'button_text' => 'View Invoice',
            'button_url' => url()->route('client.invoice.show', ['id' => $this->invoice->id]),
            'notice' => 'You received this email because you completed a payment with Phantom Hosting.',
        ]);
    }

    public function toArray($notifiable)
    {
        return [];
    }
}
