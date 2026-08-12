<?php

namespace App\Notifications;

use App\Support\CustomerName;
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
        $brand = config('app.company_name', 'Phantom Hosting');

        return (new MailMessage)->subject('Reset your ' . $brand . ' password')->view('emails.notif', [
            'subject' => 'Password reset',
            'greeting_name' => CustomerName::greetingFor($notifiable),
            'body_message' => "We received a request to reset the password for your {$brand} account.",
            'body_action' => 'Use the button below to choose a new password. If you did not ask for this, you can ignore the email.',
            'button_text' => 'Reset Password',
            'button_url' => url()->route('client.reset', ['token' => $this->token]),
            'notice' => 'For security, this link will expire after a short time.',
        ]);
    }

    public function toArray($notifiable)
    {
        return [];
    }
}
