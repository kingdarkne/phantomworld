<?php

namespace App\Notifications;

use App\Models\Currency;
use App\Models\Invoice;
use App\Models\Plan;
use App\Models\Server;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class InvoiceDueNotif extends Notification implements ShouldQueue
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
        $dueText = $dueDate ? (string) $dueDate : 'the due date';

        $body = "Your invoice for {$name} is overdue (due {$dueText}).\n"
            . "Amount due: {$symbol}{$total} {$currencyName}\n"
            . 'Please pay now to avoid suspension or removal.';

        return (new MailMessage)->subject('Overdue invoice — ' . $name)->view('emails.notif', [
            'subject' => 'Invoice overdue',
            'greeting_name' => \App\Support\CustomerName::greetingFor($notifiable),
            'body_message' => $body,
            'body_action' => 'Pay the invoice below to keep your service active.',
            'button_text' => 'Pay Invoice',
            'button_url' => url()->route('client.invoice.show', ['id' => $this->invoice->id]),
            'notice' => 'You received this email because you have an unpaid invoice with Phantom Hosting.',
        ]);
    }

    public function toArray($notifiable)
    {
        return [];
    }
}
