const axios = require('axios');

const REX_API_URL = process.env.REX_API_URL || 'http://23.238.64.91:5600';
const REX_API_KEY = process.env.REX_API_KEY || '';

module.exports = async (client, interaction, args) => {
    const question = interaction.options.getString('question');
    const guildId  = interaction.guild.id;
    const state    = global.rexState?.[guildId] || {};
    const voice    = state.voice || 'am_adam';

    await client.simpleEmbed({
        desc: `🤖 Rex is thinking...`,
        type: 'editreply',
    }, interaction);

    let reply_text = "";
    let audio_url = "";

    try {
        const resp = await axios.post(`${REX_API_URL}/chat`, {
            guild_id: guildId,
            user_text: question,
            voice: voice,
        }, {
            headers: { 'X-API-Key': REX_API_KEY, 'Content-Type': 'application/json' },
            timeout: 30000,
        });

        reply_text = resp.data.reply_text;
        audio_url = resp.data.audio_url || resp.data.audio_file;

    } catch (err) {
        console.error('[Rex ask] API Error:', err.message);
        return client.errNormal({
            error: `Rex is having a moment (AI Connection Error). Try again in a sec.`,
            type: 'editreply',
        }, interaction);
    }

    // Audio playback using Shoukaku
    if (audio_url && state.active) {
        try {
            const player = client.shoukaku.players.get(guildId);
            if (player) {
                const node = client.shoukaku.getIdealNode();
                const res = await node.rest.resolve(audio_url);
                const track = res?.data?.[0] || res?.tracks?.[0];
                
                if (track) {
                    await player.playTrack({ track: track.encoded || track.track || track });
                }
            }
        } catch (audioErr) {
            console.error('[Rex ask] Audio playback failed:', audioErr.message);
        }
    }

    // Final text reply
    return client.embed({
        title: `🤖・Rex`,
        desc: reply_text || "I'm here, but I have nothing to say.",
        fields: [
            { name: 'You asked', value: `\`${question}\``, inline: false },
        ],
        type: 'editreply',
    }, interaction);
};
