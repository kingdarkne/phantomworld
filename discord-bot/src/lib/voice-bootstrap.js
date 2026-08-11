import { createRequire } from 'node:module';
import { generateDependencyReport } from '@discordjs/voice';

const require = createRequire(import.meta.url);

/** Load libsodium + log voice dependency health (required for stable VC). */
export async function bootstrapVoiceLibs() {
  try {
    const sodium = require('libsodium-wrappers');
    await sodium.ready;
  } catch (err) {
    console.warn('libsodium-wrappers:', err?.message || err);
  }

  const report = generateDependencyReport();
  console.log('Voice dependency report:\n', report);

  if (report.includes('sodium') && report.includes('not found')) {
    console.warn('Voice encryption may fail — install libsodium-wrappers (already in package.json).');
  }
  if (report.includes('ffmpeg') && report.includes('not found')) {
    console.warn('TTS playback may fail — ffmpeg-static should be installed.');
  }
}
