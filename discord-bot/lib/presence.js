import { ActivityType } from 'discord.js';
import { getStatus } from './fivem.js';
import { displayServerName, joinUrl, cfxJoinId } from './branding.js';

const pollSeconds = Number(process.env.PRESENCE_POLL_SECONDS || 60);
const rotateSeconds = Number(process.env.PRESENCE_ROTATE_SECONDS || 25);

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

function trimActivity(text, max = 128) {
  if (!text) return '';
  const s = String(text).trim();
  return s.length <= max ? s : `${s.slice(0, max - 1)}…`;
}

function buildActivities(status) {
  const activities = [];
  const players = status.playerCount ?? 0;
  const max = status.maxPlayers ?? 48;
  const pct = max > 0 ? Math.round((players / max) * 100) : 0;
  const serverName = displayServerName(status);

  activities.push({
    name: trimActivity(`${players}/${max} online (${pct}% full)`),
    type: ActivityType.Watching,
  });

  activities.push({
    name: trimActivity(serverName),
    type: ActivityType.Playing,
  });

  const link = joinUrl();
  if (link) {
    activities.push({
      name: trimActivity(`Join → cfx.re/join/${cfxJoinId()}`),
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

  const topPlayers = status.topPlayers || [];
  if (players > 0 && topPlayers.length > 0) {
    const label = topPlayers.length === 1 ? topPlayers[0] : topPlayers.slice(0, 4).join(', ');
    activities.push({
      name: trimActivity(label),
      type: ActivityType.Listening,
    });
  } else if (players === 0) {
    activities.push({
      name: 'Waiting for players — hop in!',
      type: ActivityType.Watching,
    });
  }

  if (activities.length === 0) {
    activities.push({
      name: 'Phantom World RP',
      type: ActivityType.Watching,
    });
  }

  return activities;
}

function presenceUserStatus(status) {
  if (status.offline) return 'dnd';
  const players = status.playerCount ?? 0;
  if (players === 0) return 'idle';
  return 'online';
}

export function startLivePresence(client) {
  let activities = [{ name: 'Starting up…', type: ActivityType.Watching }];
  let userStatus = 'online';
  let rotationIndex = 0;

  function apply() {
    if (!client.user) return;
    const activity = activities[rotationIndex % activities.length];
    client.user.setPresence({
      activities: [activity],
      status: userStatus,
    });
  }

  async function refresh() {
    try {
      const status = await getStatus();
      status.offline = false;
      activities = buildActivities(status);
      userStatus = presenceUserStatus(status);
      rotationIndex = 0;
      apply();
    } catch (err) {
      console.warn('Presence refresh failed:', err.message);
      activities = [
        { name: 'Server unreachable — check /status', type: ActivityType.Watching },
      ];
      const joinId = cfxJoinId();
      if (joinId) {
        activities.push({
          name: trimActivity(`cfx.re/join/${joinId}`),
          type: ActivityType.Watching,
        });
      }
      userStatus = 'dnd';
      rotationIndex = 0;
      apply();
    }
  }

  refresh();
  setInterval(refresh, pollSeconds * 1000);
  setInterval(() => {
    if (activities.length > 1) {
      rotationIndex = (rotationIndex + 1) % activities.length;
      apply();
    }
  }, rotateSeconds * 1000);
}
