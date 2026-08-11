const { ApplicationCommandOptionType } = require('discord.js');

/**
 * Build sync helper used by /help (must exist before ClientReady finishes).
 * @param {import('discord.js').Collection<string, import('discord.js').ApplicationCommand>} appCommands
 */
function buildGetSlashMentions(appCommands) {
    return (query) => {
        const cmd = appCommands?.find?.((c) => c.name === query);
        const array = [];

        if (!cmd) {
            return [[`/${query}`, 'Not registered or not loaded yet']];
        }

        if (cmd.options?.length > 0) {
            const sub = cmd.options.filter((y) => y.type === ApplicationCommandOptionType.Subcommand);
            const group = cmd.options.filter((y) => y.type === ApplicationCommandOptionType.SubcommandGroup);

            for (const y of sub) {
                array.push([`</${cmd.name} ${y.name}:${cmd.id}>`, String(y.description || '')]);
            }

            for (const y of group) {
                const groupSub = y.options?.filter((a) => a.type === ApplicationCommandOptionType.Subcommand) || [];
                for (const x of groupSub) {
                    array.push([
                        `</${cmd.name} ${y.name} ${x.name}:${cmd.id}>`,
                        String(x.description || ''),
                    ]);
                }
            }
        }

        if (array.length === 0) {
            array.push([`</${cmd.name}:${cmd.id}>`, String(cmd.description || '')]);
        }

        return array;
    };
}

async function fetchApplicationCommands(client) {
    const guildId = process.env.DISCORD_GUILD_ID || process.env.DISCORD_ID;

    try {
        if (guildId) {
            return await client.application.commands.fetch({ guildId });
        }
        return await client.application.commands.fetch();
    } catch (err) {
        console.warn('[Phantom] Could not fetch slash commands:', err.message);
        return client.application.commands.cache;
    }
}

module.exports = { buildGetSlashMentions, fetchApplicationCommands };
