import fs from 'fs';
import os from 'os';
import path from 'path';
import { EmbedBuilder } from 'discord.js';
import {
  joinVoiceChannel,
  getVoiceConnection,
  createAudioPlayer,
  entersState,
  VoiceConnectionStatus,
  AudioPlayerStatus,
  EndBehaviorType,
  NoSubscriberBehavior,
} from '@discordjs/voice';
import { synthesizeSpeech, askAi } from './ai.js';
import { createFfmpegAudioResource } from './ffmpeg.js';

const WAKE_WORD = (process.env.REX_WAKE_WORD || 'hey rex').toLowerCase();
const rexState = new Map();

function rexApiUrl() {
  return (process.env.REX_API_URL || '').replace(/\/$/, '');
}

function rexApiKey() {
  return process.env.REX_API_KEY || '';
}

function groqKey() {
  return process.env.GROQ_API_KEY || process.env.GROQ || '';
}

export function getRexState(guildId) {
  return rexState.get(guildId) || null;
}

function setRexState(guildId, patch) {
  const prev = rexState.get(guildId) || { active: false, voice: 'am_adam' };
  const next = { ...prev, ...patch };
  rexState.set(guildId, next);
  return next;
}

async function chatViaRexApi(guildId, text, voice) {
  const base = rexApiUrl();
  if (!base) return null;
  const res = await fetch(`${base}/chat`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(rexApiKey() ? { 'X-API-Key': rexApiKey() } : {}),
    },
    body: JSON.stringify({ guild_id: guildId, user_text: text, voice }),
    signal: AbortSignal.timeout(30000),
  });
  if (!res.ok) throw new Error(`Rex API HTTP ${res.status}`);
  return res.json();
}

async function transcribeViaRexApi(wavPath) {
  const base = rexApiUrl();
  if (!base) return null;
  const buf = await fs.promises.readFile(wavPath);
  const form = new FormData();
  form.append('audio', new Blob([buf], { type: 'audio/wav' }), 'audio.wav');
  const res = await fetch(`${base}/transcribe`, {
    method: 'POST',
    headers: {
      ...(rexApiKey() ? { 'X-API-Key': rexApiKey() } : {}),
    },
    body: form,
    signal: AbortSignal.timeout(20000),
  });
  if (!res.ok) throw new Error(`Rex STT HTTP ${res.status}`);
  const data = await res.json();
  return (data.text || '').trim();
}

async function transcribeViaGroq(wavPath) {
  const key = groqKey();
  if (!key) return null;
  const buf = await fs.promises.readFile(wavPath);
  const form = new FormData();
  form.append('file', new Blob([buf], { type: 'audio/wav' }), 'audio.wav');
  form.append('model', 'whisper-large-v3-turbo');
  form.append('language', 'en');
  const res = await fetch('https://api.groq.com/openai/v1/audio/transcriptions', {
    method: 'POST',
    headers: { Authorization: `Bearer ${key}` },
    body: form,
    signal: AbortSignal.timeout(30000),
  });
  if (!res.ok) {
    const errText = await res.text().catch(() => '');
    throw new Error(`Groq STT HTTP ${res.status}: ${errText.slice(0, 120)}`);
  }
  const data = await res.json();
  return (data.text || '').trim();
}

async function chatViaGroq(text) {
  const key = groqKey();
  if (!key) return null;
  const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${key}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: process.env.GROQ_CHAT_MODEL || 'llama-3.1-8b-instant',
      messages: [
        {
          role: 'system',
          content:
            'You are Rex, a witty Discord/FiveM voice assistant for Phantom World. Keep answers short and conversational for voice (1-3 sentences).',
        },
        { role: 'user', content: text },
      ],
      temperature: 0.7,
      max_tokens: 220,
    }),
    signal: AbortSignal.timeout(30000),
  });
  if (!res.ok) throw new Error(`Groq chat HTTP ${res.status}`);
  const data = await res.json();
  return data.choices?.[0]?.message?.content?.trim() || null;
}

async function writeWavFromOpusChunks(opusChunks, outWav) {
  const prism = await import('prism-media');
  const Decoder = prism.default?.opus?.Decoder || prism.opus?.Decoder;
  if (!Decoder) throw new Error('prism-media opus decoder missing — npm i prism-media @discordjs/opus');

  const decoder = new Decoder({ frameSize: 960, channels: 2, rate: 48000 });
  const outs = [];
  await new Promise((resolve, reject) => {
    decoder.on('data', (d) => outs.push(d));
    decoder.on('end', resolve);
    decoder.on('error', reject);
    for (const c of opusChunks) decoder.write(c);
    decoder.end();
  });

  const pcmBuf = Buffer.concat(outs);
  const header = Buffer.alloc(44);
  header.write('RIFF', 0);
  header.writeUInt32LE(36 + pcmBuf.length, 4);
  header.write('WAVE', 8);
  header.write('fmt ', 12);
  header.writeUInt32LE(16, 16);
  header.writeUInt16LE(1, 20);
  header.writeUInt16LE(2, 22);
  header.writeUInt32LE(48000, 24);
  header.writeUInt32LE(48000 * 2 * 2, 28);
  header.writeUInt16LE(4, 32);
  header.writeUInt16LE(16, 34);
  header.write('data', 36);
  header.writeUInt32LE(pcmBuf.length, 40);
  await fs.promises.writeFile(outWav, Buffer.concat([header, pcmBuf]));
}

async function playAudioBuffer(guild, voiceChannelId, audioBuffer) {
  let connection = getVoiceConnection(guild.id);
  if (!connection) {
    connection = joinVoiceChannel({
      channelId: voiceChannelId,
      guildId: guild.id,
      adapterCreator: guild.voiceAdapterCreator,
      selfDeaf: false,
      selfMute: false,
    });
  }
  await entersState(connection, VoiceConnectionStatus.Ready, 15000);

  const tmp = path.join(os.tmpdir(), `rex-speak-${guild.id}-${Date.now()}.mp3`);
  await fs.promises.writeFile(tmp, audioBuffer);
  const player = createAudioPlayer({ behaviors: { noSubscriber: NoSubscriberBehavior.Play } });
  connection.subscribe(player);
  player.play(createFfmpegAudioResource(tmp));
  await entersState(player, AudioPlayerStatus.Playing, 20000).catch(() => {});
  await entersState(player, AudioPlayerStatus.Idle, 120000).catch(() => {});
  fs.promises.unlink(tmp).catch(() => {});
}

async function playAudioUrl(guild, voiceChannelId, url) {
  let connection = getVoiceConnection(guild.id);
  if (!connection) {
    connection = joinVoiceChannel({
      channelId: voiceChannelId,
      guildId: guild.id,
      adapterCreator: guild.voiceAdapterCreator,
      selfDeaf: false,
      selfMute: false,
    });
  }
  await entersState(connection, VoiceConnectionStatus.Ready, 15000);
  const player = createAudioPlayer({ behaviors: { noSubscriber: NoSubscriberBehavior.Play } });
  connection.subscribe(player);
  player.play(createFfmpegAudioResource(url));
  await entersState(player, AudioPlayerStatus.Playing, 20000).catch(() => {});
  await entersState(player, AudioPlayerStatus.Idle, 120000).catch(() => {});
}

async function answerQuestion(guildId, question, voice) {
  // Prefer dedicated Rex API when online
  try {
    const data = await chatViaRexApi(guildId, question, voice);
    if (data?.reply_text) {
      return { text: data.reply_text, audioUrl: data.audio_url || data.audio_file || null, source: 'rex-api' };
    }
  } catch (err) {
    console.warn('[rex] API chat unavailable:', err.message);
  }

  let text = null;
  try {
    text = await chatViaGroq(question);
  } catch (err) {
    console.warn('[rex] Groq chat failed:', err.message);
  }
  if (!text) {
    text = await askAi(question);
  }

  const audio = await synthesizeSpeech(text);
  return { text, audioBuffer: audio, source: 'fallback' };
}

async function transcribe(wavPath) {
  try {
    const t = await transcribeViaRexApi(wavPath);
    if (t) return t;
  } catch (err) {
    console.warn('[rex] API STT unavailable:', err.message);
  }
  return transcribeViaGroq(wavPath);
}

function wireListening(client, guild, state) {
  const { connection } = state;
  if (!connection || connection.__rexWired) return;
  connection.__rexWired = true;

  connection.receiver.speaking.on('start', async (userId) => {
    const live = getRexState(guild.id);
    if (!live?.active || live.processing) return;

    const member = guild.members.cache.get(userId) || (await guild.members.fetch(userId).catch(() => null));
    if (!member || member.user.bot) return;

    const audioStream = connection.receiver.subscribe(userId, {
      end: { behavior: EndBehaviorType.AfterSilence, duration: 1500 },
    });

    const chunks = [];
    audioStream.on('data', (c) => chunks.push(c));
    audioStream.on('end', async () => {
      const current = getRexState(guild.id);
      if (!current?.active || chunks.length < 8) return;

      const wav = path.join(os.tmpdir(), `rex-${guild.id}-${Date.now()}.wav`);
      try {
        await writeWavFromOpusChunks(chunks, wav);

        const transcribed = ((await transcribe(wav)) || '').toLowerCase().trim();
        console.log(`[rex] Heard ${member.user.username}: "${transcribed}"`);
        if (!transcribed.includes(WAKE_WORD)) return;

        const question = transcribed.replace(new RegExp(WAKE_WORD, 'gi'), '').trim();
        const textChannel = await client.channels.fetch(current.textChannelId).catch(() => null);

        if (!question || question.length < 2) {
          if (textChannel?.isTextBased()) {
            await textChannel.send(`🤖 **Rex:** Yeah? What do you want?`);
          }
          return;
        }

        setRexState(guild.id, { processing: true });
        if (textChannel?.isTextBased()) await textChannel.sendTyping().catch(() => {});

        const answer = await answerQuestion(guild.id, question, current.voice || 'am_adam');
        if (textChannel?.isTextBased()) {
          await textChannel.send(`🤖 **Rex** *(to ${member.user.username})*: ${answer.text}`);
        }

        if (answer.audioUrl) {
          await playAudioUrl(guild, current.channelId, answer.audioUrl);
        } else if (answer.audioBuffer) {
          await playAudioBuffer(guild, current.channelId, answer.audioBuffer);
        }
      } catch (err) {
        console.warn('[rex] listen pipeline:', err.message);
      } finally {
        fs.promises.unlink(wav).catch(() => {});
        setRexState(guild.id, { processing: false });
      }
    });
  });

  connection.on(VoiceConnectionStatus.Disconnected, () => {
    setRexState(guild.id, { active: false });
  });
}

export async function rexJoin({ client, guild, member, textChannelId }) {
  const voiceChannel = member?.voice?.channel;
  if (!voiceChannel) {
    throw new Error('Join a voice channel first, then run `/rex join` or `$rex join`.');
  }

  const existing = getRexState(guild.id);
  if (existing?.active) {
    throw new Error(`Rex is already listening in <#${existing.channelId}>. Use \`/rex leave\` first.`);
  }

  const connection = joinVoiceChannel({
    channelId: voiceChannel.id,
    guildId: guild.id,
    adapterCreator: guild.voiceAdapterCreator,
    selfDeaf: false,
    selfMute: false,
  });

  try {
    await entersState(connection, VoiceConnectionStatus.Ready, 15000);
  } catch (err) {
    connection.destroy();
    throw new Error(`Could not join voice: ${err.message}`);
  }

  const state = setRexState(guild.id, {
    active: true,
    channelId: voiceChannel.id,
    textChannelId,
    connection,
    voice: existing?.voice || 'am_adam',
    processing: false,
  });

  wireListening(client, guild, state);

  // Probe backend so we can warn in the reply
  let backend = 'fallback (Groq/Ollama + Edge TTS)';
  try {
    const base = rexApiUrl();
    if (base) {
      const res = await fetch(`${base}/health`, {
        headers: rexApiKey() ? { 'X-API-Key': rexApiKey() } : {},
        signal: AbortSignal.timeout(4000),
      });
      if (res.ok) backend = 'Rex AI server';
    }
  } catch {
    // keep fallback label
  }

  return {
    channelId: voiceChannel.id,
    backend,
    embed: new EmbedBuilder()
      .setColor(0x2ee6c5)
      .setTitle('Rex is listening')
      .setDescription(
        `Joined <#${voiceChannel.id}>.\n\nSay **"${WAKE_WORD}"** followed by your question.\n\n_Example: "Hey Rex, how do I join the server?"_`,
      )
      .addFields(
        { name: 'Wake word', value: `\`${WAKE_WORD}\``, inline: true },
        { name: 'Backend', value: backend, inline: true },
      ),
  };
}

export async function rexLeave(guildId) {
  const state = getRexState(guildId);
  if (!state?.active) {
    throw new Error("Rex isn't in a voice channel right now.");
  }
  const connection = getVoiceConnection(guildId) || state.connection;
  if (connection) {
    try {
      connection.destroy();
    } catch {
      // ignore
    }
  }
  setRexState(guildId, { active: false, connection: null, processing: false });
  return true;
}

export async function rexAsk({ client, guild, member, question }) {
  if (!question?.trim()) {
    throw new Error('Usage: `/rex ask question:...` or `$rex ask your question`');
  }
  const state = getRexState(guild.id) || { voice: 'am_adam' };
  const answer = await answerQuestion(guild.id, question.trim(), state.voice || 'am_adam');

  const voiceChannel = member?.voice?.channel;
  if (voiceChannel && (answer.audioUrl || answer.audioBuffer)) {
    try {
      if (answer.audioUrl) await playAudioUrl(guild, voiceChannel.id, answer.audioUrl);
      else await playAudioBuffer(guild, voiceChannel.id, answer.audioBuffer);
    } catch (err) {
      console.warn('[rex] ask playback failed:', err.message);
    }
  }

  return new EmbedBuilder()
    .setColor(0x2ee6c5)
    .setTitle('Rex')
    .setDescription(answer.text || "I'm here, but I have nothing to say.")
    .addFields({ name: 'You asked', value: `\`${question.slice(0, 200)}\`` });
}

export function rexSetVoice(guildId, voice) {
  setRexState(guildId, { voice });
  const names = {
    am_adam: 'Adam (US Male)',
    am_michael: 'Michael (US Male)',
    bm_george: 'George (British Male)',
    af_heart: 'Heart (US Female)',
    af_bella: 'Bella (US Female)',
    bf_emma: 'Emma (British Female)',
  };
  return names[voice] || voice;
}

export async function rexReset(guildId) {
  const base = rexApiUrl();
  if (!base) {
    setRexState(guildId, { memory: null });
    return true;
  }
  const res = await fetch(`${base}/reset`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(rexApiKey() ? { 'X-API-Key': rexApiKey() } : {}),
    },
    body: JSON.stringify({ guild_id: guildId }),
    signal: AbortSignal.timeout(10000),
  });
  if (!res.ok) throw new Error(`Rex reset HTTP ${res.status}`);
  return true;
}

export async function rexSetMode(guildId, enable) {
  const base = rexApiUrl();
  if (!base) throw new Error('Rex AI server is offline — mode toggle unavailable until REX_API_URL is back.');
  const res = await fetch(`${base}/mode`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(rexApiKey() ? { 'X-API-Key': rexApiKey() } : {}),
    },
    body: JSON.stringify({ guild_id: guildId, unrestricted: enable }),
    signal: AbortSignal.timeout(10000),
  });
  if (!res.ok) throw new Error(`Rex mode HTTP ${res.status}`);
  return enable;
}
