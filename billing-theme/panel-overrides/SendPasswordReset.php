<?php

namespace Pterodactyl\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;

class SendPasswordReset extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(public string $token)
    {
    }

    public function via(): array
    {
        return ['mail'];
    }

    public function toMail(mixed $notifiable): MailMessage
    {
        $brand = config('app.name', 'Phantom Hosting');
        $panelUrl = rtrim((string) config('app.url'), '/') ?: 'https://panel.phantom-chicken.com';
        $resetUrl = url('/auth/password/reset/' . $this->token . '?email=' . urlencode($notifiable->email));

        return (new MailMessage)
            ->subject('Reset your ' . $brand . ' panel password')
            ->view('emails.phantom', [
                'brand' => $brand,
                'site_url' => $panelUrl,
                'logo_url' => 'https://billing.phantom-chicken.com/img/icon.webp',
                'subject' => 'Reset your panel password',
                'greeting_name' => null,
                'body_message' => "We received a request to reset the password for your {$brand} game panel account.",
                'body_action' => 'If you did not ask for this, you can ignore the email — your password will stay the same.',
                'details' => [
                    'Panel' => $panelUrl,
                    'Account email' => $notifiable->email,
                ],
                'steps_title' => 'How to reset',
                'steps' => [
                    'Tap Reset Password below',
                    'Choose a new password and confirm it',
                    'Sign in at ' . $panelUrl . ' with your username or email + new password',
                ],
                'button_text' => 'Reset Password',
                'button_url' => $resetUrl,
                'notice' => 'For security, this link expires after a short time.',
            ]);
    }
}
