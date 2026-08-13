<?php

namespace App\Notifications;

use App\Models\Client;
use App\Support\CustomerName;
use App\Support\EmailGuide;
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
        $brand = EmailGuide::brand();
        $billingUrl = EmailGuide::billingUrl();
        $panelUrl = EmailGuide::panelUrl();
        $dashUrl = EmailGuide::billingDashUrl();

        $billingPass = $this->billingPassword
            ? $this->billingPassword . ' (save this — shown once)'
            : 'The password you chose when registering';

        $panelPass = $this->panelPassword
            ? $this->panelPassword . ' (save this — shown once)'
            : 'Same as billing, or use Forgot Password on the panel';

        $body = EmailGuide::twoSitesBlurb()
            . "\n\n"
            . "Your account is ready. Keep this email for your login details.\n"
            . "You will also get a separate Verify Email message — please confirm your address.";

        $steps = [
            'Billing: open ' . $billingUrl . ' → click Login → use your email + billing password',
            'Dashboard: after login you land on ' . $dashUrl . ' for invoices and renewals',
            'Game panel: open ' . $panelUrl . ' → sign in with username "' . $this->panelUsername . '" (or your email)',
            'Servers: click your server name to open the console, files, and Start / Stop controls',
            'Verify: open the Verify Email message and tap Verify so your account stays unlocked',
        ];

        return (new MailMessage)->subject('Welcome to ' . $brand)->view('emails.notif', [
            'subject' => 'Welcome to ' . $brand,
            'greeting_name' => CustomerName::greetingFor($this->client),
            'body_message' => $body,
            'body_action' => 'Need help? Reply to this email or open a ticket from your billing dashboard.',
            'details' => [
                'Billing URL' => $billingUrl,
                'Billing email' => $this->client->email,
                'Billing password' => $billingPass,
                'Game panel URL' => $panelUrl,
                'Panel username' => $this->panelUsername,
                'Panel password' => $panelPass,
            ],
            'steps_title' => 'Beginner login guide',
            'steps' => $steps,
            'button_text' => 'Open Billing Dashboard',
            'button_url' => $dashUrl,
            'notice' => 'You received this because an account was created on ' . $brand . '.',
        ]);
    }

    public function toArray($notifiable)
    {
        return [];
    }
}
