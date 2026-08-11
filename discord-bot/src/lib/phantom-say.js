/**
 * Phantom `$say` / `/say` TTS — URL / Edge / Google fallbacks (slim-bot merge).
 */
const fs = require('fs');
const os = require('os');
const path = require('path');
const {
  joinVoiceChannel,
  createAudioPlayer,
  createAudioResource,
  AudioPlayerStatus,
  entersState,
  NoSubscriberBehavior,
  StreamType,
} = require('@discordjs/voice');

const ttsSessions = new Map();

function getSession(guildId) {
  if (!ttsSessions.has(guildId)) {
    ttsSessions.set(guildId, { connection: null, player: null });
  }
  return ttsSessions.get(guildId);
}

async function synthesizeFromUrl(text) {
  const url = (process.env.TTS_API_URL || '').replace(/\/$/, '');
  if (!url) return null;
  const voice =
    process.env.TTS_VOICE || process.env.TTS_DEFAULT_VOICE || process.env.EDGE_TTS_VOICE || 'af_heart';
  const timeoutMs = Number(process.env.TTS_URL_TIMEOUT_MS || 8000);
  const headers = { 'Content-Type': 'application/json' };
  const key = process.env.TTS_API_KEY || process.env.REX_API_KEY || '';
  if (key) {
    headers.Authorization = `Bearer ${key}`;
    headers['X-API-Key'] = key;
  }
  const res = await fetch(url, {
    method: 'POST',
    headers,
    body: JSON.stringify({ text, input: text, voice }),
    signal: AbortSignal.timeout(timeoutMs),
  });
  if (!res.ok) throw new Error(`TTS API HTTP ${res.status}`);
  const type = res.headers.get('content-type') || '';
  if (type.includes('json')) {
    const data = await res.json();
    if (data.url) {
      const audioRes = await fetch(data.url, { signal: AbortSignal.timeout(30000) });
      return Buffer.from(await audioRes.arrayBuffer());
    }
    if (data.audio) return Buffer.from(data.audio, 'base64');
    return null;
  }
  return Buffer.from(await res.arrayBuffer());
}

async function synthesizeEdge(text) {
  const voice = process.env.EDGE_TTS_VOICE || 'en-US-JennyNeural';
  const { MsEdgeTTS, OUTPUT_FORMAT } = await import('msedge-tts');
  const tts = new MsEdgeTTS();
  await tts.setMetadata(voice, OUTPUT_FORMAT.AUDIO_24KHZ_48KBITRATE_MONO_MP3);
  const { audioStream } = tts.toStream(text.slice(0, 500));
  const chunks = [];
  await new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('Edge TTS timeout')), 45000);
    audioStream.on('data', (d) => chunks.push(d));
    audioStream.on('close', () => {
      clearTimeout(timer);
      resolve();
    });
    audioStream.on('end', () => {
      clearTimeout(timer);
      resolve();
    });
    audioStream.on('error', (err) => {
      clearTimeout(timer);
      reject(err);
    });
  });
  const buf = Buffer.concat(chunks);
  return buf.length > 500 ? buf : null;
}

async function synthesizeGoogle(text) {
  const chunks = [];
  const parts = text.match(/.{1,180}(\s|$)/g) || [text.slice(0, 180)];
  for (const part of parts.slice(0, 4)) {
    const q = encodeURIComponent(part.trim());
    if (!q) continue;
    const res = await fetch(
      `https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&q=${q}&tl=en`,
      {
        headers: { 'User-Agent': 'Mozilla/5.0' },
        signal: AbortSignal.timeout(15000),
      },
    );
    if (!res.ok) throw new Error(`Google TTS HTTP ${res.status}`);
    chunks.push(Buffer.from(await res.arrayBuffer()));
  }
  const buf = Buffer.concat(chunks);
  return buf.length > 200 ? buf : null;
}

async function tryProvider(name, fn) {
  try {
    const audio = await fn();
    if (audio?.length) {
      console.log(`[phantom-say] TTS via ${name} (${audio.length} bytes)`);
      return audio;
    }
  } catch (err) {
    console.warn(`[phantom-say] TTS ${name} failed:`, err.message);
  }
  return null;
}

async function synthesizeSpeech(text) {
  const trimmed = (text || '').trim().slice(0, 500);
  if (!trimmed) return null;
  if (process.env.TTS_API_URL) {
    const audio = await tryProvider('url', () => synthesizeFromUrl(trimmed));
    if (audio) return audio;
  }
  const edge = await tryProvider('edge', () => synthesizeEdge(trimmed));
  if (edge) return edge;
  return tryProvider('google', () => synthesizeGoogle(trimmed));
}

async function speakInChannel({ guild, guildId, member, text }) {
  const voiceChannel = member?.voice?.channel;
  if (!voiceChannel) {
    throw new Error('Join a voice channel first.');
  }

  const audio = await synthesizeSpeech(text);
  if (!audio) {
    throw new Error(
      'Voice TTS failed after trying Kokoro URL, Edge, and Google fallbacks. Check TTS_API_URL or EDGE_TTS_VOICE.',
    );
  }

  const tmpFile = path.join(os.tmpdir(), `phantom-tts-${guildId}-${Date.now()}.mp3`);
  await fs.promises.writeFile(tmpFile, audio);

  const session = getSession(guildId);
  if (!session.connection) {
    session.connection = joinVoiceChannel({
      channelId: voiceChannel.id,
      guildId,
      adapterCreator: guild.voiceAdapterCreator,
      selfDeaf: false,
    });
    session.player = createAudioPlayer({ behaviors: { noSubscriber: NoSubscriberBehavior.Play } });
    session.connection.subscribe(session.player);
  }

  const resource = createAudioResource(tmpFile, { inputType: StreamType.Arbitrary });
  session.player.play(resource);
  await entersState(session.player, AudioPlayerStatus.Playing, 20000);
  await entersState(session.player, AudioPlayerStatus.Idle, 120000);
  fs.promises.unlink(tmpFile).catch(() => {});
  return true;
}

function leaveTtsVoice(guildId) {
  const session = ttsSessions.get(guildId);
  if (!session?.connection) return false;
  session.connection.destroy();
  ttsSessions.delete(guildId);
  return true;
}

module.exports = { speakInChannel, leaveTtsVoice, synthesizeSpeech };
