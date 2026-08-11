// console.log("SRC INDEX LOADED");

// Load env
require('../env.loader');

// Global error handling to prevent silent crashes
process.on('unhandledRejection', (reason, p) => {
    console.error('[FATAL] Unhandled Rejection at:', p, 'reason:', reason);
    if (client.webhooks && client.webhooks.errorLogs) {
        const errorLogs = new (require('discord.js')).WebhookClient({
            id: client.webhooks.errorLogs.id,
            token: client.webhooks.errorLogs.token,
        });
        errorLogs.send({
            username: "Error Logs",
            embeds: [
                new (require('discord.js')).EmbedBuilder()
                    .setTitle(`❌ Unhandled Rejection`)
                    .setDescription(`**Promise:** ${p}\n**Reason:** ${reason}`)
                    .setColor("#ED4245")
                    .setTimestamp()
            ],
        }).catch(() => {});
    }
});
process.on('uncaughtException', (err) => {
    console.error('[FATAL] Uncaught Exception:', err);
    if (client.webhooks && client.webhooks.errorLogs) {
        const errorLogs = new (require('discord.js')).WebhookClient({
            id: client.webhooks.errorLogs.id,
            token: client.webhooks.errorLogs.token,
        });
        errorLogs.send({
            username: "Error Logs",
            embeds: [
                new (require('discord.js')).EmbedBuilder()
                    .setTitle(`❌ Uncaught Exception`)
                    .setDescription(`**Error:** ${err.message}\n**Stack:** ${err.stack}`)
                    .setColor("#ED4245")
                    .setTimestamp()
            ],
        }).catch(() => {});
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

// Load function handlers
try {
    const fs = require('fs');
    const path = require('path');
    const functionsPath = path.join(__dirname, 'handlers', 'functions');
    if (fs.existsSync(functionsPath)) {
        fs.readdirSync(functionsPath).forEach(file => {
            if (file.endsWith('.js')) {
                require(path.join(functionsPath, file))(client);
            }
        });
        console.log("FUNCTIONS LOADED");
    }
} catch (err) {
    console.error("ERROR LOADING FUNCTIONS:", err);
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
