<?php

namespace App\Providers;

use App\Support\CustomerName;
use Illuminate\Auth\Notifications\VerifyEmail;
use Illuminate\Foundation\Support\Providers\AuthServiceProvider as ServiceProvider;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Support\Facades\Gate;

class AuthServiceProvider extends ServiceProvider
{
    protected $policies = [];

    public function boot()
    {
        $this->registerPolicies();

        VerifyEmail::toMailUsing(function ($notifiable, $url) {
            $brand = config('app.company_name', 'Phantom Hosting');
            $greeting = CustomerName::greetingFor($notifiable);

            return (new MailMessage)
                ->subject('Verify your ' . $brand . ' account')
                ->view('emails.notif', [
                    'subject' => 'Verify your email',
                    'greeting_name' => $greeting,
                    'body_message' => "Thanks for creating your {$brand} account. Confirm your email so we can finish setup and keep your servers secure.",
                    'body_action' => 'Tap the button below to verify this address. The link expires in about an hour.',
                    'button_text' => 'Verify Email',
                    'button_url' => $url,
                    'notice' => 'If you did not create a ' . $brand . ' account, you can ignore this message.',
                ]);
        });
    }
}
