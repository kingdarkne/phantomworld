<!DOCTYPE html>
<html lang="en">
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>{{ config('app.name', 'Phantom Hosting') }}</title>
    <style type="text/css" rel="stylesheet" media="all">
        @media only screen and (max-width: 500px) {
            .button { width: 100% !important; }
        }
    </style>
</head>
@php
$brand = config('app.name', 'Phantom Hosting');
$style = [
    'body' => 'margin:0;padding:0;width:100%;background-color:#060912;',
    'email-wrapper' => 'width:100%;margin:0;padding:32px 12px;background-color:#060912;',
    'email-masthead' => 'padding:28px 24px 12px;text-align:center;background:linear-gradient(180deg,rgba(46,230,197,0.12),transparent);',
    'email-masthead_name' => 'font-size:20px;font-weight:700;letter-spacing:0.04em;color:#ffffff;text-decoration:none;',
    'email-body' => 'width:100%;margin:0;padding:0;background-color:#0c1220;border:1px solid rgba(46,230,197,0.18);border-radius:16px;overflow:hidden;',
    'email-body_inner' => 'width:auto;max-width:560px;margin:0 auto;padding:0;',
    'email-body_cell' => 'padding:28px;',
    'email-footer' => 'width:auto;max-width:560px;margin:0 auto;padding:0;text-align:center;',
    'email-footer_cell' => 'color:#667384;padding:20px;text-align:center;',
    'body_action' => 'width:100%;margin:28px auto;padding:0;text-align:center;',
    'body_sub' => 'margin-top:24px;padding-top:20px;border-top:1px solid rgba(154,168,188,0.15);',
    'anchor' => 'color:#2ee6c5;',
    'header-1' => 'margin-top:0;color:#ffffff;font-size:22px;font-weight:700;text-align:left;',
    'paragraph' => 'margin-top:0;color:#c9d4e3;font-size:15px;line-height:1.6;',
    'paragraph-sub' => 'margin-top:0;color:#7f8b9c;font-size:12px;line-height:1.5;',
    'button' => 'display:inline-block;min-width:180px;padding:12px 24px;background-color:#2ee6c5;border-radius:10px;color:#061018;font-size:15px;font-weight:700;line-height:22px;text-align:center;text-decoration:none;',
    'button--green' => 'background-color:#2ee6c5;color:#061018;',
    'button--red' => 'background-color:#e85d5d;color:#ffffff;',
    'button--blue' => 'background-color:#2ee6c5;color:#061018;',
];
$fontFamily = "font-family:'Segoe UI',Roboto,Helvetica,Arial,sans-serif;";
@endphp
<body style="{{ $style['body'] }}">
<table width="100%" cellpadding="0" cellspacing="0" role="presentation">
    <tr>
        <td style="{{ $style['email-wrapper'] }}" align="center">
            <table style="{{ $style['email-body_inner'] }}" width="560" cellpadding="0" cellspacing="0" role="presentation">
                <tr>
                    <td style="{{ $style['email-body'] }}">
                        <table width="100%" cellpadding="0" cellspacing="0" role="presentation">
                            <tr>
                                <td style="{{ $fontFamily }} {{ $style['email-masthead'] }}">
                                    <a style="{{ $style['email-masthead_name'] }}" href="{{ url('/') }}" target="_blank" rel="noopener">{{ $brand }}</a>
                                    <div style="margin-top:6px;font-size:12px;color:#9aa8bc;letter-spacing:0.08em;text-transform:uppercase;">Game Panel</div>
                                </td>
                            </tr>
                            <tr>
                                <td style="{{ $fontFamily }} {{ $style['email-body_cell'] }}">
                                    <h1 style="{{ $style['header-1'] }}">
                                        @if (! empty($greeting))
                                            {{ $greeting }}
                                        @else
                                            @if (($level ?? '') == 'error')
                                                Something went wrong
                                            @else
                                                Hi there,
                                            @endif
                                        @endif
                                    </h1>

                                    @foreach ($introLines as $line)
                                        <p style="{{ $style['paragraph'] }}">{{ $line }}</p>
                                    @endforeach

                                    @isset($actionText)
                                        <table style="{{ $style['body_action'] }}" align="center" width="100%" cellpadding="0" cellspacing="0" role="presentation">
                                            <tr>
                                                <td align="center">
                                                    @php
                                                        switch ($level ?? 'info') {
                                                            case 'success': $actionColor = 'button--green'; break;
                                                            case 'error': $actionColor = 'button--red'; break;
                                                            default: $actionColor = 'button--blue';
                                                        }
                                                    @endphp
                                                    <a href="{{ $actionUrl }}" style="{{ $fontFamily }} {{ $style['button'] }} {{ $style[$actionColor] }}" class="button" target="_blank" rel="noopener">
                                                        {{ $actionText }}
                                                    </a>
                                                </td>
                                            </tr>
                                        </table>
                                    @endisset

                                    @foreach ($outroLines as $line)
                                        <p style="{{ $style['paragraph'] }}">{{ $line }}</p>
                                    @endforeach

                                    <p style="{{ $style['paragraph'] }}">
                                        Thanks,<br>The {{ $brand }} team
                                    </p>

                                    @isset($actionText)
                                        <table style="{{ $style['body_sub'] }}" role="presentation">
                                            <tr>
                                                <td style="{{ $fontFamily }}">
                                                    <p style="{{ $style['paragraph-sub'] }}">
                                                        If the button does not work, copy and paste this URL into your browser:
                                                    </p>
                                                    <p style="{{ $style['paragraph-sub'] }}">
                                                        <a style="{{ $style['anchor'] }}" href="{{ $actionUrl }}" target="_blank" rel="noopener">{{ $actionUrl }}</a>
                                                    </p>
                                                </td>
                                            </tr>
                                        </table>
                                    @endisset
                                </td>
                            </tr>
                        </table>
                    </td>
                </tr>
                <tr>
                    <td style="{{ $fontFamily }} {{ $style['email-footer_cell'] }}">
                        <p style="{{ $style['paragraph-sub'] }}">
                            &copy; {{ date('Y') }}
                            <a style="{{ $style['anchor'] }}" href="{{ url('/') }}" target="_blank" rel="noopener">{{ $brand }}</a>.
                            All rights reserved.
                        </p>
                    </td>
                </tr>
            </table>
        </td>
    </tr>
</table>
</body>
</html>
