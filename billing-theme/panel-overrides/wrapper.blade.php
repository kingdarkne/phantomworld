<!DOCTYPE html>
<html lang="en">
    <head>
        <title>{{ config('app.name', 'Phantom Hosting') }}</title>

        @section('meta')
            <meta charset="utf-8">
            <meta http-equiv="X-UA-Compatible" content="IE=edge">
            <meta content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" name="viewport">
            <meta name="csrf-token" content="{{ csrf_token() }}">
            <meta name="robots" content="noindex">
            <link rel="apple-touch-icon" sizes="180x180" href="/favicons/apple-touch-icon.png">
            <link rel="icon" type="image/png" href="/favicons/favicon-32x32.png" sizes="32x32">
            <link rel="icon" type="image/png" href="/favicons/favicon-16x16.png" sizes="16x16">
            <link rel="icon" type="image/webp" href="/img/icon.webp">
            <link rel="manifest" href="/favicons/manifest.json">
            <link rel="mask-icon" href="/favicons/safari-pinned-tab.svg" color="#2ee6c5">
            <link rel="shortcut icon" href="/favicons/favicon.ico">
            <meta name="msapplication-config" content="/favicons/browserconfig.xml">
            <meta name="theme-color" content="#060912">
            <meta name="apple-mobile-web-app-title" content="Phantom Hosting">
        @show

        @section('user-data')
            @if(!is_null(Auth::user()))
                <script>
                    window.PhantomUser = {!! json_encode(Auth::user()->toVueObject()) !!};
                </script>
            @endif
            @if(!empty($siteConfiguration))
                <script>
                    window.SiteConfiguration = {!! json_encode($siteConfiguration) !!};
                </script>
            @endif
        @show

        @yield('assets')

        @include('layouts.scripts')

        <link rel="stylesheet" href="/themes/phantom/phantom-panel.css?v=20260814b">
    </head>
    <body class="{{ $css['body'] ?? 'bg-neutral-900' }}">
        @section('content')
            @if (request()->is('auth/*') || request()->is('auth'))
                <div class="ph-login-brand" style="position:fixed;top:28px;left:0;right:0;z-index:50;text-align:center;pointer-events:none;">
                    <img src="/img/icon.webp" alt="Phantom Hosting" width="56" height="56" style="border-radius:14px;border:1px solid rgba(46,230,197,0.35);box-shadow:0 12px 40px rgba(0,0,0,0.45);">
                    <div style="margin-top:12px;font-family:Syne,Segoe UI,sans-serif;font-weight:800;letter-spacing:0.08em;color:#fff;font-size:18px;">PHANTOM HOSTING</div>
                    <div style="margin-top:4px;font-family:Sora,Segoe UI,sans-serif;font-size:11px;letter-spacing:0.16em;text-transform:uppercase;color:#9aa8bc;">Game Panel</div>
                </div>
            @endif

            @if(!is_null(Auth::user()) && !(request()->is('auth/*') || request()->is('auth')))
                <div id="ph-sftp-warning" class="ph-sftp-warning" role="status">
                    <strong>Upload tip:</strong>
                    Use <strong>SFTP</strong> for folders and large packs (File Manager upload is for small files only).
                    Open your server → <strong>Settings → SFTP Details</strong> (port usually <strong>2022</strong>).
                    <button type="button" class="ph-sftp-warning__close" aria-label="Dismiss" onclick="this.parentElement.remove()">×</button>
                </div>
            @endif

            @yield('above-container')
            @yield('container')
            @yield('below-container')
        @show
        @section('scripts')
            {!! $asset->js('main.js') !!}
            @if(!is_null(Auth::user()))
                <script>
                    (function () {
                        function syncSftpWarning() {
                            var el = document.getElementById('ph-sftp-warning');
                            if (!el) return;
                            var onFiles = /\/server\/[^/]+\/files/.test(location.pathname);
                            el.classList.toggle('ph-sftp-warning--files', onFiles);
                        }
                        syncSftpWarning();
                        window.addEventListener('popstate', syncSftpWarning);
                        setInterval(syncSftpWarning, 800);
                    })();
                </script>
            @endif
        @show
    </body>
</html>
