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

        <link rel="stylesheet" href="/themes/phantom/phantom-panel.css?v=20260814c">
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
                    <button type="button" class="ph-guide-open ph-sftp-warning__guide" type="button">Setup guide</button>
                    <button type="button" class="ph-sftp-warning__close" aria-label="Dismiss" onclick="this.parentElement.remove()">×</button>
                </div>

                <button type="button" id="ph-guide-fab" class="ph-guide-fab ph-guide-open" title="Open setup guide">?</button>

                <div id="ph-setup-guide" class="ph-guide" hidden aria-hidden="true">
                    <div class="ph-guide__backdrop" data-ph-guide-close></div>
                    <div class="ph-guide__panel" role="dialog" aria-modal="true" aria-labelledby="ph-guide-title">
                        <header class="ph-guide__header">
                            <div>
                                <p class="ph-guide__eyebrow">Phantom Hosting</p>
                                <h2 id="ph-guide-title">New server setup guide</h2>
                            </div>
                            <button type="button" class="ph-guide__close" data-ph-guide-close aria-label="Close">×</button>
                        </header>

                        <nav class="ph-guide__tabs" role="tablist">
                            <button type="button" class="ph-guide__tab is-active" data-ph-tab="start" role="tab">Start here</button>
                            <button type="button" class="ph-guide__tab" data-ph-tab="fivem" role="tab">FiveM</button>
                            <button type="button" class="ph-guide__tab" data-ph-tab="bots" role="tab">Discord / bots</button>
                            <button type="button" class="ph-guide__tab" data-ph-tab="files" role="tab">Files &amp; SFTP</button>
                        </nav>

                        <div class="ph-guide__body">
                            <section class="ph-guide__pane is-active" data-ph-pane="start">
                                <ol class="ph-guide__steps">
                                    <li>
                                        <strong>Open your server</strong>
                                        From the dashboard, click the server name. That opens Console, Files, Startup, and Settings.
                                    </li>
                                    <li>
                                        <strong>Fill Startup variables first</strong>
                                        Go to the <em>Startup</em> tab before you press Start. Missing keys (especially FiveM) will make the server die instantly.
                                    </li>
                                    <li>
                                        <strong>Upload your files</strong>
                                        Small single files → File Manager. Folders / large packs → SFTP (see Files &amp; SFTP tab).
                                    </li>
                                    <li>
                                        <strong>Start &amp; watch Console</strong>
                                        Press <em>Start</em>, then read the Console for errors. Restart after you change Startup values.
                                    </li>
                                </ol>
                            </section>

                            <section class="ph-guide__pane" data-ph-pane="fivem" hidden>
                                <ol class="ph-guide__steps">
                                    <li>
                                        <strong>Get your CFX license key</strong>
                                        Create / log in at
                                        <a href="https://keymaster.fivem.net" target="_blank" rel="noopener noreferrer">keymaster.fivem.net</a>
                                        → New Server → copy the key (looks like <code>cfxk_…</code>).
                                    </li>
                                    <li>
                                        <strong>Paste it under Startup</strong>
                                        Server → <em>Startup</em> → <strong>FiveM License Key</strong> (<code>FIVEM_LICENSE</code>). Save. Without this, FXServer exits right away.
                                    </li>
                                    <li>
                                        <strong>Optional Steam key</strong>
                                        <code>STEAM_WEBAPIKEY</code> is optional. Leave as <code>none</code> unless you need Steam auth features.
                                        Keys come from
                                        <a href="https://steamcommunity.com/dev/apikey" target="_blank" rel="noopener noreferrer">steamcommunity.com/dev/apikey</a>.
                                    </li>
                                    <li>
                                        <strong>Players / txAdmin</strong>
                                        Set <strong>Max Players</strong> as needed. Leave <strong>Enable txAdmin</strong> at <code>0</code> unless you intentionally use txAdmin instead of <code>server.cfg</code>.
                                    </li>
                                    <li>
                                        <strong>Where files go</strong>
                                        Upload into the container root (<code>/home/container</code>). Put resources under <code>resources/</code> and keep <code>server.cfg</code> at the root. Prefer SFTP for resource folders.
                                    </li>
                                </ol>
                            </section>

                            <section class="ph-guide__pane" data-ph-pane="bots" hidden>
                                <ol class="ph-guide__steps">
                                    <li>
                                        <strong>Upload your bot code</strong>
                                        Use File Manager for a few files, or SFTP for the whole project folder. Typical root files: <code>index.js</code> / <code>bot.py</code>, <code>package.json</code> / <code>requirements.txt</code>.
                                    </li>
                                    <li>
                                        <strong>Startup / env vars</strong>
                                        Open <em>Startup</em> and set whatever your egg asks for (token, start file, branch, etc.). Put Discord bot tokens in Startup or a <code>.env</code> file — never share them publicly.
                                    </li>
                                    <li>
                                        <strong>Discord token</strong>
                                        Create an application at
                                        <a href="https://discord.com/developers/applications" target="_blank" rel="noopener noreferrer">discord.com/developers/applications</a>
                                        → Bot → Reset Token → copy. Paste into your bot’s config / Startup var, then Start and watch Console.
                                    </li>
                                    <li>
                                        <strong>Install deps</strong>
                                        Many eggs run <code>npm install</code> / <code>pip install</code> on first start. If Startup has a “user upload” / skip-git option, leave it on when you uploaded files yourself.
                                    </li>
                                </ol>
                            </section>

                            <section class="ph-guide__pane" data-ph-pane="files" hidden>
                                <ol class="ph-guide__steps">
                                    <li>
                                        <strong>File Manager (small files only)</strong>
                                        Use <em>Files</em> for single configs, edits, or small uploads. Do <strong>not</strong> drag entire resource / map folders here — browsers and the panel choke on big folder trees.
                                    </li>
                                    <li>
                                        <strong>SFTP for folders</strong>
                                        Server → <em>Settings → SFTP Details</em>. Host is usually <code>panel.phantom-chicken.com</code> (or the IP shown), port <strong>2022</strong>, username as listed. Password = your panel password (or the SFTP password shown).
                                    </li>
                                    <li>
                                        <strong>Clients</strong>
                                        Use WinSCP, FileZilla, Cyberduck, or VS Code SFTP. Connect, then upload into <code>/home/container</code> (that is your SFTP root / <code>.</code>).
                                    </li>
                                    <li>
                                        <strong>After upload</strong>
                                        Refresh Files in the panel to confirm paths. Restart the server so new resources / code load.
                                    </li>
                                </ol>
                            </section>
                        </div>

                        <footer class="ph-guide__footer">
                            <label class="ph-guide__dont">
                                <input type="checkbox" id="ph-guide-dont"> Don’t show this automatically again
                            </label>
                            <button type="button" class="ph-guide__done" data-ph-guide-close>Got it</button>
                        </footer>
                    </div>
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
                        var STORAGE_KEY = 'ph_setup_guide_v1';

                        function syncSftpWarning() {
                            var el = document.getElementById('ph-sftp-warning');
                            if (!el) return;
                            var onFiles = /\/server\/[^/]+\/files/.test(location.pathname);
                            el.classList.toggle('ph-sftp-warning--files', onFiles);
                        }
                        syncSftpWarning();
                        window.addEventListener('popstate', syncSftpWarning);
                        setInterval(syncSftpWarning, 800);

                        var guide = document.getElementById('ph-setup-guide');
                        if (!guide) return;

                        function openGuide() {
                            guide.hidden = false;
                            guide.setAttribute('aria-hidden', 'false');
                            document.documentElement.classList.add('ph-guide-open');
                        }

                        function closeGuide() {
                            var dont = document.getElementById('ph-guide-dont');
                            if (dont && dont.checked) {
                                try { localStorage.setItem(STORAGE_KEY, '1'); } catch (e) {}
                            }
                            guide.hidden = true;
                            guide.setAttribute('aria-hidden', 'true');
                            document.documentElement.classList.remove('ph-guide-open');
                        }

                        document.querySelectorAll('.ph-guide-open').forEach(function (btn) {
                            btn.addEventListener('click', function (e) {
                                e.preventDefault();
                                openGuide();
                            });
                        });
                        guide.querySelectorAll('[data-ph-guide-close]').forEach(function (btn) {
                            btn.addEventListener('click', closeGuide);
                        });
                        document.addEventListener('keydown', function (e) {
                            if (e.key === 'Escape' && !guide.hidden) closeGuide();
                        });

                        guide.querySelectorAll('[data-ph-tab]').forEach(function (tab) {
                            tab.addEventListener('click', function () {
                                var id = tab.getAttribute('data-ph-tab');
                                guide.querySelectorAll('.ph-guide__tab').forEach(function (t) {
                                    t.classList.toggle('is-active', t === tab);
                                });
                                guide.querySelectorAll('.ph-guide__pane').forEach(function (pane) {
                                    var on = pane.getAttribute('data-ph-pane') === id;
                                    pane.classList.toggle('is-active', on);
                                    pane.hidden = !on;
                                });
                            });
                        });

                        try {
                            if (!localStorage.getItem(STORAGE_KEY)) {
                                setTimeout(openGuide, 600);
                            }
                        } catch (e) {
                            setTimeout(openGuide, 600);
                        }
                    })();
                </script>
            @endif
        @show
    </body>
</html>
