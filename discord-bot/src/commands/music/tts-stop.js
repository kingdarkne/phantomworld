module.exports = async (client, interaction, args) => {
    const player = client.player.players.get(interaction.guild.id);

    if (!player) {
        return client.errNormal({
            error: `The bot is not in a voice channel!`,
            type: 'editreply',
        }, interaction);
    }

    if (!interaction.member.voice.channel) {
        return client.errNormal({
            error: `You need to be in a voice channel to use this command!`,
            type: 'editreply',
        }, interaction);
    }

    if (interaction.member.voice.channel.id !== player.voiceChannelId) {
        return client.errNormal({
            error: `You are not in the same voice channel as the bot!`,
            type: 'editreply',
        }, interaction);
    }

    player.destroy();

    return client.embed({
        title: `🎙️・TTS Stopped`,
        desc: `AI Text-to-Speech has been stopped and the bot has disconnected.`,
        type: 'editreply',
    }, interaction);
};
