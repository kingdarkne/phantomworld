<?php

namespace Pterodactyl\Notifications;

use Pterodactyl\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;

class AccountCreated extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(public User $user, public ?string $token = null)
    {
    }

    public function via(): array
    {
        return ['mail'];
    }

    public function toMail(): MailMessage
    {
        $brand = config('app.name', 'Phantom Hosting');
        $panelUrl = rtrim((string) config('app.url'), '/') ?: 'https://panel.phantom-chicken.com';
        $billingUrl = 'https://billing.phantom-chicken.com';
        $loginUrl = $panelUrl . '/auth/login';
        $greeting = $this->politeGreetingName();

        $details = [
            'Game panel' => $panelUrl,
            'Panel email' => $this->user->email,
            'Panel username' => $this->user->username,
        ];

        if (!is_null($this->token)) {
            $actionUrl = url('/auth/password/reset/' . $this->token . '?email=' . urlencode($this->user->email));
            $actionText = 'Finish Panel Setup';
            $details['Password'] = 'Set one with the button below (required once)';
            $body = "Your game panel account on {$brand} is ready.\n\n"
                . "Use the button below to choose your panel password, then sign in to manage servers and consoles.";
            $steps = [
                'Tap Finish Panel Setup and choose a strong password',
                'Open ' . $panelUrl . ' and sign in with username "' . $this->user->username . '" (or your email)',
                'Click your server to open the console, files, and Start / Stop',
                'Billing / invoices stay on ' . $billingUrl . ' (separate login)',
            ];
        } else {
            $actionUrl = $loginUrl;
            $actionText = 'Open Game Panel';
            $details['Password'] = 'Use the panel password from your Phantom Hosting welcome email';
            $body = "Your game panel account on {$brand} is ready.\n\n"
                . "This is where you start/stop servers, open the console, and manage files.\n"
                . "Orders and invoices stay on the billing site: {$billingUrl}";
            $steps = [
                'Open ' . $panelUrl . ' (or tap the button below)',
                'Sign in with username "' . $this->user->username . '" or email ' . $this->user->email,
                'Enter the panel password from your welcome email (or Forgot Password if needed)',
                'Click your server name → use Console / Start / Restart',
                'For invoices & renewals, log into ' . $billingUrl . ' with the same email',
            ];
        }

        return (new MailMessage)
            ->subject('Your ' . $brand . ' game panel is ready')
            ->view('emails.phantom', [
                'brand' => $brand,
                'site_url' => $panelUrl,
                'logo_url' => 'https://billing.phantom-chicken.com/img/icon.webp',
                'subject' => 'Your game panel is ready',
                'greeting_name' => $greeting,
                'body_message' => $body,
                'body_action' => 'Save this email — it has your panel username and where to log in.',
                'details' => $details,
                'steps_title' => 'Beginner login guide',
                'steps' => $steps,
                'button_text' => $actionText,
                'button_url' => $actionUrl,
                'notice' => 'You received this because a game panel account was created on ' . $brand . '.',
            ]);
    }

    private function politeGreetingName(): ?string
    {
        $first = trim((string) $this->user->name_first);
        $last = trim((string) $this->user->name_last);
        $full = trim($first . ' ' . $last);
        $bad = ['', 'first', 'last', 'first last', 'last first', 'user', 'customer account'];

        if (in_array(strtolower($full), $bad, true) || in_array(strtolower($first), ['first', 'last'], true)) {
            $local = strstr((string) $this->user->email, '@', true) ?: $this->user->username;
            $local = preg_replace('/[0-9._+-]+/', ' ', (string) $local);
            $local = trim($local) ?: null;
            if (!$local) {
                return null;
            }

            return mb_convert_case(explode(' ', $local)[0], MB_CASE_TITLE, 'UTF-8');
        }

        if ($last === '' || strcasecmp($last, 'Account') === 0) {
            return $first;
        }

        return $first;
    }
}
