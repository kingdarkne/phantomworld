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

    try {
        const resp = await axios.post(`${REX_API_URL}/chat`, {
            guild_id: guildId,
            user_text: question,
            voice: voice,
        }, {
            headers: { 'X-API-Key': REX_API_KEY, 'Content-Type': 'application/json' },
            timeout: 30000,
        });

        const { reply_text, audio_url } = resp.data;

        // If Rex is in a voice channel, play the audio too
        if (audio_url && state.active) {
            let player = client.shoukaku.players.get(guildId);
            if (!player) {
                const voiceChannel = interaction.member?.voice?.channel;
                if (voiceChannel) {
                    try {
                        player = await client.shoukaku.joinVoiceChannel({
                            guildId: guildId,
                            channelId: voiceChannel.id,
                            shardId: interaction.guild.shardId || 0,
                            deaf: false
                        });
                        
                        // Initialize simple queue if needed
                        if (!player.queue) {
                            player.queue = {
                                current: null,
                                tracks: [],
                                add: function(track) {
                                    if (Array.isArray(track)) this.tracks.push(...track);
                                    else this.tracks.push(track);
                                }
                            };
                        }
                    } catch (err) {
                        console.error("[Rex] Join error:", err);
                    }
                }
            }
            
            if (player) {
                const node = client.shoukaku.getIdealNode();
                const res = await node.rest.resolve(audio_url);
                const tracks = res.data || res.tracks;
                
                if (tracks && (Array.isArray(tracks) ? tracks.length : true)) {
                    const track = Array.isArray(tracks) ? tracks[0] : tracks;
                    
                    // Add to queue and play
                    player.queue.add(track);
                    if (!player.track) {
                        const first = player.queue.tracks.shift();
                        player.queue.current = first;
                        await player.playTrack({ track: first.encoded || first.track || first });
                    }
                }
            }
        }

        return client.embed({
            title: `🤖・Rex`,
            desc: reply_text,
            fields: [
                { name: 'You asked', value: `\`${question}\``, inline: false },
            ],
            type: 'editreply',
        }, interaction);

    } catch (err) {
        console.error('[Rex ask] Error:', err.message);
        return client.errNormal({
            error: `Rex is having a moment. Try again in a sec.`,
            type: 'editreply',
        }, interaction);
    }
};
