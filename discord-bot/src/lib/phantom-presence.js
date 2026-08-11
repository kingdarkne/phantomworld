const { ActivityType } = require('discord.js');
const { getPhantomStatus } = require('../../aio-bridge/fivem-status');

/** Twitch or YouTube URL required for Streaming activity (Discord API rule). */
const DEFAULT_STREAM_URL = 'https://www.youtube.com/watch?v=jfKfPfyJRdk';

function streamUrl() {
  return process.env.PHANTOM_STREAM_URL || DEFAULT_STREAM_URL;
}

function memberCount(client) {
  return client.guilds.cache.reduce((acc, guild) => acc + (guild.memberCount || 0), 0);
}

function cfxJoinId() {
  return process.env.CFX_SERVER_ID || '';
}

function trimActivity(text, max = 128) {
  if (!text) return '';
  const s = String(text).trim();
  return s.length <= max ? s : `${s.slice(0, max - 1)}…`;
}

function formatUptime(seconds) {
  if (!seconds || seconds < 0) return null;
  const total = Math.floor(seconds);
  const days = Math.floor(total / 86400);
  const hours = Math.floor((total % 86400) / 3600);
  const minutes = Math.floor((total % 3600) / 60);
  if (days > 0) return `${days}d ${hours}h uptime`;
  if (hours > 0) return `${hours}h ${minutes}m uptime`;
  return `${minutes}m uptime`;
}

/** Pre-backup live FiveM presence lines (merged back). */
function buildLiveActivities(status, client) {
  const activities = [];
  const players = status.playerCount ?? 0;
  const max = status.maxPlayers ?? 48;
  const pct = max > 0 ? Math.round((players / max) * 100) : 0;
  const serverName =
    process.env.PHANTOM_SERVER_NAME ||
    process.env.FIVEM_DISPLAY_NAME ||
    status.serverName ||
    'Phantom World';

  activities.push({
    name: trimActivity(`${players}/${max} online (${pct}% full)`),
    type: ActivityType.Watching,
  });

  activities.push({
    name: trimActivity(serverName),
    type: ActivityType.Playing,
  });

  const joinId = cfxJoinId();
  if (joinId) {
    activities.push({
      name: trimActivity(`Join → cfx.re/join/${joinId}`),
      type: ActivityType.Watching,
    });
  }

  const uptime = formatUptime(status.uptimeSeconds);
  if (uptime) {
    activities.push({
      name: trimActivity(uptime),
      type: ActivityType.Watching,
    });
  }

  if (players === 0) {
    activities.push({
      name: 'Waiting for players — hop in!',
      type: ActivityType.Watching,
    });
  }

  // Keep Phantom branding lines too (merged, not replaced)
  const servers = client.guilds.cache.size;
  const members = memberCount(client);
  activities.push(
    { name: trimActivity(`Phantom World | $help · /help`), type: ActivityType.Playing },
    { name: trimActivity(`Rex · say "Hey Rex" in VC`), type: ActivityType.Listening },
    { name: trimActivity(`Watching over ${servers} servers · ${members} users`), type: ActivityType.Watching },
    { name: trimActivity('Developed by Phantom World'), type: ActivityType.Streaming, url: streamUrl() },
  );

  return activities;
}

function presenceUserStatus(status) {
  if (status.offline) return 'dnd';
  const players = status.playerCount ?? 0;
  if (players === 0) return 'idle';
  return 'online';
}

/**
 * Merged presence: live FiveM stats (pre-backup) + Phantom branding.
 * Set FIVEM_LIVE_PRESENCE=0 to use branding-only rotation.
 */
function startPhantomPresence(client) {
  const liveEnabled = process.env.FIVEM_LIVE_PRESENCE !== '0';
  const pollSeconds = Number(process.env.PRESENCE_POLL_SECONDS || 60);
  const rotateSeconds = Number(process.env.PRESENCE_ROTATE_SECONDS || 25);

  console.log(
    `[Phantom presence] Starting merged presence (FiveM live=${liveEnabled ? 'on' : 'off'})…`,
  );

  let activities = [{ name: 'Starting up…', type: ActivityType.Watching }];
  let userStatus = 'online';
  let index = 0;

  const apply = () => {
    if (!client.user) return;
    const pick = activities[index % activities.length];
    client.user.setPresence({
      status: userStatus,
      activities: [pick],
    });
  };

  const refresh = async () => {
    if (!liveEnabled) {
      activities = [
        { name: '🌈 Phantom World | /help', type: ActivityType.Streaming, url: streamUrl() },
        { name: `🌌 Watching over ${client.guilds.cache.size} servers`, type: ActivityType.Watching },
        { name: '🎵 Phantom Vibes · $play', type: ActivityType.Listening },
        { name: '🤖 Rex · $rex join', type: ActivityType.Playing },
        { name: '✨ Developed by Phantom World', type: ActivityType.Playing },
      ];
      userStatus = 'online';
      index = 0;
      apply();
      return;
    }

    try {
      const status = await getPhantomStatus();
      status.offline = false;
      activities = buildLiveActivities(status, client);
      userStatus = presenceUserStatus(status);
      index = 0;
      apply();
      console.log(
        `[Phantom presence] Live: ${status.playerCount ?? 0}/${status.maxPlayers ?? 48} — ${status.serverName || 'Phantom World'}`,
      );
    } catch (err) {
      console.warn('[Phantom presence] FiveM refresh failed:', err.message);
      activities = [
        { name: 'Server unreachable — check /phantomstatus', type: ActivityType.Watching },
      ];
      const joinId = cfxJoinId();
      if (joinId) {
        activities.push({
          name: trimActivity(`cfx.re/join/${joinId}`),
          type: ActivityType.Watching,
        });
      }
      activities.push({
        name: 'Phantom World | $help',
        type: ActivityType.Playing,
      });
      userStatus = 'dnd';
      index = 0;
      apply();
    }
  };

  refresh();
  setInterval(refresh, pollSeconds * 1000);
  setInterval(() => {
    if (activities.length > 1) {
      index = (index + 1) % activities.length;
      apply();
    }
  }, rotateSeconds * 1000);
}

async function setPhantomBotProfile(client) {
  const description =
    '⚡ Phantom World — FiveM RP + ALL-IN-ONE Discord bot. ' +
    'Prefix $help · Slash /help · Rex ($rex join) · AI ($ask · $say) · Music ($play). ' +
    'Developed by Phantom World · discord.gg/zZSvmdUx';

  try {
    if (client.application) {
      await client.application.edit({ description: description.slice(0, 400) });
      console.log('[Phantom presence] Application description updated');
    }
  } catch (err) {
    console.warn('[Phantom presence] Application description update failed:', err.message);
  }
}

module.exports = { startPhantomPresence, setPhantomBotProfile };
