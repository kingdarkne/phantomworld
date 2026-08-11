const OPENAI_KEY = process.env.OPENAI_API_KEY || '';
const CHAT_MODEL = process.env.OPENAI_CHAT_MODEL || 'gpt-4o-mini';

export function aiConfigured() {
  return Boolean(OPENAI_KEY);
}

/**
 * @param {string} userText
 * @param {{ system?: string, userName?: string }} opts
 */
export async function chatReply(userText, opts = {}) {
  if (!OPENAI_KEY) {
    throw new Error('Set OPENAI_API_KEY in .env for voice Q&A.');
  }

  const system =
    opts.system ||
    'You are a helpful voice assistant. Keep answers short (1–3 sentences) for text-to-speech.';

  const userLine = opts.userName ? `${opts.userName}: ${userText}` : userText;

  let res;
  try {
    res = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${OPENAI_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: CHAT_MODEL,
        max_tokens: 180,
        temperature: 0.7,
        messages: [
          { role: 'system', content: system },
          { role: 'user', content: userLine },
        ],
      }),
      signal: AbortSignal.timeout(45_000),
    });
  } catch (err) {
    if (err?.name === 'TimeoutError' || err?.name === 'AbortError') {
      throw new Error('OpenAI request timed out. Try again in a few seconds.');
    }
    throw err;
  }

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`OpenAI chat failed (${res.status}): ${err.slice(0, 200)}`);
  }

  const data = await res.json();
  const text = data?.choices?.[0]?.message?.content?.trim();
  if (!text) throw new Error('OpenAI returned an empty answer.');
  return text.slice(0, 500);
}

/** Transcribe WAV buffer via Whisper */
export async function transcribeWav(wavBuffer) {
  if (!OPENAI_KEY) {
    throw new Error('Set OPENAI_API_KEY for voice listening (Whisper).');
  }

  const form = new FormData();
  form.append('file', new Blob([wavBuffer], { type: 'audio/wav' }), 'speech.wav');
  form.append('model', 'whisper-1');

  const res = await fetch('https://api.openai.com/v1/audio/transcriptions', {
    method: 'POST',
    headers: { Authorization: `Bearer ${OPENAI_KEY}` },
    body: form,
    signal: AbortSignal.timeout(60_000),
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Whisper failed (${res.status}): ${err.slice(0, 200)}`);
  }

  const data = await res.json();
  return (data.text || '').trim();
}
