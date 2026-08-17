/**
 * Rex Guardian engine — rate windows, punish nukers/raiders, server lockdown.
 */
const {
  AuditLogEvent,
  PermissionFlagsBits,
  ChannelType,
} = require('discord.js');
const fs = require('fs');
const path = require('path');
const { postGuardianAlert, ownerIds } = require('./guardian-alerts');

/** @type {Map<string, { ts: number[] }>} */
const windows = new Map();

/** @type {Map<string, number>} guildId -> lockdown until ms */
const lockdownUntil = new Map();

/** @type {Map<string, { safeZoneId: string, created: boolean, roleSnapshots?: Record<string, string[]> }>} */
const lockdownState = new Map();

/** @type {Map<string, any>} last infra snapshot */
const infraState = new Map();

const STATE_FILE = path.join(process.cwd(), 'data', 'guardian-lockdown-state.json');

function loadPersistedLockdownState() {
  try {
    const raw = JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
    for (const [guildId, state] of Object.entries(raw || {})) {
      lockdownState.set(guildId, state);
      if (state.until) lockdownUntil.set(guildId, state.until);
    }
  } catch (_) {}
}

function persistLockdownState() {
  try {
    fs.mkdirSync(path.dirname(STATE_FILE), { recursive: true });
    const out = {};
    for (const [guildId, state] of lockdownState.entries()) {
      out[guildId] = {
        ...state,
        until: lockdownUntil.get(guildId) || null,
      };
    }
    fs.writeFileSync(STATE_FILE, JSON.stringify(out, null, 2));
  } catch (err) {
    console.warn('[guardian] persist lockdown state failed:', err.message);
  }
}

loadPersistedLockdownState();

const SAFE_ZONE_BASENAME = (process.env.GUARDIAN_SAFE_ZONE_NAME || 'safe-zone').toLowerCase();

function isSafeZoneChannel(ch) {
  if (!ch?.name) return false;
  const n = String(ch.name).toLowerCase().replace(/[^a-z0-9-]/g, '');
  return n === 'safezone' || n === 'safe-zone' || n.includes('safezone') || n.includes('safe-zone');
}

async function ensureSafeZone(guild, me) {
  await guild.channels.fetch().catch(() => {});
  const existing = guild.channels.cache.find(
    (c) => c.type === ChannelType.GuildText && isSafeZoneChannel(c),
  );
  if (existing) return { channel: existing, created: false };

  const channel = await guild.channels.create({
    name: '⚠️┊safe-zone',
    type: ChannelType.GuildText,
    topic: 'Rex Guardian emergency safe zone — official lockdown notices only',
    reason: 'Rex Guardian lockdown — create safe zone',
    permissionOverwrites: [
      {
        id: guild.id,
        allow: [PermissionFlagsBits.ViewChannel, PermissionFlagsBits.ReadMessageHistory],
        deny: [
          PermissionFlagsBits.SendMessages,
          PermissionFlagsBits.AddReactions,
          PermissionFlagsBits.CreatePublicThreads,
          PermissionFlagsBits.CreatePrivateThreads,
          PermissionFlagsBits.SendMessagesInThreads,
        ],
      },
      ...(me
        ? [{
            id: me.id,
            allow: [
              PermissionFlagsBits.ViewChannel,
              PermissionFlagsBits.SendMessages,
              PermissionFlagsBits.EmbedLinks,
              PermissionFlagsBits.MentionEveryone,
            ],
          }]
        : []),
    ],
  });
  return { channel, created: true };
}

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


/**
 * Snapshot member roles then strip them (quarantine). Skips owners + Rex.
 * @returns {Record<string, string[]>}
 */
async function snapshotAndQuarantineRoles(client, guild, { reason = 'Guardian lockdown quarantine' } = {}) {
  const me = guild.members.me || (await guild.members.fetchMe().catch(() => null));
  const owners = new Set(ownerIds());
  if (client?.user?.id) owners.add(client.user.id);

  try {
    await guild.members.fetch();
  } catch (_) {}

  /** @type {Record<string, string[]>} */
  const snapshots = {};
  let strippedMembers = 0;

  for (const member of guild.members.cache.values()) {
    if (owners.has(member.id)) continue;
    if (member.user.bot && member.id === client.user.id) continue;

    const roleIds = member.roles.cache
      .filter((r) => r.id !== guild.id)
      .map((r) => r.id);
    if (!roleIds.length) continue;

    snapshots[member.id] = roleIds;

    const removable = member.roles.cache.filter(
      (r) =>
        r.id !== guild.id &&
        r.editable &&
        me &&
        r.position < me.roles.highest.position,
    );
    if (!removable.size) continue;
    try {
      await member.roles.remove(removable, `[Guardian] ${reason}`.slice(0, 512));
      strippedMembers += 1;
    } catch (err) {
      console.warn('[guardian] role strip failed', member.id, err.message);
    }
  }

  console.log(`[guardian] quarantined roles for ${strippedMembers} members (${Object.keys(snapshots).length} snapshots)`);
  return snapshots;
}

/**
 * Restore roles from a prior quarantine snapshot.
 */
async function restoreQuarantineRoles(guild, snapshots = {}) {
  let restoredMembers = 0;
  let restoredRoles = 0;
  const me = guild.members.me || (await guild.members.fetchMe().catch(() => null));

  for (const [userId, roleIds] of Object.entries(snapshots || {})) {
    if (!roleIds?.length) continue;
    let member = guild.members.cache.get(userId);
    if (!member) {
      try {
        member = await guild.members.fetch(userId);
      } catch (_) {
        continue;
      }
    }

    const toAdd = [];
    for (const roleId of roleIds) {
      const role = guild.roles.cache.get(roleId);
      if (!role) continue;
      if (member.roles.cache.has(roleId)) continue;
      if (me && role.position >= me.roles.highest.position && !role.editable) continue;
      toAdd.push(role);
    }
    if (!toAdd.length) continue;
    try {
      await member.roles.add(toAdd, 'Rex Guardian unlock — restore quarantine roles');
      restoredMembers += 1;
      restoredRoles += toAdd.length;
    } catch (err) {
      console.warn('[guardian] role restore failed', userId, err.message);
    }
  }

  console.log(`[guardian] restored roles for ${restoredMembers} members (${restoredRoles} assigns)`);
  return { restoredMembers, restoredRoles };
}

async function lockdownGuild(client, guild, reason, options = {}) {
  const isDrill = Boolean(options.drill);
  const minutes = options.minutes || envInt('GUARDIAN_LOCKDOWN_MINUTES', 30);
  lockdownUntil.set(guild.id, Date.now() + minutes * 60_000);

  const me = guild.members.me || (await guild.members.fetchMe().catch(() => null));
  let safeZone = null;
  let createdSafe = false;
  try {
    const ensured = await ensureSafeZone(guild, me);
    safeZone = ensured.channel;
    createdSafe = ensured.created;
  } catch (err) {
    console.warn('[guardian] safe-zone create/find failed:', err.message);
  }

  let locked = 0;
  let hidden = 0;
  const hideTypes = [
    ChannelType.GuildText,
    ChannelType.GuildAnnouncement,
    ChannelType.GuildVoice,
    ChannelType.GuildForum,
    ChannelType.GuildStageVoice,
    ChannelType.GuildCategory,
  ];

  const hideJobs = [];
  for (const ch of guild.channels.cache.values()) {
    if (!hideTypes.includes(ch.type)) continue;
    if (safeZone && ch.id === safeZone.id) continue;
    hideJobs.push(
      ch.permissionOverwrites
        .edit(guild.id, {
          ViewChannel: false,
          SendMessages: false,
          AddReactions: false,
          CreatePublicThreads: false,
          CreatePrivateThreads: false,
          SendMessagesInThreads: false,
          Connect: false,
          Speak: false,
        })
        .then(() => {
          hidden += 1;
          locked += 1;
        })
        .catch(() => {}),
    );
  }
  // Parallel batches so full hide finishes in ~1s instead of 20–30s
  const batchSize = envInt('GUARDIAN_LOCK_BATCH', 15);
  for (let i = 0; i < hideJobs.length; i += batchSize) {
    await Promise.all(hideJobs.slice(i, i + batchSize));
  }

  if (safeZone) {
    try {
      await safeZone.permissionOverwrites.edit(guild.id, {
        ViewChannel: true,
        ReadMessageHistory: true,
        SendMessages: false,
        AddReactions: false,
        CreatePublicThreads: false,
        CreatePrivateThreads: false,
        SendMessagesInThreads: false,
      });
      if (me) {
        await safeZone.permissionOverwrites.edit(me.id, {
          ViewChannel: true,
          SendMessages: true,
          EmbedLinks: true,
          MentionEveryone: true,
        });
      }
    } catch (err) {
      console.warn('[guardian] safe-zone perms failed:', err.message);
    }

    lockdownState.set(guild.id, {
      ...(lockdownState.get(guild.id) || {}),
      safeZoneId: safeZone.id,
      created: createdSafe,
      roleSnapshots: lockdownState.get(guild.id)?.roleSnapshots || {},
    });
    persistLockdownState();

    const { EmbedBuilder } = require('discord.js');
    const warnEmbed = new EmbedBuilder()
      .setColor(0x7f1d1d)
      .setTitle(isDrill
        ? '🚨⚠️ WARNING — SERVER LOCKDOWN (DRILL) ⚠️🚨'
        : '🚨☠️ WARNING — SERVER LOCKDOWN IN PROGRESS ☠️🚨')
      .setDescription([
        isDrill ? '# 🧪 SECURITY DRILL' : '# ⛔ NOT A DRILL',
        isDrill ? '## Lockout system test' : '## ☄️ FULL SERVER LOCKDOWN',
        '',
        `🌍 **${guild.name}** is locked by **Rex Guardian**.`,
        '',
        '### 🔒 What you can see',
        '• **This channel only** — safe zone',
        '• All other channels are **hidden** until unlock',
        '',
        `📋 **Reason:** ${reason}`,
        `⏱️ **Hold:** ~${minutes} minute(s) (or until \`/guardian unlock\`)`,
        '',
        isDrill
          ? '🧪 _This is a controlled test of the lockout system._'
          : '👮 Staff are responding. Stay here. Do not panic.',
      ].join('\n'))
      .setFooter({ text: isDrill ? 'DRILL · Rex Guardian safe zone' : 'LIVE LOCKDOWN · Rex Guardian safe zone' })
      .setTimestamp();

    // Default: no @everyone (Co-Owner app-nuke / live lock). Drills may opt in.
    const pingEveryone = options.pingEveryone === true;
    try {
      await safeZone.send({
        content: isDrill
          ? (pingEveryone
            ? '@everyone\n\n🚨 **WARNING — LOCKDOWN DRILL** 🚨\nYou are in the **SAFE ZONE**. All other channels are hidden.'
            : '🚨 **WARNING — LOCKDOWN DRILL** 🚨\nYou are in the **SAFE ZONE**. All other channels are hidden.')
          : (pingEveryone
            ? '@everyone\n\n🚨🚨🚨 **WARNING — NOT A DRILL — SERVER LOCKDOWN** 🚨🚨🚨\n☠️ You are in the **SAFE ZONE**. All other channels are **HIDDEN**. ☠️'
            : '🚨🚨🚨 **WARNING — NOT A DRILL — SERVER LOCKDOWN** 🚨🚨🚨\n☠️ You are in the **SAFE ZONE**. All other channels are **HIDDEN**. ☠️'),
        embeds: [warnEmbed],
        allowedMentions: pingEveryone ? { parse: ['everyone'] } : { parse: [] },
      });
    } catch (err) {
      console.warn('[guardian] safe-zone warn failed:', err.message);
    }
  }

  // Optional: strip member roles during lockdown and restore on unlock
  let roleSnapshots = {};
  const shouldStrip =
    options.stripRoles === true ||
    (!options.drill && envInt('GUARDIAN_STRIP_ROLES_ON_LOCKDOWN', 0) === 1);
  if (shouldStrip) {
    roleSnapshots = await snapshotAndQuarantineRoles(client, guild, {
      reason: `lockdown quarantine — ${reason}`,
    });
  }

  const prev = lockdownState.get(guild.id) || {};
  lockdownState.set(guild.id, {
    ...prev,
    safeZoneId: safeZone?.id || prev.safeZoneId || null,
    created: safeZone ? (prev.created ?? createdSafe) : prev.created,
    roleSnapshots: Object.keys(roleSnapshots).length
      ? roleSnapshots
      : prev.roleSnapshots || {},
    until: lockdownUntil.get(guild.id) || null,
  });
  persistLockdownState();

  await postGuardianAlert(client, {
    level: 'critical',
    title: isDrill ? 'DRILL — LOCKDOWN + SAFE ZONE' : 'LOCKDOWN + SAFE ZONE ENGAGED',
    description: [
      `# ${isDrill ? 'DRILL' : '⛔ FULL'} LOCKDOWN`,
      'All channels **hidden**. Only **safe-zone** is visible.',
      `**Reason:** ${reason}`,
      `**Duration:** ~${minutes} minutes (or \`/guardian unlock\`).`,
      shouldStrip
        ? `**Roles:** quarantined for **${Object.keys(roleSnapshots).length}** members (restored on unlock).`
        : '',
    ]
      .filter(Boolean)
      .join('\n'),
    fields: [
      { name: 'Channels hidden', value: String(hidden), inline: true },
      { name: 'Safe zone', value: safeZone ? `<#${safeZone.id}>` : '_failed_', inline: true },
      { name: 'Mode', value: isDrill ? 'DRILL / TEST' : 'LIVE', inline: true },
    ],
    pingOwner: true,
  });

  return {
    locked,
    hidden,
    safeZoneId: safeZone?.id || null,
    rolesStripped: Object.keys(roleSnapshots).length,
  };
}

async function unlockGuild(client, guild, options = {}) {
  const isDrill = Boolean(options.drill);
  lockdownUntil.delete(guild.id);
  const state = lockdownState.get(guild.id);
  lockdownState.delete(guild.id);

  let unlocked = 0;
  const restoreJobs = [];
  const restoreTypes = [
    ChannelType.GuildText,
    ChannelType.GuildAnnouncement,
    ChannelType.GuildVoice,
    ChannelType.GuildForum,
    ChannelType.GuildStageVoice,
    ChannelType.GuildCategory,
  ];

  for (const ch of guild.channels.cache.values()) {
    if (!restoreTypes.includes(ch.type)) continue;
    if (state?.safeZoneId && ch.id === state.safeZoneId) continue;
    restoreJobs.push(
      ch.permissionOverwrites
        .edit(guild.id, {
          ViewChannel: null,
          SendMessages: null,
          AddReactions: null,
          CreatePublicThreads: null,
          CreatePrivateThreads: null,
          SendMessagesInThreads: null,
          Connect: null,
          Speak: null,
          ReadMessageHistory: null,
        })
        .then(() => {
          unlocked += 1;
        })
        .catch(() => {}),
    );
  }
  const batchSize = envInt('GUARDIAN_LOCK_BATCH', 15);
  for (let i = 0; i < restoreJobs.length; i += batchSize) {
    await Promise.all(restoreJobs.slice(i, i + batchSize));
  }

  // Clean up safe-zone: delete if we created it, otherwise restore perms
  if (state?.safeZoneId) {
    try {
      const sz = await guild.channels.fetch(state.safeZoneId).catch(() => null);
      if (sz) {
        if (state.created) {
          await sz.delete('Rex Guardian unlock — remove temporary safe zone');
        } else {
          await sz.permissionOverwrites.edit(guild.id, {
            ViewChannel: null,
            SendMessages: null,
            AddReactions: null,
          });
        }
      }
    } catch (err) {
      console.warn('[guardian] safe-zone cleanup failed:', err.message);
    }
  }

  // Restore roles that were quarantined during lockdown
  let roleRestore = { restoredMembers: 0, restoredRoles: 0 };
  if (state?.roleSnapshots && Object.keys(state.roleSnapshots).length) {
    roleRestore = await restoreQuarantineRoles(guild, state.roleSnapshots);
  }
  persistLockdownState();

  await postGuardianAlert(client, {
    level: 'medium',
    title: isDrill ? 'DRILL COMPLETE — Lockdown lifted' : 'Lockdown lifted',
    description: isDrill
      ? [
          '# ✅ SECURITY DRILL COMPLETE',
          '',
          `The **test lockdown** on **${guild.name}** has ended.`,
          `**${unlocked}** channels restored. Safe zone cleaned up.`,
          `**Roles restored:** ${roleRestore.restoredMembers} members / ${roleRestore.restoredRoles} assigns`,
          '_This was a drill — no hostile activity was detected._',
        ].join('\n')
      : [
          `**${guild.name}** lockdown cleared (${unlocked} channels restored).`,
          `**Roles restored:** ${roleRestore.restoredMembers} members / ${roleRestore.restoredRoles} assigns`,
        ].join('\n'),
    pingOwner: false,
  });
  return { unlocked, ...roleRestore };
}

/**
 * Professional server-wide lockdown drill: warn everyone, lock, hold, unlock.
 */
async function runLockdownDrill(client, guild, {
  holdSeconds = 1,
  announceChannelId = null,
} = {}) {
  const { EmbedBuilder } = require('discord.js');
  const { resolveAlertsTarget, ownerIds } = require('./guardian-alerts');
  const hold = Math.max(1, Number(holdSeconds) || 1);

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

  const lockResult = await lockdownGuild(client, guild, 'Scheduled security drill / lockout system test', {
    drill: true,
    minutes: Math.max(1, Math.ceil(hold / 60)),
  });
  const locked = typeof lockResult === 'object' ? lockResult.locked : lockResult;

  await new Promise((r) => setTimeout(r, hold * 1000));

  const unlockResult = await unlockGuild(client, guild, { drill: true });
  const unlockedCount =
    typeof unlockResult === 'object' ? unlockResult.unlocked : unlockResult;

  // All-clear in announce channels — NO @everyone ping on lift
  const clearEmbed = new EmbedBuilder()
    .setColor(0x16a34a)
    .setTitle('✅ ALL CLEAR — LOCKDOWN LIFTED')
    .setDescription(
      [
        `Lockdown on **${guild.name}** has ended.`,
        `Channels restored: **${unlockedCount}**`,
        '',
        '_Rex Guardian — no @everyone ping on unlock._',
      ].join('\n'),
    )
    .setFooter({ text: 'Lockdown lifted · quiet unlock' })
    .setTimestamp();

  for (const id of announced) {
    try {
      const ch = await client.channels.fetch(id);
      if (!ch?.isTextBased?.()) continue;
      await ch.send({
        embeds: [clearEmbed],
        allowedMentions: { parse: [] },
      });
    } catch (_) {}
  }

  return { locked, unlocked: unlockedCount, holdSeconds: hold };
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
 * Ban (preferred) or kick a nuker/raider.
 * Bots: ban/kick FIRST (role strip wastes critical ms during mass-delete).
 * Humans: strip roles then ban/kick.
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

  const isBot = Boolean(member?.user?.bot);
  const doStrip = async () => {
    try {
      if (member) {
        const removable = member.roles.cache.filter((r) => r.id !== guild.id && r.editable);
        if (removable.size) await member.roles.remove(removable, `[Guardian] ${reason}`).catch(() => {});
      }
    } catch (_) {}
  };

  // Humans: strip first. Bots: remove immediately — strip is pointless once banned.
  if (!isBot) await doStrip();

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

  if (isBot) await doStrip();
  return { ok: false, reason: 'no_perms' };
}

/** guildId:userId → in-flight nuke response (dedupe concurrent ChannelDelete floods) */
const nukeInFlight = new Set();

/**
 * Record a dangerous action; auto-punish + lockdown when thresholds trip.
 * Bot executors on destructive actions: threshold forced to 1 (instant ban/kick).
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
    return;
  }

  let member = executorId ? guild.members.cache.get(executorId) : null;
  if (executorId && !member) {
    try {
      member = await guild.members.fetch(executorId);
    } catch (_) {}
  }
  if (!member && executorId) {
    try {
      const u = await client.users.fetch(executorId);
      if (u?.bot) member = { user: u, id: executorId };
    } catch (_) {}
  }

  const isBot = Boolean(member?.user?.bot);
  const destructActions = new Set([
    'channelDelete', 'channelCreate', 'roleDelete', 'roleCreate', 'webhookCreate',
  ]);
  // Instant response for any bot nuke — do not allow a free first delete
  const botInstant = isBot && destructActions.has(action);
  const limit = botInstant
    ? envInt('GUARDIAN_BOT_DESTRUCT_THRESHOLD', 1)
    : threshold;

  const key = `${guild.id}:${action}:${executorId || 'unknown'}`;
  const count = hit(key, windowMs);

  if (count < limit) {
    await postGuardianAlert(client, {
      level: count >= Math.max(1, limit - 1) ? 'high' : 'medium',
      title: `${action} detected`,
      description: detail || `Suspicious **${action}** in **${guild.name}**.`,
      fields: [
        { name: 'Executor', value: executorId ? `<@${executorId}> (\`${executorId}\`)\n${executorTag || ''}` : 'Unknown (check Audit Log)', inline: true },
        { name: 'Target', value: String(targetLabel || '—').slice(0, 200), inline: true },
        { name: 'Window', value: `${count}/${limit} in ${Math.round(windowMs / 1000)}s`, inline: true },
      ],
      pingOwner: false,
    });
    return;
  }

  const punishReason = `Anti-nuke: ${action} x${count}`;
  const flightKey = `${guild.id}:${executorId || 'unknown'}:${action}`;
  if (nukeInFlight.has(flightKey)) {
    return;
  }
  nukeInFlight.add(flightKey);
  setTimeout(() => nukeInFlight.delete(flightKey), 15_000);

  // Punish FIRST (before alerts) — mass-delete bots win races against Discord REST otherwise
  const { jailMember } = require('./guardian-jail');
  let result;
  if (isBot) {
    result = await punish(client, guild, executorId, punishReason, { ban: punishBan });
    // Jail humans who ran .clear / purge, and Co-Owner inviters — audit only shows the bot
    try {
      const { jailOperatorsForBotNuke } = require('./guardian-operators');
      await jailOperatorsForBotNuke(client, guild, executorId, punishReason);
    } catch (err) {
      console.warn('[guardian] jail operators failed:', err.message);
    }
  } else {
    const jail = await jailMember(client, guild, executorId, punishReason, { force: true });
    result = jail.ok
      ? { ok: true, action: jail.action }
      : await punish(client, guild, executorId, punishReason, { ban: punishBan });
  }

  if (lockdown && !isLocked(guild.id)) {
    lockdownGuild(client, guild, punishReason, { pingEveryone: false }).catch((err) => {
      console.warn('[guardian] lockdown after nuke failed:', err.message);
    });
  }

  await postGuardianAlert(client, {
    level: 'critical',
    title: `${action} detected`,
    description: detail || `Suspicious **${action}** in **${guild.name}**.`,
    fields: [
      { name: 'Executor', value: executorId ? `<@${executorId}> (\`${executorId}\`)\n${executorTag || ''}` : 'Unknown (check Audit Log)', inline: true },
      { name: 'Target', value: String(targetLabel || '—').slice(0, 200), inline: true },
      { name: 'Window', value: `${count}/${limit} in ${Math.round(windowMs / 1000)}s`, inline: true },
    ],
    pingOwner: true,
  });

  await postGuardianAlert(client, {
    level: 'critical',
    title: `JAILED / punished for ${action}`,
    description: result?.ok
      ? `Applied **${result.action}** to <@${executorId}> for **${action}** nuke activity.`
      : `Threshold hit but jail/punish failed: \`${result?.reason || result?.error || result?.skipped || 'unknown'}\`.`,
    fields: [
      { name: 'Executor', value: `<@${executorId}>`, inline: true },
      { name: 'Count', value: `${count}/${limit}`, inline: true },
      { name: 'Type', value: isBot ? 'Bot account (instant)' : 'Human / role', inline: true },
    ],
    pingOwner: true,
  });
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
  snapshotAndQuarantineRoles,
  restoreQuarantineRoles,
  runLockdownDrill,
  isLocked,
  punish,
  noteAction,
  THRESHOLDS,
  DANGEROUS_PERMS,
  lockdownUntil,
  lockdownState,
  infraState,
  envInt,
  envList,
};
