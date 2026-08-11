const fs = require('fs');
const os = require('os');
const path = require('path');
const {
  joinVoiceChannel,
  createAudioPlayer,
  createAudioResource,
  getVoiceConnection,
  entersState,
  VoiceConnectionStatus,
  AudioPlayerStatus,
  NoSubscriberBehavior,
} = require('@discordjs/voice');

// #region agent log
function agentLog(hypothesisId, location, message, data = {}) {
  const payload = { hypothesisId, location, message, data, timestamp: Date.now() };
  try {
    fs.mkdirSync('/opt/cursor/logs', { recursive: true });
    fs.appendFileSync('/opt/cursor/logs/debug.log', `${JSON.stringify(payload)}\n`);
  } catch (_) {}
  try {
    console.log('[agent-log]', JSON.stringify(payload));
  } catch (_) {}
}
// #endregion

function lavalinkOnline(client) {
  if (client?.shoukaku?.nodes) {
    for (const node of client.shoukaku.nodes.values()) {
      if (node.state === 1) return true;
    }
  }
  return false;
}

async function stopShoukakuGuild(client, guildId) {
  if (!client?.shoukaku) return;
  try {
    if (typeof client.radio?.stopRadio === 'function') {
      await client.radio.stopRadio(client, guildId).catch(() => {});
    }
  } catch (_) {}
  try {
    await client.shoukaku.leaveVoiceChannel(guildId);
  } catch (_) {}
  try {
    client.shoukaku.players?.delete?.(guildId);
  } catch (_) {}
}

async function downloadToTemp(url) {
  const res = await fetch(url, { signal: AbortSignal.timeout(20000) });
  if (!res.ok) throw new Error(`Audio download HTTP ${res.status}`);
  const buf = Buffer.from(await res.arrayBuffer());
  if (buf.length < 200) throw new Error('Audio download empty');
  const tmp = path.join(os.tmpdir(), `rex-play-${Date.now()}-${Math.random().toString(16).slice(2)}.mp3`);
  await fs.promises.writeFile(tmp, buf);
  return tmp;
}

/**
 * Play on the existing @discordjs/voice connection (Rex listener mode).
 */
async function playFileDirect(guild, voiceChannelId, filePath) {
  let connection = getVoiceConnection(guild.id);
  if (!connection) {
    connection = joinVoiceChannel({
      channelId: voiceChannelId,
      guildId: guild.id,
      adapterCreator: guild.voiceAdapterCreator,
      selfDeaf: false,
      selfMute: false,
    });
  }

  await entersState(connection, VoiceConnectionStatus.Ready, 15_000);

  const player = createAudioPlayer({
    behaviors: { noSubscriber: NoSubscriberBehavior.Play },
  });
  const resource = createAudioResource(filePath, { inlineVolume: true });
  if (resource.volume) resource.volume.setVolume(1);
  connection.subscribe(player);
  player.play(resource);

  await entersState(player, AudioPlayerStatus.Playing, 10_000).catch(() => {});
  await new Promise((resolve) => {
    const done = () => {
      player.removeAllListeners();
      resolve();
    };
    player.once('idle', done);
    player.once('error', (err) => {
      console.warn('[Rex] Direct voice playback error:', err.message);
      done();
    });
    setTimeout(done, 120_000);
  });
}

/**
 * Play TTS via Lavalink (reliable; radio/music must release the guild first).
 */
async function playViaLavalink(client, { guildId, voiceChannelId, audioUrl, title }) {
  const guild = client.guilds.cache.get(guildId);
  if (!guild) throw new Error('Guild missing');
  if (!lavalinkOnline(client)) throw new Error('Lavalink offline');

  // Always reclaim the voice channel from radio/music
  await stopShoukakuGuild(client, guildId);

  // Destroy any stale discord.js connection so Shoukaku can join
  const existing = getVoiceConnection(guildId);
  if (existing) {
    try {
      existing.destroy();
    } catch (_) {}
  }
  agentLog('D', 'lib/rex-voice-play.cjs:107', 'after voice cleanup before shoukaku join', {
    guildId,
    voiceChannelId,
    hadDiscordConnection: Boolean(existing),
    hasShoukakuPlayer: Boolean(client.shoukaku.players?.get?.(guildId)),
    shoukakuPlayers: client.shoukaku.players?.size,
  });

  await new Promise((r) => setTimeout(r, 400));

  const player = await client.shoukaku.joinVoiceChannel({
    guildId,
    channelId: voiceChannelId,
    shardId: guild.shardId || 0,
    deaf: false,
  });
  if (!player.__agentRexEventLogAttached) {
    player.__agentRexEventLogAttached = true;
    const eventData = (data) => ({
      guildId,
      voiceChannelId,
      playerTrackPresent: Boolean(player.track),
      reason: data?.reason,
      severity: data?.exception?.severity,
      cause: data?.exception?.cause,
      code: data?.code,
    });
    player.on('start', (data) =>
      agentLog('C', 'lib/rex-voice-play.cjs:124', 'shoukaku player start event', eventData(data)),
    );
    player.on('end', (data) =>
      agentLog('C', 'lib/rex-voice-play.cjs:127', 'shoukaku player end event', eventData(data)),
    );
    player.on('exception', (data) =>
      agentLog('C', 'lib/rex-voice-play.cjs:130', 'shoukaku player exception event', eventData(data)),
    );
    player.on('stuck', (data) =>
      agentLog('C', 'lib/rex-voice-play.cjs:133', 'shoukaku player stuck event', eventData(data)),
    );
    player.on('closed', (data) =>
      agentLog('F', 'lib/rex-voice-play.cjs:136', 'shoukaku player closed event', eventData(data)),
    );
  }
  agentLog('D,F', 'lib/rex-voice-play.cjs:139', 'shoukaku join returned', {
    guildId,
    voiceChannelId,
    playerTrackPresent: Boolean(player.track),
    playerNode: player.node?.name,
    connectionState: client.shoukaku.connections?.get?.(guildId)?.state,
  });

  const node = client.shoukaku.getIdealNode();
  const res = await node.rest.resolve(audioUrl);
  let track = null;
  if (res?.loadType === 'track') track = res.data;
  else if (res?.loadType === 'search' || Array.isArray(res?.data)) track = res.data?.[0];
  else if (res?.data?.encoded) track = res.data;
  else track = res?.tracks?.[0] || res?.data?.[0] || null;

  if (!track) throw new Error('Lavalink could not resolve Rex audio URL');

  const encoded = track.encoded || track.track;
  if (!encoded) throw new Error('No encoded track from Lavalink');
  agentLog('A,C', 'lib/rex-voice-play.cjs:159', 'lavalink resolve selected track', {
    guildId,
    loadType: res?.loadType,
    type: res?.type,
    dataIsArray: Array.isArray(res?.data),
    trackHasEncoded: Boolean(track.encoded),
    trackHasTrack: Boolean(track.track),
    encodedLength: encoded.length,
    title: track.info?.title,
    length: track.info?.length,
  });

  if (title) {
    try {
      track.info = track.info || {};
      track.info.title = title;
    } catch (_) {}
  }

  await player.playTrack({ track: { encoded } });
  agentLog('A,C,F', 'lib/rex-voice-play.cjs:177', 'playTrack accepted by shoukaku', {
    guildId,
    voiceChannelId,
    playerTrackPresent: Boolean(player.track),
    playerPaused: player.paused,
    playerPosition: player.position,
    playerVolume: player.volume,
  });
  console.log('[Rex] Lavalink playback started');
  return true;
}

/**
 * Play Rex TTS audio.
 * - If Rex is listening (@discordjs/voice): play on that connection (file + ffmpeg)
 * - Otherwise: Lavalink (after stopping radio)
 */
async function playRexAudio(client, { guildId, voiceChannelId, audioUrl, title }) {
  const guild = client.guilds.cache.get(guildId);
  if (!guild || !audioUrl) return false;

  const state = global.rexState?.[guildId];
  const alreadyListening = Boolean(state?.active && (state?.connection || getVoiceConnection(guildId)));
  const botVoice = guild.members.me?.voice;
  agentLog('B,D', 'lib/rex-voice-play.cjs:198', 'playRexAudio entry', {
    guildId,
    voiceChannelId,
    audioUrlHost: (() => {
      try {
        return new URL(audioUrl).host;
      } catch (_) {
        return 'invalid';
      }
    })(),
    alreadyListening,
    stateActive: Boolean(state?.active),
    botChannelId: botVoice?.channelId,
    selfMute: botVoice?.selfMute,
    serverMute: botVoice?.serverMute,
    suppress: botVoice?.suppress,
  });

  let tmp = null;
  try {
    if (alreadyListening) {
      console.log('[Rex] Listening mode — direct discord.js playback');
      tmp = await downloadToTemp(audioUrl);
      await playFileDirect(guild, voiceChannelId, tmp);
      return true;
    }

    try {
      await playViaLavalink(client, { guildId, voiceChannelId, audioUrl, title });
      return true;
    } catch (e) {
      console.warn('[Rex] Lavalink playback failed, trying direct:', e.message);
    }

    // Direct fallback: leave shoukaku then use discord.js voice
    await stopShoukakuGuild(client, guildId);
    await new Promise((r) => setTimeout(r, 400));
    tmp = await downloadToTemp(audioUrl);
    await playFileDirect(guild, voiceChannelId, tmp);
    return true;
  } catch (e) {
    console.error('[Rex] playRexAudio failed:', e.message);
    return false;
  } finally {
    if (tmp) fs.promises.unlink(tmp).catch(() => {});
  }
}

module.exports = {
  playRexAudio,
  lavalinkOnline,
  stopShoukakuGuild,
  playViaLavalink,
};
