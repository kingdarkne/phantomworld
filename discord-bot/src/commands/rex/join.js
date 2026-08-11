const {
  joinVoiceChannel,
  getVoiceConnection,
  VoiceConnectionStatus,
  EndBehaviorType,
  entersState,
} = require('@discordjs/voice');
const axios = require('axios');
const fs = require('fs');
const { playRexAudio, stopShoukakuGuild } = require('../../lib/rex-voice-play.cjs');

const REX_API_URL = (process.env.REX_API_URL || 'http://127.0.0.1:5600').replace(/\/$/, '');
const REX_API_KEY = process.env.REX_API_KEY || '';
const WAKE_WORD = (process.env.REX_WAKE_WORD || 'hey rex').toLowerCase();

if (!global.rexState) global.rexState = {};

module.exports = async (client, interaction) => {
  if (!interaction.deferred && !interaction.replied) {
    await interaction.deferReply().catch(() => {});
  }

  const voiceChannel = interaction.member?.voice?.channel;
  if (!voiceChannel) {
    return client.errNormal(
      { error: `You need to be in a voice channel first!`, type: 'editreply' },
      interaction,
    );
  }

  const guildId = interaction.guild.id;

  // Radio/music holds Shoukaku VC — release it before Rex listens
  await stopShoukakuGuild(client, guildId);
  const existingConnection = getVoiceConnection(guildId);
  if (existingConnection) {
    try {
      existingConnection.destroy();
    } catch (_) {}
  }
  await new Promise((r) => setTimeout(r, 400));

  try {
    const connection = joinVoiceChannel({
      channelId: voiceChannel.id,
      guildId,
      adapterCreator: interaction.guild.voiceAdapterCreator,
      selfDeaf: false,
      selfMute: false,
    });

    await entersState(connection, VoiceConnectionStatus.Ready, 15_000);

    global.rexState[guildId] = {
      active: true,
      channelId: voiceChannel.id,
      textChannelId: interaction.channel.id,
      connection,
      voice: global.rexState[guildId]?.voice || 'am_adam',
      processing: false,
    };

    await client.embed(
      {
        title: `🤖・Rex is Listening`,
        desc: `Rex has joined <#${voiceChannel.id}>!\n\nSay **"Hey Rex"** to talk to me.`,
        fields: [
          { name: 'Wake Word', value: '`Hey Rex`', inline: true },
          { name: 'Voice', value: '🔵 Adam', inline: true },
          { name: 'Audio', value: 'Local Rex AI + voice playback', inline: true },
        ],
        type: 'editreply',
      },
      interaction,
    );

    connection.receiver.speaking.on('start', async (userId) => {
      const state = global.rexState[guildId];
      if (!state?.active || state.processing) return;

      const user =
        interaction.guild.members.cache.get(userId) ||
        (await interaction.guild.members.fetch(userId).catch(() => null));
      if (!user || user.user.bot) return;

      console.log(`[Rex VC] Started hearing ${user.user.username}...`);

      const audioStream = connection.receiver.subscribe(userId, {
        end: { behavior: EndBehaviorType.AfterSilence, duration: 1500 },
      });

      const chunks = [];
      audioStream.on('data', (chunk) => chunks.push(chunk));

      audioStream.on('end', async () => {
        if (!state?.active || chunks.length < 5) return;

        const tmpWav = `/tmp/rex_vc_${guildId}_${Date.now()}.wav`;
        const tmpOpus = tmpWav.replace('.wav', '.opus');

        try {
          fs.writeFileSync(tmpOpus, Buffer.concat(chunks));
          const { execSync } = require('child_process');
          try {
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
            timeout: 20000,
          });

          const transcribed = (sttResp.data.text || '').toLowerCase().trim();
          console.log(`[Rex VC] Heard: "${transcribed}"`);
          if (!transcribed.includes(WAKE_WORD)) return;

          const targetChannel =
            client.channels.cache.get(state.textChannelId) || interaction.channel;
          if (targetChannel?.isTextBased?.()) {
            await targetChannel.send(`🤖 **Rex:** I heard you! Thinking... 🧠`).catch(() => {});
          }

          const question = transcribed.replace(new RegExp(WAKE_WORD, 'gi'), '').trim();
          state.processing = true;

          const chatResp = await axios.post(
            `${REX_API_URL}/chat`,
            {
              guild_id: guildId,
              user_text: question || 'Hello',
              voice: state.voice || 'am_adam',
            },
            {
              headers: { 'X-API-Key': REX_API_KEY, 'Content-Type': 'application/json' },
              timeout: 45000,
            },
          );

          const { reply_text, audio_url } = chatResp.data;
          if (targetChannel?.isTextBased?.()) {
            await targetChannel
              .send(`🤖 **Rex** *(to ${user.user.username})*: ${reply_text}`)
              .catch(() => {});
          }

          if (audio_url) {
            const ok = await playRexAudio(client, {
              guildId,
              voiceChannelId: state.channelId,
              audioUrl: audio_url,
              title: `Rex: ${(reply_text || '').slice(0, 40)}`,
            });
            console.log(`[Rex VC] playback ok=${ok}`);
          }
        } catch (err) {
          console.error('[Rex VC] Error:', err.message);
        } finally {
          state.processing = false;
          try {
            if (fs.existsSync(tmpOpus)) fs.unlinkSync(tmpOpus);
          } catch (_) {}
          try {
            if (fs.existsSync(tmpWav)) fs.unlinkSync(tmpWav);
          } catch (_) {}
        }
      });
    });

    connection.on(VoiceConnectionStatus.Disconnected, () => {
      if (global.rexState[guildId]) global.rexState[guildId].active = false;
    });
  } catch (err) {
    console.error('[Rex Join] Error:', err.message);
    return client.errNormal(
      { error: `Rex failed to join. Try again in a moment.`, type: 'editreply' },
      interaction,
    );
  }
};
