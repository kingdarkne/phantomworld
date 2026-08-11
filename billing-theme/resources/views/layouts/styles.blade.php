<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="icon" href="{{ config('app.favicon_file_path') }}">

{{-- Preload display fonts (non-blocking) --}}
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="preload" as="style" href="https://fonts.googleapis.com/css2?family=Sora:wght@400;500;600&family=Syne:wght@600;700;800&display=swap" onload="this.onload=null;this.rel='stylesheet'">
<noscript><link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Sora:wght@400;500;600&family=Syne:wght@600;700;800&display=swap"></noscript>

{{-- Critical theme CSS --}}
<link rel="stylesheet" href="/dist/css/adminlte.min.css">
<link rel="stylesheet" href="/dist/css/phantom-theme.css?v=20260811">

{{-- Defer heavy icon/toast CSS via JS (existing lazy loader) --}}
<noscript>
    <link rel="stylesheet" href="/plugins/fontawesome-free/css/all.min.css">
    <link rel="stylesheet" href="/plugins/toastr/toastr.min.css">
</noscript>

@if (config('app.google_analytics_id'))
    <script async src="https://www.googletagmanager.com/gtag/js?id={{ config('app.google_analytics_id') }}"></script>
    <script>
        window.dataLayer = window.dataLayer || [];
        function gtag(){dataLayer.push(arguments);}
        gtag('js', new Date());
        gtag('config', '{{ config('app.google_analytics_id') }}');
    </script>
@endif
