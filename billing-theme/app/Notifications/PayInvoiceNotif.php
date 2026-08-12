<?php

namespace App\Notifications;

use App\Models\Currency;
use App\Models\Invoice;
use App\Models\Plan;
use App\Models\Server;
use App\Support\CustomerName;
use App\Support\EmailGuide;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class PayInvoiceNotif extends Notification implements ShouldQueue
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
        $dueDate = $this->invoice->due_date ?: ($server->due_date ?? null);

        if ($server) {
            $plan = Plan::find($server->plan_id);
            $name = $plan->name ?? $name;
        }

        $currency = Currency::where('default', true)->first();
        $symbol = $currency->symbol ?? '$';
        $currencyName = $currency->name ?? 'USD';
        $total = number_format((float) $this->invoice->total, 2);
        $dueText = $dueDate ? (string) $dueDate : 'upon receipt';
        $invoiceUrl = url()->route('client.invoice.show', ['id' => $this->invoice->id]);

        return (new MailMessage)->subject('Payment due — ' . $name . ' (' . $symbol . $total . ')')->view('emails.notif', [
            'subject' => 'Payment due',
            'greeting_name' => CustomerName::greetingFor($notifiable),
            'body_message' => "Please pay for {$name} to keep your service active.",
            'body_action' => 'Log into billing if the button asks you to sign in first.',
            'details' => [
                'Service' => $name,
                'Amount due' => $symbol . $total . ' ' . $currencyName,
                'Due / renew date' => $dueText,
            ],
            'steps_title' => 'How to pay',
            'steps' => [
                'Tap View Invoice (or open ' . EmailGuide::billingUrl() . ' → Login)',
                'Review the amount and choose a payment method',
                'After payment, watch for a confirmation email',
            ],
            'button_text' => 'View Invoice',
            'button_url' => $invoiceUrl,
            'notice' => 'You received this because you ordered a product or service from ' . EmailGuide::brand() . '.',
        ]);
    }

    public function toArray($notifiable)
    {
        return [];
    }
}
