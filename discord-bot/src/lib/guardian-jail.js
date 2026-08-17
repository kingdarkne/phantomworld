/**
 * Rex Guardian jail — strip power roles, apply Jail, optional timeout.
 * Never jails the server owner / configured owners / Rex itself.
 */
const {
  PermissionFlagsBits,
  ChannelType,
} = require('discord.js');
const { ownerIds } = require('./guardian-alerts');

function envInt(name, fallback) {
  const n = Number(process.env[name]);
  return Number.isFinite(n) ? n : fallback;
}

function envList(name) {
  return String(process.env[name] || '')
    .split(/[,\s]+/)
    .map((s) => s.trim())
    .filter(Boolean);
}

const DEFAULT_JAIL_NAME = 'Jail';

function jailRoleIds() {
  return envList('GUARDIAN_JAIL_ROLE_IDS');
}

function isOwnerProtected(userId) {
  if (!userId) return true;
  const owners = new Set([
    ...ownerIds(),
    ...envList('OWNER_IDS'),
    '413173364216168449', // Erica / night_phanton23 fallback
  ]);
  return owners.has(userId);
}

async function ensureJailRole(guild) {
  for (const id of jailRoleIds()) {
    const existing = guild.roles.cache.get(id);
    if (existing) return existing;
  }

  let role =
    guild.roles.cache.find((r) => /^jail$/i.test(r.name)) ||
    guild.roles.cache.find((r) => /jail|prison|detain/i.test(r.name));

  if (role) return role;

  const me = guild.members.me;
  if (!me?.permissions?.has(PermissionFlagsBits.ManageRoles)) {
    throw new Error('Rex needs Manage Roles to create Jail');
  }

  role = await guild.roles.create({
    name: process.env.GUARDIAN_JAIL_ROLE_NAME || DEFAULT_JAIL_NAME,
    colors: { primary: 0x111827 },
    hoist: true,
    mentionable: false,
    permissions: [],
    reason: 'Rex Guardian: create Jail role',
  });

  // Deny speak/send on text + voice channels we can edit (best-effort, batched)
  const denyJobs = [];
  for (const ch of guild.channels.cache.values()) {
    if (![
      ChannelType.GuildText,
      ChannelType.GuildAnnouncement,
      ChannelType.GuildVoice,
      ChannelType.GuildStageVoice,
      ChannelType.GuildForum,
      ChannelType.GuildCategory,
    ].includes(ch.type)) continue;
    denyJobs.push(
      ch.permissionOverwrites
        .edit(role.id, {
          ViewChannel: false,
          SendMessages: false,
          AddReactions: false,
          Connect: false,
          Speak: false,
          SendMessagesInThreads: false,
          CreatePublicThreads: false,
          CreatePrivateThreads: false,
        })
        .catch(() => {}),
    );
  }
  const batch = 15;
  for (let i = 0; i < denyJobs.length; i += batch) {
    await Promise.all(denyJobs.slice(i, i + batch));
  }

  return role;
}

/**
 * Jail a member (human). For bots, prefer kick via punish — this still strips + kicks.
 * @param {{ force?: boolean, timeoutMs?: number, kickBots?: boolean }} options
 *   force — jail even if they have trusted/co-founder roles (NOT owners)
 */
async function jailMember(client, guild, userId, reason, options = {}) {
  const force = options.force === true;
  const kickBots = options.kickBots !== false;
  const timeoutMs = options.timeoutMs ?? envInt('GUARDIAN_JAIL_TIMEOUT_MS', 24 * 60 * 60 * 1000);

  if (!userId) return { skipped: true, reason: 'no_id' };
  if (userId === client.user?.id) return { skipped: true, reason: 'self' };
  if (isOwnerProtected(userId)) return { skipped: true, reason: 'owner' };

  let member = guild.members.cache.get(userId);
  if (!member) {
    try {
      member = await guild.members.fetch(userId);
    } catch (_) {}
  }

  if (!member) {
    // Not in guild — try ban as last resort for nukers who left
    return { skipped: true, reason: 'not_in_guild' };
  }

  const me = guild.members.me || (await guild.members.fetchMe().catch(() => null));
  if (me && member.roles.highest.position >= me.roles.highest.position) {
    return { skipped: true, reason: 'hierarchy' };
  }

  // Bots that nuke: kick them (jail role is for humans)
  if (member.user.bot && kickBots) {
    try {
      await member.kick(`[Guardian Jail] ${reason}`.slice(0, 512));
      return { ok: true, action: 'kick_bot', userId };
    } catch (err) {
      return { ok: false, reason: err.message };
    }
  }

  let jailRole;
  try {
    jailRole = await ensureJailRole(guild);
  } catch (err) {
    return { ok: false, reason: `jail_role: ${err.message}` };
  }

  const kept = new Set([guild.id, jailRole.id]);
  const removable = member.roles.cache.filter((r) => !kept.has(r.id) && r.editable);
  if (removable.size) {
    await member.roles.remove(removable, `[Guardian Jail] ${reason}`).catch(() => {});
  }

  if (!member.roles.cache.has(jailRole.id)) {
    await member.roles.add(jailRole, `[Guardian Jail] ${reason}`).catch(() => {});
  }

  if (timeoutMs > 0 && me?.permissions?.has(PermissionFlagsBits.ModerateMembers)) {
    const capped = Math.min(timeoutMs, 28 * 24 * 60 * 60 * 1000);
    await member.timeout(capped, `[Guardian Jail] ${reason}`.slice(0, 512)).catch(() => {});
  }

  return {
    ok: true,
    action: 'jail',
    userId,
    jailRoleId: jailRole.id,
    force,
    stripped: removable.size,
  };
}

module.exports = {
  ensureJailRole,
  jailMember,
  isOwnerProtected,
};
