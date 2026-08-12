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
        $greeting = $this->politeGreeting();

        $message = (new MailMessage())
            ->subject('Welcome to ' . $brand)
            ->greeting($greeting)
            ->line('Your game panel account is ready on ' . $brand . '.')
            ->line('Panel login email: ' . $this->user->email)
            ->line('Panel username: ' . $this->user->username)
            ->line('Use the password from your Phantom Hosting welcome email, or set one with the button below if you were asked to finish setup.');

        if (!is_null($this->token)) {
            return $message->action(
                'Finish Panel Setup',
                url('/auth/password/reset/' . $this->token . '?email=' . urlencode($this->user->email))
            );
        }

        return $message->action('Open Game Panel', url('/auth/login'));
    }

    private function politeGreeting(): string
    {
        $first = trim((string) $this->user->name_first);
        $last = trim((string) $this->user->name_last);
        $full = trim($first . ' ' . $last);
        $bad = ['', 'first', 'last', 'first last', 'last first', 'user', 'customer account'];

        if (in_array(strtolower($full), $bad, true) || in_array(strtolower($first), ['first', 'last'], true)) {
            $local = strstr((string) $this->user->email, '@', true) ?: $this->user->username;
            $local = preg_replace('/[0-9._+-]+/', ' ', (string) $local);
            $local = trim($local) ?: 'there';
            $name = mb_convert_case(explode(' ', $local)[0], MB_CASE_TITLE, 'UTF-8');

            return 'Hi ' . $name . ',';
        }

        if ($last === '' || strcasecmp($last, 'Account') === 0) {
            return 'Hi ' . $first . ',';
        }

        return 'Hi ' . $first . ',';
    }
}
