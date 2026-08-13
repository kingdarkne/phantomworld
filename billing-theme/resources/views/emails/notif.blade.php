<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <title>{{ $subject ?? config('app.company_name', 'Phantom Hosting') }}</title>
</head>
<body style="margin:0;padding:0;background:#05080f;font-family:Georgia,'Times New Roman',serif;">
@php
    $brand = $brand ?? config('app.company_name', 'Phantom Hosting');
    $logo = $logo ?? config('app.logo_file_path', '/img/icon.webp');
    $site = rtrim((string) ($site_url ?? config('app.url')), '/');
    $logoSrc = $logo_url ?? (str_starts_with((string) $logo, 'http') ? $logo : url($logo));
    $hello = $greeting_name ?? null;
    if ($hello) {
        $hello = trim(preg_replace('/\s+/', ' ', (string) $hello));
        if (in_array(strtolower($hello), ['first last', 'first', 'last first', 'there'], true)) {
            $hello = null;
        }
    }
    $details = is_array($details ?? null) ? $details : [];
    $steps = is_array($steps ?? null) ? $steps : [];
    $stepsTitle = $steps_title ?? 'How to log in';
    $buttonUrl = $button_url ?? null;
    $buttonText = $button_text ?? null;
@endphp
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#05080f;padding:40px 14px;">
    <tr>
        <td align="center">
            <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:580px;background:#0b1220;border:1px solid rgba(46,230,197,0.22);border-radius:18px;overflow:hidden;box-shadow:0 18px 50px rgba(0,0,0,0.45);">
                {{-- Header --}}
                <tr>
                    <td style="padding:0;background:linear-gradient(135deg,#0d1a2a 0%,#0b1220 55%,#0a1f1c 100%);">
                        <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
                            <tr>
                                <td style="height:4px;background:linear-gradient(90deg,#2ee6c5,#5eead4,#2ee6c5);font-size:0;line-height:0;">&nbsp;</td>
                            </tr>
                            <tr>
                                <td style="padding:30px 32px 22px;text-align:center;font-family:'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
                                    <img src="{{ $logoSrc }}" alt="{{ $brand }}" width="64" height="64" style="display:inline-block;border-radius:14px;border:1px solid rgba(46,230,197,0.35);">
                                    <div style="margin-top:14px;font-size:22px;font-weight:700;letter-spacing:0.06em;color:#ffffff;">{{ $brand }}</div>
                                    <div style="margin-top:6px;font-size:11px;color:#8fa0b5;letter-spacing:0.14em;text-transform:uppercase;">Game &amp; Bot Hosting</div>
                                </td>
                            </tr>
                        </table>
                    </td>
                </tr>

                {{-- Body --}}
                <tr>
                    <td style="padding:8px 32px 0;font-family:'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
                        <div style="height:1px;background:rgba(46,230,197,0.18);"></div>
                    </td>
                </tr>
                <tr>
                    <td style="padding:26px 32px 8px;font-family:'Segoe UI',Roboto,Helvetica,Arial,sans-serif;color:#e8eef7;">
                        <h1 style="margin:0 0 10px;font-size:24px;line-height:1.25;color:#ffffff;font-weight:700;letter-spacing:-0.02em;">
                            {{ $subject ?? 'Message from '.$brand }}
                        </h1>
                        <p style="margin:0 0 18px;font-size:16px;line-height:1.55;color:#c9d4e3;">
                            @if ($hello)
                                Hi {{ $hello }},
                            @else
                                Hi there,
                            @endif
                        </p>
                        <div style="font-size:15px;line-height:1.7;color:#c9d4e3;">
                            {!! nl2br(e($body_message ?? '')) !!}
                        </div>
                        @if (!empty($body_action))
                            <p style="margin:18px 0 0;font-size:15px;line-height:1.65;color:#9aa8bc;">
                                {!! nl2br(e($body_action)) !!}
                            </p>
                        @endif
                    </td>
                </tr>

                {{-- Credential / detail card --}}
                @if (count($details))
                <tr>
                    <td style="padding:18px 32px 6px;font-family:'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
                        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#071018;border:1px solid rgba(46,230,197,0.16);border-radius:12px;">
                            <tr>
                                <td style="padding:16px 18px;">
                                    @foreach ($details as $label => $value)
                                        <div style="margin:{{ $loop->first ? '0' : '12px' }} 0 0;">
                                            <div style="font-size:11px;letter-spacing:0.08em;text-transform:uppercase;color:#7f8b9c;margin-bottom:3px;">{{ $label }}</div>
                                            <div style="font-size:15px;color:#e8eef7;font-weight:600;word-break:break-all;">{{ $value }}</div>
                                        </div>
                                    @endforeach
                                </td>
                            </tr>
                        </table>
                    </td>
                </tr>
                @endif

                {{-- Beginner steps --}}
                @if (count($steps))
                <tr>
                    <td style="padding:18px 32px 6px;font-family:'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
                        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:linear-gradient(180deg,rgba(46,230,197,0.08),rgba(46,230,197,0.02));border:1px solid rgba(46,230,197,0.2);border-radius:12px;">
                            <tr>
                                <td style="padding:16px 18px;">
                                    <div style="font-size:13px;font-weight:700;letter-spacing:0.06em;text-transform:uppercase;color:#2ee6c5;margin-bottom:12px;">{{ $stepsTitle }}</div>
                                    @foreach ($steps as $i => $step)
                                        <p style="margin:{{ $i === 0 ? '0' : '10px' }} 0 0;font-size:14px;line-height:1.55;color:#c9d4e3;">
                                            <span style="display:inline-block;min-width:22px;color:#2ee6c5;font-weight:700;">{{ $i + 1 }}.</span>
                                            {{ $step }}
                                        </p>
                                    @endforeach
                                </td>
                            </tr>
                        </table>
                    </td>
                </tr>
                @endif

                {{-- CTA --}}
                @if (!empty($buttonUrl) && !empty($buttonText))
                <tr>
                    <td style="padding:26px 32px 10px;font-family:'Segoe UI',Roboto,Helvetica,Arial,sans-serif;" align="center">
                        <a href="{{ $buttonUrl }}" style="display:inline-block;background:#2ee6c5;color:#061018;text-decoration:none;font-weight:700;font-size:15px;padding:14px 30px;border-radius:12px;letter-spacing:0.01em;">
                            {{ $buttonText }}
                        </a>
                        <p style="margin:14px 0 0;font-size:12px;line-height:1.5;color:#7f8b9c;word-break:break-all;">
                            Button not working? Copy this link:<br>
                            <a href="{{ $buttonUrl }}" style="color:#2ee6c5;text-decoration:none;">{{ $buttonUrl }}</a>
                        </p>
                    </td>
                </tr>
                @endif

                {{-- Notice / footer --}}
                <tr>
                    <td style="padding:12px 32px 24px;font-family:'Segoe UI',Roboto,Helvetica,Arial,sans-serif;color:#7f8b9c;font-size:12px;line-height:1.55;">
                        @if (!empty($notice))
                            <p style="margin:0 0 12px;">{{ $notice }}</p>
                        @endif
                        <p style="margin:0;">
                            You’re receiving this from <strong style="color:#9aa8bc;">{{ $brand }}</strong>.
                            Visit <a href="{{ $site }}" style="color:#2ee6c5;text-decoration:none;">{{ parse_url($site, PHP_URL_HOST) ?: $site }}</a>
                            anytime.
                        </p>
                    </td>
                </tr>
                <tr>
                    <td style="padding:16px 32px 26px;border-top:1px solid rgba(154,168,188,0.12);text-align:center;font-family:'Segoe UI',Roboto,Helvetica,Arial,sans-serif;color:#5c6b7c;font-size:11px;">
                        &copy; {{ date('Y') }} {{ $brand }}. All rights reserved.
                    </td>
                </tr>
            </table>
        </td>
    </tr>
</table>
</body>
</html>
