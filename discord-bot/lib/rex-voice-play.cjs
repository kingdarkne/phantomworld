const {
  joinVoiceChannel,
  createAudioPlayer,
  createAudioResource,
  getVoiceConnection,
  entersState,
  VoiceConnectionStatus,
  NoSubscriberBehavior,
  StreamType
} = require('@discordjs/voice');

function lavalinkOnline(client) {
  if (client?.shoukaku?.nodes) {
    for (const node of client.shoukaku.nodes.values()) {
      if (node.state === 1) return true; // 1 = CONNECTED
    }
  }
  return false;
}

async function playUrlDirect(guild, voiceChannelId, url) {
  let connection = getVoiceConnection(guild.id);
  
  // If no connection, or it's not in the right channel, join it
  if (!connection) {
    connection = joinVoiceChannel({
      channelId: voiceChannelId,
      guildId: guild.id,
      adapterCreator: guild.voiceAdapterCreator,
      selfDeaf: false,
      selfMute: false,
    });
  }

  try {
    await entersState(connection, VoiceConnectionStatus.Ready, 15_000);
  } catch (err) {
    console.error("[Rex] Connection failed to ready:", err.message);
    throw err;
  }

  const player = createAudioPlayer({
    behaviors: { noSubscriber: NoSubscriberBehavior.Play },
  });
  
  // Use StreamType.Arbitrary for better compatibility with remote URLs
  const resource = createAudioResource(url, { 
    inlineVolume: true,
    inputType: StreamType.Arbitrary 
  });
  
  connection.subscribe(player);
  player.play(resource);

  return new Promise((resolve) => {
    const finish = () => {
      player.removeAllListeners();
      resolve();
    };
    player.on('idle', finish);
    player.on('error', (err) => {
      console.warn('[Rex] Direct voice playback error:', err.message);
      finish();
    });
  });
}

/**
 * Play Rex TTS audio — Lavalink when available, otherwise @discordjs/voice HTTP stream.
 */
async function playRexAudio(client, { guildId, voiceChannelId, audioUrl, title }) {
  const guild = client.guilds.cache.get(guildId);
  if (!guild || !audioUrl) return false;

  // IMPORTANT: If we are already in the voice channel (listening), 
  // we MUST use playUrlDirect to avoid conflicting with the receiver.
  // Shoukaku/Lavalink creates its own connection which would kick us out.
  const state = global.rexState?.[guildId];
  const alreadyListening = state?.active && state?.connection;

  if (alreadyListening) {
    console.log("[Rex] Already listening in VC, using direct voice playback to avoid conflict.");
    try {
      await playUrlDirect(guild, voiceChannelId, audioUrl);
      return true;
    } catch (e) {
      console.error('[Rex] Direct audio fail:', e.message);
      return false;
    }
  }

  // If not listening, try Lavalink
  if (lavalinkOnline(client)) {
    try {
      let player = client.shoukaku.players.get(guildId);
      if (!player) {
        player = await client.shoukaku.joinVoiceChannel({
          guildId: guildId,
          channelId: voiceChannelId,
          shardId: guild.shardId || 0,
          deaf: false,
        });
        
        if (!player.queue) {
            player.queue = {
                current: null,
                tracks: [],
                add: function(track) {
                    if (Array.isArray(track)) this.tracks.push(...track);
                    else this.tracks.push(track);
                }
            };
        }
      }
      
      const node = client.shoukaku.getIdealNode();
      const res = await node.rest.resolve(audioUrl);
      const tracks = res.data || res.tracks;
      
      if (tracks && (Array.isArray(tracks) ? tracks.length : true)) {
        const track = Array.isArray(tracks) ? tracks[0] : tracks;
        if (title) track.title = title;
        
        player.queue.add(track);
        if (!player.track) {
            const first = player.queue.tracks.shift();
            player.queue.current = first;
            await player.playTrack({ track: first.encoded || first.track || first });
        }
        return true;
      }
    } catch (e) {
      console.warn('[Rex] Lavalink playback failed, using voice fallback:', e.message);
    }
  }

  // Final fallback
  try {
    await playUrlDirect(guild, voiceChannelId, audioUrl);
    return true;
  } catch (e) {
    console.error('[Rex] Final audio fallback fail:', e.message);
    return false;
  }
}

module.exports = { playRexAudio, lavalinkOnline };
