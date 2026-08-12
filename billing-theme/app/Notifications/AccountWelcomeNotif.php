<?php

namespace App\Notifications;

use App\Models\Client;
use App\Models\Setting;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class AccountWelcomeNotif extends Notification implements ShouldQueue
{
    use Queueable;

    protected Client $client;

    protected string $panelUsername;

    protected ?string $panelPassword;

    protected ?string $billingPassword;

    public function __construct(Client $client, string $panelUsername, ?string $panelPassword = null, ?string $billingPassword = null)
    {
        $this->client = $client;
        $this->panelUsername = $panelUsername;
        $this->panelPassword = $panelPassword;
        $this->billingPassword = $billingPassword;
    }

    public function via($notifiable)
    {
        return ['mail'];
    }

    public function toMail($notifiable)
    {
        $panelUrl = rtrim((string) Setting::where('key', 'panel_url')->value('value'), '/') ?: 'https://panel.phantom-chicken.com';
        $billingUrl = rtrim((string) config('app.url'), '/');

        $lines = [
            'Your Phantom Hosting account is ready.',
            '',
            'Billing portal: ' . $billingUrl,
            'Billing email: ' . $this->client->email,
        ];

        if ($this->billingPassword) {
            $lines[] = 'Billing password: ' . $this->billingPassword;
            $lines[] = '(Save this password — it is only shown once.)';
        } else {
            $lines[] = 'Billing password: the password you chose when registering (or use Forgot Password).';
        }

        $lines[] = '';
        $lines[] = 'Game panel: ' . $panelUrl;
        $lines[] = 'Panel username: ' . $this->panelUsername;
        $lines[] = 'Panel email: ' . $this->client->email;

        if ($this->panelPassword) {
            $lines[] = 'Panel password: ' . $this->panelPassword;
            $lines[] = '(Same tip — save it now; it is only emailed once.)';
        } else {
            $lines[] = 'Panel password: check your panel welcome/reset email, or use Forgot Password on the panel.';
        }

        $lines[] = '';
        $lines[] = 'After checkout you will also receive emails with the amount due, renew/due date, and a link to manage or renew your server.';

        return (new MailMessage)->subject('Your Phantom Hosting login details')->view('emails.notif', [
            'subject' => 'Your account is ready',
            'greeting_name' => \App\Support\CustomerName::greetingFor($this->client),
            'body_message' => implode("\n", $lines),
            'body_action' => 'Open the billing portal to manage servers, invoices, and renewals.',
            'button_text' => 'Open Billing',
            'button_url' => $billingUrl . '/client',
            'notice' => 'You received this email because an account was created for an order on Phantom Hosting.',
        ]);
    }

    public function toArray($notifiable)
    {
        return [];
    }
}
