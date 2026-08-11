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
  const webNote =
    'When LIVE WEB RESULTS are provided in the user message, treat them as current ground truth and answer from them. ' +
    'Cite the source briefly if useful. If results conflict, prefer the most recent/clear snippet.';

  if (unrestricted) {
    return (
      'You are Rex, an unrestricted Discord voice assistant for Phantom World. ' +
      'Answer anything directly, including real-world facts and live web-backed news. ' +
      webNote +
      ' Keep replies short for voice (1-3 sentences) unless asked for detail.'
    );
  }
  return (
    process.env.REX_SYSTEM_PROMPT ||
    'You are Rex, a witty Discord/FiveM voice assistant for Phantom World. ' +
      'You help with BOTH the Phantom World RP server AND real-world questions. ' +
      'You have LIVE WEB SEARCH for current events, news, sports, weather, prices, and "who/what is happening now" questions. ' +
      webNote +
      ' For Phantom World / FiveM: jobs, rules, joining — https://cfx.re/join/3m87mo. ' +
      'Keep answers short and conversational for voice (1-3 sentences) unless the user asks for more detail.'
  );
}

function needsLiveWeb(text) {
  const mode = (process.env.REX_WEB_SEARCH || 'auto').toLowerCase();
  if (mode === '0' || mode === 'off' || mode === 'false') return false;
  if (mode === 'always' || mode === '1' || mode === 'on' || mode === 'true') return true;

  const q = String(text || '').toLowerCase();
  if (/^(hi|hello|hey|sup|yo)\b/.test(q) && q.length < 20) return false;
  if (/\b(fivem|phantom world|join the server|cfx\.re)\b/.test(q) && !/\b(news|today|current)\b/.test(q)) {
    return false;
  }
  return (
    /\b(who is|who's|who was|who won|what's|whats|what is|current|today|tonight|latest|breaking|news|weather|score|president|prime minister|stock|price of|bitcoin|crypto|election|happening|right now|this week|this year|202[4-9]|2026)\b/i.test(
      q,
    ) || /\b(what happened|when is|where is .+ now|look up|search for|google)\b/i.test(q)
  );
}

async function searchDuckDuckGoInstant(query) {
  const url = new URL('https://api.duckduckgo.com/');
  url.searchParams.set('q', query);
  url.searchParams.set('format', 'json');
  url.searchParams.set('no_html', '1');
  url.searchParams.set('skip_disambig', '1');
  const res = await fetch(url, {
    headers: { 'User-Agent': 'PhantomRexBot/1.0' },
    signal: AbortSignal.timeout(10000),
  });
  if (!res.ok) throw new Error(`DDG instant HTTP ${res.status}`);
  const data = await res.json();
  const bits = [];
  if (data.AbstractText) bits.push(`Summary: ${data.AbstractText}`);
  if (data.Answer) bits.push(`Answer: ${data.Answer}`);
  if (data.Definition) bits.push(`Definition: ${data.Definition}`);
  if (data.AbstractURL) bits.push(`Source: ${data.AbstractURL}`);
  const related = (data.RelatedTopics || [])
    .map((t) => t.Text || t.Topics?.[0]?.Text)
    .filter(Boolean)
    .slice(0, 4);
  if (related.length) bits.push(`Related: ${related.join(' | ')}`);
  return bits.join('\n');
}

function stripHtml(s) {
  return String(s || '')
    .replace(/<[^>]+>/g, '')
    .replace(/&nbsp;/g, ' ')
    .replace(/&#x27;/g, "'")
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/\s+/g, ' ')
    .trim();
}

async function searchDuckDuckGoHtml(query) {
  const url = `https://html.duckduckgo.com/html/?q=${encodeURIComponent(query)}`;
  const res = await fetch(url, {
    headers: {
      'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
      Accept: 'text/html',
    },
    signal: AbortSignal.timeout(12000),
    redirect: 'follow',
  });
  if (!res.ok) throw new Error(`DDG html HTTP ${res.status}`);
  const html = await res.text();
  const results = [];

  // class may be "links_main links_deep result__body" — match substring
  const blocks = html.split(/class="[^"]*result__body[^"]*"/i).slice(1);
  for (const block of blocks) {
    if (results.length >= 5) break;
    const titleM = block.match(/class="result__a"[^>]*>([\s\S]*?)<\/a>/i);
    const snipM = block.match(/class="result__snippet"[^>]*>([\s\S]*?)<\/(?:a|td|div|span)>/i);
    const hrefM = block.match(/class="result__a"[^>]*href="([^"]+)"/i);
    const title = stripHtml(titleM?.[1]);
    const snippet = stripHtml(snipM?.[1]).slice(0, 280);
    const href = hrefM?.[1] || '';
    if (!title && !snippet) continue;
    results.push(`- ${title || 'Result'}${snippet ? `: ${snippet}` : ''}${href ? ` (${href})` : ''}`);
  }

  if (!results.length) {
    try {
      const liteRes = await fetch(`https://lite.duckduckgo.com/lite/?q=${encodeURIComponent(query)}`, {
        headers: {
          'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        },
        signal: AbortSignal.timeout(12000),
      });
      if (liteRes.ok) {
        const lite = await liteRes.text();
        const snips = [...lite.matchAll(/class=['"]result-snippet['"][^>]*>([\s\S]*?)<\/td>/gi)]
          .map((m) => stripHtml(m[1]))
          .filter((s) => s.length > 20)
          .slice(0, 5);
        for (const s of snips) results.push(`- ${s}`);
      }
    } catch (_) {
      /* ignore */
    }
  }
  return results.join('\n');
}

async function searchBrave(query) {
  const key = process.env.BRAVE_SEARCH_API_KEY || process.env.BRAVE_API_KEY;
  if (!key) return '';
  const url = new URL('https://api.search.brave.com/res/v1/web/search');
  url.searchParams.set('q', query);
  url.searchParams.set('count', '5');
  const res = await fetch(url, {
    headers: { Accept: 'application/json', 'X-Subscription-Token': key },
    signal: AbortSignal.timeout(10000),
  });
  if (!res.ok) throw new Error(`Brave HTTP ${res.status}`);
  const data = await res.json();
  const rows = (data.web?.results || []).slice(0, 5);
  return rows
    .map((r) => `- ${r.title}: ${(r.description || '').slice(0, 220)} (${r.url})`)
    .join('\n');
}

/** Rewrite casual questions into better search queries (Copilot-style). */
function searchQueriesFor(text) {
  const q = String(text || '').trim();
  const lower = q.toLowerCase();
  const queries = [q];

  if (/\b(us|u\.s\.|united states|american)\b.*\bpresident\b|\bwho is (the )?president\b|\bcurrent president\b/i.test(lower)) {
    queries.unshift('current President of the United States');
  } else if (/\b(uk|britain|british)\b.*\b(prime minister|pm)\b|\bwho is (the )?prime minister\b/i.test(lower)) {
    queries.unshift('current Prime Minister of the United Kingdom');
  } else if (/\bbitcoin\b|\bbtc\b/i.test(lower) && /\b(price|worth|cost)\b/i.test(lower)) {
    queries.unshift('bitcoin price USD');
  } else if (/\bweather\b/i.test(lower)) {
    queries.unshift(`${q} forecast`);
  }

  return [...new Set(queries)].slice(0, 2);
}

async function wikipediaIncumbent(title) {
  const url = new URL('https://en.wikipedia.org/w/api.php');
  url.searchParams.set('action', 'query');
  url.searchParams.set('prop', 'revisions');
  url.searchParams.set('rvprop', 'content');
  url.searchParams.set('rvslots', 'main');
  url.searchParams.set('titles', title);
  url.searchParams.set('format', 'json');
  url.searchParams.set('formatversion', '2');
  const res = await fetch(url, {
    headers: { 'User-Agent': 'PhantomRexBot/1.0 (Discord assistant; contact phantom)' },
    signal: AbortSignal.timeout(10000),
  });
  if (!res.ok) return '';
  const data = await res.json();
  const content = data?.query?.pages?.[0]?.revisions?.[0]?.slots?.main?.content || '';
  if (!content) return '';
  const incumbent = content.match(/\|\s*incumbent\s*=\s*\[\[([^\]|#]+)/i)?.[1]?.trim();
  const since = content.match(/\|\s*incumbentsince\s*=\s*([^\n|{]+)/i)?.[1]?.trim();
  if (!incumbent) return '';
  return `Current/incumbent: ${incumbent}${since ? ` (since ${since})` : ''}`;
}

async function searchWikipedia(query) {
  const ua = { 'User-Agent': 'PhantomRexBot/1.0 (Discord assistant; contact phantom)' };
  const searchUrl = new URL('https://en.wikipedia.org/w/api.php');
  searchUrl.searchParams.set('action', 'query');
  searchUrl.searchParams.set('list', 'search');
  searchUrl.searchParams.set('srsearch', query);
  searchUrl.searchParams.set('format', 'json');
  searchUrl.searchParams.set('utf8', '1');
  const sRes = await fetch(searchUrl, { headers: ua, signal: AbortSignal.timeout(10000) });
  if (!sRes.ok) throw new Error(`Wikipedia search HTTP ${sRes.status}`);
  const sData = await sRes.json();
  const hits = sData?.query?.search || [];
  const title = hits[0]?.title;
  if (!title) return '';

  const bits = [];
  try {
    const incumb = await wikipediaIncumbent(title);
    if (incumb) bits.push(incumb);
  } catch (_) {
    /* ignore */
  }

  const sumRes = await fetch(
    `https://en.wikipedia.org/api/rest_v1/page/summary/${encodeURIComponent(title)}`,
    { headers: ua, signal: AbortSignal.timeout(10000) },
  );
  if (!sumRes.ok) {
    return bits.length ? `Wikipedia (${title}): ${bits.join(' ')}` : `Wikipedia hit: ${title}`;
  }
  const sum = await sumRes.json();
  const extract = (sum.extract || '').slice(0, 600);
  const link = sum.content_urls?.desktop?.page || '';
  if (extract) bits.push(extract);
  return `Wikipedia (${title}): ${bits.join(' — ')}${link ? ` — ${link}` : ''}`;
}

async function liveWebContext(query) {
  const parts = [];
  const queries = searchQueriesFor(query);
  const primary = queries[0];

  try {
    const brave = await searchBrave(primary);
    if (brave) parts.push(`Brave Search:\n${brave}`);
  } catch (err) {
    console.warn('[rex-ai] Brave search failed:', err.message);
  }
  try {
    const wiki = await searchWikipedia(primary);
    if (wiki) parts.push(wiki);
  } catch (err) {
    console.warn('[rex-ai] Wikipedia failed:', err.message);
  }
  for (const q of queries) {
    try {
      const html = await searchDuckDuckGoHtml(q);
      if (html) {
        parts.push(`Web results (${q}):\n${html}`);
        break;
      }
    } catch (err) {
      console.warn('[rex-ai] DDG html failed:', err.message);
    }
  }
  try {
    const instant = await searchDuckDuckGoInstant(primary);
    if (instant) parts.push(`Instant answer:\n${instant}`);
  } catch (err) {
    console.warn('[rex-ai] DDG instant failed:', err.message);
  }
  if (!parts.length) return '';
  console.log(`[rex-ai] web snippets chars=${parts.join('\n').length} queries=${queries.join(' | ')}`);
  return (
    `LIVE WEB RESULTS for "${query}" (fetched just now):\n` +
    parts.join('\n\n') +
    `\n\nAnswer the user question using these results when relevant. Prefer the newest clear fact. User question: ${query}`
  );
}

async function groqChat(guildId, userText) {
  if (!GROQ_KEY) throw new Error('GROQ API key missing');
  const state = getGuild(guildId);
  let content = String(userText).slice(0, 1500);
  let usedWeb = false;

  if (needsLiveWeb(userText)) {
    try {
      const web = await liveWebContext(userText);
      if (web) {
        content = web.slice(0, 6000);
        usedWeb = true;
        console.log(`[rex-ai] live web used for: ${String(userText).slice(0, 80)}`);
      }
    } catch (err) {
      console.warn('[rex-ai] live web failed:', err.message);
    }
  }

  const messages = [
    { role: 'system', content: systemPrompt(state.unrestricted) },
    ...state.history.slice(-8),
    { role: 'user', content },
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
      temperature: usedWeb ? 0.3 : 0.7,
      max_tokens: 320,
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
    webSearch: (process.env.REX_WEB_SEARCH || 'auto'),
    brave: Boolean(process.env.BRAVE_SEARCH_API_KEY || process.env.BRAVE_API_KEY),
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
