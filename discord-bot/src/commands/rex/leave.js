const { getVoiceConnection } = require('@discordjs/voice');

module.exports = async (client, interaction, args) => {
    // Ensure the interaction is deferred
    if (!interaction.deferred && !interaction.replied) {
        await interaction.deferReply();
    }

    const guildId = interaction.guild.id;
    const connection = getVoiceConnection(guildId);

    if (!connection) {
        return client.errNormal({ 
            error: "Rex is not in a voice channel!", 
            type: 'editreply' 
        }, interaction);
    }

    // Clear state
    if (global.rexState && global.rexState[guildId]) {
        global.rexState[guildId].active = false;
        global.rexState[guildId].processing = false;
    }

    try {
        connection.destroy();
        
        // Also check for Shoukaku player and destroy it if it's Rex's
        const player = client.shoukaku.players.get(guildId);
        if (player) {
            await client.shoukaku.leaveVoiceChannel(guildId);
        }

        return client.succNormal({
            text: "Rex has left the voice channel and stopped listening.",
            type: 'editreply'
        }, interaction);
    } catch (err) {
        console.error('[Rex Leave] Error:', err.message);
        return client.errNormal({ 
            error: "An error occurred while Rex was trying to leave.", 
            type: 'editreply' 
        }, interaction);
    }
};
