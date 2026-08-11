const axios = require('axios');
const { playRexAudio } = require('../../lib/rex-voice-play.cjs');
const { askAi } = require('../../lib/phantom-ai');

const REX_API_URL = (process.env.REX_API_URL || 'http://127.0.0.1:5600').replace(/\/$/, '');
const REX_API_KEY = process.env.REX_API_KEY || '';

module.exports = async (client, interaction, args = []) => {
  if (!interaction.deferred && !interaction.replied) {
    await interaction.deferReply().catch(() => {});
  }

  const question =
    interaction.options?.getString?.('question') ||
    (Array.isArray(args) ? args.join(' ') : '') ||
    '';

  if (!question.trim()) {
    return client.errNormal(
      { error: 'Usage: `/rex ask question:...` or `$rex ask <question>`', type: 'editreply' },
      interaction,
    );
  }

  const guildId = interaction.guild.id;
  const state = global.rexState?.[guildId] || {};
  const voice = state.voice || 'am_adam';

  await client
    .simpleEmbed({ desc: `🤖 Rex is thinking...`, type: 'editreply' }, interaction)
    .catch(() => {});

  let reply_text = '';
  let audio_url = '';
  let via = 'rex-api';

  try {
    const resp = await axios.post(
      `${REX_API_URL}/chat`,
      { guild_id: guildId, user_text: question, voice },
      {
        headers: { 'X-API-Key': REX_API_KEY, 'Content-Type': 'application/json' },
        timeout: 45000,
      },
    );
    reply_text = resp.data.reply_text;
    audio_url = resp.data.audio_url || resp.data.audio_file;
  } catch (err) {
    console.warn('[Rex ask] API failed, falling back to Groq:', err.message);
    via = 'groq-fallback';
    try {
      reply_text = await askAi(question);
    } catch (aiErr) {
      return client.errNormal(
        { error: `Rex is having a moment (${aiErr.message}).`, type: 'editreply' },
        interaction,
      );
    }
  }

  // Ensure we have a playable URL (Lavalink-friendly)
  if (!audio_url && reply_text) {
    try {
      const tts = await axios.post(
        `${REX_API_URL}/tts`,
        { text: reply_text, voice },
        {
          headers: { 'X-API-Key': REX_API_KEY, 'Content-Type': 'application/json' },
          timeout: 30000,
        },
      );
      audio_url = tts.data.url || tts.data.audio_url;
    } catch (ttsErr) {
      console.warn('[Rex ask] /tts failed:', ttsErr.message);
    }
  }

  const voiceChannel = interaction.member?.voice?.channel;
  let played = false;
  if (voiceChannel && audio_url) {
    try {
      played = await playRexAudio(client, {
        guildId,
        voiceChannelId: voiceChannel.id,
        audioUrl: audio_url,
        title: `🤖 Rex: ${(reply_text || '').slice(0, 50)}`,
      });
    } catch (audioErr) {
      console.warn('[Rex ask] Audio playback failed:', audioErr.message);
    }
  }

  return client.embed(
    {
      title: `🤖・Rex`,
      desc: reply_text || "I'm here, but I have nothing to say.",
      fields: [
        { name: 'You asked', value: `\`${question.slice(0, 900)}\``, inline: false },
        {
          name: 'Voice',
          value: voiceChannel
            ? played
              ? `Playing in <#${voiceChannel.id}>`
              : `In VC but playback failed — try again`
            : 'Join a voice channel to hear Rex',
          inline: true,
        },
        ...(via === 'groq-fallback'
          ? [{ name: 'Mode', value: 'Local AI fallback', inline: true }]
          : []),
      ],
      type: 'editreply',
    },
    interaction,
  );
};
