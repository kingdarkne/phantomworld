import {
  ActionRowBuilder,
  ButtonBuilder,
  ButtonStyle,
  EmbedBuilder,
} from 'discord.js';
import { getLavalink, lavalinkReady, waitForLavalink } from './lavalink.js';
import { forceClearAllVoice } from './voice-guard.js';

/** @typedef {{ encoded: string, url?: string, title: string, thumbnail?: string, author?: string, durationSec?: number, requester: string, requesterId: string }} Track */

const sessions = new Map();
const pendingPicks = new Map();

function getSession(guildId) {
  if (!sessions.has(guildId)) {
    sessions.set(guildId, {
      queue: [],
      previous: [],
      player: null,
      playing: false,
      paused: false,
      stopping: false,
      current: null,
      textChannelId: null,
      voiceChannelId: null,
      nowPlayingMessageId: null,
      nowPlayingChannelId: null,
      startedAt: null,
      client: null,
    });
  }
  return sessions.get(guildId);
}

function lavalinkTrackToMeta(track, requester, requesterId) {
  const info = track.info || {};
  return {
    encoded: track.encoded,
    url: info.uri || info.sourceName,
    title: info.title || 'Unknown',
    thumbnail: info.artworkUrl,
    author: info.author || 'Unknown',
    durationSec: Math.floor((info.length || 0) / 1000),
    requester,
    requesterId,
  };
}

async function resolveTracks(query) {
  const shoukaku = getLavalink();
  const node = shoukaku?.getIdealNode();
  if (!node) throw new Error('Lavalink is not connected. Wait a few seconds and try again.');

  const identifier = /^https?:\/\//i.test(query.trim()) ? query.trim() : `ytsearch:${query.trim()}`;
  const result = await node.rest.resolve(identifier);

  if (!result?.tracks?.length) throw new Error('No music was found.');

  return {
    type: result.type,
    playlistName: result.playlistName,
    tracks: result.tracks,
  };
}

export function formatEndsAt(durationSec) {
  if (!durationSec || durationSec <= 0) return '—';
  const ends = Math.floor(Date.now() / 1000) + durationSec;
  return `<t:${ends}:f>`;
}

export function buildControlRow(paused = false) {
  return new ActionRowBuilder().addComponents(
    new ButtonBuilder()
      .setEmoji('⏮️')
      .setCustomId('phantom-music-prev')
      .setStyle(ButtonStyle.Secondary),
    new ButtonBuilder()
      .setEmoji(paused ? '▶️' : '⏸️')
      .setCustomId(paused ? 'phantom-music-resume' : 'phantom-music-pause')
      .setStyle(ButtonStyle.Secondary),
    new ButtonBuilder()
      .setEmoji('⏹️')
      .setCustomId('phantom-music-stop')
      .setStyle(ButtonStyle.Secondary),
    new ButtonBuilder()
      .setEmoji('⏭️')
      .setCustomId('phantom-music-next')
      .setStyle(ButtonStyle.Secondary),
  );
}

export function buildNowPlayingEmbed(track, voiceChannelId, { paused = false } = {}) {
  const embed = new EmbedBuilder()
    .setColor(paused ? 0xef4444 : 0x8b5cf6)
    .setTitle(`🎵・${track.title}`)
    .setURL(track.url || undefined)
    .setDescription(
      paused
        ? `Music paused in <#${voiceChannelId}>`
        : `Music started in <#${voiceChannelId}>!`,
    )
    .addFields(
      { name: '👤┆Requested By', value: track.requester, inline: true },
      { name: '⏰┆Ends at', value: formatEndsAt(track.durationSec), inline: true },
      { name: '🎬┆Author', value: track.author || 'Unknown', inline: true },
    );

  if (track.thumbnail) embed.setThumbnail(track.thumbnail);
  return embed;
}

export function buildQueueEmbed(guildName, session) {
  const current = session.current;
  let desc = '_Queue is empty._';
  if (session.queue.length > 0) {
    desc = session.queue
      .map((t, i) => `**[#${i + 1}]**┆${t.title.length >= 45 ? `${t.title.slice(0, 45)}…` : t.title} (<@${t.requesterId}>)`)
      .join('\n');
  }

  const embed = new EmbedBuilder()
    .setColor(0x8b5cf6)
    .setTitle(`🎵・Songs queue — ${guildName}`)
    .setDescription(desc.slice(0, 4096));

  if (current?.thumbnail) embed.setThumbnail(current.thumbnail);

  if (current) {
    embed.addFields({
      name: '🎵 Current song',
      value: `${current.title} (<@${current.requesterId}>)`,
    });
  }

  return embed;
}

export async function searchYouTube(query, limit = 5) {
  const { tracks } = await resolveTracks(query);
  return tracks.slice(0, limit).map((t) => {
    const info = t.info || {};
    return {
      encoded: t.encoded,
      url: info.uri,
      title: info.title || 'Unknown',
      thumbnail: info.artworkUrl,
      author: info.author || 'Unknown',
      durationSec: Math.floor((info.length || 0) / 1000),
    };
  });
}

export function buildSearchPickRow(count) {
  const emojis = ['1️⃣', '2️⃣', '3️⃣', '4️⃣', '5️⃣'];
  const row = new ActionRowBuilder();
  for (let i = 0; i < count; i++) {
    row.addComponents(
      new ButtonBuilder()
        .setEmoji(emojis[i])
        .setCustomId(`phantom-music-pick-${i}`)
        .setStyle(ButtonStyle.Secondary),
    );
  }
  return row;
}

export function registerPendingPick(messageId, data) {
  pendingPicks.set(messageId, { ...data, expires: Date.now() + 30_000 });
  setTimeout(() => pendingPicks.delete(messageId), 31_000);
}

export function getPendingPick(messageId) {
  const pick = pendingPicks.get(messageId);
  if (!pick || pick.expires < Date.now()) {
    pendingPicks.delete(messageId);
    return null;
  }
  return pick;
}

export function clearPendingPick(messageId) {
  pendingPicks.delete(messageId);
}

function wirePlayerEvents(guildId, player, client) {
  player.on('end', (data) => {
    const session = sessions.get(guildId);
    if (!session || session.stopping) return;
    if (data.reason === 'finished' || data.reason === 'loadFailed' || data.reason === 'stopped') {
      playNext(guildId, client);
    }
  });

  player.on('closed', () => {
    const session = sessions.get(guildId);
    if (session && !session.stopping) {
      sessions.delete(guildId);
    }
  });
}

async function ensureVoice(interaction) {
  const lavalinkUp = await waitForLavalink(25_000);
  if (!lavalinkUp) {
    throw new Error(
      'Lavalink is offline (music unavailable). Use /vcjoin for voice Q&A, or retry /play in a minute.',
    );
  }

  const voiceChannel = interaction.member?.voice?.channel;
  if (!voiceChannel) throw new Error("You're not in a voice channel!");

  const { leaveVcAssistant } = await import('./vc-assistant.js');
  await leaveVcAssistant(interaction.guildId);
  await forceClearAllVoice(interaction.guildId);

  const shoukaku = getLavalink();
  const session = getSession(interaction.guildId);
  session.client = interaction.client;

  if (session.voiceChannelId && session.voiceChannelId !== voiceChannel.id) {
    throw new Error('You are not in the same voice channel!');
  }

  let player = shoukaku.players.get(interaction.guildId);
  if (!player) {
    player = await shoukaku.joinVoiceChannel({
      guildId: interaction.guildId,
      channelId: voiceChannel.id,
      shardId: 0,
    });
    session.player = player;
    session.voiceChannelId = voiceChannel.id;
    session.textChannelId = interaction.channelId;
    wirePlayerEvents(interaction.guildId, player, interaction.client);

    if (voiceChannel.type === 13) {
      setTimeout(() => {
        interaction.guild.members.me?.voice.setSuppressed(false).catch(() => {});
      }, 500);
    }
  } else if (!session.textChannelId) {
    session.textChannelId = interaction.channelId;
  }

  return session;
}

export async function enqueueTrack(interaction, trackMeta) {
  const session = await ensureVoice(interaction);
  const track = {
    ...trackMeta,
    requester: trackMeta.requester || interaction.user.tag,
    requesterId: trackMeta.requesterId || interaction.user.id,
  };

  if (!track.encoded) throw new Error('Invalid track (missing Lavalink encoding).');

  session.queue.push(track);

  if (!session.playing && !session.paused) {
    await playNext(interaction.guildId, interaction.client);
    return { queued: false, track };
  }

  return { queued: true, track };
}

export async function playInChannel(interaction, query) {
  await ensureVoice(interaction);

  const resolved = await resolveTracks(query);
  const tracks = resolved.tracks;

  if (resolved.type === 'PLAYLIST' && tracks.length > 1) {
    const metas = tracks.map((t) =>
      lavalinkTrackToMeta(t, interaction.user.tag, interaction.user.id),
    );
    for (const meta of metas) {
      getSession(interaction.guildId).queue.push(meta);
    }
    if (!getSession(interaction.guildId).playing && !getSession(interaction.guildId).paused) {
      await playNext(interaction.guildId, interaction.client);
    }
    return {
      mode: 'queued',
      track: metas[0],
      results: null,
      playlistName: resolved.playlistName,
    };
  }

  if (tracks.length === 1 || resolved.type === 'TRACK') {
    const track = lavalinkTrackToMeta(tracks[0], interaction.user.tag, interaction.user.id);
    const result = await enqueueTrack(interaction, track);
    return { mode: result.queued ? 'queued' : 'playing', track, results: null };
  }

  const results = tracks.slice(0, 5).map((t) => {
    const info = t.info || {};
    return {
      encoded: t.encoded,
      url: info.uri,
      title: info.title || 'Unknown',
      thumbnail: info.artworkUrl,
      author: info.author || 'Unknown',
      durationSec: Math.floor((info.length || 0) / 1000),
    };
  });

  if (results.length === 1) {
    const track = { ...results[0], requester: interaction.user.tag, requesterId: interaction.user.id };
    const result = await enqueueTrack(interaction, track);
    return { mode: result.queued ? 'queued' : 'playing', track, results: null };
  }

  return { mode: 'pick', track: null, results };
}

async function playNext(guildId, client) {
  const session = sessions.get(guildId);
  if (!session?.player) return null;

  if (session.current) {
    session.previous.push(session.current);
    if (session.previous.length > 25) session.previous.shift();
  }

  if (!session.queue.length) {
    session.playing = false;
    session.paused = false;
    session.current = null;
    session.startedAt = null;
    return null;
  }

  const track = session.queue.shift();
  session.current = track;
  session.playing = true;
  session.paused = false;
  session.startedAt = Date.now();

  try {
    await session.player.playTrack({ track: { encoded: track.encoded } });

    if (client && session.textChannelId) {
      await postNowPlaying(client, guildId);
    }

    return track.title;
  } catch (err) {
    session.playing = false;
    console.warn('Lavalink play failed:', err.message);
    return playNext(guildId, client);
  }
}

export async function postNowPlaying(client, guildId) {
  const session = sessions.get(guildId);
  if (!session?.current || !session.textChannelId) return;

  const channel = await client.channels.fetch(session.textChannelId).catch(() => null);
  if (!channel?.isTextBased()) return;

  const embed = buildNowPlayingEmbed(session.current, session.voiceChannelId, {
    paused: session.paused,
  });
  const row = buildControlRow(session.paused);

  if (session.nowPlayingMessageId) {
    const msg = await channel.messages.fetch(session.nowPlayingMessageId).catch(() => null);
    if (msg) {
      await msg.edit({ embeds: [embed], components: [row] });
      return;
    }
  }

  const msg = await channel.send({ embeds: [embed], components: [row] });
  session.nowPlayingMessageId = msg.id;
  session.nowPlayingChannelId = channel.id;
}

export function skipTrack(guildId) {
  const session = sessions.get(guildId);
  if (!session?.player || !session.current) return false;
  session.player.stopTrack();
  return true;
}

export function pauseMusic(guildId) {
  const session = sessions.get(guildId);
  if (!session?.player || !session.playing || session.paused) return false;
  session.player.setPaused(true);
  session.paused = true;
  return true;
}

export function resumeMusic(guildId) {
  const session = sessions.get(guildId);
  if (!session?.player || !session.paused) return false;
  session.player.setPaused(false);
  session.paused = false;
  session.playing = true;
  return true;
}

export function playPrevious(guildId) {
  const session = sessions.get(guildId);
  if (!session?.previous.length) return false;
  const prev = session.previous.pop();
  if (session.current) session.queue.unshift(session.current);
  session.queue.unshift(prev);
  session.player?.stopTrack();
  return true;
}

export async function stopMusic(guildId) {
  const session = sessions.get(guildId);
  const hadPlayer = Boolean(getLavalink()?.players.get(guildId));

  if (session) {
    session.stopping = true;
    session.queue = [];
    session.previous = [];
    session.playing = false;
    session.paused = false;
    session.current = null;
    session.player = null;
    session.nowPlayingMessageId = null;
    sessions.delete(guildId);
  }

  await forceClearAllVoice(guildId);
  return Boolean(session) || hadPlayer;
}

export function getQueue(guildId) {
  const session = sessions.get(guildId);
  if (!session) return { current: null, upcoming: [] };
  return {
    current: session.current,
    upcoming: session.queue.map((t) => t.title),
  };
}

export function getFullQueue(guildId) {
  const session = sessions.get(guildId);
  if (!session) return null;
  return { current: session.current, queue: session.queue };
}

export function getNowPlaying(guildId) {
  const session = sessions.get(guildId);
  if (!session?.current) return null;
  return {
    track: session.current,
    paused: session.paused,
    voiceChannelId: session.voiceChannelId,
  };
}

export function getSessionVoiceChannel(guildId) {
  return sessions.get(guildId)?.voiceChannelId || null;
}

export async function handleMusicButton(interaction) {
  const id = interaction.customId;
  if (!id.startsWith('phantom-music-')) return false;

  const session = sessions.get(interaction.guildId);
  const memberChannel = interaction.member?.voice?.channelId;
  const botChannel = session?.voiceChannelId;

  if (botChannel && memberChannel !== botChannel) {
    await interaction.reply({
      content: "You're not in the same voice channel!",
      ephemeral: true,
    });
    return true;
  }

  if (id === 'phantom-music-pause') {
    const ok = pauseMusic(interaction.guildId);
    if (!ok) {
      await interaction.reply({ content: 'Nothing playing.', ephemeral: true });
      return true;
    }
    await interaction.deferUpdate();
    await postNowPlaying(interaction.client, interaction.guildId);
    return true;
  }

  if (id === 'phantom-music-resume') {
    const ok = resumeMusic(interaction.guildId);
    if (!ok) {
      await interaction.reply({ content: 'Music is not paused.', ephemeral: true });
      return true;
    }
    await interaction.deferUpdate();
    await postNowPlaying(interaction.client, interaction.guildId);
    return true;
  }

  if (id === 'phantom-music-stop') {
    await stopMusic(interaction.guildId);
    await interaction.deferUpdate();
    const embed = new EmbedBuilder()
      .setColor(0xef4444)
      .setDescription('Music is currently stopped');
    await interaction.message.edit({ embeds: [embed], components: [] });
    return true;
  }

  if (id === 'phantom-music-next') {
    if (!session?.current) {
      await interaction.reply({ content: 'Nothing playing.', ephemeral: true });
      return true;
    }
    await interaction.deferUpdate();
    skipTrack(interaction.guildId);
    return true;
  }

  if (id === 'phantom-music-prev') {
    const ok = playPrevious(interaction.guildId);
    if (!ok) {
      await interaction.reply({ content: 'No previous track.', ephemeral: true });
      return true;
    }
    await interaction.deferUpdate();
    return true;
  }

  if (id.startsWith('phantom-music-pick-')) {
    const pick = getPendingPick(interaction.message.id);
    if (!pick || pick.userId !== interaction.user.id) {
      await interaction.reply({ content: 'This search expired or is not yours.', ephemeral: true });
      return true;
    }

    if (id === 'phantom-music-pick-cancel') {
      clearPendingPick(interaction.message.id);
      await stopMusic(interaction.guildId);
      await interaction.update({ content: 'Search cancelled.', embeds: [], components: [] });
      return true;
    }

    const index = Number(id.replace('phantom-music-pick-', ''));
    const track = pick.tracks[index];
    if (!track) {
      await interaction.reply({ content: 'Invalid selection.', ephemeral: true });
      return true;
    }

    clearPendingPick(interaction.message.id);
    await interaction.deferUpdate();

    const fakeInteraction = {
      guildId: interaction.guildId,
      channelId: pick.channelId,
      member: interaction.member,
      guild: interaction.guild,
      user: interaction.user,
      client: interaction.client,
    };

    const result = await enqueueTrack(fakeInteraction, {
      ...track,
      requester: interaction.user.tag,
      requesterId: interaction.user.id,
    });

    const embed = buildNowPlayingEmbed(
      result.track,
      getSessionVoiceChannel(interaction.guildId),
      { paused: false },
    );
    if (result.queued) embed.setDescription('The song has been added to the queue!');

    await interaction.message.edit({
      embeds: [embed],
      components: result.queued ? [] : [buildControlRow(false)],
    });
    return true;
  }

  return false;
}
