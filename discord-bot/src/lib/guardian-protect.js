/**
 * Rex role fortress + Xeon backup-bot countermeasures.
 *
 * Discord cannot make a role truly undeletable for the server owner, but Guardian
 * keeps Rex as high/powerful as possible, restores stripped perms/roles, and
 * punishes anyone who tries to remove/kick Rex.
 *
 * Xeon: do NOT kick on join — wait until it (or its operator) tries backup/delete
 * style actions, then kick Xeon + the human, DM both, and skip full lockdown.
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
} = require('./guardian-engine');
const { postGuardianAlert, ownerIds } = require('./guardian-alerts');

/** guildId -> Map(botId -> { invitedBy, taggedAt, tag }) */
const xeonWatch = new Map();

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

function guildHasXeon(guild) {
  const watched = guildXeonMap(guild.id);
  if (watched.size) return true;
  return guild.members.cache.some((m) => isXeonBot(m.user));
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
    .setTitle(kind === 'xeon' ? '🚫 Backup/nuke bot blocked' : '🚫 Action blocked by Rex Guardian')
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

/**
 * Push Rex role as high as editable + ensure Administrator.
 */
async function fortifyBotRole(guild, me) {
  if (!me) return { ok: false, reason: 'no_me' };
  const role = me.roles.highest;
  if (!role || role.id === guild.id) return { ok: false, reason: 'no_role' };

  const changes = [];

  // Ensure dangerous protection perms on the role when editable
  if (role.editable) {
    const need = [
      PermissionFlagsBits.Administrator,
    ];
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

    // Raise role as high as we can (below uneditable roles)
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
      // Hierarchy may block — owner must drag Rex above other bots manually once
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
 * Handle Xeon (or operator) attempting backup / delete / structure changes.
 * No full lockdown — kick Xeon + human, DM them.
 */
async function handleXeonThreat(client, guild, {
  action,
  executorId,
  xeonId,
  detail,
}) {
  const watched = guildXeonMap(guild.id);
  const inviterFromWatch = xeonId ? watched.get(xeonId)?.invitedBy : null;

  // Collect xeon ids in guild
  const xeonIds = new Set([
    ...watched.keys(),
    ...guild.members.cache.filter((m) => isXeonBot(m.user)).map((m) => m.id),
  ]);
  if (xeonId) xeonIds.add(xeonId);

  const humans = new Set();
  if (executorId && !guild.members.cache.get(executorId)?.user?.bot) humans.add(executorId);
  if (inviterFromWatch) humans.add(inviterFromWatch);

  // If executor is the xeon bot itself, blame inviter
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
    await punish(client, guild, id, reason, { ban: false }); // kick bot
    watched.delete(id);
  }

  for (const id of humans) {
    if (isWhitelisted(client, id)) continue;
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
  // ---- Fortify loop ----
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
    // Seed watchlist for Xeon bots already in guilds
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
    console.log('[guardian-protect] Rex role fortress + Xeon watch armed');
  };

  if (client.isReady?.() || client.readyAt) start();
  else client.once(Events.ClientReady, start);

  // ---- Xeon join: watch only ----
  client.on(Events.GuildMemberAdd, async (member) => {
    try {
      if (!guardianEnabled() || !member.user.bot) return;
      if (!isXeonBot(member.user)) return;

      const ex = await fetchExecutor(member.guild, AuditLogEvent.BotAdd, member.id);
      const map = guildXeonMap(member.guild.id);
      map.set(member.id, {
        invitedBy: ex?.id || null,
        taggedAt: Date.now(),
        tag: member.user.tag,
      });

      await postGuardianAlert(client, {
        level: 'high',
        title: 'Xeon / backup bot joined — WATCHING',
        description: [
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
      console.warn('[guardian-protect] xeon join:', err.message);
    }
  });

  client.on(Events.GuildMemberRemove, async (member) => {
    try {
      guildXeonMap(member.guild.id).delete(member.id);
    } catch (_) {}
  });

  // ---- Destructive actions while Xeon present / by Xeon ----
  const maybeXeonCounter = async (guild, action, targetId, auditType) => {
    if (!guardianEnabled() || !guild) return false;
    const ex = await fetchExecutor(guild, auditType, targetId);
    const execMember = ex?.id ? guild.members.cache.get(ex.id) : null;
    let execXeon = Boolean(execMember && isXeonBot(execMember.user)) || guildXeonMap(guild.id).has(ex?.id);
    if (!execXeon && ex?.id) {
      try {
        const u = await client.users.fetch(ex.id);
        execXeon = isXeonBot(u);
      } catch (_) {}
    }
    const hasXeon = guildHasXeon(guild) || execXeon;
    if (!hasXeon && !execXeon) return false;

    await handleXeonThreat(client, guild, {
      action,
      executorId: ex?.id,
      xeonId: execXeon ? ex.id : [...guildXeonMap(guild.id).keys()][0],
      detail: `Detected **${action}** while Xeon/backup bot activity is in play.`,
    });
    return true;
  };

  client.on(Events.ChannelDelete, async (channel) => {
    try {
      if (!channel.guild) return;
      await maybeXeonCounter(channel.guild, 'channelDelete', channel.id, AuditLogEvent.ChannelDelete);
    } catch (_) {}
  });
  client.on(Events.ChannelCreate, async (channel) => {
    try {
      if (!channel.guild) return;
      await maybeXeonCounter(channel.guild, 'channelCreate', channel.id, AuditLogEvent.ChannelCreate);
    } catch (_) {}
  });
  client.on(Events.GuildRoleDelete, async (role) => {
    try {
      await maybeXeonCounter(role.guild, 'roleDelete', role.id, AuditLogEvent.RoleDelete);
    } catch (_) {}
  });
  client.on(Events.GuildRoleCreate, async (role) => {
    try {
      await maybeXeonCounter(role.guild, 'roleCreate', role.id, AuditLogEvent.RoleCreate);
    } catch (_) {}
  });

  // ---- Protect Rex role from being stripped / deleted ----
  client.on(Events.GuildRoleUpdate, async (oldRole, newRole) => {
    try {
      if (!guardianEnabled()) return;
      const me = newRole.guild.members.me;
      if (!me?.roles.cache.has(newRole.id)) return;

      // Permissions stripped from Rex role
      const lostAdmin = oldRole.permissions.has(PermissionFlagsBits.Administrator)
        && !newRole.permissions.has(PermissionFlagsBits.Administrator);
      if (lostAdmin || oldRole.permissions.bitfield !== newRole.permissions.bitfield) {
        const ex = await fetchExecutor(newRole.guild, AuditLogEvent.RoleUpdate, newRole.id);
        await fortifyBotRole(newRole.guild, me);
        if (ex?.id && ex.id !== client.user.id) {
          await punishRoleAttacker(client, newRole.guild, ex.id, 'Tried to weaken / edit Rex role permissions');
        }
      }

      // Position lowered
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
      // If a role Rex had is deleted — alert (can't undelete)
      // Detect via audit if someone deleted a high role while targeting protection
      const me = role.guild.members.me;
      if (!me) return;
      const ex = await fetchExecutor(role.guild, AuditLogEvent.RoleDelete, role.id);
      // If executor tried to delete roles and also recently touched bot — handled by xeon/nuke paths
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

      // Re-add editable roles we lost
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

  // Kicked / removed from guild
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
  guildHasXeon,
  xeonWatch,
};
