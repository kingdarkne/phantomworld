const axios = require('axios');
const { playRexAudio } = require('../../../lib/rex-voice-play.cjs');
const { askAi } = require('../../lib/phantom-ai');
const { synthesizeSpeech } = require('../../lib/phantom-say');
const fs = require('fs');
const os = require('os');
const path = require('path');

const REX_API_URL = process.env.REX_API_URL || 'http://23.238.64.91:5600';
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
      {
        guild_id: guildId,
        user_text: question,
        voice,
      },
      {
        headers: { 'X-API-Key': REX_API_KEY, 'Content-Type': 'application/json' },
        timeout: 20000,
      },
    );
    reply_text = resp.data.reply_text;
    audio_url = resp.data.audio_url || resp.data.audio_file;
  } catch (err) {
    console.warn('[Rex ask] API failed, falling back to Groq/local AI:', err.message);
    via = 'groq-fallback';
    try {
      reply_text = await askAi(question);
    } catch (aiErr) {
      console.error('[Rex ask] fallback AI failed:', aiErr.message);
      return client.errNormal(
        {
          error: `Rex is having a moment (AI Connection Error). Try again in a sec.`,
          type: 'editreply',
        },
        interaction,
      );
    }
  }

  // Prefer Rex API audio; otherwise synthesize locally if user is in VC
  const voiceChannel = interaction.member?.voice?.channel;
  if (voiceChannel) {
    try {
      if (audio_url) {
        await playRexAudio(client, {
          guildId,
          voiceChannelId: voiceChannel.id,
          audioUrl: audio_url,
          title: `🤖 Rex: ${(reply_text || '').slice(0, 50)}`,
        });
      } else if (reply_text) {
        const audio = await synthesizeSpeech(reply_text);
        if (audio) {
          const tmpFile = path.join(os.tmpdir(), `rex-ask-${guildId}-${Date.now()}.mp3`);
          await fs.promises.writeFile(tmpFile, audio);
          const { createAudioResource, StreamType, createAudioPlayer, joinVoiceChannel, getVoiceConnection, NoSubscriberBehavior } =
            require('@discordjs/voice');
          let connection = getVoiceConnection(guildId);
          if (!connection) {
            connection = joinVoiceChannel({
              channelId: voiceChannel.id,
              guildId,
              adapterCreator: interaction.guild.voiceAdapterCreator,
              selfDeaf: false,
            });
          }
          const player = createAudioPlayer({
            behaviors: { noSubscriber: NoSubscriberBehavior.Play },
          });
          connection.subscribe(player);
          player.play(createAudioResource(tmpFile, { inputType: StreamType.Arbitrary }));
          fs.promises.unlink(tmpFile).catch(() => {});
        }
      }
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
        ...(via === 'groq-fallback'
          ? [{ name: 'Mode', value: 'Local AI fallback (Rex API unreachable)', inline: true }]
          : []),
      ],
      type: 'editreply',
    },
    interaction,
  );
};
