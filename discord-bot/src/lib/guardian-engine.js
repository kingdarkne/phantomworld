/**
 * Rex Guardian engine — rate windows, punish nukers/raiders, server lockdown.
 */
const {
  AuditLogEvent,
  PermissionFlagsBits,
  ChannelType,
} = require('discord.js');
const { postGuardianAlert, ownerIds } = require('./guardian-alerts');

/** @type {Map<string, { ts: number[] }>} */
const windows = new Map();

/** @type {Map<string, number>} guildId -> lockdown until ms */
const lockdownUntil = new Map();

/** @type {Map<string, any>} last infra snapshot */
const infraState = new Map();

function envInt(name, fallback) {
  const n = Number(process.env[name]);
  return Number.isFinite(n) && n > 0 ? n : fallback;
}

function envList(name) {
  return String(process.env[name] || '')
    .split(/[,\s]+/)
    .map((s) => s.trim())
    .filter(Boolean);
}

function guardianEnabled() {
  const raw = process.env.GUARDIAN_ENABLED;
  if (raw == null || raw === '') return true;
  return !['0', 'false', 'off', 'no'].includes(String(raw).toLowerCase());
}

function whitelistIds(client) {
  const ids = new Set([
    ...ownerIds(),
    ...envList('SECURITY_WHITELIST_IDS'),
    ...envList('GUARDIAN_WHITELIST_IDS'),
  ]);
  if (client?.user?.id) ids.add(client.user.id);
  return ids;
}

function trustedRoleIds() {
  return new Set([...envList('SECURITY_TRUSTED_ROLE_IDS'), ...envList('GUARDIAN_TRUSTED_ROLE_IDS')]);
}

function isWhitelisted(client, userId, member) {
  if (!userId) return false;
  if (whitelistIds(client).has(userId)) return true;
  const roles = trustedRoleIds();
  if (roles.size && member?.roles?.cache) {
    for (const id of roles) {
      if (member.roles.cache.has(id)) return true;
    }
  }
  return false;
}

/**
 * Sliding window counter.
 * @returns {number} count in window after push
 */
function hit(key, windowMs) {
  const now = Date.now();
  const entry = windows.get(key) || { ts: [] };
  entry.ts = entry.ts.filter((t) => now - t < windowMs);
  entry.ts.push(now);
  windows.set(key, entry);
  return entry.ts.length;
}

function windowCount(key, windowMs) {
  const now = Date.now();
  const entry = windows.get(key);
  if (!entry) return 0;
  entry.ts = entry.ts.filter((t) => now - t < windowMs);
  windows.set(key, entry);
  return entry.ts.length;
}

async function fetchExecutor(guild, type, targetId) {
  try {
    if (!guild.members.me?.permissions?.has(PermissionFlagsBits.ViewAuditLog)) {
      return null;
    }
    const logs = await guild.fetchAuditLogs({ type, limit: 6 });
    const now = Date.now();
    for (const entry of logs.entries.values()) {
      if (now - entry.createdTimestamp > 15000) continue;
      if (targetId && entry.target?.id && entry.target.id !== targetId) continue;
      return {
        id: entry.executor?.id,
        tag: entry.executor?.tag || entry.executor?.username,
        reason: entry.reason || null,
        entry,
      };
    }
    // fallback: most recent matching type
    const first = logs.entries.first();
    if (first && Date.now() - first.createdTimestamp < 20000) {
      return {
        id: first.executor?.id,
        tag: first.executor?.tag || first.executor?.username,
        reason: first.reason || null,
        entry: first,
      };
    }
  } catch (err) {
    console.warn('[guardian] audit fetch failed:', err.message);
  }
  return null;
}

async function lockdownGuild(client, guild, reason) {
  const minutes = envInt('GUARDIAN_LOCKDOWN_MINUTES', 30);
  lockdownUntil.set(guild.id, Date.now() + minutes * 60_000);

  let locked = 0;
  for (const ch of guild.channels.cache.values()) {
    if (![ChannelType.GuildText, ChannelType.GuildAnnouncement, ChannelType.GuildVoice, ChannelType.GuildForum].includes(ch.type)) {
      continue;
    }
    try {
      await ch.permissionOverwrites.edit(guild.id, {
        SendMessages: false,
        AddReactions: false,
        CreatePublicThreads: false,
        CreatePrivateThreads: false,
        SendMessagesInThreads: false,
        Connect: ch.type === ChannelType.GuildVoice ? false : undefined,
      });
      locked += 1;
    } catch (_) {}
  }

  await postGuardianAlert(client, {
    level: 'critical',
    title: 'LOCKDOWN ENGAGED',
    description: `**${guild.name}** is under automatic lockdown.\n**Reason:** ${reason}\n**Duration:** ~${minutes} minutes (or until \`/guardian unlock\`).`,
    fields: [
      { name: 'Channels locked', value: String(locked), inline: true },
      { name: 'Guild', value: `${guild.name} (\`${guild.id}\`)`, inline: true },
    ],
    pingOwner: true,
  });

  return locked;
}

async function unlockGuild(client, guild) {
  lockdownUntil.delete(guild.id);
  let unlocked = 0;
  for (const ch of guild.channels.cache.values()) {
    if (![ChannelType.GuildText, ChannelType.GuildAnnouncement, ChannelType.GuildVoice, ChannelType.GuildForum].includes(ch.type)) {
      continue;
    }
    try {
      await ch.permissionOverwrites.edit(guild.id, {
        SendMessages: null,
        AddReactions: null,
        CreatePublicThreads: null,
        CreatePrivateThreads: null,
        SendMessagesInThreads: null,
        Connect: null,
      });
      unlocked += 1;
    } catch (_) {}
  }
  await postGuardianAlert(client, {
    level: 'medium',
    title: 'Lockdown lifted',
    description: `**${guild.name}** lockdown cleared (${unlocked} channels restored to default @everyone overwrites).`,
    pingOwner: true,
  });
  return unlocked;
}

function isLocked(guildId) {
  const until = lockdownUntil.get(guildId);
  if (!until) return false;
  if (Date.now() > until) {
    lockdownUntil.delete(guildId);
    return false;
  }
  return true;
}

/**
 * Ban (preferred) or kick a nuker/raider and strip roles first.
 */
async function punish(client, guild, userId, reason, { ban = true } = {}) {
  if (!userId || isWhitelisted(client, userId)) {
    return { skipped: true, reason: 'whitelist' };
  }

  let member = guild.members.cache.get(userId);
  if (!member) {
    try {
      member = await guild.members.fetch(userId);
    } catch (_) {}
  }

  // Never punish the bot or higher roles we can't touch
  if (userId === client.user.id) return { skipped: true, reason: 'self' };
  if (member && guild.members.me && member.roles.highest.position >= guild.members.me.roles.highest.position) {
    await postGuardianAlert(client, {
      level: 'critical',
      title: 'Cannot punish — role hierarchy',
      description: `Suspect <@${userId}> (\`${userId}\`) is at/above Rex’s highest role.\n**Move Rex’s role to the top**, then re-run punishment.\n**Reason:** ${reason}`,
      pingOwner: true,
    });
    return { skipped: true, reason: 'hierarchy' };
  }

  try {
    if (member) {
      const removable = member.roles.cache.filter((r) => r.id !== guild.id && r.editable);
      if (removable.size) await member.roles.remove(removable, `[Guardian] ${reason}`).catch(() => {});
    }
  } catch (_) {}

  try {
    if (ban && guild.members.me?.permissions?.has(PermissionFlagsBits.BanMembers)) {
      await guild.members.ban(userId, {
        deleteMessageSeconds: envInt('GUARDIAN_BAN_DELETE_SECONDS', 86400),
        reason: `[Guardian] ${reason}`.slice(0, 512),
      });
      return { ok: true, action: 'ban' };
    }
  } catch (err) {
    console.warn('[guardian] ban failed:', err.message);
  }

  try {
    if (member && guild.members.me?.permissions?.has(PermissionFlagsBits.KickMembers)) {
      await member.kick(`[Guardian] ${reason}`.slice(0, 512));
      return { ok: true, action: 'kick' };
    }
  } catch (err) {
    console.warn('[guardian] kick failed:', err.message);
  }

  return { ok: false, reason: 'no_perms' };
}

/**
 * Record a dangerous action; auto-punish + lockdown when thresholds trip.
 */
async function noteAction(client, guild, {
  action,
  executorId,
  executorTag,
  targetLabel,
  detail,
  threshold,
  windowMs,
  lockdown = true,
  punishBan = true,
}) {
  if (!guardianEnabled() || !guild) return;
  if (executorId && isWhitelisted(client, executorId)) {
    // Still log quietly at low level for visibility? skip to reduce noise
    return;
  }

  const key = `${guild.id}:${action}:${executorId || 'unknown'}`;
  const count = hit(key, windowMs);
  const limit = threshold;

  await postGuardianAlert(client, {
    level: count >= limit ? 'critical' : count >= Math.max(1, limit - 1) ? 'high' : 'medium',
    title: `${action} detected`,
    description: detail || `Suspicious **${action}** in **${guild.name}**.`,
    fields: [
      { name: 'Executor', value: executorId ? `<@${executorId}> (\`${executorId}\`)\n${executorTag || ''}` : 'Unknown (check Audit Log)', inline: true },
      { name: 'Target', value: String(targetLabel || '—').slice(0, 200), inline: true },
      { name: 'Window', value: `${count}/${limit} in ${Math.round(windowMs / 1000)}s`, inline: true },
    ],
    pingOwner: count >= limit,
  });

  if (count < limit) return;

  const punishReason = `Anti-nuke: ${action} x${count}`;
  const result = await punish(client, guild, executorId, punishReason, { ban: punishBan });

  await postGuardianAlert(client, {
    level: 'critical',
    title: `Punished for ${action}`,
    description: result.ok
      ? `Applied **${result.action}** to <@${executorId}> for **${action}** spam.`
      : `Threshold hit but punishment failed: \`${result.reason || result.error || 'unknown'}\`.`,
    fields: [
      { name: 'Executor', value: `<@${executorId}>`, inline: true },
      { name: 'Count', value: `${count}/${limit}`, inline: true },
    ],
    pingOwner: true,
  });

  if (lockdown && !isLocked(guild.id)) {
    await lockdownGuild(client, guild, punishReason);
  }
}

/** Threshold presets — “maximum” defaults, overridable via env */
const THRESHOLDS = {
  channelDelete: { threshold: envInt('GUARDIAN_CH_DELETE', 2), windowMs: envInt('GUARDIAN_CH_DELETE_MS', 20000) },
  channelCreate: { threshold: envInt('GUARDIAN_CH_CREATE', 3), windowMs: envInt('GUARDIAN_CH_CREATE_MS', 20000) },
  roleDelete: { threshold: envInt('GUARDIAN_ROLE_DELETE', 2), windowMs: envInt('GUARDIAN_ROLE_DELETE_MS', 20000) },
  roleCreate: { threshold: envInt('GUARDIAN_ROLE_CREATE', 3), windowMs: envInt('GUARDIAN_ROLE_CREATE_MS', 20000) },
  memberBan: { threshold: envInt('GUARDIAN_BAN', 3), windowMs: envInt('GUARDIAN_BAN_MS', 25000) },
  memberKick: { threshold: envInt('GUARDIAN_KICK', 3), windowMs: envInt('GUARDIAN_KICK_MS', 25000) },
  webhookCreate: { threshold: envInt('GUARDIAN_WEBHOOK', 2), windowMs: envInt('GUARDIAN_WEBHOOK_MS', 30000) },
  emojiDelete: { threshold: envInt('GUARDIAN_EMOJI', 3), windowMs: envInt('GUARDIAN_EMOJI_MS', 30000) },
  massJoin: { threshold: envInt('GUARDIAN_JOIN', 6), windowMs: envInt('GUARDIAN_JOIN_MS', 12000) },
};

const DANGEROUS_PERMS = [
  PermissionFlagsBits.Administrator,
  PermissionFlagsBits.BanMembers,
  PermissionFlagsBits.KickMembers,
  PermissionFlagsBits.ManageGuild,
  PermissionFlagsBits.ManageRoles,
  PermissionFlagsBits.ManageChannels,
  PermissionFlagsBits.ManageWebhooks,
  PermissionFlagsBits.MentionEveryone,
];

module.exports = {
  AuditLogEvent,
  guardianEnabled,
  isWhitelisted,
  whitelistIds,
  hit,
  windowCount,
  fetchExecutor,
  lockdownGuild,
  unlockGuild,
  isLocked,
  punish,
  noteAction,
  THRESHOLDS,
  DANGEROUS_PERMS,
  lockdownUntil,
  infraState,
  envInt,
  envList,
};
