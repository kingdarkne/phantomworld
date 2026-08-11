import { Shoukaku, Connectors } from 'shoukaku';

let shoukaku = null;
let lavalinkReady = false;

function lavalinkPassword() {
  return (
    process.env.LAVALINK_PASSWORD ||
    process.env.LAVALINK_SERVER_PASSWORD ||
    process.env.LAVALINK_AUTH ||
    'youshallnotpass'
  );
}

export function isLavalinkEnabled() {
  return Boolean(
    process.env.LAVALINK_HOST ||
      process.env.LAVALINK_URL ||
      process.env.LAVALINK_SERVER_HOST,
  );
}

export function isLavalinkReady() {
  return lavalinkReady;
}

export function getShoukaku() {
  return shoukaku;
}

export function initLavalink(client) {
  if (!isLavalinkEnabled()) {
    console.log('[lavalink] Not configured — music uses play-dl fallback');
    return null;
  }

  const host =
    process.env.LAVALINK_HOST ||
    process.env.LAVALINK_SERVER_HOST ||
    '127.0.0.1';
  const port = process.env.LAVALINK_PORT || process.env.LAVALINK_SERVER_PORT || '2333';
  const password = lavalinkPassword();
  const secure = process.env.LAVALINK_SECURE === '1' || process.env.LAVALINK_SECURE === 'true';
  const name = process.env.LAVALINK_NAME || 'main';

  shoukaku = new Shoukaku(new Connectors.DiscordJS(client), [
    {
      name,
      url: `${host}:${port}`,
      auth: password,
      secure,
    },
  ]);

  shoukaku.on('ready', (nodeName) => {
    lavalinkReady = true;
    console.log(`[lavalink] Node ready: ${nodeName} (${host}:${port})`);
  });

  shoukaku.on('error', (nodeName, error) => {
    lavalinkReady = false;
    console.warn(`[lavalink] Node error (${nodeName}):`, error?.message || error);
  });

  shoukaku.on('close', (nodeName, code, reason) => {
    lavalinkReady = false;
    console.warn(`[lavalink] Node closed (${nodeName}):`, code, reason);
  });

  console.log(`[lavalink] Connecting to ${host}:${port}…`);
  return shoukaku;
}

function resolveQuery(query) {
  const q = query.trim();
  if (/^https?:\/\//i.test(q)) return q;
  return `ytsearch:${q}`;
}

export async function lavalinkPlay({ guildId, channelId, shardId, query }) {
  if (!shoukaku) throw new Error('Lavalink is not configured.');
  const node = shoukaku.getIdealNode();
  if (!node) {
    throw new Error(
      'Lavalink node is offline. Check LAVALINK_PASSWORD (VPS uses phantomworld) and that Lavalink is running.',
    );
  }

  const result = await node.rest.resolve(resolveQuery(query));
  const tracks = result?.tracks;
  if (!tracks?.length) throw new Error('No results for that search.');

  const track = tracks[0];
  let player = shoukaku.players.get(guildId);
  if (!player) {
    player = await shoukaku.joinVoiceChannel({
      guildId,
      channelId,
      shardId: shardId ?? 0,
      deaf: true,
    });
  } else if (player.channelId !== channelId) {
    await player.move(channelId);
  }

  lastEncoded.set(guildId, track.encoded);
  hookPlayerLoop(player);
  await player.playTrack({ track: track.encoded });
  return track.info?.title || query;
}

export function lavalinkSkip(guildId) {
  const player = shoukaku?.players.get(guildId);
  if (!player) return false;
  player.stopTrack();
  return true;
}

export function lavalinkStop(guildId) {
  const player = shoukaku?.players.get(guildId);
  if (!player) return false;
  shoukaku.leaveVoiceChannel(guildId);
  return true;
}

export function lavalinkQueueTitles(guildId) {
  const player = shoukaku?.players.get(guildId);
  if (!player) return [];
  const titles = [];
  if (player.track?.info?.title) titles.push(`▶️ ${player.track.info.title}`);
  if (Array.isArray(player.queue)) {
    for (const t of player.queue) {
      if (t?.info?.title) titles.push(t.info.title);
    }
  }
  return titles;
}

export function lavalinkPause(guildId, paused = true) {
  const player = shoukaku?.players.get(guildId);
  if (!player) return false;
  player.setPaused(paused);
  return true;
}

export function lavalinkVolume(guildId, volume) {
  const player = shoukaku?.players.get(guildId);
  if (!player) return false;
  const vol = Math.min(Math.max(Number(volume) || 100, 1), 200);
  player.setGlobalVolume(vol);
  return vol;
}

const loopModes = new Map(); // guildId -> 'none' | 'track'
const lastEncoded = new Map(); // guildId -> encoded track string

export function lavalinkLoop(guildId, mode) {
  const player = shoukaku?.players.get(guildId);
  if (!player) return null;
  const next =
    mode === 'track' || mode === 'one'
      ? 'track'
      : mode === 'toggle'
        ? loopModes.get(guildId) === 'track'
          ? 'none'
          : 'track'
        : 'none';
  loopModes.set(guildId, next);
  return next;
}

export function lavalinkNowPlaying(guildId) {
  const player = shoukaku?.players.get(guildId);
  if (!player?.track?.info) return null;
  return {
    title: player.track.info.title,
    author: player.track.info.author,
    uri: player.track.info.uri,
    loop: loopModes.get(guildId) || 'none',
  };
}

export function getLavalinkPlayer(guildId) {
  return shoukaku?.players.get(guildId) || null;
}

function hookPlayerLoop(player) {
  if (!player || player.__loopHooked) return;
  player.__loopHooked = true;
  player.on('end', async (data) => {
    try {
      const reason = data?.reason || data?.type;
      if (reason && reason !== 'finished') return;
      const guildId = player.guildId;
      if (loopModes.get(guildId) !== 'track') return;
      const encoded = lastEncoded.get(guildId) || player.track?.encoded;
      if (!encoded) return;
      await player.playTrack({ track: encoded });
    } catch (err) {
      console.warn('[lavalink] loop replay failed:', err.message);
    }
  });
}
