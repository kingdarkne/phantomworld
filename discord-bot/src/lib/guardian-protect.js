/**
 * Rex role fortress + Xeon backup-bot + Co-Owner-added app countermeasures.
 *
 * Co-Owner / Co-Founder may add apps. If an app THEY added tries to nuke
 * (channel/role create/delete), Rex kicks the app and full-lockdowns with
 * NO @everyone ping. The Co-Owner is not punished for the invite itself.
 *
 * Xeon (not invited by Co-Owner): wait for backup/delete, then kick Xeon +
 * operator and DM them (legacy path; no full lockdown unless Co-Owner-added).
 */
const {
  AuditLogEvent,
  Events,
  PermissionFlagsBits,
  EmbedBuilder,
} = require('discord.js');
const {
  fetchExecutor,
  punish,
  isWhitelisted,
  envInt,
  envList,
  guardianEnabled,
  lockdownGuild,
  isLocked,
} = require('./guardian-engine');
const { postGuardianAlert, ownerIds } = require('./guardian-alerts');
const { memberHasCoOwnerRole } = require('./ensure-staff-roles');

/** guildId -> Map(botId -> { invitedBy, taggedAt, tag }) */
const xeonWatch = new Map();

/** guildId -> Map(botId -> { invitedBy, taggedAt, tag, coOwner: true }) */
const coOwnerAppWatch = new Map();

function xeonNameRe() {
  const extra = envList('GUARDIAN_XEON_NAMES');
  const parts = ['xeon', 'xeon.?bot', 'xeon.?backup', ...extra.map((s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'))];
  return new RegExp(parts.join('|'), 'i');
}

function xeonIdSet() {
  return new Set(envList('GUARDIAN_XEON_BOT_IDS'));
}

function isXeonBot(user) {
  if (!user?.bot) return false;
  if (xeonIdSet().has(user.id)) return true;
  const name = `${user.username || ''} ${user.globalName || ''} ${user.tag || ''}`;
  return xeonNameRe().test(name);
}

function guildXeonMap(guildId) {
  if (!xeonWatch.has(guildId)) xeonWatch.set(guildId, new Map());
  return xeonWatch.get(guildId);
}

function guildCoOwnerAppMap(guildId) {
  if (!coOwnerAppWatch.has(guildId)) coOwnerAppWatch.set(guildId, new Map());
  return coOwnerAppWatch.get(guildId);
}

function guildHasXeon(guild) {
  const watched = guildXeonMap(guild.id);
  if (watched.size) return true;
  return guild.members.cache.some((m) => isXeonBot(m.user));
}

function guildHasCoOwnerApp(guild) {
  return guildCoOwnerAppMap(guild.id).size > 0;
}

function isWatchedCoOwnerApp(guild, userId) {
  return guildCoOwnerAppMap(guild.id).has(userId);
}

async function dmUser(client, userId, payload) {
  try {
    const user = await client.users.fetch(userId);
    await user.send(payload);
    return true;
  } catch (err) {
    console.warn('[guardian-protect] DM failed', userId, err.message);
    return false;
  }
}

function threatDmEmbed({ guildName, reason, kind }) {
  return new EmbedBuilder()
    .setColor(0x7f1d1d)
    .setTitle(
      kind === 'xeon'
        ? '🚫 Backup/nuke bot blocked'
        : kind === 'coowner-app'
          ? '🚫 App blocked — nuke attempt'
          : '🚫 Action blocked by Rex Guardian',
    )
    .setDescription(
      [
        `You were removed from **${guildName}**.`,
        '',
        `**Reason:** ${reason}`,
        '',
        'Rex Guardian protects this server. Do not attempt to remove Rex, load unauthorized backups, or delete server structure.',
      ].join('\n'),
    )
    .setFooter({ text: 'Rex Guardian · Phantom World Security' })
    .setTimestamp();
}

async function fortifyBotRole(guild, me) {
  if (!me) return { ok: false, reason: 'no_me' };
  const role = me.roles.highest;
  if (!role || role.id === guild.id) return { ok: false, reason: 'no_role' };

  const changes = [];

  if (role.editable) {
    const need = [PermissionFlagsBits.Administrator];
    let perms = role.permissions;
    let changedPerms = false;
    for (const p of need) {
      if (!perms.has(p)) {
        perms = perms.add(p);
        changedPerms = true;
      }
    }
    if (changedPerms) {
      try {
        await role.setPermissions(perms, 'Rex Guardian: fortify role permissions');
        changes.push('restored Administrator on Rex role');
      } catch (err) {
        changes.push(`perm restore failed: ${err.message}`);
      }
    }

    try {
      const maxEditable = guild.roles.cache
        .filter((r) => r.id !== role.id && r.editable)
        .sort((a, b) => b.position - a.position)
        .first();
      const targetPos = maxEditable ? maxEditable.position + 1 : role.position;
      if (targetPos > role.position) {
        await role.setPosition(targetPos, { reason: 'Rex Guardian: keep role on top' });
        changes.push(`raised role position → ${targetPos}`);
      }
    } catch (err) {
      changes.push(`position raise blocked: ${err.message}`);
    }
  }

  return { ok: true, roleId: role.id, position: role.position, changes };
}

async function punishRoleAttacker(client, guild, executorId, reason) {
  if (!executorId || isWhitelisted(client, executorId)) return;
  await punish(client, guild, executorId, reason, { ban: true });
  await dmUser(client, executorId, {
    embeds: [threatDmEmbed({ guildName: guild.name, reason, kind: 'role' })],
  });
  await postGuardianAlert(client, {
    level: 'critical',
    title: 'Rex role / presence attacked',
    description: `Punished <@${executorId}> for: **${reason}**\nRex role fortress will keep restoring power.`,
    pingOwner: true,
  });
}

/**
 * App added by Co-Owner/Co-Founder tried to nuke → kick app + lockdown (no @everyone).
 * Co-Owner is NOT kicked for adding the app.
 */
async function handleCoOwnerAppNuke(client, guild, {
  action,
  executorId,
  appId,
  detail,
}) {
  const watched = guildCoOwnerAppMap(guild.id);
  const entry = (appId && watched.get(appId)) || (executorId && watched.get(executorId)) || null;
  const targetAppId = appId || executorId || [...watched.keys()][0];
  const inviterId = entry?.invitedBy || null;

  const reason = `Co-Owner-added app nuke attempt (${action})`;

  await postGuardianAlert(client, {
    level: 'critical',
    title: 'Co-Owner app nuke — kick + lockdown (no @everyone)',
    description: [
      `**Action:** ${action}`,
      detail || '',
      '',
      'Kicking the **app**. Engaging **safe-zone lockdown** with **no @everyone** ping.',
      'Co-Owner who added the app is **not** punished for the invite.',
    ]
      .filter(Boolean)
      .join('\n'),
    fields: [
      { name: 'App', value: targetAppId ? `<@${targetAppId}>` : '—', inline: true },
      { name: 'Added by (Co-Owner)', value: inviterId ? `<@${inviterId}>` : 'Unknown', inline: true },
      { name: 'Executor', value: executorId ? `<@${executorId}>` : '—', inline: true },
    ],
    pingOwner: true,
  });

  if (targetAppId) {
    await dmUser(client, targetAppId, {
      embeds: [threatDmEmbed({ guildName: guild.name, reason, kind: 'coowner-app' })],
    });
    await punish(client, guild, targetAppId, reason, { ban: false });
    watched.delete(targetAppId);
    guildXeonMap(guild.id).delete(targetAppId);
  }

  if (executorId && executorId !== targetAppId) {
    const execMember = guild.members.cache.get(executorId);
    if (execMember?.user?.bot) {
      await punish(client, guild, executorId, reason, { ban: false });
      watched.delete(executorId);
    }
  }

  if (!isLocked(guild.id)) {
    await lockdownGuild(client, guild, reason, {
      pingEveryone: false,
      minutes: envInt('GUARDIAN_LOCKDOWN_MINUTES', 30),
    });
  }

  return { appId: targetAppId, inviterId };
}

async function handleXeonThreat(client, guild, {
  action,
  executorId,
  xeonId,
  detail,
}) {
  const watched = guildXeonMap(guild.id);
  const coMap = guildCoOwnerAppMap(guild.id);
  const inviterFromWatch = xeonId ? watched.get(xeonId)?.invitedBy : null;

  if (coMap.has(xeonId) || coMap.has(executorId) || (xeonId && coMap.has(xeonId))) {
    return handleCoOwnerAppNuke(client, guild, {
      action,
      executorId,
      appId: xeonId || executorId,
      detail: detail || 'Xeon/backup bot was added by Co-Owner and attempted a nuke action.',
    });
  }

  const xeonIds = new Set([
    ...watched.keys(),
    ...guild.members.cache.filter((m) => isXeonBot(m.user)).map((m) => m.id),
  ]);
  if (xeonId) xeonIds.add(xeonId);

  const humans = new Set();
  if (executorId && !guild.members.cache.get(executorId)?.user?.bot) humans.add(executorId);
  if (inviterFromWatch) humans.add(inviterFromWatch);
  if (executorId && xeonIds.has(executorId) && inviterFromWatch) {
    humans.add(inviterFromWatch);
  }

  await postGuardianAlert(client, {
    level: 'critical',
    title: 'Xeon / backup-bot threat — countered (no lockdown)',
    description: [
      `**Action:** ${action}`,
      detail || '',
      '',
      'Rex is kicking the backup bot and the operator. **Full lockdown skipped** for this case.',
    ]
      .filter(Boolean)
      .join('\n'),
    fields: [
      { name: 'Xeon bot(s)', value: [...xeonIds].map((id) => `<@${id}>`).join(', ') || '—', inline: false },
      { name: 'Operator(s)', value: [...humans].map((id) => `<@${id}>`).join(', ') || '—', inline: false },
    ],
    pingOwner: true,
  });

  const reason = `Unauthorized backup/nuke bot activity (${action})`;

  for (const id of xeonIds) {
    await dmUser(client, id, {
      embeds: [threatDmEmbed({ guildName: guild.name, reason, kind: 'xeon' })],
    });
    await punish(client, guild, id, reason, { ban: false });
    watched.delete(id);
  }

  for (const id of humans) {
    if (isWhitelisted(client, id)) continue;
    if (memberHasCoOwnerRole(guild.members.cache.get(id))) continue;
    await dmUser(client, id, {
      embeds: [threatDmEmbed({ guildName: guild.name, reason, kind: 'xeon' })],
    });
    await punish(client, guild, id, reason, {
      ban: envInt('GUARDIAN_XEON_BAN_OPERATOR', 1) === 1,
    });
  }

  return { xeonIds: [...xeonIds], humans: [...humans] };
}

function registerGuardianProtect(client) {
  const fortifyAll = async () => {
    if (!guardianEnabled()) return;
    for (const guild of client.guilds.cache.values()) {
      try {
        const me = guild.members.me || (await guild.members.fetchMe());
        const result = await fortifyBotRole(guild, me);
        if (result.changes?.length) {
          console.log(`[guardian-protect] ${guild.name}:`, result.changes.join('; '));
        }
      } catch (err) {
        console.warn('[guardian-protect] fortify', guild.id, err.message);
      }
    }
  };

  const start = () => {
    for (const guild of client.guilds.cache.values()) {
      for (const m of guild.members.cache.values()) {
        if (isXeonBot(m.user)) {
          guildXeonMap(guild.id).set(m.id, {
            invitedBy: null,
            taggedAt: Date.now(),
            tag: m.user.tag,
          });
        }
      }
    }
    fortifyAll().catch(() => {});
    setInterval(() => fortifyAll().catch(() => {}), envInt('GUARDIAN_FORTIFY_MS', 15000));
    console.log('[guardian-protect] Rex role fortress + Co-Owner app watch + Xeon watch armed');
  };

  if (client.isReady?.() || client.readyAt) start();
  else client.once(Events.ClientReady, start);

  client.on(Events.GuildMemberAdd, async (member) => {
    try {
      if (!guardianEnabled() || !member.user.bot) return;

      const ex = await fetchExecutor(member.guild, AuditLogEvent.BotAdd, member.id);
      let inviter = null;
      if (ex?.id) {
        inviter = member.guild.members.cache.get(ex.id)
          || (await member.guild.members.fetch(ex.id).catch(() => null));
      }

      const byCoOwner = Boolean(inviter && memberHasCoOwnerRole(inviter));

      if (byCoOwner) {
        guildCoOwnerAppMap(member.guild.id).set(member.id, {
          invitedBy: ex.id,
          taggedAt: Date.now(),
          tag: member.user.tag,
          coOwner: true,
        });
        await postGuardianAlert(client, {
          level: 'high',
          title: 'App added by Co-Owner — WATCHING',
          description: [
            `**${member.user.tag}** was added by a **Co-Owner/Co-Founder**.`,
            'If this app tries to **nuke** (mass delete/create channels or roles), Rex will **kick it** and **lockdown** with **no @everyone**.',
          ].join('\n'),
          fields: [
            { name: 'App', value: `<@${member.id}>`, inline: true },
            { name: 'Added by', value: `<@${ex.id}>`, inline: true },
          ],
          pingOwner: true,
        });
      }

      if (!isXeonBot(member.user)) return;

      guildXeonMap(member.guild.id).set(member.id, {
        invitedBy: ex?.id || null,
        taggedAt: Date.now(),
        tag: member.user.tag,
      });

      await postGuardianAlert(client, {
        level: 'high',
        title: byCoOwner
          ? 'Xeon / backup bot joined via Co-Owner — WATCHING (kick+lockdown on nuke)'
          : 'Xeon / backup bot joined — WATCHING',
        description: byCoOwner
          ? [
              `**${member.user.tag}** entered **${member.guild.name}** (added by Co-Owner).`,
              'Nuke attempt → **kick app + lockdown**, **no @everyone**.',
            ].join('\n')
          : [
              `**${member.user.tag}** entered **${member.guild.name}**.`,
              'Rex will **not** lockdown yet.',
              'If it tries to **backup / restore / delete** anything, Rex will kick the bot + the operator and DM them.',
            ].join('\n'),
        fields: [
          { name: 'Bot', value: `<@${member.id}>`, inline: true },
          { name: 'Added by', value: ex?.id ? `<@${ex.id}>` : 'Unknown', inline: true },
        ],
        pingOwner: true,
      });
    } catch (err) {
      console.warn('[guardian-protect] bot join watch:', err.message);
    }
  });

  client.on(Events.GuildMemberRemove, async (member) => {
    try {
      guildXeonMap(member.guild.id).delete(member.id);
      guildCoOwnerAppMap(member.guild.id).delete(member.id);
    } catch (_) {}
  });

  const maybeThreatCounter = async (guild, action, targetId, auditType) => {
    if (!guardianEnabled() || !guild) return false;
    const ex = await fetchExecutor(guild, auditType, targetId);
    const execId = ex?.id || null;
    const execMember = execId ? guild.members.cache.get(execId) : null;
    let execXeon = Boolean(execMember && isXeonBot(execMember.user)) || guildXeonMap(guild.id).has(execId);
    if (!execXeon && execId) {
      try {
        const u = await client.users.fetch(execId);
        execXeon = isXeonBot(u);
      } catch (_) {}
    }

    const coMap = guildCoOwnerAppMap(guild.id);
    const execIsCoApp = execId && coMap.has(execId);
    const hasCoApp = coMap.size > 0;

    if (execIsCoApp || (hasCoApp && execMember?.user?.bot && coMap.has(execId))) {
      await handleCoOwnerAppNuke(client, guild, {
        action,
        executorId: execId,
        appId: execId,
        detail: `Detected **${action}** by an app added by Co-Owner/Co-Founder.`,
      });
      return true;
    }

    if (hasCoApp && execMember?.user?.bot) {
      const firstApp = [...coMap.keys()][0];
      await handleCoOwnerAppNuke(client, guild, {
        action,
        executorId: execId,
        appId: firstApp,
        detail: `Detected **${action}** while Co-Owner-added apps are present.`,
      });
      return true;
    }

    const hasXeon = guildHasXeon(guild) || execXeon;
    if (!hasXeon && !execXeon) return false;

    await handleXeonThreat(client, guild, {
      action,
      executorId: execId,
      xeonId: execXeon ? execId : [...guildXeonMap(guild.id).keys()][0],
      detail: `Detected **${action}** while Xeon/backup bot activity is in play.`,
    });
    return true;
  };

  client.on(Events.ChannelDelete, async (channel) => {
    try {
      if (!channel.guild) return;
      await maybeThreatCounter(channel.guild, 'channelDelete', channel.id, AuditLogEvent.ChannelDelete);
    } catch (_) {}
  });
  client.on(Events.ChannelCreate, async (channel) => {
    try {
      if (!channel.guild) return;
      await maybeThreatCounter(channel.guild, 'channelCreate', channel.id, AuditLogEvent.ChannelCreate);
    } catch (_) {}
  });
  client.on(Events.GuildRoleDelete, async (role) => {
    try {
      await maybeThreatCounter(role.guild, 'roleDelete', role.id, AuditLogEvent.RoleDelete);
    } catch (_) {}
  });
  client.on(Events.GuildRoleCreate, async (role) => {
    try {
      await maybeThreatCounter(role.guild, 'roleCreate', role.id, AuditLogEvent.RoleCreate);
    } catch (_) {}
  });

  client.on(Events.GuildRoleUpdate, async (oldRole, newRole) => {
    try {
      if (!guardianEnabled()) return;
      const me = newRole.guild.members.me;
      if (!me?.roles.cache.has(newRole.id)) return;

      const lostAdmin = oldRole.permissions.has(PermissionFlagsBits.Administrator)
        && !newRole.permissions.has(PermissionFlagsBits.Administrator);
      if (lostAdmin || oldRole.permissions.bitfield !== newRole.permissions.bitfield) {
        const ex = await fetchExecutor(newRole.guild, AuditLogEvent.RoleUpdate, newRole.id);
        await fortifyBotRole(newRole.guild, me);
        if (ex?.id && ex.id !== client.user.id) {
          await punishRoleAttacker(client, newRole.guild, ex.id, 'Tried to weaken / edit Rex role permissions');
        }
      }

      if (newRole.position < oldRole.position) {
        const ex = await fetchExecutor(newRole.guild, AuditLogEvent.RoleUpdate, newRole.id);
        await fortifyBotRole(newRole.guild, me);
        if (ex?.id && ex.id !== client.user.id) {
          await punishRoleAttacker(client, newRole.guild, ex.id, 'Tried to lower Rex role hierarchy');
        }
      }
    } catch (err) {
      console.warn('[guardian-protect] roleUpdate:', err.message);
    }
  });

  client.on(Events.GuildRoleDelete, async (role) => {
    try {
      if (!guardianEnabled()) return;
      const me = role.guild.members.me;
      if (!me) return;
      const ex = await fetchExecutor(role.guild, AuditLogEvent.RoleDelete, role.id);
      if (ex?.id && role.permissions?.has?.(PermissionFlagsBits.Administrator)) {
        await postGuardianAlert(client, {
          level: 'critical',
          title: 'Admin role deleted',
          description: `Role **${role.name}** deleted by <@${ex.id || 'unknown'}>. Fortifying Rex.`,
          pingOwner: true,
        });
        await fortifyBotRole(role.guild, me);
      }
    } catch (_) {}
  });

  client.on(Events.GuildMemberUpdate, async (oldMember, newMember) => {
    try {
      if (!guardianEnabled()) return;
      if (newMember.id !== client.user.id) return;

      const lost = oldMember.roles.cache.filter((r) => !newMember.roles.cache.has(r.id) && r.id !== newMember.guild.id);
      if (!lost.size) return;

      const ex = await fetchExecutor(newMember.guild, AuditLogEvent.MemberRoleUpdate, newMember.id);
      await postGuardianAlert(client, {
        level: 'critical',
        title: 'Someone stripped Rex roles',
        description: `Removed: ${lost.map((r) => r.name).join(', ') || 'roles'}\nRestoring fortress + punishing attacker.`,
        fields: [{ name: 'Executor', value: ex?.id ? `<@${ex.id}>` : 'Unknown' }],
        pingOwner: true,
      });

      for (const role of lost.values()) {
        if (role.editable || newMember.guild.members.me?.roles?.highest?.position > role.position) {
          await newMember.roles.add(role, 'Rex Guardian: restore stripped role').catch(() => {});
        }
      }
      await fortifyBotRole(newMember.guild, newMember);

      if (ex?.id && ex.id !== client.user.id) {
        await punishRoleAttacker(client, newMember.guild, ex.id, 'Tried to remove roles from Rex');
      }
    } catch (err) {
      console.warn('[guardian-protect] memberUpdate:', err.message);
    }
  });

  client.on(Events.GuildDelete, async (guild) => {
    try {
      const owners = ownerIds();
      for (const id of owners) {
        await dmUser(client, id, {
          embeds: [
            new EmbedBuilder()
              .setColor(0x7f1d1d)
              .setTitle('🚨 Rex was removed from a server')
              .setDescription(
                [
                  `Rex lost access to **${guild.name || 'a guild'}** (\`${guild.id}\`).`,
                  'Someone may have kicked Rex to bypass lockdown.',
                  '',
                  'Re-invite Rex and place its role at the **very top** (under you only).',
                ].join('\n'),
              )
              .setTimestamp(),
          ],
        });
      }
    } catch (_) {}
  });
}

module.exports = {
  registerGuardianProtect,
  fortifyBotRole,
  isXeonBot,
  handleXeonThreat,
  handleCoOwnerAppNuke,
  guildHasXeon,
  guildHasCoOwnerApp,
  isWatchedCoOwnerApp,
  xeonWatch,
  coOwnerAppWatch,
};
