<?php

namespace App\Support;

class CustomerName
{
    /**
     * Build a polite first/last name pair for billing + panel accounts.
     *
     * @return array{0:string,1:string,2:string} [first, last, greeting]
     */
    public static function from(string $email, ?string $first = null, ?string $last = null): array
    {
        $first = self::clean($first);
        $last = self::clean($last);

        if (self::isPlaceholder($first) && self::isPlaceholder($last)) {
            [$first, $last] = self::fromEmail($email);
        } elseif ($first && !$last) {
            $last = 'Account';
        } elseif (!$first && $last) {
            $first = $last;
            $last = 'Account';
        }

        if (self::isPlaceholder($first)) {
            $first = 'there';
        }
        if (self::isPlaceholder($last) || strcasecmp($last, 'there') === 0) {
            $last = 'Account';
        }

        // Panel requires real-looking names; avoid greeting "there Account"
        $greeting = ($first === 'there') ? null : $first;
        if ($greeting && !self::isPlaceholder($last) && strcasecmp($last, 'Account') !== 0) {
            $greeting = trim($first . ' ' . $last);
        }

        // For panel API, never send "there"
        $panelFirst = ($first === 'there') ? self::fromEmail($email)[0] : $first;
        $panelLast = $last;

        return [$panelFirst, $panelLast, $greeting ?: $panelFirst];
    }

    public static function greetingFor($client): ?string
    {
        if (!$client) {
            return null;
        }

        $email = (string) ($client->email ?? '');
        [, , $greeting] = self::from(
            $email,
            $client->first_name ?? null,
            $client->last_name ?? null
        );

        return $greeting;
    }

    private static function fromEmail(string $email): array
    {
        $local = strstr($email, '@', true) ?: 'customer';
        $local = preg_replace('/^guest[_-]*/i', '', $local) ?: 'customer';
        $local = str_replace(['.', '_', '-', '+'], ' ', $local);
        $local = preg_replace('/\d+/', ' ', $local);
        $parts = array_values(array_filter(preg_split('/\s+/', trim($local)) ?: []));

        if (!$parts) {
            return ['Customer', 'Account'];
        }

        $first = self::clean($parts[0]) ?: 'Customer';
        $last = isset($parts[1]) ? (self::clean($parts[1]) ?: 'Account') : 'Account';

        return [$first, $last];
    }

    private static function clean(?string $value): ?string
    {
        if ($value === null) {
            return null;
        }
        $value = trim(preg_replace('/\s+/', ' ', $value));
        if ($value === '') {
            return null;
        }
        // Title-case simple names
        $value = implode('-', array_map(function ($chunk) {
            return mb_convert_case($chunk, MB_CASE_TITLE, 'UTF-8');
        }, explode('-', $value)));

        return $value;
    }

    private static function isPlaceholder(?string $value): bool
    {
        if ($value === null || $value === '') {
            return true;
        }
        $v = strtolower(trim($value));

        return in_array($v, ['first', 'last', 'first last', 'last first', 'user', 'name', 'null', 'undefined'], true);
    }
}
