const { joinVoiceChannel, getVoiceConnection, VoiceConnectionStatus, EndBehaviorType } = require('@discordjs/voice');
const { OpusEncoder } = require('@discordjs/opus');
const axios = require('axios');
const fs = require('fs');
const path = require('path');
const { pipeline } = require('stream');
const { promisify } = require('util');
const { playRexAudio } = require('../../../lib/rex-voice-play.cjs');

const REX_API_URL = process.env.REX_API_URL || 'http://23.238.64.91:5600';
const REX_API_KEY = process.env.REX_API_KEY || '';
const WAKE_WORD   = 'hey rex';

// Per-guild Rex state
if (!global.rexState) global.rexState = {};

module.exports = async (client, interaction, args) => {
    const member = interaction.member;
    const voiceChannel = member?.voice?.channel;

    if (!voiceChannel) {
        return client.errNormal({
            error: `You need to be in a voice channel first!`,
            type: 'editreply',
        }, interaction);
    }

    const guildId = interaction.guild.id;

    // Check if already active
    if (global.rexState[guildId]?.active) {
        return client.errNormal({
            error: `Rex is already listening in <#${global.rexState[guildId].channelId}>! Use \`/rex leave\` first.`,
            type: 'editreply',
        }, interaction);
    }

    // Join the voice channel
    const connection = joinVoiceChannel({
        channelId: voiceChannel.id,
        guildId: guildId,
        adapterCreator: interaction.guild.voiceAdapterCreator,
        selfDeaf: false,   // Must NOT be deafened to receive audio
        selfMute: false,
    });

    // Init guild state
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
        desc: `Rex has joined <#${voiceChannel.id}>!\n\nSay **"Hey Rex"** followed by your question and I'll respond.\n\n*Example: "Hey Rex, what's the meaning of life?"*`,
        fields: [
            { name: 'Wake Word', value: '`Hey Rex`', inline: true },
            { name: 'Voice', value: '🔵 Adam (US Male)', inline: true },
            { name: 'Mode', value: '🔒 Normal', inline: true },
        ],
        type: 'editreply',
    }, interaction);

    const textChannel = interaction.channel;

    // Listen for voice activity
    connection.receiver.speaking.on('start', async (userId) => {
        const state = global.rexState[guildId];
        if (!state?.active || state.processing) return;

        // Ignore bots
        const user = interaction.guild.members.cache.get(userId);
        if (!user || user.user.bot) return;

        // Capture audio stream
        const audioStream = connection.receiver.subscribe(userId, {
            end: { behavior: EndBehaviorType.AfterSilence, duration: 1500 },
        });

        const chunks = [];
        audioStream.on('data', chunk => chunks.push(chunk));

        audioStream.on('end', async () => {
            if (!state?.active) return;
            if (chunks.length < 5) return; // Too short, ignore

            // Convert Opus chunks to PCM WAV via ffmpeg
            const rawBuffer = Buffer.concat(chunks);
            const tmpOpus = `/tmp/rex_${guildId}_${Date.now()}.opus`;
            const tmpWav  = `/tmp/rex_${guildId}_${Date.now()}.wav`;

            try {
                fs.writeFileSync(tmpOpus, rawBuffer);

                // Use ffmpeg to convert opus to wav
                const { execSync } = require('child_process');
                execSync(`ffmpeg -y -f opus -i "${tmpOpus}" "${tmpWav}" 2>/dev/null`, { timeout: 10000 });

                // Send to Rex STT first to check for wake word
                const FormData = require('form-data');
                const form = new FormData();
                form.append('audio', fs.createReadStream(tmpWav), 'audio.wav');

                const sttResp = await axios.post(`${REX_API_URL}/transcribe`, form, {
                    headers: { ...form.getHeaders(), 'X-API-Key': REX_API_KEY },
                    timeout: 15000,
                });

                const transcribed = (sttResp.data.text || '').toLowerCase().trim();
                console.log(`[Rex] Heard from ${user.user.username}: "${transcribed}"`);

                // Check for wake word
                if (!transcribed.includes(WAKE_WORD)) {
                    return; // Not addressed to Rex
                }

                // Extract the actual question (remove wake word)
                const question = transcribed.replace(WAKE_WORD, '').trim();
                if (!question || question.length < 2) {
                    // Just the wake word, acknowledge
                    await textChannel.send(`🤖 **Rex:** Yeah? What do you want?`);
                    return;
                }

                // Mark as processing to avoid overlapping responses
                state.processing = true;

                // Show typing indicator
                await textChannel.sendTyping();

                // Full pipeline: question → LLM → TTS
                const chatResp = await axios.post(`${REX_API_URL}/chat`, {
                    guild_id: guildId,
                    user_text: question,
                    voice: state.voice || 'am_adam',
                }, {
                    headers: { 'X-API-Key': REX_API_KEY, 'Content-Type': 'application/json' },
                    timeout: 30000,
                });

                const { reply_text, audio_url } = chatResp.data;

                // Show reply in text channel
                await textChannel.send(`🤖 **Rex** *(to ${user.user.username})*: ${reply_text}`);

                // Play audio (Lavalink or direct voice fallback)
                if (audio_url) {
                    await playRexAudio(client, {
                        guildId,
                        voiceChannelId: state.channelId,
                        audioUrl: audio_url,
                        title: `🤖 Rex: ${reply_text.slice(0, 50)}`,
                    });
                }

            } catch (err) {
                console.error('[Rex] Pipeline error:', err.message);
            } finally {
                // Cleanup temp files
                try { fs.unlinkSync(tmpOpus); } catch {}
                try { fs.unlinkSync(tmpWav); } catch {}
                if (state) state.processing = false;
            }
        });
    });

    // Handle disconnection
    connection.on(VoiceConnectionStatus.Disconnected, () => {
        if (global.rexState[guildId]) {
            global.rexState[guildId].active = false;
        }
    });
};
