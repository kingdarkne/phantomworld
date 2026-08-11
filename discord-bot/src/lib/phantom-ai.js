/**
 * Phantom text AI — Groq / Ollama / OpenAI / keyword fallback (slim-bot merge).
 */
const FALLBACK_REPLIES = {
  default:
    'I can help with Phantom World! Try asking about jobs, banking, housing, or how to join the FiveM server.',
  job: 'Check city hall or job centers in-game. Many whitelisted jobs are posted in our Discord.',
  bank: 'Use any ATM or bank branch in Los Santos. Your balance is also on your phone.',
  garage: 'Use your phone vehicle app or marked garage blips on the map to retrieve vehicles.',
  join: 'Connect on FiveM: https://cfx.re/join/3m87mo — Discord: https://discord.gg/phantomworld',
  fivem: 'Open FiveM → Play → paste: https://cfx.re/join/3m87mo',
  discord: 'Join our community: https://discord.gg/phantomworld',
  rules:
    'Follow Discord and in-city rules. No RDM, VDM, or exploiting. Staff may warn or ban for violations.',
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

async function askGroq(question) {
  const key = process.env.GROQ || process.env.GROQ_API_KEY;
  if (!key) return null;
  const Groq = require('groq-sdk');
  const client = new Groq({ apiKey: key });
  const completion = await client.chat.completions.create({
    messages: [
      { role: 'system', content: systemPrompt() },
      { role: 'user', content: question.slice(0, 1000) },
    ],
    model: process.env.GROQ_MODEL || 'llama-3.3-70b-versatile',
    temperature: 0.7,
    max_tokens: 512,
  });
  return completion?.choices?.[0]?.message?.content?.trim() || null;
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
  if (!res.ok) throw new Error(`Ollama HTTP ${res.status}`);
  const data = await res.json();
  return data?.message?.content?.trim() || null;
}

async function askOpenAi(question) {
  const key = process.env.OPENAI_API_KEY;
  if (!key || key.length < 10) return null;
  const base = (process.env.OPENAI_BASE_URL || process.env.AI_API_URL || 'https://api.openai.com/v1').replace(
    /\/$/,
    '',
  );
  const res = await fetch(`${base}/chat/completions`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${key}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: process.env.OPENAI_CHAT_MODEL || 'gpt-4o-mini',
      max_tokens: 400,
      messages: [
        { role: 'system', content: systemPrompt() },
        { role: 'user', content: question.slice(0, 1000) },
      ],
    }),
    signal: AbortSignal.timeout(45000),
  });
  if (!res.ok) throw new Error(`OpenAI HTTP ${res.status}`);
  const data = await res.json();
  return data?.choices?.[0]?.message?.content?.trim() || null;
}

async function askAi(question) {
  const text = (question || '').trim();
  if (!text) return 'Ask me a question — e.g. `$ask how do I join the server?`';

  const tries = [
    ['groq', askGroq],
    ['ollama', askOllama],
    ['openai', askOpenAi],
  ];

  for (const [name, fn] of tries) {
    try {
      const reply = await fn(text);
      if (reply) {
        console.log(`[phantom-ai] reply via ${name}`);
        return reply.slice(0, 1900);
      }
    } catch (err) {
      console.warn(`[phantom-ai] ${name} failed:`, err.message);
    }
  }

  return fallbackReply(text);
}

module.exports = { askAi, fallbackReply };
