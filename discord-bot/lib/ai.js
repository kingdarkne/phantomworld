const FALLBACK_REPLIES = {
  default:
    'I can help with Phantom World! Try asking about jobs, banking, housing, or how to join the FiveM server.',
  job: 'Check city hall or job centers in-game. Many whitelisted jobs are posted in our Discord.',
  bank: 'Use any ATM or bank branch in Los Santos. Your balance is also on your phone.',
  garage: 'Use your phone vehicle app or marked garage blips on the map to retrieve vehicles.',
  join: 'Connect on FiveM: https://cfx.re/join/3m87mo — Discord: https://discord.gg/phantomworld',
  fivem: 'Open FiveM → Play → paste: https://cfx.re/join/3m87mo',
  discord: 'Join our community: https://discord.gg/phantomworld',
  rules: 'Follow Discord and in-city rules. No RDM, VDM, or exploiting. Staff may warn or ban for violations.',
};

function systemPrompt() {
  return (
    process.env.AI_SYSTEM_PROMPT ||
    'You are the Phantom World Discord support bot for a FiveM roleplay community. ' +
      'Answer briefly and helpfully. Join link: https://cfx.re/join/3m87mo. Discord: discord.gg/phantomworld.'
  );
}

function fallbackReply(question) {
  const q = (question || '').toLowerCase().replace(/\?/g, '');
  for (const [keyword, msg] of Object.entries(FALLBACK_REPLIES)) {
    if (keyword !== 'default' && q.includes(keyword)) return msg;
  }
  return FALLBACK_REPLIES.default;
}

export function aiProvider() {
  if (process.env.AI_PROVIDER) return process.env.AI_PROVIDER;
  if (process.env.AI_API_URL || process.env.OPENAI_BASE_URL) return 'openai-compatible';
  if (process.env.OLLAMA_HOST || process.env.OLLAMA_URL) return 'ollama';
  if ((process.env.OPENAI_API_KEY || '').length >= 10) return 'openai';
  return 'fallback';
}

export function hasOpenAiKey() {
  return (process.env.OPENAI_API_KEY || '').length >= 10;
}

async function askOllama(question) {
  const host = (process.env.OLLAMA_HOST || process.env.OLLAMA_URL || 'http://127.0.0.1:11434').replace(
    /\/$/,
    '',
  );
  const model = process.env.OLLAMA_MODEL || 'llama3.2';

  const res = await fetch(`${host}/api/chat`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model,
      stream: false,
      messages: [
        { role: 'system', content: systemPrompt() },
        { role: 'user', content: question.slice(0, 1000) },
      ],
    }),
    signal: AbortSignal.timeout(60000),
  });

  if (!res.ok) {
    throw new Error(`Ollama HTTP ${res.status}`);
  }

  const data = await res.json();
  return data?.message?.content?.trim() || null;
}

async function askOpenAiCompatible(question) {
  const base = (
    process.env.AI_API_URL ||
    process.env.OPENAI_BASE_URL ||
    'https://api.openai.com'
  ).replace(/\/$/, '');
  const key = process.env.AI_API_KEY || process.env.OPENAI_API_KEY || '';
  const url = base.includes('/chat/completions') ? base : `${base}/v1/chat/completions`;

  const headers = { 'Content-Type': 'application/json' };
  if (key) headers.Authorization = `Bearer ${key}`;

  const res = await fetch(url, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      model: process.env.AI_MODEL || process.env.OPENAI_MODEL || 'gpt-4o-mini',
      max_tokens: Number(process.env.AI_MAX_TOKENS || process.env.OPENAI_MAX_TOKENS || 300),
      messages: [
        { role: 'system', content: systemPrompt() },
        { role: 'user', content: question.slice(0, 1000) },
      ],
    }),
    signal: AbortSignal.timeout(60000),
  });

  if (!res.ok) {
    throw new Error(`AI API HTTP ${res.status}`);
  }

  const data = await res.json();
  return data?.choices?.[0]?.message?.content?.trim() || null;
}

export async function askAi(question) {
  const text = (question || '').trim();
  if (!text) return 'Ask me a question — e.g. `$ask how do I join the server?`';

  const provider = aiProvider();

  try {
    let reply = null;
    if (provider === 'ollama') {
      reply = await askOllama(text);
    } else if (provider === 'openai-compatible' || provider === 'openai') {
      reply = await askOpenAiCompatible(text);
    }

    if (reply) return reply;
  } catch (err) {
    console.warn(`[ai] ${provider} failed:`, err.message);
    if (provider === 'ollama' && hasOpenAiKey()) {
      try {
        const reply = await askOpenAiCompatible(text);
        if (reply) return reply;
      } catch (fallbackErr) {
        console.warn('[ai] OpenAI fallback failed:', fallbackErr.message);
      }
    }
  }

  return fallbackReply(text);
}

async function synthesizeFromUrl(text) {
  const url = (process.env.TTS_API_URL || '').replace(/\/$/, '');
  if (!url) return null;

  const voice =
    process.env.TTS_VOICE || process.env.TTS_DEFAULT_VOICE || process.env.EDGE_TTS_VOICE || 'af_heart';
  const timeoutMs = Number(process.env.TTS_URL_TIMEOUT_MS || 8000);

  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(process.env.TTS_API_KEY
        ? { Authorization: `Bearer ${process.env.TTS_API_KEY}` }
        : {}),
    },
    body: JSON.stringify({
      text,
      input: text,
      voice,
    }),
    signal: AbortSignal.timeout(timeoutMs),
  });

  if (!res.ok) {
    throw new Error(`TTS API HTTP ${res.status}`);
  }

  const type = res.headers.get('content-type') || '';
  if (type.includes('json')) {
    const data = await res.json();
    if (data.url) {
      const audioRes = await fetch(data.url, { signal: AbortSignal.timeout(30000) });
      return Buffer.from(await audioRes.arrayBuffer());
    }
    if (data.audio) {
      return Buffer.from(data.audio, 'base64');
    }
    return null;
  }

  return Buffer.from(await res.arrayBuffer());
}

async function synthesizeOpenAi(text) {
  const key = process.env.OPENAI_API_KEY;
  if (!key || key.length < 10) return null;

  const res = await fetch('https://api.openai.com/v1/audio/speech', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${key}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: process.env.OPENAI_TTS_MODEL || 'tts-1',
      voice: process.env.OPENAI_TTS_VOICE || process.env.TTS_VOICE || 'nova',
      input: text,
    }),
    signal: AbortSignal.timeout(45000),
  });

  if (!res.ok) return null;
  return Buffer.from(await res.arrayBuffer());
}

/** Microsoft Edge neural TTS (server-side). */
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

/** Google Translate TTS fallback (no key). Chunks long text. */
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
      console.log(`[ai] TTS via ${name} (${audio.length} bytes)`);
      return audio;
    }
  } catch (err) {
    console.warn(`[ai] TTS ${name} failed:`, err.message);
  }
  return null;
}

export async function synthesizeSpeech(text) {
  const trimmed = (text || '').trim().slice(0, 500);
  if (!trimmed) return null;

  const provider = (process.env.TTS_PROVIDER || 'auto').toLowerCase();
  const wantsUrl = provider === 'url' || provider === 'auto' || Boolean(process.env.TTS_API_URL);
  const wantsOpenAi = provider === 'openai' || provider === 'auto';
  const wantsEdge = provider === 'edge' || provider === 'auto';
  const wantsGoogle = provider === 'google' || provider === 'auto';

  if (provider === 'url' || (wantsUrl && process.env.TTS_API_URL)) {
    const audio = await tryProvider('url', () => synthesizeFromUrl(trimmed));
    if (audio) return audio;
    if (provider === 'url') return null;
  }

  if (wantsOpenAi) {
    const audio = await tryProvider('openai', () => synthesizeOpenAi(trimmed));
    if (audio) return audio;
  }

  if (wantsEdge) {
    const audio = await tryProvider('edge', () => synthesizeEdge(trimmed));
    if (audio) return audio;
  }

  if (wantsGoogle) {
    const audio = await tryProvider('google', () => synthesizeGoogle(trimmed));
    if (audio) return audio;
  }

  return null;
}

export async function probeAiServices() {
  const results = { provider: aiProvider(), ollama: false, lavalinkNote: 'see startup logs' };

  if (process.env.OLLAMA_HOST || process.env.OLLAMA_URL || aiProvider() === 'ollama') {
    const host = (process.env.OLLAMA_HOST || process.env.OLLAMA_URL || 'http://127.0.0.1:11434').replace(
      /\/$/,
      '',
    );
    try {
      const res = await fetch(`${host}/api/tags`, { signal: AbortSignal.timeout(5000) });
      results.ollama = res.ok;
      if (res.ok) {
        const data = await res.json();
        results.ollamaModels = (data.models || []).map((m) => m.name).slice(0, 5);
      }
    } catch {
      results.ollama = false;
    }
  }

  return results;
}
