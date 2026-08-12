<?php

namespace App\Support;

use App\Models\Setting;

/**
 * Shared copy + URLs for customer emails (beginner-friendly login help).
 */
class EmailGuide
{
    public static function brand(): string
    {
        return (string) (config('app.company_name') ?: config('app.name') ?: 'Phantom Hosting');
    }

    public static function billingUrl(): string
    {
        return rtrim((string) config('app.url'), '/') ?: 'https://billing.phantom-chicken.com';
    }

    public static function panelUrl(): string
    {
        $fromSettings = Setting::where('key', 'panel_url')->value('value');

        return rtrim((string) ($fromSettings ?: 'https://panel.phantom-chicken.com'), '/');
    }

    public static function billingDashUrl(): string
    {
        try {
            return url()->route('client.dash');
        } catch (\Throwable $e) {
            return self::billingUrl() . '/my';
        }
    }

    /**
     * Beginner steps for the billing storefront (orders, invoices, renewals).
     *
     * @return list<string>
     */
    public static function billingLoginSteps(?string $email = null): array
    {
        $emailHint = $email ? " ({$email})" : '';

        return [
            'Open ' . self::billingUrl() . ' in your browser',
            'Click Login at the top of the page',
            'Enter your email' . $emailHint . ' and your billing password',
            'You will land on your dashboard — manage servers, invoices, and renewals there',
        ];
    }

    /**
     * Beginner steps for the game panel (console, start/stop, files).
     *
     * @return list<string>
     */
    public static function panelLoginSteps(?string $username = null, ?string $email = null): array
    {
        $who = $username ?: ($email ?: 'your username or email');

        return [
            'Open ' . self::panelUrl() . ' in your browser',
            'Sign in with ' . $who . ' and your panel password',
            'Click your server name to open the console and file manager',
            'Use Start / Restart from the console when your game or bot is ready',
        ];
    }

    /**
     * Short dual-site explainer for welcome emails.
     */
    public static function twoSitesBlurb(): string
    {
        $brand = self::brand();

        return "{$brand} uses two sites:\n"
            . '• Billing (' . self::billingUrl() . ') — account, plans, invoices, renewals' . "\n"
            . '• Game panel (' . self::panelUrl() . ') — start/stop servers, console, files';
    }
}
