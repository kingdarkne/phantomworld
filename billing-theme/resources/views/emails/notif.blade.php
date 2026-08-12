<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <title>{{ $subject ?? config('app.company_name', 'Phantom Hosting') }}</title>
</head>
<body style="margin:0;padding:0;background:#060912;font-family:'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
@php
    $brand = config('app.company_name', 'Phantom Hosting');
    $logo = config('app.logo_file_path', '/img/icon.webp');
    $site = rtrim((string) config('app.url'), '/');
    $hello = $greeting_name ?? null;
    if ($hello) {
        $hello = trim(preg_replace('/\s+/', ' ', (string) $hello));
        if (strcasecmp($hello, 'First Last') === 0 || strcasecmp($hello, 'First') === 0 || strcasecmp($hello, 'Last First') === 0) {
            $hello = null;
        }
    }
@endphp
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#060912;padding:32px 12px;">
    <tr>
        <td align="center">
            <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:560px;background:#0c1220;border:1px solid rgba(46,230,197,0.18);border-radius:16px;overflow:hidden;">
                <tr>
                    <td style="padding:28px 28px 12px;text-align:center;background:linear-gradient(180deg,rgba(46,230,197,0.12),transparent);">
                        <img src="{{ url($logo) }}" alt="{{ $brand }}" width="56" height="56" style="display:inline-block;border-radius:12px;">
                        <div style="margin-top:12px;font-size:20px;font-weight:700;letter-spacing:0.04em;color:#ffffff;">{{ $brand }}</div>
                        <div style="margin-top:4px;font-size:12px;color:#9aa8bc;letter-spacing:0.08em;text-transform:uppercase;">Game &amp; Bot Hosting</div>
                    </td>
                </tr>
                <tr>
                    <td style="padding:8px 28px 0;">
                        <div style="height:1px;background:rgba(46,230,197,0.2);"></div>
                    </td>
                </tr>
                <tr>
                    <td style="padding:24px 28px 8px;color:#e8eef7;">
                        <h1 style="margin:0 0 12px;font-size:22px;line-height:1.3;color:#ffffff;font-weight:700;">{{ $subject ?? 'Message from '.$brand }}</h1>
                        <p style="margin:0 0 16px;font-size:16px;line-height:1.55;color:#c9d4e3;">
                            @if ($hello)
                                Hi {{ $hello }},
                            @else
                                Hi there,
                            @endif
                        </p>
                        <div style="font-size:15px;line-height:1.6;color:#c9d4e3;">
                            {!! nl2br(e($body_message ?? '')) !!}
                        </div>
                        @if (!empty($body_action))
                            <p style="margin:18px 0 0;font-size:15px;line-height:1.6;color:#9aa8bc;">
                                {!! nl2br(e($body_action)) !!}
                            </p>
                        @endif
                    </td>
                </tr>
                @if (!empty($button_url) && !empty($button_text))
                <tr>
                    <td style="padding:24px 28px;" align="center">
                        <a href="{{ $button_url }}" style="display:inline-block;background:#2ee6c5;color:#061018;text-decoration:none;font-weight:700;font-size:15px;padding:12px 28px;border-radius:10px;">
                            {{ $button_text }}
                        </a>
                    </td>
                </tr>
                @endif
                <tr>
                    <td style="padding:8px 28px 24px;color:#7f8b9c;font-size:12px;line-height:1.5;">
                        @if (!empty($notice))
                            <p style="margin:0 0 12px;">{{ $notice }}</p>
                        @endif
                        <p style="margin:0;">
                            You’re receiving this from <strong style="color:#9aa8bc;">{{ $brand }}</strong>.
                            Visit <a href="{{ $site }}" style="color:#2ee6c5;text-decoration:none;">{{ parse_url($site, PHP_URL_HOST) ?: $site }}</a>
                            to manage your account.
                        </p>
                    </td>
                </tr>
                <tr>
                    <td style="padding:16px 28px 24px;border-top:1px solid rgba(154,168,188,0.15);text-align:center;color:#667384;font-size:11px;">
                        &copy; {{ date('Y') }} {{ $brand }}. All rights reserved.
                    </td>
                </tr>
            </table>
        </td>
    </tr>
</table>
</body>
</html>
