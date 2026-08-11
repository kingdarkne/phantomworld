import { Readable } from 'node:stream';
import { createAudioResource, StreamType } from '@discordjs/voice';
import ffmpegStatic from 'ffmpeg-static';
import { getPersona } from './personas.js';

if (ffmpegStatic) {
  process.env.FFMPEG_PATH = ffmpegStatic;
}

const OPENAI_KEY = process.env.OPENAI_API_KEY || '';
const TTS_MODEL = process.env.OPENAI_TTS_MODEL || 'tts-1';

/**
 * @param {string} text
 * @param {string} personaKey
 */
export async function textToSpeechResource(text, personaKey = 'assistant') {
  const spoken = (text || '').replace(/\s+/g, ' ').trim().slice(0, 800);
  if (!spoken) throw new Error('Nothing to speak.');
  if (!OPENAI_KEY) throw new Error('OPENAI_API_KEY required for speech.');

  const persona = getPersona(personaKey);
  const voice = persona.openaiVoice || 'onyx';

  const res = await fetch('https://api.openai.com/v1/audio/speech', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${OPENAI_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: TTS_MODEL,
      voice,
      input: spoken,
    }),
    signal: AbortSignal.timeout(60_000),
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`OpenAI TTS failed (${res.status}): ${err.slice(0, 200)}`);
  }

  const buffer = Buffer.from(await res.arrayBuffer());
  const stream = Readable.from(buffer);

  return createAudioResource(stream, {
    inputType: StreamType.Arbitrary,
    inlineVolume: true,
  });
}
