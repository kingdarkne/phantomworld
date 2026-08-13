const axios = require('axios');

module.exports = async (client, interaction, args) => {
    // Must be in a voice channel
    if (!interaction.member.voice.channel) {
        return client.errNormal({
            error: `You need to be in a voice channel to use TTS!`,
            type: 'editreply',
        }, interaction);
    }

    const channel = interaction.member.voice.channel;
    const text = interaction.options.getString('text');
    const voice = interaction.options.getString('voice') || process.env.TTS_DEFAULT_VOICE || 'af_heart';

    const ttsApiUrl = process.env.TTS_API_URL || 'http://23.238.64.91:5500';
    const ttsApiKey = process.env.TTS_API_KEY || '';

    // Validate text length
    if (text.length > 500) {
        return client.errNormal({
            error: `Text is too long! Maximum 500 characters allowed.`,
            type: 'editreply',
        }, interaction);
    }

    // Show generating status
    await client.simpleEmbed({
        desc: `🎙️┆Generating AI speech... please wait`,
        type: 'editreply',
    }, interaction);

    let audioUrl;
    try {
        // Call the Kokoro TTS API on the VPS
        const response = await axios.post(`${ttsApiUrl}/tts`, {
            text: text,
            voice: voice,
            speed: 1.0
        }, {
            headers: {
                'X-API-Key': ttsApiKey,
                'Content-Type': 'application/json'
            },
            timeout: 30000
        });

        if (!response.data || !response.data.url) {
            throw new Error('TTS API returned no audio URL');
        }

        audioUrl = response.data.url;
    } catch (err) {
        console.error('[TTS] API error:', err.message);
        return client.errNormal({
            error: `Failed to generate speech. The TTS server may be starting up — please try again in a moment.`,
            type: 'editreply',
        }, interaction);
    }

    // Get or create Shoukaku player
    let player = client.shoukaku.players.get(interaction.guild.id);

    if (player && channel.id !== player.voiceChannelIdId) {
        return client.errNormal({
            error: `You are not in the same voice channel as the bot!`,
            type: 'editreply',
        }, interaction);
    }

    if (!player) {
        try {
            player = await client.shoukaku.joinVoiceChannel({
                guildId: interaction.guild.id,
                channelId: channel.id,
                shardId: interaction.guild.shardId || 0,
                deaf: true
            });
            
            // Initialize simple queue
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
            console.error("[TTS] Join error:", err);
            return client.errNormal({
                error: `I cannot join that voice channel!`,
                type: 'editreply',
            }, interaction);
        }
    }

    // Search for the TTS audio URL via Shoukaku
    const node = client.shoukaku.getIdealNode();
    const res = await node.rest.resolve(audioUrl);
    const tracks = res.data || res.tracks;

    if (!tracks || (Array.isArray(tracks) && tracks.length === 0)) {
        return client.errNormal({
            error: `Could not load the TTS audio. Please try again.`,
            type: 'editreply',
        }, interaction);
    }

    const track = Array.isArray(tracks) ? tracks[0] : tracks;

    // Give the TTS track a friendly title
    track.title = `🎙️ TTS: ${text.length > 50 ? text.slice(0, 50) + '...' : text}`;
    track.author = `Kokoro AI (${voice})`;

    // Queue and play
    player.queue.add(track);
    if (!player.track) {
        const first = player.queue.tracks.shift();
        player.queue.current = first;
        await player.playTrack({ track: first.encoded || first.track || first });
    }

    const voiceNames = {
        'af_heart': '💜 Heart',
        'af_bella': '⭐ Bella',
        'af_nicole': '🌸 Nicole',
        'af_sarah': '🎙️ Sarah',
        'am_adam': '🔵 Adam',
        'am_michael': '🟢 Michael',
        'bf_emma': '🇬🇧 Emma',
        'bf_isabella': '🇬🇧 Isabella',
        'bm_george': '🇬🇧 George'
    };

    return client.embed({
        title: `🎙️・AI Text-to-Speech`,
        desc: `Now speaking in <#${channel.id}>`,
        fields: [
            { name: 'Text', value: `\`\`\`${text}\`\`\``, inline: false },
            { name: 'Voice', value: voiceNames[voice] || voice, inline: true },
            { name: 'Requested by', value: `<@${interaction.user.id}>`, inline: true },
        ],
        type: 'editreply',
    }, interaction);
};
