/**
 * Rex VC listen pipeline — wake word "Hey Rex" → STT → chat → speak.
 * Uses prism-media to decode Discord Opus frames (raw packets are NOT .opus files).
 */
const fs = require('fs');
const os = require('os');
const path = require('path');
const axios = require('axios');
const {
  joinVoiceChannel,
  getVoiceConnection,
  VoiceConnectionStatus,
  EndBehaviorType,
  entersState,
} = require('@discordjs/voice');
const { playRexAudio, stopShoukakuGuild } = require('./rex-voice-play.cjs');

const REX_API_URL = (process.env.REX_API_URL || 'http://127.0.0.1:5600').replace(/\/$/, '');
const REX_API_KEY = process.env.REX_API_KEY || '';
const WAKE_WORD = (process.env.REX_WAKE_WORD || 'hey rex').toLowerCase();

if (!global.rexState) global.rexState = {};

function wakeMatched(text) {
  const t = String(text || '')
    .toLowerCase()
    .replace(/[^\w\s']/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
  if (!t) return false;
  if (t.includes(WAKE_WORD)) return true;
  // common mis-hears
  const alts = [
    'hey rex',
    'hey wrecks',
    'hey recks',
    'a rex',
    'hey racks',
    'hey rx',
    'hey rix',
    'hey rex,',
  ];
  if (alts.some((a) => t.includes(a))) return true;
  // bare "rex ..." at start
  if (/^(hey\s+)?rex\b/.test(t)) return true;
  return false;
}

function stripWake(text) {
  return String(text || '')
    .replace(/hey\s+(wrecks|recks|racks|rex|rix|rx)/gi, '')
    .replace(/\brex\b/gi, '')
    .replace(/[^\w\s']/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

async function writeWavFromOpusPackets(opusChunks, outWav) {
  let Decoder;
  try {
    const prism = require('prism-media');
    Decoder = prism.opus?.Decoder || prism.default?.opus?.Decoder;
  } catch (err) {
    throw new Error(`prism-media missing: ${err.message}`);
  }
  if (!Decoder) throw new Error('prism-media opus Decoder unavailable');

  const decoder = new Decoder({ frameSize: 960, channels: 2, rate: 48000 });
  const pcmParts = [];

  await new Promise((resolve, reject) => {
    decoder.on('data', (d) => pcmParts.push(d));
    decoder.on('end', resolve);
    decoder.on('error', reject);
    for (const chunk of opusChunks) {
      try {
        decoder.write(chunk);
      } catch (_) {
        // skip bad frames
      }
    }
    decoder.end();
  });

  const pcmBuf = Buffer.concat(pcmParts);
  if (pcmBuf.length < 1000) throw new Error(`PCM too short (${pcmBuf.length} bytes)`);

  // Downmix stereo 48k → mono 16k for Whisper via ffmpeg
  const tmpPcm = `${outWav}.s16le`;
  await fs.promises.writeFile(tmpPcm, pcmBuf);
  const { execFileSync } = require('child_process');
  try {
    execFileSync(
      'ffmpeg',
      [
        '-y',
        '-f',
        's16le',
        '-ar',
        '48000',
        '-ac',
        '2',
        '-i',
        tmpPcm,
        '-ar',
        '16000',
        '-ac',
        '1',
        outWav,
      ],
      { stdio: ['ignore', 'ignore', 'pipe'] },
    );
  } finally {
    fs.promises.unlink(tmpPcm).catch(() => {});
  }
  if (!fs.existsSync(outWav)) throw new Error('ffmpeg did not write wav');
}

async function transcribeWav(wavPath) {
  const FormData = require('form-data');
  const form = new FormData();
  form.append('audio', fs.createReadStream(wavPath), {
    filename: 'audio.wav',
    contentType: 'audio/wav',
  });
  const sttResp = await axios.post(`${REX_API_URL}/transcribe`, form, {
    headers: { ...form.getHeaders(), 'X-API-Key': REX_API_KEY },
    timeout: 30000,
    maxContentLength: Infinity,
    maxBodyLength: Infinity,
  });
  return (sttResp.data?.text || '').trim();
}

async function chatRex(guildId, userText, voice) {
  const chatResp = await axios.post(
    `${REX_API_URL}/chat`,
    { guild_id: guildId, user_text: userText || 'Hello', voice: voice || 'am_adam' },
    {
      headers: { 'X-API-Key': REX_API_KEY, 'Content-Type': 'application/json' },
      timeout: 45000,
    },
  );
  return chatResp.data;
}

function wireListening(client, guild, connection) {
  if (connection.__rexWired) return;
  connection.__rexWired = true;

  connection.receiver.speaking.on('start', async (userId) => {
    const guildId = guild.id;
    const state = global.rexState[guildId];
    if (!state?.active || state.processing) return;
    if (userId === client.user?.id) return;

    console.log(`[Rex VC] speaking start userId=${userId}`);

    let displayName = userId;
    try {
      const member =
        guild.members.cache.get(userId) || (await guild.members.fetch(userId).catch(() => null));
      if (member?.user?.bot) return;
      displayName = member?.user?.username || userId;
    } catch (_) {
      // continue without member — still try to listen
    }

    const audioStream = connection.receiver.subscribe(userId, {
      end: { behavior: EndBehaviorType.AfterSilence, duration: 1800 },
    });

    const chunks = [];
    audioStream.on('data', (chunk) => chunks.push(chunk));
    audioStream.on('error', (err) => console.warn('[Rex VC] subscribe error:', err.message));

    audioStream.on('end', async () => {
      const live = global.rexState[guildId];
      if (!live?.active) return;
      if (chunks.length < 8) {
        console.log(`[Rex VC] ignore short utterance chunks=${chunks.length}`);
        return;
      }

      const wav = path.join(os.tmpdir(), `rex-${guildId}-${Date.now()}.wav`);
      try {
        console.log(`[Rex VC] decoding ${chunks.length} frames from ${displayName}`);
        await writeWavFromOpusPackets(chunks, wav);
        const transcribed = await transcribeWav(wav);
        console.log(`[Rex VC] Heard ${displayName}: "${transcribed}"`);

        if (!wakeMatched(transcribed)) {
          console.log('[Rex VC] no wake word — ignoring');
          return;
        }

        const question = stripWake(transcribed) || 'Hello';
        live.processing = true;

        const targetChannel =
          client.channels.cache.get(live.textChannelId) ||
          (await client.channels.fetch(live.textChannelId).catch(() => null));

        if (targetChannel?.isTextBased?.()) {
          await targetChannel.send(`🤖 **Rex:** I heard you! Thinking...`).catch(() => {});
        }

        const data = await chatRex(guildId, question, live.voice);
        const reply_text = data.reply_text || "I'm here.";
        const audio_url = data.audio_url || data.audio_file;

        if (targetChannel?.isTextBased?.()) {
          await targetChannel
            .send(`🤖 **Rex** *(to ${displayName})*: ${reply_text}`)
            .catch(() => {});
        }

        if (audio_url) {
          // MUST stay on discord.js connection — Lavalink would kill the listener
          const ok = await playRexAudio(client, {
            guildId,
            voiceChannelId: live.channelId,
            audioUrl: audio_url,
            title: `Rex: ${reply_text.slice(0, 40)}`,
            forceDirect: true,
          });
          console.log(`[Rex VC] playback ok=${ok}`);
        }
      } catch (err) {
        const msg = err?.response?.data?.error || err.message || 'listen failed';
        console.error('[Rex VC] Error:', msg);
        // Rate-limit Discord error posts so one bad STT loop does not spam the channel.
        const liveErr = global.rexState[guildId];
        const now = Date.now();
        if (!liveErr || !liveErr._lastErrPost || now - liveErr._lastErrPost > 15000) {
          if (liveErr) liveErr._lastErrPost = now;
          try {
            const ch = client.channels.cache.get(global.rexState[guildId]?.textChannelId);
            await ch?.send?.(`🤖 **Rex:** Listen error — ${String(msg)}`.slice(0, 400)).catch(() => {});
          } catch (_) {}
        }
      } finally {
        if (global.rexState[guildId]) global.rexState[guildId].processing = false;
        fs.promises.unlink(wav).catch(() => {});
      }
    });
  });

  connection.on(VoiceConnectionStatus.Disconnected, async () => {
    console.warn('[Rex VC] disconnected');
    if (global.rexState[guild.id]) global.rexState[guild.id].active = false;
  });
}

async function rexJoinListen(client, interaction) {
  const voiceChannel = interaction.member?.voice?.channel;
  if (!voiceChannel) {
    throw new Error('You need to be in a voice channel first!');
  }

  const guildId = interaction.guild.id;

  // Kick radio/music off this guild so we own the VC for receiving
  await stopShoukakuGuild(client, guildId);
  const existing = getVoiceConnection(guildId);
  if (existing) {
    try {
      existing.destroy();
    } catch (_) {}
  }
  await new Promise((r) => setTimeout(r, 500));

  const connection = joinVoiceChannel({
    channelId: voiceChannel.id,
    guildId,
    adapterCreator: interaction.guild.voiceAdapterCreator,
    selfDeaf: false,
    selfMute: false,
  });

  await entersState(connection, VoiceConnectionStatus.Ready, 20_000);

  global.rexState[guildId] = {
    active: true,
    channelId: voiceChannel.id,
    textChannelId: interaction.channel.id,
    connection,
    voice: global.rexState[guildId]?.voice || 'am_adam',
    processing: false,
  };

  wireListening(client, interaction.guild, connection);

  console.log(
    `[Rex Join] listening in guild=${guildId} channel=${voiceChannel.id} wake="${WAKE_WORD}"`,
  );

  return {
    channelId: voiceChannel.id,
    wakeWord: WAKE_WORD,
  };
}

module.exports = {
  rexJoinListen,
  wakeMatched,
  wireListening,
};
