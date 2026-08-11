import {
  joinVoiceChannel,
  createAudioPlayer,
  createAudioResource,
  AudioPlayerStatus,
  entersState,
  VoiceConnectionStatus,
  NoSubscriberBehavior,
} from '@discordjs/voice';
import play from 'play-dl';
import {
  isLavalinkReady,
  lavalinkPlay,
  lavalinkSkip,
  lavalinkStop,
  lavalinkQueueTitles,
} from './lavalink.js';

/** Per-guild simple music queue (play-dl fallback) */
const sessions = new Map();

function getSession(guildId) {
  if (!sessions.has(guildId)) {
    sessions.set(guildId, { queue: [], connection: null, player: null, playing: false });
  }
  return sessions.get(guildId);
}

export async function playInChannel({ guildId, member, guild, shardId }, query) {
  const voiceChannel = member?.voice?.channel;
  if (!voiceChannel) {
    throw new Error('Join a voice channel first.');
  }

  if (isLavalinkReady()) {
    return lavalinkPlay({
      guildId,
      channelId: voiceChannel.id,
      shardId,
      query,
    });
  }

  const session = getSession(guildId);
  let url = query;
  if (!/^https?:\/\//i.test(query)) {
    const searched = await play.search(query, { limit: 1, source: { youtube: 'video' } });
    if (!searched.length) throw new Error('No results for that search.');
    url = searched[0].url;
  }

  const info = await play.video_info(url);
  const title = info?.video_details?.title || query;
  session.queue.push({ url, title });

  if (!session.connection) {
    session.connection = joinVoiceChannel({
      channelId: voiceChannel.id,
      guildId,
      adapterCreator: guild.voiceAdapterCreator,
      selfDeaf: true,
    });
    session.player = createAudioPlayer({ behaviors: { noSubscriber: NoSubscriberBehavior.Play } });
    session.connection.subscribe(session.player);

    session.player.on(AudioPlayerStatus.Idle, () => {
      playNext(guildId);
    });
  }

  if (!session.playing) {
    await playNext(guildId);
  }

  return title;
}

async function playNext(guildId) {
  const session = sessions.get(guildId);
  if (!session || !session.queue.length) {
    if (session) session.playing = false;
    return null;
  }

  const track = session.queue.shift();
  session.playing = true;

  try {
    const stream = await play.stream(track.url);
    const resource = createAudioResource(stream.stream, { inputType: stream.type });
    session.player.play(resource);
    await entersState(session.player, AudioPlayerStatus.Playing, 15000);
    return track.title;
  } catch (err) {
    session.playing = false;
    console.warn('Music play failed:', err.message);
    return playNext(guildId);
  }
}

export function skipTrack(guildId) {
  if (isLavalinkReady()) return lavalinkSkip(guildId);
  const session = sessions.get(guildId);
  if (!session?.player) return false;
  session.player.stop();
  return true;
}

export function stopMusic(guildId) {
  if (isLavalinkReady()) return lavalinkStop(guildId);
  const session = sessions.get(guildId);
  if (!session) return false;
  session.queue = [];
  session.playing = false;
  if (session.player) session.player.stop();
  if (session.connection) {
    session.connection.destroy();
    session.connection = null;
  }
  sessions.delete(guildId);
  return true;
}

export function getQueue(guildId) {
  if (isLavalinkReady()) return lavalinkQueueTitles(guildId);
  const session = sessions.get(guildId);
  if (!session) return [];
  return session.queue.map((t) => t.title);
}
