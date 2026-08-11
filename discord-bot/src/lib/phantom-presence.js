const { ActivityType } = require('discord.js');

/** Twitch or YouTube URL required for Streaming activity (Discord API rule). */
const DEFAULT_STREAM_URL = 'https://www.youtube.com/watch?v=jfKfPfyJRdk';

function streamUrl() {
  return process.env.PHANTOM_STREAM_URL || DEFAULT_STREAM_URL;
}

function memberCount(client) {
  return client.guilds.cache.reduce((acc, guild) => acc + (guild.memberCount || 0), 0);
}

function phantomRotations(client) {
  const servers = client.guilds.cache.size;
  const members = memberCount(client);

  // Rainbow/Colorful themed statuses with various icons
  return [
    {
      status: 'online',
      activity: { type: ActivityType.Streaming, name: '🌈 Phantom World | /help', url: streamUrl() },
    },
    {
      status: 'online',
      activity: { type: ActivityType.Watching, name: '🌌 Watching over ' + servers + ' servers', icon: '👁' },
    },
    {
      status: 'idle',
      activity: { type: ActivityType.Listening, name: '🎵 Phantom Vibes · ' + members + ' users', icon: '🎧' },
    },
    {
      status: 'dnd',
      activity: { type: ActivityType.Playing, name: '⚔ 400+ Slash Commands | Active', icon: '🎮' },
    },
    {
      status: 'online',
      activity: { type: ActivityType.Streaming, name: '💎 Premium Discord Bot', url: streamUrl() },
    },
    {
      status: 'online',
      activity: { type: ActivityType.Competing, name: '🏆 Top Tier Performance', icon: '🔥' },
    },
    {
      status: 'idle',
      activity: { type: ActivityType.Watching, name: '📺 Phantom World RP', icon: '🌃' },
    },
    {
      status: 'online',
      activity: { type: ActivityType.Listening, name: '🎶 High Quality Music', icon: '🔊' },
    },
    {
      status: 'dnd',
      activity: { type: ActivityType.Playing, name: '✨ Developed by Phantom World', icon: '🛠' },
    },
    {
      status: 'online',
      activity: { type: ActivityType.Streaming, name: '🔴 Live & Ready!', url: streamUrl() },
    },
  ];
}

function startPhantomPresence(client) {
  console.log('[Phantom presence] Starting presence rotation...');
  let index = 0;
  // Faster rotation to make it feel more "active" and "rainbow-like" in transition
  const intervalMs = Number(process.env.PRESENCE_INTERVAL_MS || 15000); 

  const apply = () => {
    const pool = phantomRotations(client);
    const pick = pool[index % pool.length];
    index += 1;

    client.user
      .setPresence({
        status: pick.status,
        activities: [pick.activity],
      });
    console.log(`[Phantom presence] Set presence to: ${pick.activity.name}`);
  };

  apply();
  return setInterval(apply, intervalMs);
}

async function setPhantomBotProfile(client) {
  const description =
    '⚡ Phantom World ALL-IN-ONE — music, moderation, economy, tickets & FiveM tools. ' +
    '400+ slash commands. Developed by Phantom World · discord.gg/zZSvmdUx';

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
