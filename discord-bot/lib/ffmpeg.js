import { createRequire } from 'module';
import { spawn, spawnSync } from 'child_process';
import { createAudioResource, StreamType } from '@discordjs/voice';
import fs from 'fs';

const require = createRequire(import.meta.url);

let cachedPath = null;

/** Resolve a working ffmpeg binary (bundled static preferred, then system). */
export function resolveFfmpegPath() {
  if (cachedPath) return cachedPath;

  const candidates = [];

  try {
    const ffmpegStatic = require('ffmpeg-static');
    if (typeof ffmpegStatic === 'string') candidates.push(ffmpegStatic);
    else if (ffmpegStatic?.path) candidates.push(ffmpegStatic.path);
  } catch {
    // optional dependency path
  }

  if (process.env.FFMPEG_PATH) candidates.push(process.env.FFMPEG_PATH);
  candidates.push('/usr/bin/ffmpeg', '/bin/ffmpeg', 'ffmpeg');

  for (const bin of candidates) {
    if (!bin) continue;
    if (bin.startsWith('/') && !fs.existsSync(bin)) continue;
    const result = spawnSync(bin, ['-version'], { encoding: 'utf8', windowsHide: true });
    if (!result.error && result.status === 0) {
      cachedPath = bin;
      return cachedPath;
    }
  }

  throw new Error(
    'FFmpeg/avconv not found! Install ffmpeg (`apt install ffmpeg`) or npm package `ffmpeg-static`.',
  );
}

/**
 * Play an mp3/wav/ogg file/url through Discord voice without relying on prism's
 * internal ffmpeg discovery (which can fail even when system ffmpeg exists).
 */
export function createFfmpegAudioResource(input, { inlineVolume = false } = {}) {
  const ffmpeg = resolveFfmpegPath();
  const args = [
    '-hide_banner',
    '-loglevel',
    'error',
    '-i',
    typeof input === 'string' ? input : 'pipe:0',
    '-analyzeduration',
    '0',
    '-f',
    's16le',
    '-ar',
    '48000',
    '-ac',
    '2',
    'pipe:1',
  ];

  const proc = spawn(ffmpeg, args, { windowsHide: true, stdio: ['pipe', 'pipe', 'pipe'] });
  proc.stderr?.on('data', () => {});
  proc.on('error', (err) => {
    console.warn('[ffmpeg] spawn error:', err.message);
  });

  if (typeof input !== 'string' && input?.pipe) {
    input.pipe(proc.stdin);
  }

  return createAudioResource(proc.stdout, {
    inputType: StreamType.Raw,
    inlineVolume,
  });
}

export function assertFfmpegAvailable() {
  const bin = resolveFfmpegPath();
  console.log(`[ffmpeg] using ${bin}`);
  return bin;
}
