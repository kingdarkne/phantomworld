module.exports = async (client, interaction, args) => {
    const guildId  = interaction.guild.id;
    const newVoice = interaction.options.getString('pick');

    if (!global.rexState) global.rexState = {};
    if (!global.rexState[guildId]) global.rexState[guildId] = {};
    global.rexState[guildId].voice = newVoice;

    const voiceNames = {
        'am_adam':    '🔵 Adam (US Male)',
        'am_michael': '🟢 Michael (US Male)',
        'bm_george':  '🇬🇧 George (British Male)',
        'af_heart':   '💜 Heart (US Female)',
        'af_bella':   '⭐ Bella (US Female)',
        'bf_emma':    '🇬🇧 Emma (British Female)',
    };

    return client.embed({
        title: `🤖・Rex Voice Changed`,
        desc: `Rex will now speak as **${voiceNames[newVoice] || newVoice}**.`,
        fields: [
            { name: 'New Voice', value: voiceNames[newVoice] || newVoice, inline: true },
        ],
        type: 'editreply',
    }, interaction);
};
