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

        $body = "Please pay for {$name}.\n"
            . "Amount due: {$symbol}{$total} {$currencyName}\n"
            . "Due / renew date: {$dueText}";

        return (new MailMessage)->subject('Payment due — ' . $name . ' (' . $symbol . $total . ')')->view('emails.notif', [
            'subject' => 'New Product Payment',
            'body_message' => $body,
            'body_action' => 'Click below to view the invoice, amount due, and pay or renew.',
            'button_text' => 'View Invoice',
            'button_url' => url()->route('client.invoice.show', ['id' => $this->invoice->id]),
            'notice' => 'You received this email because you ordered a product or service from Phantom Hosting.',
        ]);
    }

    public function toArray($notifiable)
    {
        return [];
    }
}
