/**
 * Unified security / infra alerts → one Discord channel (or Rex Alerts thread).
 */
const {
  EmbedBuilder,
  ActionRowBuilder,
  ButtonBuilder,
  ButtonStyle,
} = require('discord.js');

function ownerIds() {
  return [...new Set([
    process.env.OWNER_ID,
    process.env.DISCORD_OWNER_USER_ID,
  ].filter(Boolean))];
}

function alertsChannelId() {
  return (
    process.env.SECURITY_ALERTS_CHANNEL_ID ||
    process.env.DISCORD_ALERTS_CHANNEL_ID ||
    process.env.LEAVE_FEEDBACK_CHANNEL_ID ||
    ''
  );
}

function alertsThreadId() {
  return process.env.DISCORD_ALERTS_THREAD_ID || process.env.SECURITY_ALERTS_THREAD_ID || '';
}

function severityColor(level) {
  switch (String(level || '').toLowerCase()) {
    case 'critical':
      return 0x7f1d1d;
    case 'high':
      return 0xef4444;
    case 'medium':
      return 0xf59e0b;
    case 'low':
      return 0x3b82f6;
    default:
      return 0x64748b;
  }
}

/**
 * Resolve the destination text channel / thread for all guardian alerts.
 * @param {import('discord.js').Client} client
 */
async function resolveAlertsTarget(client) {
  const threadId = alertsThreadId();
  const channelId = alertsChannelId();

  if (threadId) {
    try {
      const thread = await client.channels.fetch(threadId);
      if (thread) return thread;
    } catch (_) {}
  }

  if (!channelId) return null;

  try {
    const channel = await client.channels.fetch(channelId);
    if (!channel) return null;

    // Prefer existing Rex Alerts thread under the channel when configured by name
    const threadName = process.env.DISCORD_ALERTS_THREAD_NAME || '🚨 Rex Alerts';
    if (channel.threads?.fetchActive) {
      try {
        const active = await channel.threads.fetchActive();
        const hit =
          active.threads.find((t) => t.id === threadId) ||
          active.threads.find((t) => t.name === threadName);
        if (hit) return hit;
      } catch (_) {}
    }
    return channel;
  } catch (err) {
    console.warn('[guardian-alerts] resolve failed:', err.message);
    return null;
  }
}

/**
 * @param {import('discord.js').Client} client
 * @param {{
 *   title: string,
 *   description?: string,
 *   fields?: { name: string, value: string, inline?: boolean }[],
 *   level?: 'critical'|'high'|'medium'|'low'|'info',
 *   pingOwner?: boolean,
 *   footer?: string,
 * }} opts
 */
async function postGuardianAlert(client, opts) {
  const target = await resolveAlertsTarget(client);
  const level = opts.level || 'medium';
  const owners = ownerIds();
  const ping =
    opts.pingOwner !== false && (level === 'critical' || level === 'high')
      ? owners.map((id) => `<@${id}>`).join(' ')
      : '';

  const embed = new EmbedBuilder()
    .setColor(severityColor(level))
    .setTitle(`🛡 ${opts.title}`)
    .setDescription((opts.description || '').slice(0, 4000) || '—')
    .setTimestamp()
    .setFooter({ text: opts.footer || `Rex Guardian · ${level.toUpperCase()}` });

  if (opts.fields?.length) {
    embed.addFields(
      opts.fields.slice(0, 25).map((f) => ({
        name: String(f.name).slice(0, 256),
        value: String(f.value).slice(0, 1024),
        inline: Boolean(f.inline),
      })),
    );
  }

  const payload = {
    content: ping || undefined,
    embeds: [embed],
    allowedMentions: { users: owners },
  };

  if (!target) {
    console.warn('[guardian-alerts] no alerts channel configured —', opts.title);
    return { ok: false, reason: 'no_target' };
  }

  try {
    const msg = await target.send(payload);
    return { ok: true, messageId: msg.id, channelId: target.id };
  } catch (err) {
    console.warn('[guardian-alerts] send failed:', err.message);
    return { ok: false, error: err.message };
  }
}

module.exports = {
  ownerIds,
  alertsChannelId,
  alertsThreadId,
  resolveAlertsTarget,
  postGuardianAlert,
};
