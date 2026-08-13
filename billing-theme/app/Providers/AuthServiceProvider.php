<?php

namespace App\Providers;

use App\Support\CustomerName;
use App\Support\EmailGuide;
use Illuminate\Auth\Notifications\VerifyEmail;
use Illuminate\Foundation\Support\Providers\AuthServiceProvider as ServiceProvider;
use Illuminate\Notifications\Messages\MailMessage;

class AuthServiceProvider extends ServiceProvider
{
    protected $policies = [];

    public function boot()
    {
        $this->registerPolicies();

        VerifyEmail::toMailUsing(function ($notifiable, $url) {
            $brand = EmailGuide::brand();
            $greeting = CustomerName::greetingFor($notifiable);
            $email = (string) ($notifiable->email ?? '');

            return (new MailMessage)
                ->subject('Verify your ' . $brand . ' account')
                ->view('emails.notif', [
                    'subject' => 'Verify your email',
                    'greeting_name' => $greeting,
                    'body_message' => "Thanks for joining {$brand}. Confirm this email so we can finish setup and keep your servers secure.\n\n"
                        . "This link expires in about one hour.",
                    'body_action' => 'After you verify, use Login on the billing site with this email and the password you chose.',
                    'details' => array_filter([
                        'Billing site' => EmailGuide::billingUrl(),
                        'Your email' => $email ?: null,
                        'Next step' => 'Tap Verify Email below, then log in at the billing site',
                    ]),
                    'steps_title' => 'Quick start after verifying',
                    'steps' => [
                        'Tap the Verify Email button below (opens your billing site)',
                        'You will be signed in and sent to your dashboard',
                        'Order a plan when ready — your game panel login arrives in the welcome email',
                    ],
                    'button_text' => 'Verify Email',
                    'button_url' => $url,
                    'notice' => 'If you did not create a ' . $brand . ' account, you can ignore this message.',
                ]);
        });
    }
}
