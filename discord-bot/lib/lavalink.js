import { Shoukaku, Connectors } from 'shoukaku';

let shoukaku = null;
let lavalinkReady = false;

export function isLavalinkEnabled() {
  return Boolean(process.env.LAVALINK_HOST || process.env.LAVALINK_URL);
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

  const host = process.env.LAVALINK_HOST || '127.0.0.1';
  const port = process.env.LAVALINK_PORT || '2333';
  const password = process.env.LAVALINK_PASSWORD || 'youshallnotpass';
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
    console.log(`[lavalink] Node ready: ${nodeName}`);
  });

  shoukaku.on('error', (nodeName, error) => {
    lavalinkReady = false;
    console.warn(`[lavalink] Node error (${nodeName}):`, error?.message || error);
  });

  shoukaku.on('close', (nodeName, code, reason) => {
    lavalinkReady = false;
    console.warn(`[lavalink] Node closed (${nodeName}):`, code, reason);
  });

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
  if (!node) throw new Error('Lavalink node is offline. Check LAVALINK_HOST / password and restart Lavalink.');

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
  if (player.track?.info?.title) titles.push(player.track.info.title);
  if (Array.isArray(player.queue)) {
    for (const t of player.queue) {
      if (t?.info?.title) titles.push(t.info.title);
    }
  }
  return titles;
}
