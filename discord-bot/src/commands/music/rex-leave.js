const { getVoiceConnection } = require('@discordjs/voice');

module.exports = async (client, interaction, args) => {
    const guildId = interaction.guild.id;
    const state = global.rexState?.[guildId];

    if (!state?.active) {
        return client.errNormal({
            error: `Rex isn't in a voice channel right now!`,
            type: 'editreply',
        }, interaction);
    }

    // Destroy voice connection
    const connection = getVoiceConnection(guildId);
    if (connection) connection.destroy();

    // Destroy Lavalink player if exists
    const player = client.player?.players?.get(guildId);
    if (player) player.destroy();

    // Clear state
    global.rexState[guildId] = { active: false };

    return client.embed({
        title: `🤖・Rex Left`,
        desc: `Rex has left the voice channel. Later, nerds.`,
        type: 'editreply',
    }, interaction);
};
