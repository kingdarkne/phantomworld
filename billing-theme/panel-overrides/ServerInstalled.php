<?php

namespace Pterodactyl\Notifications;

use Pterodactyl\Models\User;
use Illuminate\Bus\Queueable;
use Pterodactyl\Events\Event;
use Pterodactyl\Models\Server;
use Illuminate\Container\Container;
use Pterodactyl\Events\Server\Installed;
use Illuminate\Notifications\Notification;
use Illuminate\Contracts\Queue\ShouldQueue;
use Pterodactyl\Contracts\Core\ReceivesEvents;
use Illuminate\Contracts\Notifications\Dispatcher;
use Illuminate\Notifications\Messages\MailMessage;

class ServerInstalled extends Notification implements ShouldQueue, ReceivesEvents
{
    use Queueable;

    public Server $server;

    public User $user;

    public function handle(Event|Installed $event): void
    {
        $event->server->loadMissing('user');

        $this->server = $event->server;
        $this->user = $event->server->user;

        Container::getInstance()->make(Dispatcher::class)->sendNow($this->user, $this);
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
        $serverUrl = url('/server/' . $this->server->uuidShort);

        return (new MailMessage)
            ->subject('Your server is installed — ' . $this->server->name)
            ->view('emails.phantom', [
                'brand' => $brand,
                'site_url' => $panelUrl,
                'logo_url' => 'https://billing.phantom-chicken.com/img/icon.webp',
                'subject' => 'Your server is ready',
                'greeting_name' => $this->user->name_first ?: $this->user->username,
                'body_message' => "Good news — \"{$this->server->name}\" finished installing and is ready to use on {$brand}.",
                'body_action' => 'Open the panel console to start the server and check logs.',
                'details' => [
                    'Server name' => $this->server->name,
                    'Panel' => $panelUrl,
                    'Billing / renewals' => $billingUrl,
                ],
                'steps_title' => 'Beginner next steps',
                'steps' => [
                    'Open the panel and sign in with your username or email',
                    'Click your server name (or use the button below)',
                    'Press Start if it is stopped, then open Console to watch it boot',
                    'Manage invoices and renewals anytime at ' . $billingUrl,
                ],
                'button_text' => 'Open Server Console',
                'button_url' => $serverUrl,
                'notice' => 'You received this because a server finished installing on ' . $brand . '.',
            ]);
    }
}
