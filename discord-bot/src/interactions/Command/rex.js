const { CommandInteraction, Client, PermissionsBitField, SlashCommandBuilder, EmbedBuilder } = require('discord.js');
const axios = require('axios');
const { playRexAudio } = require('../../../lib/rex-voice-play.cjs');

const REX_API_URL = process.env.REX_API_URL || 'http://23.238.64.91:5600';
const REX_API_KEY = process.env.REX_API_KEY || '';

module.exports = {
    data: new SlashCommandBuilder()
        .setName('rex')
        .setDescription('Rex — AI voice assistant powered by Groq + Kokoro')
        .addSubcommand(sub =>
            sub.setName('join')
                .setDescription('Rex joins your voice channel and starts listening for "Hey Rex"')
        )
        .addSubcommand(sub =>
            sub.setName('leave')
                .setDescription('Rex leaves the voice channel and stops listening')
        )
        .addSubcommand(sub =>
            sub.setName('ask')
                .setDescription('Ask Rex something via text (no voice needed)')
                .addStringOption(opt =>
                    opt.setName('question')
                        .setDescription('What do you want to ask Rex?')
                        .setRequired(true)
                )
        )
        .addSubcommand(sub =>
            sub.setName('mode')
                .setDescription('[ADMIN ONLY] Toggle Rex unrestricted mode')
                .addStringOption(opt =>
                    opt.setName('setting')
                        .setDescription('Enable or disable unrestricted mode')
                        .setRequired(true)
                        .addChoices(
                            { name: '🔓 Enable Unrestricted Mode', value: 'on' },
                            { name: '🔒 Disable (Normal Mode)', value: 'off' }
                        )
                )
        )
        .addSubcommand(sub =>
            sub.setName('reset')
                .setDescription('Clear Rex\'s conversation memory for this server')
        )
        .addSubcommand(sub =>
            sub.setName('voice')
                .setDescription('Change Rex\'s voice')
                .addStringOption(opt =>
                    opt.setName('pick')
                        .setDescription('Choose a voice for Rex')
                        .setRequired(true)
                        .addChoices(
                            { name: '🔵 Adam (US Male) — Default', value: 'am_adam' },
                            { name: '🟢 Michael (US Male)', value: 'am_michael' },
                            { name: '🇬🇧 George (British Male)', value: 'bm_george' },
                            { name: '💜 Heart (US Female)', value: 'af_heart' },
                            { name: '⭐ Bella (US Female)', value: 'af_bella' },
                            { name: '🇬🇧 Emma (British Female)', value: 'bf_emma' }
                        )
                )
        ),

    run: async (client, interaction, args) => {
        const sub = interaction.options.getSubcommand();
        
        // Handle 'ask' subcommand directly
        if (sub === 'ask') {
            if (!interaction.deferred && !interaction.replied) await interaction.deferReply({});
            
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

                const reply_text = resp.data.reply_text;
                const audio_url = resp.data.audio_url || resp.data.audio_file;

                if (audio_url) {
                    const voiceChannel = interaction.member?.voice?.channel;
                    if (voiceChannel) {
                        await playRexAudio(client, {
                            guildId,
                            voiceChannelId: voiceChannel.id,
                            audioUrl: audio_url,
                            title: `🤖 Rex: ${reply_text.slice(0, 50)}`,
                        });
                    }
                }

                return client.embed({
                    title: `🤖・Rex`,
                    desc: reply_text || "I'm here, but I have nothing to say.",
                    fields: [{ name: 'You asked', value: `\`${question}\``, inline: false }],
                    type: 'editreply',
                }, interaction);

            } catch (err) {
                console.error('[Rex] API Error:', err.message);
                return client.errNormal({
                    error: `Rex is having a moment (AI Provider Error: ${err.message}). Try again in a sec.`,
                    type: 'editreply',
                }, interaction);
            }
        }

        // For all other subcommands, use the standard loader
        // Note: deferReply is handled by the subcommands themselves usually, 
        // but for 'join' it might be needed.
        client.loadSubcommands(client, interaction, args);
    },
};
