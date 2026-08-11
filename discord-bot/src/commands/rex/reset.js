const axios = require('axios');

const REX_API_URL = process.env.REX_API_URL || 'http://23.238.64.91:5600';
const REX_API_KEY = process.env.REX_API_KEY || '';

module.exports = async (client, interaction, args) => {
    const guildId = interaction.guild.id;

    try {
        await axios.post(`${REX_API_URL}/reset`, {
            guild_id: guildId,
        }, {
            headers: { 'X-API-Key': REX_API_KEY, 'Content-Type': 'application/json' },
            timeout: 10000,
        });

        return client.embed({
            title: `🤖・Rex Memory Cleared`,
            desc: `Rex has forgotten everything about this server. Fresh start.\n\n*"Who are you people again?" — Rex, probably.*`,
            type: 'editreply',
        }, interaction);

    } catch (err) {
        return client.errNormal({
            error: `Couldn't clear Rex's memory. He's stubborn like that.`,
            type: 'editreply',
        }, interaction);
    }
};
