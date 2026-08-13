const axios = require('axios');

module.exports = async (client, interaction) => {
    const text = interaction.options.getString('text');
    const voice = interaction.options.getString('voice') || 'af_heart';

    if (!interaction.deferred && !interaction.replied) await interaction.deferReply().catch(() => {});

    try {
        const response = await axios.post(`${process.env.REX_API_URL}/tts`, {
            text: text,
            voice: voice
        }, {
            headers: { 'Authorization': `Bearer ${process.env.REX_API_KEY}` }
        });

        const audioUrl = response.data.url;
        
        // Use Shoukaku player
        const player = client.shoukaku.players.get(interaction.guild.id);

        if (!player) {
            return client.errNormal({
                error: "I'm not in a voice channel! Use `/rex join` first.",
                type: 'editreply'
            }, interaction);
        }

        const node = client.shoukaku.getIdealNode();
        const res = await node.rest.resolve(audioUrl);
        
        if (res && (res.data || res.tracks)) {
            const track = res.data?.[0] || res.tracks?.[0];
            if (track) {
                await player.playTrack({ track: track.encoded || track.track || track });
            }
        }

        return client.embed({
            title: `🔊・Rex is speaking...`,
            desc: `**Text:** ${text}\n**Voice:** ${voice}`,
            type: 'editreply'
        }, interaction);

    } catch (err) {
        console.error("[TTS speak] Error:", err);
        return client.errNormal({
            error: "Failed to generate AI speech. Check if the VPS is online!",
            type: 'editreply'
        }, interaction);
    }
};
