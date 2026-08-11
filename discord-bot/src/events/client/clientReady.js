const Discord = require('discord.js');
const chalk = require('chalk');
const { startPhantomPresence, setPhantomBotProfile } = require('../../lib/phantom-presence');

module.exports = async (client) => {
    console.log('[clientReady.js] Handler started.');
    
    const startLogs = new Discord.WebhookClient({
        id: client.webhooks.startLogs.id,
        token: client.webhooks.startLogs.token,
    });

    console.log(`\u001b[0m`);
    console.log(chalk.blue(chalk.bold(`Bot`)), (chalk.white(`>>`)), chalk.green(`Started on`), chalk.red(`${client.guilds.cache.size}`), chalk.green(`servers!`))

    // Send Webhook Log
    startLogs.send({
        username: "Bot Logs",
        embeds: [
            new Discord.EmbedBuilder()
                .setTitle(`✅ Bot Started`)
                .setDescription(`Bot has started on ${client.guilds.cache.size} servers!`)
                .setColor("#57F287")
                .setTimestamp()
        ],
    }).catch(err => console.error('[WEBHOOK] Error sending start log:', err.message));

    // Owner DM — exact pre-backup Phantom World Online message (merged back)
    const ownerId = process.env.DISCORD_OWNER_USER_ID || process.env.OWNER_ID;
    const fivemUrl = (process.env.FIVEM_SERVER_URL || 'http://172.245.71.46:30120').replace(/\/$/, '');
    const prefix = client.config?.discord?.prefix || process.env.COMMAND_PREFIX || '$';
    if (ownerId) {
        try {
            const owner = await client.users.fetch(ownerId);
            if (owner) {
                await owner.send({
                    embeds: [
                        new Discord.EmbedBuilder()
                            .setColor(0x8b5cf6)
                            .setTitle('Phantom World Bot Online')
                            .setDescription(
                                `**Prefix:** \`${prefix}help\` · **Slash:** \`/help\` — dropdown command menu\n` +
                                    `**Rex:** \`${prefix}rex join\` / \`/rex join\` — say **"Hey Rex"** in VC\n` +
                                    `**AI/TTS:** \`${prefix}ask\` · \`${prefix}say\` · **Music:** \`${prefix}play\`\n\n` +
                                    `FiveM: ${fivemUrl}`,
                            )
                            .setTimestamp(),
                    ],
                });
                console.log(`[READY] DM sent to owner: ${owner.tag}`);
            }
        } catch (err) {
            console.error('[READY] Failed to send DM to owner:', err.message);
        }
    }

    // Merged presence: live FiveM player counts + Phantom branding (pre-backup status restored)
    if (process.env.DISCORD_STATUS && process.env.DISCORD_STATUS_MODE === 'legacy') {
        setInterval(() => {
            const statuttext = process.env.DISCORD_STATUS.split(', ');
            const randomText = statuttext[Math.floor(Math.random() * statuttext.length)];
            client.user.setPresence({
                activities: [{ name: randomText, type: Discord.ActivityType.Playing }],
                status: 'online',
            });
        }, 50000);
    } else {
        console.log('[clientReady.js] Calling startPhantomPresence(client) — FiveM live + branding…');
        startPhantomPresence(client);
    }

    // Sync EVERY guild to COMMAND_PREFIX / `$` (merged Phantom slim-bot behavior)
    try {
        const Functions = require('../../database/models/functions');
        const prefix = client.config.discord.prefix || process.env.COMMAND_PREFIX || '$';
        const result = await Functions.updateMany({}, { $set: { Prefix: prefix } });
        console.log(`[READY] Synced ${result.modifiedCount || 0} guild prefix(es) to ${prefix}`);
        for (const guild of client.guilds.cache.values()) {
            await Functions.findOneAndUpdate(
                { Guild: guild.id },
                { $set: { Prefix: prefix } },
                { upsert: true },
            );
        }
        console.log(`[READY] Ensured prefix ${prefix} for ${client.guilds.cache.size} joined guild(s)`);
    } catch (err) {
        console.warn('[READY] prefix upsert failed:', err.message);
    }

    setPhantomBotProfile(client).catch(() => {});

    // Live FiveM status channel (editable embed)
    try {
        const { startLiveStatusChannel } = require('../../lib/live-status-channel');
        startLiveStatusChannel(client);
    } catch (err) {
        console.warn('[READY] live status failed:', err.message);
    }

    // Optional auto DM invite broadcast on start
    if (process.env.SERVER_INVITE_DM_ON_START === '1') {
        const guildId = process.env.DISCORD_GUILD_ID || process.env.GUILD_ID;
        if (guildId) {
            const { broadcastServerInviteDms } = require('../../lib/server-invite-dm');
            broadcastServerInviteDms(client, guildId)
                .then((r) => console.log('[invite] auto broadcast:', r))
                .catch((err) => console.warn('[invite] auto broadcast failed:', err.message));
        }
    }

    // Standardized Radio auto-start (if enabled in DB)
    try {
        const RadioSchema = require('../../database/models/music');
        const allData = await RadioSchema.find({ Channel: { $ne: null } });
        for (const data of allData) {
            if (client.guilds.cache.has(data.Guild)) {
                console.log(`[RADIO] Auto-starting radio for guild: ${data.Guild}`);
                const defaultStream = "http://icecast.radiofrance.fr/fip-midfi.mp3";
                client.radio.startRadio(client, data.Guild, data.Channel, defaultStream).catch(e => {
                    console.error(`[RADIO] Auto-start failed for ${data.Guild}:`, e.message);
                });
            }
        }
    } catch (err) {
        console.error("[RADIO] Auto-start manager error:", err.message);
    }
}
