const { joinVoiceChannel, getVoiceConnection, VoiceConnectionStatus, EndBehaviorType } = require('@discordjs/voice');
const axios = require('axios');
const fs = require('fs');
const path = require('path');

const REX_API_URL = process.env.REX_API_URL || 'http://23.238.64.91:5600';
const REX_API_KEY = process.env.REX_API_KEY || '';
const WAKE_WORD   = 'hey rex';
const TARGET_CHANNEL_ID = '1472295681577193707';

if (!global.rexState) global.rexState = {};

module.exports = async (client, interaction, args) => {
    if (!interaction.deferred && !interaction.replied) {
        await interaction.deferReply();
    }

    const voiceChannel = interaction.member?.voice?.channel;
    if (!voiceChannel) {
        return client.errNormal({ error: `You need to be in a voice channel first!`, type: 'editreply' }, interaction);
    }

    const guildId = interaction.guild.id;
    
    // Clean up any existing connection first
    const existingConnection = getVoiceConnection(guildId);
    if (existingConnection) {
        existingConnection.destroy();
    }

    try {
        const connection = joinVoiceChannel({
            channelId: voiceChannel.id,
            guildId: guildId,
            adapterCreator: interaction.guild.voiceAdapterCreator,
            selfDeaf: false,
            selfMute: false,
        });

        global.rexState[guildId] = {
            active: true,
            channelId: voiceChannel.id,
            textChannelId: interaction.channel.id,
            connection: connection,
            voice: global.rexState[guildId]?.voice || 'am_adam',
            processing: false,
        };

        await client.embed({
            title: `🤖・Rex is Listening`,
            desc: `Rex has joined <#${voiceChannel.id}>!\n\nSay **"Hey Rex"** to talk to me.`,
            fields: [
                { name: 'Wake Word', value: '`Hey Rex`', inline: true },
                { name: 'Voice', value: '🔵 Adam', inline: true },
            ],
            type: 'editreply',
        }, interaction);

        // Standardized Voice Recognition Logic
        connection.receiver.speaking.on('start', async (userId) => {
            const state = global.rexState[guildId];
            if (!state?.active || state.processing) return;

            const user = interaction.guild.members.cache.get(userId);
            if (!user || user.user.bot) return;

            console.log(`[Rex VC] Started hearing ${user.user.username}...`);

            const audioStream = connection.receiver.subscribe(userId, {
                end: { behavior: EndBehaviorType.AfterSilence, duration: 1500 },
            });

            const chunks = [];
            audioStream.on('data', chunk => chunks.push(chunk));

            audioStream.on('end', async () => {
                if (!state?.active || chunks.length < 5) return;

                const tmpWav = `/tmp/rex_vc_${guildId}_${Date.now()}.wav`;
                const tmpOpus = tmpWav.replace('.wav', '.opus');

                try {
                    const rawBuffer = Buffer.concat(chunks);
                    fs.writeFileSync(tmpOpus, rawBuffer);
                    
                    const { execSync } = require('child_process');
                    try {
                        // Convert Opus to Wav for STT
                        execSync(`ffmpeg -y -f opus -i "${tmpOpus}" -ar 16000 -ac 1 "${tmpWav}" 2>/dev/null`);
                    } catch (e) {
                        console.error('[Rex VC] FFMPEG Error:', e.message);
                        return;
                    }

                    if (!fs.existsSync(tmpWav)) return;

                    const FormData = require('form-data');
                    const form = new FormData();
                    form.append('audio', fs.createReadStream(tmpWav), 'audio.wav');

                    const sttResp = await axios.post(`${REX_API_URL}/transcribe`, form, {
                        headers: { ...form.getHeaders(), 'X-API-Key': REX_API_KEY },
                        timeout: 15000,
                    });

                    const transcribed = (sttResp.data.text || '').toLowerCase().trim();
                    console.log(`[Rex VC] Heard: "${transcribed}"`);

                    if (!transcribed.includes(WAKE_WORD)) return;

                    // FEEDBACK
                    const targetChannel = client.channels.cache.get(state.textChannelId) || client.channels.cache.get(TARGET_CHANNEL_ID);
                    if (targetChannel) {
                        await targetChannel.send(`🤖 **Rex:** I heard you! Thinking... 🧠`);
                        await targetChannel.sendTyping();
                    }

                    const question = transcribed.replace(WAKE_WORD, '').trim();
                    state.processing = true;

                    const chatResp = await axios.post(`${REX_API_URL}/chat`, {
                        guild_id: guildId,
                        user_text: question || "Hello",
                        voice: state.voice || 'am_adam',
                    }, {
                        headers: { 'X-API-Key': REX_API_KEY, 'Content-Type': 'application/json' },
                        timeout: 30000,
                    });

                    const { reply_text, audio_url } = chatResp.data;
                    
                    if (targetChannel) {
                        await targetChannel.send(`🤖 **Rex** *(to ${user.user.username})*: ${reply_text}`);
                    }

                    if (audio_url) {
                        const player = client.shoukaku.players.get(guildId);
                        if (player) {
                            const node = client.shoukaku.getIdealNode();
                            const res = await node.rest.resolve(audio_url);
                            const track = res?.data?.[0] || res?.tracks?.[0];
                            if (track) {
                                await player.playTrack({ track: track.encoded || track.track || track });
                            }
                        }
                    }

                } catch (err) {
                    console.error('[Rex VC] Error:', err.message);
                } finally {
                    state.processing = false;
                    try { if (fs.existsSync(tmpOpus)) fs.unlinkSync(tmpOpus); } catch {}
                    try { if (fs.existsSync(tmpWav)) fs.unlinkSync(tmpWav); } catch {}
                }
            });
        });

        connection.on(VoiceConnectionStatus.Disconnected, () => {
            if (global.rexState[guildId]) global.rexState[guildId].active = false;
        });

    } catch (err) {
        console.error('[Rex Join] Error:', err.message);
        return client.errNormal({ error: `Rex failed to join. Try again in a moment.`, type: 'editreply' }, interaction);
    }
};
