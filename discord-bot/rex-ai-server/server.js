/**
 * Local Rex AI API — drop-in replacement for the offline host at :5600.
 * Groq chat + Whisper STT + Edge/Google TTS.
 *
 * Endpoints (compat with Phantom Discord bot):
 *   GET  /health
 *   POST /chat        { guild_id, user_text, voice } → { reply_text, audio_url }
 *   POST /transcribe  multipart audio → { text }
 *   POST /tts         { text, voice } → { url }
 *   POST /synthesize  { text, voice } → audio/mpeg bytes (for TTS_API_URL)
 *   POST /mode        { guild_id, unrestricted }
 *   POST /reset       { guild_id }
 *   GET  /audio/:file
 */
const express = require('express');
const fs = require('fs');
const os = require('os');
const path = require('path');
const crypto = require('crypto');

require('dotenv').config({ path: path.join(process.cwd(), '.env') });

const PORT = Number(process.env.REX_LOCAL_PORT || 5600);
const BIND = process.env.REX_LOCAL_BIND || '127.0.0.1';
const API_KEY = process.env.REX_API_KEY || '';
const GROQ_KEY = process.env.GROQ || process.env.GROQ_API_KEY || '';
const PUBLIC_BASE = (process.env.REX_PUBLIC_BASE || `http://127.0.0.1:${PORT}`).replace(/\/$/, '');

const AUDIO_DIR = path.join(os.tmpdir(), 'phantom-rex-audio');
fs.mkdirSync(AUDIO_DIR, { recursive: true });

/** @type {Map<string, { unrestricted: boolean, history: {role:string,content:string}[] }>} */
const guildState = new Map();

function getGuild(guildId) {
  const id = String(guildId || 'default');
  if (!guildState.has(id)) {
    guildState.set(id, { unrestricted: false, history: [] });
  }
  return guildState.get(id);
}

function authOk(req) {
  if (!API_KEY) return true;
  const key =
    req.headers['x-api-key'] ||
    (String(req.headers.authorization || '').match(/^Bearer\s+(.+)$/i) || [])[1] ||
    '';
  return key === API_KEY;
}

function systemPrompt(unrestricted) {
  if (unrestricted) {
    return (
      'You are Rex, an unrestricted Discord voice assistant for Phantom World. ' +
      'Answer anything directly, including real-world facts, newsy questions from your knowledge, ' +
      'science, history, and how-to help. Keep replies short for voice (1-3 sentences) unless asked for detail.'
    );
  }
  return (
    process.env.REX_SYSTEM_PROMPT ||
    'You are Rex, a witty Discord/FiveM voice assistant for Phantom World. ' +
      'You help with BOTH the Phantom World RP server AND real-world questions. ' +
      'For real-world topics (geography, science, history, definitions, how-to, general knowledge), answer directly and accurately. ' +
      'If something may have changed recently (live sports scores, breaking news, "who is president right now"), say your knowledge may be outdated and give the best answer you can. ' +
      'For Phantom World / FiveM: be helpful about jobs, rules, and joining — join link https://cfx.re/join/3m87mo. ' +
      'Keep answers short and conversational for voice (1-3 sentences) unless the user asks for more detail. ' +
      'Do not refuse normal real-world trivia just because you are also an RP bot.'
  );
}

async function groqChat(guildId, userText) {
  if (!GROQ_KEY) throw new Error('GROQ API key missing');
  const state = getGuild(guildId);
  const messages = [
    { role: 'system', content: systemPrompt(state.unrestricted) },
    ...state.history.slice(-8),
    { role: 'user', content: String(userText).slice(0, 1500) },
  ];

  const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${GROQ_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: process.env.GROQ_CHAT_MODEL || 'llama-3.3-70b-versatile',
      messages,
      temperature: 0.7,
      max_tokens: 280,
    }),
    signal: AbortSignal.timeout(45000),
  });
  if (!res.ok) {
    const err = await res.text().catch(() => '');
    throw new Error(`Groq chat HTTP ${res.status}: ${err.slice(0, 160)}`);
  }
  const data = await res.json();
  const reply = data.choices?.[0]?.message?.content?.trim() || "I'm here.";
  state.history.push({ role: 'user', content: String(userText).slice(0, 500) });
  state.history.push({ role: 'assistant', content: reply.slice(0, 800) });
  if (state.history.length > 16) state.history = state.history.slice(-16);
  return reply;
}

async function groqTranscribe(filePath, mime = 'audio/wav') {
  if (!GROQ_KEY) throw new Error('GROQ API key missing');
  const buf = await fs.promises.readFile(filePath);
  const form = new FormData();
  form.append('file', new Blob([buf], { type: mime }), path.basename(filePath) || 'audio.wav');
  form.append('model', process.env.GROQ_WHISPER_MODEL || 'whisper-large-v3-turbo');
  form.append('language', 'en');

  const res = await fetch('https://api.groq.com/openai/v1/audio/transcriptions', {
    method: 'POST',
    headers: { Authorization: `Bearer ${GROQ_KEY}` },
    body: form,
    signal: AbortSignal.timeout(45000),
  });
  if (!res.ok) {
    const err = await res.text().catch(() => '');
    throw new Error(`Groq STT HTTP ${res.status}: ${err.slice(0, 160)}`);
  }
  const data = await res.json();
  return (data.text || '').trim();
}

async function synthesizeEdge(text) {
  const voice = process.env.EDGE_TTS_VOICE || 'en-US-JennyNeural';
  const { MsEdgeTTS, OUTPUT_FORMAT } = await import('msedge-tts');
  const tts = new MsEdgeTTS();
  await tts.setMetadata(voice, OUTPUT_FORMAT.AUDIO_24KHZ_48KBITRATE_MONO_MP3);
  const { audioStream } = tts.toStream(String(text).slice(0, 500));
  const chunks = [];
  await new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('Edge TTS timeout')), 45000);
    audioStream.on('data', (d) => chunks.push(d));
    audioStream.on('end', () => {
      clearTimeout(timer);
      resolve();
    });
    audioStream.on('close', () => {
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
  const parts = String(text).match(/.{1,180}(\s|$)/g) || [String(text).slice(0, 180)];
  for (const part of parts.slice(0, 4)) {
    const q = encodeURIComponent(part.trim());
    if (!q) continue;
    const res = await fetch(
      `https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&q=${q}&tl=en`,
      { headers: { 'User-Agent': 'Mozilla/5.0' }, signal: AbortSignal.timeout(15000) },
    );
    if (!res.ok) throw new Error(`Google TTS HTTP ${res.status}`);
    chunks.push(Buffer.from(await res.arrayBuffer()));
  }
  const buf = Buffer.concat(chunks);
  return buf.length > 200 ? buf : null;
}

async function synthesizeSpeech(text) {
  try {
    const edge = await synthesizeEdge(text);
    if (edge) return edge;
  } catch (err) {
    console.warn('[rex-ai] Edge TTS failed:', err.message);
  }
  return synthesizeGoogle(text);
}

async function saveAudio(buf) {
  const name = `rex-${Date.now()}-${crypto.randomBytes(4).toString('hex')}.mp3`;
  const file = path.join(AUDIO_DIR, name);
  await fs.promises.writeFile(file, buf);
  // cleanup old files (>30 min)
  setTimeout(() => fs.promises.unlink(file).catch(() => {}), 30 * 60 * 1000);
  return `${PUBLIC_BASE}/audio/${name}`;
}

async function readUploadToTemp(req) {
  // Prefer multer if available; else parse raw body with busboy-less approach via formidable-free
  return new Promise((resolve, reject) => {
    const chunks = [];
    const contentType = req.headers['content-type'] || '';
    if (!contentType.includes('multipart/')) {
      req.on('data', (c) => chunks.push(c));
      req.on('end', async () => {
        const buf = Buffer.concat(chunks);
        if (!buf.length) return reject(new Error('Empty audio body'));
        const tmp = path.join(os.tmpdir(), `rex-up-${Date.now()}.wav`);
        await fs.promises.writeFile(tmp, buf);
        resolve(tmp);
      });
      req.on('error', reject);
      return;
    }

    // manual multipart boundary parse for field name audio/file
    try {
      const multer = require('multer');
      const upload = multer({ dest: os.tmpdir() }).any();
      upload(req, {}, async (err) => {
        if (err) return reject(err);
        const file = (req.files || [])[0];
        if (!file?.path) return reject(new Error('No audio file in multipart'));
        resolve(file.path);
      });
    } catch (e) {
      reject(new Error('multer not installed — npm i multer'));
    }
  });
}

const app = express();
app.use(express.json({ limit: '2mb' }));

app.get('/health', (_req, res) => {
  res.json({
    ok: true,
    service: 'phantom-rex-ai',
    groq: Boolean(GROQ_KEY),
    port: PORT,
  });
});

app.use((req, res, next) => {
  if (req.path.startsWith('/audio/')) return next();
  if (req.path === '/health') return next();
  if (!authOk(req)) return res.status(401).json({ error: 'Unauthorized' });
  return next();
});

app.get('/audio/:file', (req, res) => {
  const name = path.basename(req.params.file);
  const file = path.join(AUDIO_DIR, name);
  if (!fs.existsSync(file)) return res.status(404).end();
  res.setHeader('Content-Type', 'audio/mpeg');
  fs.createReadStream(file).pipe(res);
});

app.post('/chat', async (req, res) => {
  try {
    const guildId = req.body.guild_id || 'default';
    const userText = req.body.user_text || req.body.text || '';
    if (!userText.trim()) return res.status(400).json({ error: 'user_text required' });

    const reply_text = await groqChat(guildId, userText);
    let audio_url = null;
    try {
      const audio = await synthesizeSpeech(reply_text);
      if (audio) audio_url = await saveAudio(audio);
    } catch (err) {
      console.warn('[rex-ai] TTS after chat failed:', err.message);
    }
    res.json({ reply_text, audio_url, audio_file: audio_url });
  } catch (err) {
    console.error('[rex-ai] /chat', err.message);
    res.status(500).json({ error: err.message });
  }
});

app.post('/transcribe', async (req, res) => {
  let tmp = null;
  try {
    tmp = await readUploadToTemp(req);
    const text = await groqTranscribe(tmp);
    res.json({ text });
  } catch (err) {
    console.error('[rex-ai] /transcribe', err.message);
    res.status(500).json({ error: err.message });
  } finally {
    if (tmp) fs.promises.unlink(tmp).catch(() => {});
  }
});

app.post('/tts', async (req, res) => {
  try {
    const text = req.body.text || req.body.input || '';
    if (!text.trim()) return res.status(400).json({ error: 'text required' });
    const audio = await synthesizeSpeech(text);
    if (!audio) return res.status(502).json({ error: 'TTS failed' });
    const url = await saveAudio(audio);
    res.json({ url, audio_url: url });
  } catch (err) {
    console.error('[rex-ai] /tts', err.message);
    res.status(500).json({ error: err.message });
  }
});

/** Raw audio for TTS_API_URL consumers (phantom-say) */
app.post('/synthesize', async (req, res) => {
  try {
    const text = req.body.text || req.body.input || '';
    if (!text.trim()) return res.status(400).json({ error: 'text required' });
    const audio = await synthesizeSpeech(text);
    if (!audio) return res.status(502).json({ error: 'TTS failed' });
    res.setHeader('Content-Type', 'audio/mpeg');
    res.send(audio);
  } catch (err) {
    console.error('[rex-ai] /synthesize', err.message);
    res.status(500).json({ error: err.message });
  }
});

app.post('/mode', (req, res) => {
  const guildId = req.body.guild_id || 'default';
  const unrestricted = Boolean(req.body.unrestricted);
  const state = getGuild(guildId);
  state.unrestricted = unrestricted;
  res.json({ ok: true, unrestricted });
});

app.post('/reset', (req, res) => {
  const guildId = req.body.guild_id || 'default';
  guildState.set(String(guildId), { unrestricted: false, history: [] });
  res.json({ ok: true });
});

app.listen(PORT, BIND, () => {
  console.log(`[rex-ai] listening on http://${BIND}:${PORT} (public base ${PUBLIC_BASE})`);
  console.log(`[rex-ai] groq=${GROQ_KEY ? 'yes' : 'NO'} auth=${API_KEY ? 'yes' : 'open'}`);
});
