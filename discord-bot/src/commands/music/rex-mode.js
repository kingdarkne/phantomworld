const axios = require('axios');
const { PermissionsBitField } = require('discord.js');

const REX_API_URL = process.env.REX_API_URL || 'http://23.238.64.91:5600';
const REX_API_KEY = process.env.REX_API_KEY || '';

module.exports = async (client, interaction, args) => {
    // Admin only — must have Administrator permission
    if (!interaction.member.permissions.has(PermissionsBitField.Flags.Administrator)) {
        return client.errNormal({
            error: `This command is for admins only. Nice try though.`,
            type: 'editreply',
        }, interaction);
    }

    const setting  = interaction.options.getString('setting');
    const guildId  = interaction.guild.id;
    const enable   = setting === 'on';

    try {
        await axios.post(`${REX_API_URL}/mode`, {
            guild_id: guildId,
            unrestricted: enable,
        }, {
            headers: { 'X-API-Key': REX_API_KEY, 'Content-Type': 'application/json' },
            timeout: 10000,
        });

        if (enable) {
            return client.embed({
                title: `🔓・Rex Unrestricted Mode ENABLED`,
                desc: `Rex is now running in **Unrestricted Mode**.\n\nAll filters are off. Rex will answer anything, use any language, and hold nothing back.\n\n*Use \`/rex mode setting:Disable\` to return to normal.*`,
                fields: [
                    { name: '⚠️ Warning', value: 'This mode removes all content restrictions. Use responsibly.', inline: false },
                    { name: 'Enabled by', value: `<@${interaction.user.id}>`, inline: true },
                ],
                type: 'editreply',
            }, interaction);
        } else {
            return client.embed({
                title: `🔒・Rex Normal Mode ENABLED`,
                desc: `Rex is back to **Normal Mode**. Filters restored, Rex is behaving again.\n\n*For now.*`,
                type: 'editreply',
            }, interaction);
        }

    } catch (err) {
        console.error('[Rex mode] Error:', err.message);
        return client.errNormal({
            error: `Failed to change Rex's mode. The AI server may be restarting.`,
            type: 'editreply',
        }, interaction);
    }
};
