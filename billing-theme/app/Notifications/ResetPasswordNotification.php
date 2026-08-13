<?php

namespace App\Notifications;

use App\Support\CustomerName;
use App\Support\EmailGuide;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class ResetPasswordNotification extends Notification implements ShouldQueue
{
    use Queueable;

    protected $token;

    public function __construct($token)
    {
        $this->token = $token;
    }

    public function via($notifiable)
    {
        return ['mail'];
    }

    public function toMail($notifiable)
    {
        $brand = EmailGuide::brand();
        $resetUrl = url()->route('client.reset', ['token' => $this->token]);

        return (new MailMessage)->subject('Reset your ' . $brand . ' password')->view('emails.notif', [
            'subject' => 'Password reset',
            'greeting_name' => CustomerName::greetingFor($notifiable),
            'body_message' => "We received a request to reset the password for your {$brand} billing account.",
            'body_action' => 'If you did not ask for this, ignore the email — your password will stay the same.',
            'details' => [
                'Billing site' => EmailGuide::billingUrl(),
                'Account email' => (string) ($notifiable->email ?? ''),
            ],
            'steps_title' => 'How to reset',
            'steps' => [
                'Tap Reset Password below',
                'Enter your email, choose a new password, and confirm it',
                'Return to ' . EmailGuide::billingUrl() . ' and click Login with the new password',
            ],
            'button_text' => 'Reset Password',
            'button_url' => $resetUrl,
            'notice' => 'For security, this link will expire after a short time.',
        ]);
    }

    public function toArray($notifiable)
    {
        return [];
    }
}
