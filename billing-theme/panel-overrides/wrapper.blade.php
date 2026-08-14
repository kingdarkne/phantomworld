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

        <link rel="stylesheet" href="/themes/phantom/phantom-panel.css?v=20260814d">
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
                    <button type="button" class="ph-guide-open ph-sftp-warning__guide">Setup guide</button>
                    <button type="button" class="ph-sftp-warning__close" aria-label="Dismiss" onclick="this.parentElement.remove()">×</button>
                </div>

                <button type="button" id="ph-guide-fab" class="ph-guide-fab ph-guide-open" title="Open setup guide">?</button>

                <div id="ph-setup-guide" class="ph-guide" hidden aria-hidden="true">
                    <div class="ph-guide__backdrop" data-ph-guide-close></div>
                    <div class="ph-guide__panel" role="dialog" aria-modal="true" aria-labelledby="ph-guide-title">
                        <header class="ph-guide__header">
                            <div>
                                <p class="ph-guide__eyebrow">Phantom Hosting</p>
                                <h2 id="ph-guide-title">Server setup guide</h2>
                                <p id="ph-guide-egg-label" class="ph-guide__egg-label">Detecting your server egg…</p>
                            </div>
                            <button type="button" class="ph-guide__close" data-ph-guide-close aria-label="Close">×</button>
                        </header>

                        <nav class="ph-guide__tabs" role="tablist" id="ph-guide-tabs">
                            <button type="button" class="ph-guide__tab is-active" data-ph-tab="start" role="tab">Start here</button>
                            <button type="button" class="ph-guide__tab" data-ph-tab="egg" role="tab" id="ph-guide-egg-tab">Egg setup</button>
                            <button type="button" class="ph-guide__tab" data-ph-tab="files" role="tab">Files &amp; SFTP</button>
                        </nav>

                        <div class="ph-guide__body">
                            <section class="ph-guide__pane is-active" data-ph-pane="start">
                                <ol class="ph-guide__steps" id="ph-guide-start-steps">
                                    <li>
                                        <strong>Open your server</strong>
                                        From the dashboard, click the server name. That opens Console, Files, Startup, and Settings.
                                    </li>
                                    <li>
                                        <strong>Fill Startup variables first</strong>
                                        Go to the <em>Startup</em> tab before you press Start. Required keys depend on your egg (shown in the next tab).
                                    </li>
                                    <li>
                                        <strong>Upload your files</strong>
                                        Small single files → File Manager. Folders / large packs → SFTP (see Files &amp; SFTP).
                                    </li>
                                    <li>
                                        <strong>Start &amp; watch Console</strong>
                                        Press <em>Start</em>, then read the Console for errors. Restart after you change Startup values.
                                    </li>
                                </ol>
                            </section>

                            {{-- Egg-specific panes; JS shows the one matching the server egg --}}
                            <section class="ph-guide__pane" data-ph-pane="egg" data-ph-egg="fivem" hidden>
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
                                        <code>STEAM_WEBAPIKEY</code> is optional. Leave as <code>none</code> unless you need Steam auth.
                                        Keys:
                                        <a href="https://steamcommunity.com/dev/apikey" target="_blank" rel="noopener noreferrer">steamcommunity.com/dev/apikey</a>.
                                    </li>
                                    <li>
                                        <strong>Players / txAdmin</strong>
                                        Set <strong>Max Players</strong> as needed. Leave <strong>Enable txAdmin</strong> at <code>0</code> unless you intentionally use txAdmin instead of <code>server.cfg</code>.
                                    </li>
                                    <li>
                                        <strong>Where files go</strong>
                                        Upload into <code>/home/container</code>. Put resources under <code>resources/</code> and keep <code>server.cfg</code> at the root. Use SFTP for resource folders.
                                    </li>
                                </ol>
                            </section>

                            <section class="ph-guide__pane" data-ph-pane="egg" data-ph-egg="discord" hidden>
                                <ol class="ph-guide__steps">
                                    <li>
                                        <strong>Upload your bot code</strong>
                                        Use File Manager for a few files, or SFTP for the whole project. Typical root: <code>index.js</code> / <code>bot.py</code>, <code>package.json</code> / <code>requirements.txt</code>.
                                    </li>
                                    <li>
                                        <strong>Startup: User Uploaded Files</strong>
                                        On <em>Startup</em>, set <code>USER_UPLOAD</code> to <code>1</code> if you uploaded files yourself (skip git clone). Set <code>MAIN_FILE</code> / <code>PY_FILE</code> to your entry script.
                                    </li>
                                    <li>
                                        <strong>Discord bot token</strong>
                                        Create an app at
                                        <a href="https://discord.com/developers/applications" target="_blank" rel="noopener noreferrer">discord.com/developers/applications</a>
                                        → Bot → Reset Token. Put the token in your bot’s config or <code>.env</code> — never share it.
                                    </li>
                                    <li>
                                        <strong>Optional Git clone</strong>
                                        If you prefer Git: set <code>GIT_ADDRESS</code>, set <code>USER_UPLOAD</code> to <code>0</code>, then reinstall / start so the egg can clone.
                                    </li>
                                    <li>
                                        <strong>Start &amp; invite</strong>
                                        Press Start and watch Console for “ready / logged in”. Invite the bot with the OAuth2 URL Generator (bot + applications.commands scopes as needed).
                                    </li>
                                </ol>
                            </section>

                            <section class="ph-guide__pane" data-ph-pane="egg" data-ph-egg="node" hidden>
                                <ol class="ph-guide__steps">
                                    <li>
                                        <strong>Upload your Node app</strong>
                                        Put your project in the container root via SFTP (folders) or File Manager (small files). Keep <code>package.json</code> at the root when possible.
                                    </li>
                                    <li>
                                        <strong>Startup variables</strong>
                                        <em>Startup</em> → set <code>MAIN_FILE</code> (e.g. <code>index.js</code>), <code>USER_UPLOAD=1</code> if you uploaded files, and optional <code>NODE_PACKAGES</code> / <code>NODE_ARGS</code>.
                                    </li>
                                    <li>
                                        <strong>Secrets</strong>
                                        Put API tokens in Startup vars or a <code>.env</code> file. Do not commit secrets to public repos.
                                    </li>
                                    <li>
                                        <strong>Start</strong>
                                        Press Start. The egg runs <code>npm install</code> when <code>package.json</code> exists, then launches your main file. Check Console for errors.
                                    </li>
                                </ol>
                            </section>

                            <section class="ph-guide__pane" data-ph-pane="egg" data-ph-egg="python" hidden>
                                <ol class="ph-guide__steps">
                                    <li>
                                        <strong>Upload your Python app</strong>
                                        Upload the project (prefer SFTP for folders). Keep your entry script and <code>requirements.txt</code> at the root when possible.
                                    </li>
                                    <li>
                                        <strong>Startup variables</strong>
                                        <em>Startup</em> → set <code>PY_FILE</code> (e.g. <code>bot.py</code> / <code>main.py</code>), <code>REQUIREMENTS_FILE</code> if needed, and <code>USER_UPLOAD=1</code> when you uploaded files.
                                    </li>
                                    <li>
                                        <strong>Secrets</strong>
                                        Store tokens in Startup or <code>.env</code>. Restart after changing them.
                                    </li>
                                    <li>
                                        <strong>Start</strong>
                                        Press Start and watch Console. Deps install from requirements on start for most eggs.
                                    </li>
                                </ol>
                            </section>

                            <section class="ph-guide__pane" data-ph-pane="egg" data-ph-egg="minecraft" hidden>
                                <ol class="ph-guide__steps">
                                    <li>
                                        <strong>Startup version / jar</strong>
                                        Open <em>Startup</em> and set the Minecraft / Paper version (and jar file name if shown). Save before starting.
                                    </li>
                                    <li>
                                        <strong>First start</strong>
                                        Press Start once so the egg downloads the jar. Accept the EULA by editing <code>eula.txt</code> to <code>eula=true</code> in Files, then Restart.
                                    </li>
                                    <li>
                                        <strong>Config &amp; mods</strong>
                                        Edit <code>server.properties</code> in Files. Upload mods / plugins / worlds with <strong>SFTP</strong> (folders), not the File Manager drag-drop.
                                    </li>
                                    <li>
                                        <strong>Connect</strong>
                                        Players join via the IP and port shown on Console / Network. Restart after big config changes.
                                    </li>
                                </ol>
                            </section>

                            <section class="ph-guide__pane" data-ph-pane="egg" data-ph-egg="rust" hidden>
                                <ol class="ph-guide__steps">
                                    <li>
                                        <strong>Startup identity</strong>
                                        Open <em>Startup</em> and set <strong>Server Name</strong> (<code>HOSTNAME</code>), description, max players, and optional world size / seed.
                                    </li>
                                    <li>
                                        <strong>Ports</strong>
                                        Keep the allocated game / query / RCON ports as shown under Network. Only change RCON password in Startup if you need RCON.
                                    </li>
                                    <li>
                                        <strong>Mods / maps</strong>
                                        Upload custom maps or Oxide/uMod files with SFTP into the container. Prefer SFTP for folders.
                                    </li>
                                    <li>
                                        <strong>Start</strong>
                                        Press Start and wait for the server to finish bootstrapping in Console (first start can take a while).
                                    </li>
                                </ol>
                            </section>

                            <section class="ph-guide__pane" data-ph-pane="egg" data-ph-egg="lavalink" hidden>
                                <ol class="ph-guide__steps">
                                    <li>
                                        <strong>Config</strong>
                                        Edit <code>application.yml</code> (or the egg’s config file) in Files. Set a strong password and matching host/port for your Discord bot.
                                    </li>
                                    <li>
                                        <strong>Startup</strong>
                                        Check <em>Startup</em> for any version / Java options your egg exposes, then Save.
                                    </li>
                                    <li>
                                        <strong>Point your bot at it</strong>
                                        In your bot host, use this server’s IP + Lavalink port and the password from the config.
                                    </li>
                                    <li>
                                        <strong>Start</strong>
                                        Press Start and confirm Console shows Lavalink ready / listening.
                                    </li>
                                </ol>
                            </section>

                            <section class="ph-guide__pane" data-ph-pane="egg" data-ph-egg="source" hidden>
                                <ol class="ph-guide__steps">
                                    <li>
                                        <strong>Startup vars</strong>
                                        Open <em>Startup</em> and set game-specific options (map, max players, Steam token / GSLT if required, extra args).
                                    </li>
                                    <li>
                                        <strong>Steam game server token (when required)</strong>
                                        Some Source games need a GSLT from
                                        <a href="https://steamcommunity.com/dev/managegameservers" target="_blank" rel="noopener noreferrer">steamcommunity.com/dev/managegameservers</a>.
                                        Paste it into the Startup field your egg provides.
                                    </li>
                                    <li>
                                        <strong>Files</strong>
                                        Upload configs / addons with SFTP for folders. Keep game files under the container root the egg expects.
                                    </li>
                                    <li>
                                        <strong>Start</strong>
                                        Press Start and watch Console for map load / server secure messages.
                                    </li>
                                </ol>
                            </section>

                            <section class="ph-guide__pane" data-ph-pane="egg" data-ph-egg="generic" hidden>
                                <ol class="ph-guide__steps">
                                    <li>
                                        <strong>Check Startup</strong>
                                        Open <em>Startup</em> and fill every required variable for your egg (tokens, start file, version, ports).
                                    </li>
                                    <li>
                                        <strong>Upload files</strong>
                                        Small files → File Manager. Folders / large packs → SFTP (Settings → SFTP Details, port 2022).
                                    </li>
                                    <li>
                                        <strong>Start &amp; Console</strong>
                                        Press Start and read Console output. Fix missing vars or paths, then Restart.
                                    </li>
                                </ol>
                            </section>

                            <section class="ph-guide__pane" data-ph-pane="files" hidden>
                                <ol class="ph-guide__steps">
                                    <li>
                                        <strong>File Manager (small files only)</strong>
                                        Use <em>Files</em> for single configs, edits, or small uploads. Do <strong>not</strong> drag entire resource / mod folders here.
                                    </li>
                                    <li>
                                        <strong>SFTP for folders</strong>
                                        Server → <em>Settings → SFTP Details</em>. Host is usually <code>panel.phantom-chicken.com</code> (or the IP shown), port <strong>2022</strong>, username as listed. Password = your panel password (or the SFTP password shown).
                                    </li>
                                    <li>
                                        <strong>Clients</strong>
                                        Use WinSCP, FileZilla, Cyberduck, or VS Code SFTP. Connect, then upload into <code>/home/container</code> (SFTP root / <code>.</code>).
                                    </li>
                                    <li>
                                        <strong>After upload</strong>
                                        Refresh Files in the panel to confirm paths. Restart the server so new files load.
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
                        var eggCache = {};
                        var currentEggKey = 'generic';
                        var currentEggName = '';

                        function csrf() {
                            var m = document.querySelector('meta[name="csrf-token"]');
                            return m ? m.getAttribute('content') : '';
                        }

                        function apiGet(path) {
                            return fetch(path, {
                                credentials: 'same-origin',
                                headers: {
                                    'Accept': 'application/json',
                                    'X-Requested-With': 'XMLHttpRequest',
                                    'X-CSRF-TOKEN': csrf()
                                }
                            }).then(function (r) {
                                if (!r.ok) throw new Error('api ' + r.status);
                                return r.json();
                            });
                        }

                        function serverIdFromPath() {
                            var m = location.pathname.match(/^\/server\/([^/]+)/);
                            return m ? m[1] : null;
                        }

                        function classifyEgg(name) {
                            var n = String(name || '').toLowerCase();
                            if (!n) return 'generic';
                            if (n.indexOf('fivem') !== -1) return 'fivem';
                            if (n.indexOf('discord') !== -1) return 'discord';
                            if (n.indexOf('lavalink') !== -1 || n.indexOf('mumble') !== -1 || n.indexOf('teamspeak') !== -1) return 'lavalink';
                            if (n.indexOf('minecraft') !== -1 || n.indexOf('paper') !== -1 || n.indexOf('forge') !== -1 || n.indexOf('sponge') !== -1 || n.indexOf('bungee') !== -1 || n.indexOf('vanilla') !== -1) return 'minecraft';
                            if (n.indexOf('rust') !== -1) return 'rust';
                            if (n.indexOf('source') !== -1 || n.indexOf('counter-strike') !== -1 || n.indexOf('garrys') !== -1 || n.indexOf('garry') !== -1 || n.indexOf('team fortress') !== -1 || n.indexOf('insurgency') !== -1 || n.indexOf('ark') !== -1) return 'source';
                            if (n.indexOf('python') !== -1) return 'python';
                            if (n.indexOf('node') !== -1) return 'node';
                            return 'generic';
                        }

                        function eggTabLabel(key, eggName) {
                            var labels = {
                                fivem: 'FiveM setup',
                                discord: 'Discord bot',
                                node: 'Node.js app',
                                python: 'Python app',
                                minecraft: 'Minecraft',
                                rust: 'Rust setup',
                                lavalink: 'Lavalink / voice',
                                source: 'Source game',
                                generic: 'Egg setup'
                            };
                            if (eggName && key === 'generic') return eggName;
                            return labels[key] || eggName || 'Egg setup';
                        }

                        function startStepsFor(key) {
                            var commonTail = [
                                { t: 'Upload your files', d: 'Small single files → File Manager. Folders / large packs → SFTP (see Files & SFTP).' },
                                { t: 'Start & watch Console', d: 'Press Start, then read the Console for errors. Restart after you change Startup values.' }
                            ];
                            var heads = {
                                fivem: [
                                    { t: 'Open your FiveM server', d: 'Click the server on the dashboard to open Console, Files, Startup, and Settings.' },
                                    { t: 'Paste your CFX license first', d: 'Startup → FiveM License Key (FIVEM_LICENSE) from keymaster.fivem.net before you press Start.' }
                                ],
                                discord: [
                                    { t: 'Open your bot server', d: 'Click the server on the dashboard to open Console, Files, and Startup.' },
                                    { t: 'Set Startup + token', d: 'Set MAIN_FILE / PY_FILE and USER_UPLOAD=1 if you uploaded files. Put your Discord token in config/.env.' }
                                ],
                                node: [
                                    { t: 'Open your Node server', d: 'Click the server on the dashboard to open Console, Files, and Startup.' },
                                    { t: 'Set MAIN_FILE', d: 'Startup → MAIN_FILE (e.g. index.js) and USER_UPLOAD=1 when you uploaded the project yourself.' }
                                ],
                                python: [
                                    { t: 'Open your Python server', d: 'Click the server on the dashboard to open Console, Files, and Startup.' },
                                    { t: 'Set PY_FILE', d: 'Startup → PY_FILE (e.g. main.py) and USER_UPLOAD=1 when you uploaded the project yourself.' }
                                ],
                                minecraft: [
                                    { t: 'Open your Minecraft server', d: 'Click the server on the dashboard to open Console, Files, and Startup.' },
                                    { t: 'Set version / jar', d: 'Startup → set the Minecraft/Paper version (and jar name if shown), then Start once and accept eula.txt.' }
                                ],
                                rust: [
                                    { t: 'Open your Rust server', d: 'Click the server on the dashboard to open Console, Files, and Startup.' },
                                    { t: 'Set hostname & players', d: 'Startup → Server Name / max players / world options before the first long boot.' }
                                ],
                                lavalink: [
                                    { t: 'Open your voice server', d: 'Click the server on the dashboard to open Console, Files, and Startup.' },
                                    { t: 'Set password in config', d: 'Edit application.yml (or egg config) with a strong password your Discord bot will use.' }
                                ],
                                source: [
                                    { t: 'Open your game server', d: 'Click the server on the dashboard to open Console, Files, and Startup.' },
                                    { t: 'Fill Startup (GSLT if needed)', d: 'Set map/players and paste a Steam game server token when the egg asks for one.' }
                                ],
                                generic: [
                                    { t: 'Open your server', d: 'From the dashboard, click the server name. That opens Console, Files, Startup, and Settings.' },
                                    { t: 'Fill Startup variables first', d: 'Go to the Startup tab before you press Start. Required keys depend on your egg (next tab).' }
                                ]
                            };
                            return (heads[key] || heads.generic).concat(commonTail);
                        }

                        function renderStartSteps(key) {
                            var ol = document.getElementById('ph-guide-start-steps');
                            if (!ol) return;
                            var steps = startStepsFor(key);
                            ol.innerHTML = steps.map(function (s) {
                                return '<li><strong>' + s.t + '</strong> ' + s.d + '</li>';
                            }).join('');
                        }

                        function showEggPane(key) {
                            currentEggKey = key || 'generic';
                            var eggTab = document.getElementById('ph-guide-egg-tab');
                            var label = document.getElementById('ph-guide-egg-label');
                            var title = document.getElementById('ph-guide-title');

                            if (eggTab) eggTab.textContent = eggTabLabel(currentEggKey, currentEggName);
                            if (title) title.textContent = (currentEggName ? currentEggName + ' setup guide' : 'Server setup guide');
                            if (label) {
                                label.textContent = currentEggName
                                    ? ('Detected egg: ' + currentEggName)
                                    : 'Open a server for an egg-specific guide';
                            }

                            renderStartSteps(currentEggKey);

                            guide.querySelectorAll('.ph-guide__pane[data-ph-pane="egg"]').forEach(function (pane) {
                                var match = pane.getAttribute('data-ph-egg') === currentEggKey;
                                pane.hidden = true;
                                pane.classList.remove('is-active');
                                pane.setAttribute('data-ph-egg-active', match ? '1' : '0');
                            });
                        }

                        function activateTab(id) {
                            guide.querySelectorAll('.ph-guide__tab').forEach(function (t) {
                                t.classList.toggle('is-active', t.getAttribute('data-ph-tab') === id);
                            });
                            guide.querySelectorAll('.ph-guide__pane').forEach(function (pane) {
                                var paneId = pane.getAttribute('data-ph-pane');
                                var on = false;
                                if (paneId === 'egg') {
                                    on = id === 'egg' && pane.getAttribute('data-ph-egg-active') === '1';
                                } else {
                                    on = paneId === id;
                                }
                                pane.classList.toggle('is-active', on);
                                pane.hidden = !on;
                            });
                        }

                        function pickEggFromServerPayload(data) {
                            var eggName = '';
                            try {
                                var rel = data.attributes && data.relationships && data.relationships.egg;
                                if (rel && rel.attributes && rel.attributes.name) eggName = rel.attributes.name;
                                if (!eggName && data.relationships && data.relationships.egg && data.relationships.egg.attributes) {
                                    eggName = data.relationships.egg.attributes.name;
                                }
                                // fractal may nest under included
                                if (!eggName && data.attributes && data.attributes.name && data.egg) eggName = data.egg.name;
                            } catch (e) {}
                            return eggName;
                        }

                        function resolveEggFromFractal(json) {
                            // Single server: { object, attributes, relationships: { egg: { attributes: { name }}}}
                            if (json && json.attributes) {
                                var name = '';
                                if (json.relationships && json.relationships.egg) {
                                    var egg = json.relationships.egg;
                                    if (egg.attributes && egg.attributes.name) name = egg.attributes.name;
                                    else if (egg.data && egg.data.attributes) name = egg.data.attributes.name;
                                }
                                return name;
                            }
                            return '';
                        }

                        function applyEgg(name) {
                            currentEggName = name || '';
                            showEggPane(classifyEgg(currentEggName));
                        }

                        function detectEgg() {
                            var sid = serverIdFromPath();
                            if (!sid) {
                                // Dashboard: use first owned server egg if only one type, else generic multi hint
                                return apiGet('/api/client?include=egg&per_page=100').then(function (json) {
                                    var items = (json && json.data) || [];
                                    var names = [];
                                    items.forEach(function (s) {
                                        var n = resolveEggFromFractal(s);
                                        if (n) names.push(n);
                                    });
                                    if (!names.length) {
                                        applyEgg('');
                                        return;
                                    }
                                    var keys = names.map(classifyEgg);
                                    var unique = keys.filter(function (k, i) { return keys.indexOf(k) === i; });
                                    if (unique.length === 1) {
                                        applyEgg(names[0]);
                                    } else {
                                        applyEgg('');
                                        var label = document.getElementById('ph-guide-egg-label');
                                        if (label) {
                                            label.textContent = 'You have mixed eggs (' + names.filter(function (n, i) { return names.indexOf(n) === i; }).join(', ') + '). Open a server for a tailored guide.';
                                        }
                                        showEggPane('generic');
                                    }
                                }).catch(function () {
                                    applyEgg('');
                                    showEggPane('generic');
                                });
                            }

                            if (eggCache[sid]) {
                                applyEgg(eggCache[sid]);
                                return Promise.resolve();
                            }

                            return apiGet('/api/client/servers/' + encodeURIComponent(sid) + '?include=egg').then(function (json) {
                                var name = resolveEggFromFractal(json);
                                eggCache[sid] = name;
                                applyEgg(name);
                            }).catch(function () {
                                applyEgg('');
                                showEggPane('generic');
                            });
                        }

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
                            detectEgg().then(function () {
                                if (serverIdFromPath() && currentEggName) activateTab('egg');
                                else activateTab('start');
                            });
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
                                activateTab(tab.getAttribute('data-ph-tab'));
                            });
                        });

                        // Keep egg in sync when navigating between servers (SPA)
                        var lastPath = location.pathname;
                        setInterval(function () {
                            if (location.pathname !== lastPath) {
                                lastPath = location.pathname;
                                syncSftpWarning();
                                if (!guide.hidden) detectEgg().then(function () { activateTab(currentEggName ? 'egg' : 'start'); });
                                else detectEgg();
                            }
                        }, 700);

                        detectEgg();

                        try {
                            if (!localStorage.getItem(STORAGE_KEY)) {
                                setTimeout(openGuide, 700);
                            }
                        } catch (e) {
                            setTimeout(openGuide, 700);
                        }
                    })();
                </script>
            @endif
        @show
    </body>
</html>
