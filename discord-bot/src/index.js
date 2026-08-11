// console.log("SRC INDEX LOADED");

// Load env
require('../env.loader');

// Voice libs — Node 22 often lacks @discordjs/opus prebuilds; opusscript is the JS fallback
try {
  require('opusscript');
  console.log('[voice] opusscript loaded');
} catch (err) {
  console.warn('[voice] opusscript missing:', err.message);
}
try {
  const sodium = require('libsodium-wrappers');
  sodium.ready.then(() => console.log('[voice] libsodium ready')).catch(() => {});
} catch (err) {
  console.warn('[voice] libsodium-wrappers:', err.message);
}
try {
  const { generateDependencyReport } = require('@discordjs/voice');
  console.log('[voice] deps:\n' + generateDependencyReport());
} catch (_) {}

// Global error handling to prevent silent crashes
process.on('unhandledRejection', (reason, p) => {
    const msg =
        reason?.errors
            ? `${reason.message || 'Received one or more errors'}: ${reason.errors
                  .map((e) => e?.message || String(e))
                  .join(' | ')}`
            : reason?.stack || reason?.message || String(reason);
    console.error('[FATAL] Unhandled Rejection:', msg);
    if (client?.webhooks?.errorLogs?.id && client.webhooks.errorLogs.token && client.webhooks.errorLogs.token !== 'REPLACE_ME') {
        const errorLogs = new (require('discord.js')).WebhookClient({
            id: client.webhooks.errorLogs.id,
            token: client.webhooks.errorLogs.token,
        });
        errorLogs
            .send({
                username: 'Error Logs',
                embeds: [
                    new (require('discord.js')).EmbedBuilder()
                        .setTitle(`❌ Unhandled Rejection`)
                        .setDescription(String(msg).slice(0, 4000))
                        .setColor('#ED4245')
                        .setTimestamp(),
                ],
            })
            .catch(() => {});
    }
});
process.on('uncaughtException', (err) => {
    console.error('[FATAL] Uncaught Exception:', err);
    if (client?.webhooks?.errorLogs?.id && client.webhooks.errorLogs.token && client.webhooks.errorLogs.token !== 'REPLACE_ME') {
        const errorLogs = new (require('discord.js')).WebhookClient({
            id: client.webhooks.errorLogs.id,
            token: client.webhooks.errorLogs.token,
        });
        errorLogs
            .send({
                username: 'Error Logs',
                embeds: [
                    new (require('discord.js')).EmbedBuilder()
                        .setTitle(`❌ Uncaught Exception`)
                        .setDescription(`**Error:** ${err.message}\n**Stack:** ${String(err.stack || '').slice(0, 3500)}`)
                        .setColor('#ED4245')
                        .setTimestamp(),
                ],
            })
            .catch(() => {});
    }
});

// Load bot (creates client)
const client = require('./bot.js');

// Load config
try {
    client.config = require('./config/bot.js');
    // console.log("CONFIG LOADED");
} catch (err) {
    console.error("ERROR LOADING CONFIG:", err);
}

// Load webhooks (never commit real tokens — use webhooks.json on the server)
try {
    const fs = require('fs');
    const path = require('path');
    const primary = path.join(__dirname, 'config', 'webhooks.json');
    const fallback = path.join(__dirname, 'config', 'webhooks.example.json');
    const file = fs.existsSync(primary) ? primary : fallback;
    client.webhooks = require(file);
} catch (err) {
    console.error("ERROR LOADING WEBHOOKS:", err);
    client.webhooks = {};
}

// Connect to Database
try {
    require('./database/connect.js')();
} catch (err) {
    console.error("ERROR CONNECTING TO DATABASE:", err);
}

// Load handlers (functions, components, security, games, linkspanel)
try {
    const fs = require('fs');
    const path = require('path');
    const handlerRoots = ['functions', 'components', 'security', 'games', 'linkspanel'];
    for (const dir of handlerRoots) {
        const handlersPath = path.join(__dirname, 'handlers', dir);
        if (!fs.existsSync(handlersPath)) continue;
        for (const file of fs.readdirSync(handlersPath).filter((f) => f.endsWith('.js'))) {
            try {
                const mod = require(path.join(handlersPath, file));
                if (typeof mod === 'function') mod(client);
                console.log(`[handlers/${dir}] loaded ${file}`);
            } catch (err) {
                console.error(`[handlers/${dir}] failed ${file}:`, err.message);
            }
        }
    }
    // Safety: ensure log-channel helper always exists even if customEvents failed
    if (typeof client.getLogs !== 'function') {
        client.getLogs = async function () {
            return false;
        };
        console.warn('[handlers] client.getLogs fallback installed');
    }
    console.log('HANDLERS LOADED');
} catch (err) {
    console.error('ERROR LOADING HANDLERS:', err);
}

// Load slash command loader
try {
    require('./handlers/loaders/commands.js')(client);
    // console.log("COMMANDS LOADED");
} catch (err) {
    console.error("ERROR LOADING COMMANDS:", err);
}

// Load event loader
try {
    console.log("[INDEX] Calling event loader...");
    require('./handlers/loaders/event.js')(client);
    console.log("[INDEX] Event loader finished.");
} catch (err) {
    console.error("ERROR LOADING EVENTS:", err);
}

// Load lavalink
try {
    import('./lib/lavalink.js').then(m => client.shoukaku = m.initLavalink(client));
    // console.log("LAVALINK LOADED");
} catch (err) {
    console.error("ERROR LOADING LAVALINK:", err);
}

// Start express dashboard
try {
    const express = require('express');
    const app = express();
    const chalk = require('chalk');

    const httpPort = Number(process.env.BOT_HTTP_PORT || process.env.PORT || 3099);
    const httpBind = process.env.BOT_HTTP_BIND || '127.0.0.1';

    app.use(express.json({ limit: '64kb' }));
    global.phantomHttpApp = app;

    app.get("/", (req, res) => {
        res.setHeader('Content-Type', 'text/html');
        res.send(`<!DOCTYPE html><html><head><meta charset="utf-8"><title>Phantom World Bot</title></head><body style="font-family:system-ui;background:#111;color:#eee;padding:2rem"><h1>Phantom World Discord Bot</h1><p>Developed by Phantom World</p><p><a href="https://discord.gg/zZSvmdUx" style="color:#8b5cf6">Discord</a></p><p>Health: <a href="/health" style="color:#8b5cf6">/health</a></p></body></html>`);
    });

    app.get("/health", (_req, res) =>
        res.json({
            ok: true,
            phantom: true,
            bot: client.user?.tag || 'starting',
            developedBy: 'Phantom World',
            commands: client.commands?.size || 0,
        }),
    );

    app.listen(httpPort, httpBind, () =>
        console.log(chalk.blue(chalk.bold(`Server`)), chalk.white(`>>`), chalk.green(`Running on`), chalk.red(`${httpBind}:${httpPort}`)),
    );

    // FiveM event relay + /phantomstatus interaction handler
    try {
        require('../aio-bridge')(client);
        console.log('[phantom] aio-bridge loaded');
    } catch (bridgeErr) {
        console.warn('[phantom] aio-bridge failed:', bridgeErr.message);
    }

    // console.log("DASHBOARD LOADED");
} catch (err) {
    console.error("ERROR LOADING DASHBOARD:", err);
}

// Final login after all loaders are finished
console.log("[INDEX] Logging in...");
client.login(process.env.DISCORD_TOKEN || process.env.DISCORD_BOT_TOKEN);
