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

async function lockdownGuild(client, guild, reason, options = {}) {
  const isDrill = Boolean(options.drill);
  const minutes = options.minutes || envInt('GUARDIAN_LOCKDOWN_MINUTES', 30);
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
    title: isDrill ? 'DRILL — LOCKDOWN ENGAGED' : 'LOCKDOWN ENGAGED',
    description: isDrill
      ? [
          `# 🚨☠️ WARNING — SERVER LOCKDOWN IN PROGRESS ☠️🚨`,
          `## ☄️ THIS IS A SCHEDULED SECURITY DRILL ☄️`,
          '',
          `🌍 **${guild.name}** is under a **full communication lockdown** to validate Rex Guardian.`,
          '',
          '💣 Messaging, reactions, and voice connects are restricted for `@everyone`',
          '🛡️ Staff with override permissions may still operate',
          '🧪 **This is not a real attack** — systems are being tested on purpose',
          '',
          `📋 **Drill reason:** ${reason}`,
          `⏱️ **Hold time:** ~${minutes} minute(s) (or until \`/guardian unlock\`)`,
          '',
          '☢️ **END-OF-THE-WORLD ENERGY. DRILL PROTOCOLS ACTIVE.** ☢️',
        ].join('\n')
      : `**${guild.name}** is under automatic lockdown.\n**Reason:** ${reason}\n**Duration:** ~${minutes} minutes (or until \`/guardian unlock\`).`,
    fields: [
      { name: 'Channels locked', value: String(locked), inline: true },
      { name: 'Mode', value: isDrill ? 'DRILL / TEST' : 'LIVE', inline: true },
      { name: 'Guild', value: `${guild.name} (\`${guild.id}\`)`, inline: false },
    ],
    pingOwner: true,
  });

  return locked;
}

async function unlockGuild(client, guild, options = {}) {
  const isDrill = Boolean(options.drill);
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
    level: isDrill ? 'medium' : 'medium',
    title: isDrill ? 'DRILL COMPLETE — Lockdown lifted' : 'Lockdown lifted',
    description: isDrill
      ? [
          `# ✅ SECURITY DRILL COMPLETE`,
          '',
          `The **test lockdown** on **${guild.name}** has ended.`,
          `**${unlocked}** channels were restored to normal \`@everyone\` permissions.`,
          '',
          'Thank you for your patience. Rex Guardian lockout systems are verified and ready.',
          '_This was a drill — no hostile activity was detected._',
        ].join('\n')
      : `**${guild.name}** lockdown cleared (${unlocked} channels restored to default @everyone overwrites).`,
    pingOwner: true,
  });
  return unlocked;
}

/**
 * Professional server-wide lockdown drill: warn everyone, lock, hold, unlock.
 */
async function runLockdownDrill(client, guild, {
  holdSeconds = 45,
  announceChannelId = null,
} = {}) {
  const { EmbedBuilder } = require('discord.js');
  const { resolveAlertsTarget, ownerIds } = require('./guardian-alerts');
  const hold = Math.max(15, Number(holdSeconds) || 45);

  const warningEmbed = new EmbedBuilder()
    .setColor(0x7f1d1d)
    .setTitle('🚨☠️⚠️ WARNING — SERVER LOCKDOWN IN PROGRESS ⚠️☠️🚨')
    .setDescription(
      [
        '# 🌑 THIS IS NOT A DRILL… WAIT — IT IS A DRILL 🌑',
        '## ☄️ SECURITY LOCKOUT SYSTEM TEST ☄️',
        '',
        '🛑🛑🛑 **STOP. READ THIS. NOW.** 🛑🛑🛑',
        '',
        `🌍 **${guild.name}** is entering **FULL SERVER LOCKDOWN**.`,
        '📡 Communications are being sealed. Voice gates are closing. Chat is going dark.',
        '',
        '### 🔥 WHAT IS HAPPENING',
        '💣 Messaging · reactions · voice connects → **RESTRICTED**',
        '🛡️ Staff overrides may still operate',
        '🧪 **THIS IS A CONTROLLED SECURITY DRILL** — not a real raid/nuke',
        '',
        '### 👤 WHAT YOU SHOULD DO',
        '😮‍💨 Stay calm. Do not panic.',
        '🙅 Do not try to bypass lockdown.',
        '⏳ Stand by — access returns when the drill ends.',
        '',
        `⏱️ _Hold window: ~**${hold} seconds**_`,
        '🦖 _Issued by **Rex Guardian** · Phantom World Security_',
        '',
        '### 📢 NOTICE',
        '🚨 If this were real, the same lockdown would protect the city.',
        '✅ Today it is a **TEST** of that shield.',
        '',
        '☢️ **END-OF-THE-WORLD VIBES. DRILL PROTOCOLS. REMAIN ONLINE.** ☢️',
      ].join('\n'),
    )
    .setFooter({ text: '🧪 DRILL ONLY · Not a real incident · Rex Guardian' })
    .setTimestamp();

  const owners = ownerIds();
  const announceIds = [
    announceChannelId,
    process.env.GUARDIAN_DRILL_ANNOUNCE_CHANNEL_ID,
    process.env.DISCORD_ALERTS_CHANNEL_ID,
  ].filter(Boolean);

  const announced = new Set();
  for (const id of announceIds) {
    try {
      const ch = await client.channels.fetch(id);
      if (!ch?.isTextBased?.()) continue;
      // Prefer parent channel for @everyone (threads often can't ping as well)
      const target = ch.isThread?.() ? ch.parent || ch : ch;
      if (announced.has(target.id)) continue;
      announced.add(target.id);
      await target.send({
        content: [
          '@everyone',
          '',
          '🚨🚨🚨 **WARNING WARNING WARNING** 🚨🚨🚨',
          '☠️ **SERVER LOCKDOWN IN PROGRESS** ☠️',
          '☄️🌍💥 **THIS IS A SECURITY DRILL / TEST OF THE LOCKOUT SYSTEM** 💥🌍☄️',
          '☢️ Stay calm. Do not panic. This is **NOT** a real attack. ☢️',
        ].join('\n'),
        embeds: [warningEmbed],
        allowedMentions: { parse: ['everyone'], users: owners },
      });
    } catch (err) {
      console.warn('[guardian] drill announce failed:', err.message);
    }
  }

  // Also post to alerts thread
  try {
    const alerts = await resolveAlertsTarget(client);
    if (alerts && !announced.has(alerts.id)) {
      await alerts.send({
        content: owners.map((id) => `<@${id}>`).join(' '),
        embeds: [warningEmbed],
        allowedMentions: { users: owners },
      });
    }
  } catch (_) {}

  const locked = await lockdownGuild(client, guild, 'Scheduled security drill / lockout system test', {
    drill: true,
    minutes: Math.max(1, Math.ceil(hold / 60)),
  });

  await new Promise((r) => setTimeout(r, hold * 1000));

  const unlocked = await unlockGuild(client, guild, { drill: true });

  // All-clear in announce channels
  const clearEmbed = new EmbedBuilder()
    .setColor(0x16a34a)
    .setTitle('✅🌤️ ALL CLEAR — SECURITY DRILL COMPLETE 🌤️✅')
    .setDescription(
      [
        '# 🌈 THE SKY CLEARS',
        '',
        `🎉 The lockdown drill on **${guild.name}** is finished.`,
        `🔓 Channels restored: **${unlocked}**`,
        '💚 Thank you for cooperating. Normal operations have resumed.',
        '',
        '🦖🛡 _Rex Guardian lockout systems tested successfully._',
        '📢 _This was a drill — no hostile activity was detected._',
      ].join('\n'),
    )
    .setFooter({ text: '✅ DRILL COMPLETE · Systems normal' })
    .setTimestamp();

  for (const id of announced) {
    try {
      const ch = await client.channels.fetch(id);
      if (!ch?.isTextBased?.()) continue;
      await ch.send({ embeds: [clearEmbed] });
    } catch (_) {}
  }

  return { locked, unlocked, holdSeconds: hold };
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
  runLockdownDrill,
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
