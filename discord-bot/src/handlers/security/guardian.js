/**
 * Rex Guardian — automatic anti-raid / anti-nuke + infra watch.
 * Loaded from handlers/security (auto-required by index.js).
 */
const Discord = require('discord.js');
const {
  AuditLogEvent,
  Events,
  PermissionFlagsBits,
} = require('discord.js');
const {
  guardianEnabled,
  isWhitelisted,
  fetchExecutor,
  noteAction,
  punish,
  lockdownGuild,
  THRESHOLDS,
  DANGEROUS_PERMS,
  infraState,
  envInt,
  hit,
  isLocked,
} = require('../../lib/guardian-engine');
const { postGuardianAlert, ownerIds } = require('../../lib/guardian-alerts');

async function maybeExecutor(guild, type, targetId) {
  return fetchExecutor(guild, type, targetId);
}

async function checkInfra(client) {
  const checks = [];

  // FiveM
  try {
    const { getPhantomStatus } = require('../../../aio-bridge/fivem-status');
    const status = await getPhantomStatus();
    const online = Boolean(status?.online ?? status?.serverName ?? typeof status?.playerCount === 'number');
    checks.push({
      id: 'fivem',
      label: 'FiveM',
      ok: online,
      detail: online
        ? `${status.playerCount ?? 0}/${status.maxPlayers ?? 48} — ${status.serverName || 'online'}`
        : 'Unreachable / offline',
    });
  } catch (err) {
    checks.push({ id: 'fivem', label: 'FiveM', ok: false, detail: err.message });
  }

  // Billing site
  const billingUrl = (process.env.BILLING_URL || 'https://billing.phantom-chicken.com').replace(/\/$/, '');
  try {
    const ac = new AbortController();
    const t = setTimeout(() => ac.abort(), 8000);
    const res = await fetch(`${billingUrl}/`, { signal: ac.signal, redirect: 'follow' }).catch(() => null);
    clearTimeout(t);
    const ok = Boolean(res && res.status < 500);
    checks.push({
      id: 'billing',
      label: 'Billing',
      ok,
      detail: res ? `HTTP ${res.status}` : 'No response',
    });
  } catch (err) {
    checks.push({ id: 'billing', label: 'Billing', ok: false, detail: err.message });
  }

  // Panel
  const panelUrl = (process.env.PANEL_URL || 'https://panel.phantom-chicken.com').replace(/\/$/, '');
  try {
    const ac = new AbortController();
    const t = setTimeout(() => ac.abort(), 8000);
    const res = await fetch(`${panelUrl}/`, { signal: ac.signal, redirect: 'follow' }).catch(() => null);
    clearTimeout(t);
    const ok = Boolean(res && res.status < 500);
    checks.push({
      id: 'panel',
      label: 'Panel',
      ok,
      detail: res ? `HTTP ${res.status}` : 'No response',
    });
  } catch (err) {
    checks.push({ id: 'panel', label: 'Panel', ok: false, detail: err.message });
  }

  // Local bot relay health
  try {
    const ac = new AbortController();
    const t = setTimeout(() => ac.abort(), 3000);
    const res = await fetch('http://127.0.0.1:3099/health', { signal: ac.signal }).catch(() => null);
    clearTimeout(t);
    const ok = Boolean(res && res.ok);
    checks.push({
      id: 'bot_health',
      label: 'Bot relay :3099',
      ok,
      detail: res ? `HTTP ${res.status}` : 'Down',
    });
  } catch (err) {
    checks.push({ id: 'bot_health', label: 'Bot relay :3099', ok: false, detail: err.message });
  }

  // Lavalink (optional)
  const llHost = process.env.LAVALINK_HOST || process.env.LAVALINK_URL;
  if (llHost) {
    try {
      let url = String(llHost);
      if (!/^https?:/i.test(url)) url = `http://${llHost}:${process.env.LAVALINK_PORT || 2333}`;
      const versionUrl = url.replace(/\/$/, '') + '/version';
      const ac = new AbortController();
      const t = setTimeout(() => ac.abort(), 5000);
      const res = await fetch(versionUrl, {
        signal: ac.signal,
        headers: process.env.LAVALINK_PASSWORD
          ? { Authorization: process.env.LAVALINK_PASSWORD }
          : undefined,
      }).catch(() => null);
      clearTimeout(t);
      checks.push({
        id: 'lavalink',
        label: 'Lavalink',
        ok: Boolean(res && res.status < 500),
        detail: res ? `HTTP ${res.status}` : 'Unreachable',
      });
    } catch (err) {
      checks.push({ id: 'lavalink', label: 'Lavalink', ok: false, detail: err.message });
    }
  }

  for (const check of checks) {
    const prev = infraState.get(check.id);
    infraState.set(check.id, check);
    if (prev && prev.ok === check.ok) continue;

    // First run: only alert if currently down
    if (!prev && check.ok) continue;

    await postGuardianAlert(client, {
      level: check.ok ? 'medium' : 'critical',
      title: check.ok ? `${check.label} recovered` : `${check.label} DOWN`,
      description: check.ok
        ? `**${check.label}** is back online.\n${check.detail}`
        : `**${check.label}** failed health check.\n${check.detail}`,
      fields: [
        { name: 'Service', value: check.label, inline: true },
        { name: 'Status', value: check.ok ? 'OK' : 'DOWN', inline: true },
      ],
      pingOwner: !check.ok,
      footer: 'Rex Guardian · infra watch',
    });
  }

  return checks;
}

module.exports = async (client) => {
  if (!guardianEnabled()) {
    console.log('[guardian] disabled (GUARDIAN_ENABLED=0)');
    return;
  }

  console.log('[guardian] Anti-raid / anti-nuke / infra watch armed');

  // ---- Mass join raid ----
  client.on(Events.GuildMemberAdd, async (member) => {
    try {
      if (!guardianEnabled() || member.user.bot) return;
      const guild = member.guild;
      const key = `${guild.id}:joins`;
      const count = hit(key, THRESHOLDS.massJoin.windowMs);

      if (count === Math.max(2, THRESHOLDS.massJoin.threshold - 2)) {
        await postGuardianAlert(client, {
          level: 'high',
          title: 'Join spike',
          description: `Elevated joins on **${guild.name}**: **${count}** in ${Math.round(THRESHOLDS.massJoin.windowMs / 1000)}s.`,
          pingOwner: true,
        });
      }

      if (count < THRESHOLDS.massJoin.threshold) return;

      const ageDays =
        (Date.now() - member.user.createdTimestamp) / (1000 * 60 * 60 * 24);
      const newAccount = ageDays < envInt('GUARDIAN_NEW_ACCOUNT_DAYS', 7);

      await postGuardianAlert(client, {
        level: 'critical',
        title: 'RAID — mass joins',
        description: `**${count}** joins in ${Math.round(THRESHOLDS.massJoin.windowMs / 1000)}s on **${guild.name}**.\nLatest: <@${member.id}> (account age **${ageDays.toFixed(1)}d**).`,
        pingOwner: true,
      });

      if (newAccount || envInt('GUARDIAN_RAID_BAN_ALL', 0) === 1) {
        await punish(
          client,
          guild,
          member.id,
          `Anti-raid: mass join (${count})`,
          { ban: envInt('GUARDIAN_RAID_BAN', 1) === 1 },
        );
      }

      if (!isLocked(guild.id)) {
        await lockdownGuild(client, guild, `Anti-raid: ${count} joins`);
      }
    } catch (err) {
      console.warn('[guardian] join handler:', err.message);
    }
  });

  // ---- Channel delete / create ----
  client.on(Events.ChannelDelete, async (channel) => {
    try {
      if (!channel.guild || !guardianEnabled()) return;
      const ex = await maybeExecutor(channel.guild, AuditLogEvent.ChannelDelete, channel.id);
      await noteAction(client, channel.guild, {
        action: 'channelDelete',
        executorId: ex?.id,
        executorTag: ex?.tag,
        targetLabel: `#${channel.name} (${channel.id})`,
        detail: `Channel **#${channel.name}** was deleted.`,
        ...THRESHOLDS.channelDelete,
      });
    } catch (err) {
      console.warn('[guardian] channelDelete:', err.message);
    }
  });

  client.on(Events.ChannelCreate, async (channel) => {
    try {
      if (!channel.guild || !guardianEnabled()) return;
      const ex = await maybeExecutor(channel.guild, AuditLogEvent.ChannelCreate, channel.id);
      await noteAction(client, channel.guild, {
        action: 'channelCreate',
        executorId: ex?.id,
        executorTag: ex?.tag,
        targetLabel: `#${channel.name} (${channel.id})`,
        detail: `Channel **#${channel.name}** was created.`,
        ...THRESHOLDS.channelCreate,
      });
    } catch (err) {
      console.warn('[guardian] channelCreate:', err.message);
    }
  });

  // ---- Roles ----
  client.on(Events.GuildRoleDelete, async (role) => {
    try {
      if (!guardianEnabled()) return;
      const ex = await maybeExecutor(role.guild, AuditLogEvent.RoleDelete, role.id);
      await noteAction(client, role.guild, {
        action: 'roleDelete',
        executorId: ex?.id,
        executorTag: ex?.tag,
        targetLabel: `@${role.name} (${role.id})`,
        detail: `Role **${role.name}** was deleted.`,
        ...THRESHOLDS.roleDelete,
      });
    } catch (err) {
      console.warn('[guardian] roleDelete:', err.message);
    }
  });

  client.on(Events.GuildRoleCreate, async (role) => {
    try {
      if (!guardianEnabled()) return;
      const ex = await maybeExecutor(role.guild, AuditLogEvent.RoleCreate, role.id);
      await noteAction(client, role.guild, {
        action: 'roleCreate',
        executorId: ex?.id,
        executorTag: ex?.tag,
        targetLabel: `@${role.name} (${role.id})`,
        detail: `Role **${role.name}** was created.`,
        ...THRESHOLDS.roleCreate,
      });
    } catch (err) {
      console.warn('[guardian] roleCreate:', err.message);
    }
  });

  client.on(Events.GuildRoleUpdate, async (oldRole, newRole) => {
    try {
      if (!guardianEnabled()) return;
      const addedDanger = DANGEROUS_PERMS.filter(
        (p) => !oldRole.permissions.has(p) && newRole.permissions.has(p),
      );
      if (!addedDanger.length) return;

      const ex = await maybeExecutor(newRole.guild, AuditLogEvent.RoleUpdate, newRole.id);
      if (ex?.id && isWhitelisted(client, ex.id)) return;

      const permNames = {
        [PermissionFlagsBits.Administrator]: 'Administrator',
        [PermissionFlagsBits.BanMembers]: 'BanMembers',
        [PermissionFlagsBits.KickMembers]: 'KickMembers',
        [PermissionFlagsBits.ManageGuild]: 'ManageGuild',
        [PermissionFlagsBits.ManageRoles]: 'ManageRoles',
        [PermissionFlagsBits.ManageChannels]: 'ManageChannels',
        [PermissionFlagsBits.ManageWebhooks]: 'ManageWebhooks',
        [PermissionFlagsBits.MentionEveryone]: 'MentionEveryone',
      };

      await postGuardianAlert(client, {
        level: 'critical',
        title: 'Dangerous permissions granted',
        description: `Role **${newRole.name}** received dangerous permissions.`,
        fields: [
          {
            name: 'Permissions',
            value: addedDanger.map((p) => `\`${permNames[p] || p}\``).join(', ') || 'dangerous',
          },
          { name: 'Executor', value: ex?.id ? `<@${ex.id}>` : 'Unknown', inline: true },
        ],
        pingOwner: true,
      });

      // Immediate punish on admin grant spam / first admin grant from non-whitelist
      if (addedDanger.includes(PermissionFlagsBits.Administrator)) {
        await noteAction(client, newRole.guild, {
          action: 'dangerousPerms',
          executorId: ex?.id,
          executorTag: ex?.tag,
          targetLabel: `@${newRole.name}`,
          detail: `Administrator (or dangerous) perms added to **${newRole.name}**.`,
          threshold: envInt('GUARDIAN_DANGER_PERM', 1),
          windowMs: envInt('GUARDIAN_DANGER_PERM_MS', 60000),
        });
      }
    } catch (err) {
      console.warn('[guardian] roleUpdate:', err.message);
    }
  });

  // ---- Bans / kicks (moderation) ----
  client.on(Events.GuildBanAdd, async (ban) => {
    try {
      if (!guardianEnabled()) return;
      const ex = await maybeExecutor(ban.guild, AuditLogEvent.MemberBanAdd, ban.user.id);
      // Ignore our own guardian bans
      if (ex?.id === client.user.id) return;
      await noteAction(client, ban.guild, {
        action: 'memberBan',
        executorId: ex?.id,
        executorTag: ex?.tag,
        targetLabel: `${ban.user.tag} (${ban.user.id})`,
        detail: `Member **${ban.user.tag}** was banned.`,
        ...THRESHOLDS.memberBan,
      });
    } catch (err) {
      console.warn('[guardian] banAdd:', err.message);
    }
  });

  client.on(Events.GuildMemberRemove, async (member) => {
    try {
      if (!guardianEnabled()) return;
      // Detect kicks via audit (leaves won't match recent kick)
      const ex = await maybeExecutor(member.guild, AuditLogEvent.MemberKick, member.id);
      if (!ex?.id) return;
      if (ex.id === client.user.id) return;
      await noteAction(client, member.guild, {
        action: 'memberKick',
        executorId: ex.id,
        executorTag: ex.tag,
        targetLabel: `${member.user.tag} (${member.id})`,
        detail: `Member **${member.user.tag}** was kicked.`,
        ...THRESHOLDS.memberKick,
      });
    } catch (err) {
      console.warn('[guardian] memberRemove kick:', err.message);
    }
  });

  // ---- Webhooks ----
  client.on(Events.WebhooksUpdate, async (channel) => {
    try {
      if (!channel.guild || !guardianEnabled()) return;
      const ex = await maybeExecutor(channel.guild, AuditLogEvent.WebhookCreate, null);
      await noteAction(client, channel.guild, {
        action: 'webhookCreate',
        executorId: ex?.id,
        executorTag: ex?.tag,
        targetLabel: `#${channel.name}`,
        detail: `Webhooks updated in **#${channel.name}** (possible webhook create).`,
        ...THRESHOLDS.webhookCreate,
      });
    } catch (err) {
      console.warn('[guardian] webhooksUpdate:', err.message);
    }
  });

  // ---- Bot adds ----
  client.on(Events.GuildMemberAdd, async (member) => {
    try {
      if (!guardianEnabled() || !member.user.bot) return;
      if (isWhitelisted(client, member.id)) return;
      const allow = new Set(
        String(process.env.GUARDIAN_ALLOWED_BOTS || '')
          .split(/[,\s]+/)
          .filter(Boolean),
      );
      if (allow.has(member.id)) return;

      const ex = await maybeExecutor(member.guild, AuditLogEvent.BotAdd, member.id);
      await postGuardianAlert(client, {
        level: 'high',
        title: 'Bot added',
        description: `Bot **${member.user.tag}** joined **${member.guild.name}**.`,
        fields: [
          { name: 'Bot', value: `<@${member.id}> (\`${member.id}\`)`, inline: true },
          { name: 'Added by', value: ex?.id ? `<@${ex.id}>` : 'Unknown', inline: true },
        ],
        pingOwner: true,
      });

      if (envInt('GUARDIAN_KICK_UNKNOWN_BOTS', 1) === 1) {
        if (ex?.id && isWhitelisted(client, ex.id)) return;
        await punish(client, member.guild, member.id, 'Anti-nuke: unauthorized bot', {
          ban: envInt('GUARDIAN_BAN_UNKNOWN_BOTS', 0) === 1,
        });
        if (ex?.id && !isWhitelisted(client, ex.id)) {
          await noteAction(client, member.guild, {
            action: 'botAdd',
            executorId: ex.id,
            executorTag: ex.tag,
            targetLabel: member.user.tag,
            detail: `Unauthorized bot add: **${member.user.tag}**`,
            threshold: envInt('GUARDIAN_BOT_ADD', 1),
            windowMs: envInt('GUARDIAN_BOT_ADD_MS', 60000),
          });
        }
      }
    } catch (err) {
      console.warn('[guardian] bot add:', err.message);
    }
  });

  // ---- Guild update (vanity / name) ----
  client.on(Events.GuildUpdate, async (oldGuild, newGuild) => {
    try {
      if (!guardianEnabled()) return;
      const changes = [];
      if (oldGuild.name !== newGuild.name) changes.push(`Name: \`${oldGuild.name}\` → \`${newGuild.name}\``);
      if (oldGuild.vanityURLCode !== newGuild.vanityURLCode) {
        changes.push(`Vanity: \`${oldGuild.vanityURLCode || 'none'}\` → \`${newGuild.vanityURLCode || 'none'}\``);
      }
      if (oldGuild.icon !== newGuild.icon) changes.push('Icon changed');
      if (!changes.length) return;

      const ex = await maybeExecutor(newGuild, AuditLogEvent.GuildUpdate, newGuild.id);
      await postGuardianAlert(client, {
        level: 'critical',
        title: 'Guild settings changed',
        description: changes.join('\n'),
        fields: [{ name: 'Executor', value: ex?.id ? `<@${ex.id}>` : 'Unknown' }],
        pingOwner: true,
      });

      if (oldGuild.vanityURLCode !== newGuild.vanityURLCode && ex?.id && !isWhitelisted(client, ex.id)) {
        await noteAction(client, newGuild, {
          action: 'vanitySteal',
          executorId: ex.id,
          executorTag: ex.tag,
          targetLabel: newGuild.vanityURLCode || 'vanity',
          detail: 'Vanity URL changed — possible steal attempt.',
          threshold: 1,
          windowMs: 60000,
        });
      }
    } catch (err) {
      console.warn('[guardian] guildUpdate:', err.message);
    }
  });

  // ---- Ready: announce + infra loop ----
  const startWatch = async () => {
    await postGuardianAlert(client, {
      level: 'info',
      title: 'Guardian online',
      description: [
        'Automatic **anti-raid / anti-nuke** is armed.',
        'Watching: mass joins, channel/role nukes, mass ban/kick, webhooks, bot adds, dangerous perms, guild/vanity changes.',
        'Infra watch: FiveM, billing, panel, bot relay' + (process.env.LAVALINK_HOST ? ', Lavalink' : '') + '.',
        '',
        `Owners: ${ownerIds().map((id) => `<@${id}>`).join(' ') || '_none set_'}`,
        'All alerts post **here**.',
      ].join('\n'),
      pingOwner: false,
      footer: 'Rex Guardian · maximum lockdown',
    });

    const interval = envInt('GUARDIAN_INFRA_INTERVAL_MS', 60000);
    const tick = async () => {
      try {
        await checkInfra(client);
      } catch (err) {
        console.warn('[guardian] infra tick:', err.message);
      }
    };
    await tick();
    setInterval(tick, interval);
  };

  if (client.isReady?.() || client.readyAt) {
    startWatch().catch(() => {});
  } else {
    client.once(Events.ClientReady, () => {
      startWatch().catch((err) => console.warn('[guardian] start:', err.message));
    });
  }
};

// re-export helpers for slash command
module.exports.checkInfra = checkInfra;
