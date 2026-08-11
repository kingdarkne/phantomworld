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

function fallbackReply(question) {
  const q = (question || '').toLowerCase().replace(/\?/g, '');
  for (const [keyword, msg] of Object.entries(FALLBACK_REPLIES)) {
    if (keyword !== 'default' && q.includes(keyword)) return msg;
  }
  return FALLBACK_REPLIES.default;
}

export function hasOpenAiKey() {
  const key = process.env.OPENAI_API_KEY || '';
  return key.length >= 10;
}

export async function askAi(question) {
  const text = (question || '').trim();
  if (!text) return 'Ask me a question — e.g. `$ask how do I join the server?`';

  const key = process.env.OPENAI_API_KEY;
  if (!key || key.length < 10) {
    return fallbackReply(text);
  }

  const system =
    process.env.AI_SYSTEM_PROMPT ||
    'You are the Phantom World Discord support bot for a FiveM roleplay community. ' +
      'Answer briefly and helpfully. Join link: https://cfx.re/join/3m87mo. Discord: discord.gg/phantomworld.';

  try {
    const res = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${key}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
        max_tokens: Number(process.env.OPENAI_MAX_TOKENS || 300),
        messages: [
          { role: 'system', content: system },
          { role: 'user', content: text.slice(0, 1000) },
        ],
      }),
      signal: AbortSignal.timeout(30000),
    });

    if (!res.ok) {
      console.warn('[ai] OpenAI chat failed:', res.status, await res.text().catch(() => ''));
      return fallbackReply(text);
    }

    const data = await res.json();
    const reply = data?.choices?.[0]?.message?.content?.trim();
    return reply || fallbackReply(text);
  } catch (err) {
    console.warn('[ai] OpenAI error:', err.message);
    return fallbackReply(text);
  }
}

export async function synthesizeSpeech(text) {
  const trimmed = (text || '').trim().slice(0, 500);
  if (!trimmed) return null;

  const key = process.env.OPENAI_API_KEY;
  if (!key || key.length < 10) {
    return null;
  }

  try {
    const res = await fetch('https://api.openai.com/v1/audio/speech', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${key}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: process.env.OPENAI_TTS_MODEL || 'tts-1',
        voice: process.env.OPENAI_TTS_VOICE || 'nova',
        input: trimmed,
      }),
      signal: AbortSignal.timeout(60000),
    });

    if (!res.ok) {
      console.warn('[ai] OpenAI TTS failed:', res.status);
      return null;
    }

    return Buffer.from(await res.arrayBuffer());
  } catch (err) {
    console.warn('[ai] TTS error:', err.message);
    return null;
  }
}
