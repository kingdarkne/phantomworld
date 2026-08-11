import fs from 'fs';
import os from 'os';
import path from 'path';
import {
  joinVoiceChannel,
  createAudioPlayer,
  AudioPlayerStatus,
  entersState,
  NoSubscriberBehavior,
} from '@discordjs/voice';
import { synthesizeSpeech } from './ai.js';
import { createFfmpegAudioResource } from './ffmpeg.js';

const ttsSessions = new Map();

function getSession(guildId) {
  if (!ttsSessions.has(guildId)) {
    ttsSessions.set(guildId, { connection: null, player: null });
  }
  return ttsSessions.get(guildId);
}

export async function speakInChannel({ guild, guildId, member, text }) {
  const voiceChannel = member?.voice?.channel;
  if (!voiceChannel) {
    throw new Error('Join a voice channel first.');
  }

  const audio = await synthesizeSpeech(text);
  if (!audio) {
    throw new Error(
      'Voice TTS failed after trying Kokoro URL, Edge, and Google fallbacks. Check TTS_API_URL or set EDGE_TTS_VOICE.',
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

  const resource = createFfmpegAudioResource(tmpFile);
  session.player.play(resource);
  await entersState(session.player, AudioPlayerStatus.Playing, 20000);
  await entersState(session.player, AudioPlayerStatus.Idle, 120000);

  fs.promises.unlink(tmpFile).catch(() => {});

  return true;
}

export function leaveTtsVoice(guildId) {
  const session = ttsSessions.get(guildId);
  if (!session?.connection) return false;
  session.connection.destroy();
  ttsSessions.delete(guildId);
  return true;
}
