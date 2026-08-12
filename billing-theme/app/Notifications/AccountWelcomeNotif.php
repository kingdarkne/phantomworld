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
        $dashUrl = url()->route('client.dash');

        $lines = [
            'Welcome to Phantom Hosting — your account is ready.',
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
            $lines[] = 'Panel password: use Forgot Password on the panel if you need a reset.';
        }

        $lines[] = '';
        $lines[] = 'Check your inbox for a separate email with a Verify Email button — please confirm your address.';

        return (new MailMessage)->subject('Welcome to Phantom Hosting')->view('emails.notif', [
            'subject' => 'Welcome to Phantom Hosting',
            'greeting_name' => \App\Support\CustomerName::greetingFor($this->client),
            'body_message' => implode("\n", $lines),
            'body_action' => 'Open your billing dashboard to manage servers, invoices, and renewals.',
            'button_text' => 'Open Billing Dashboard',
            'button_url' => $dashUrl,
            'notice' => 'You received this email because an account was created on Phantom Hosting.',
        ]);
    }

    public function toArray($notifiable)
    {
        return [];
    }
}
