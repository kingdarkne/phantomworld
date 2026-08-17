/**
 * Keep Member auto-assigned and Co-Founder able to invite/add bots (Manage Server).
 */
const { Events, PermissionFlagsBits } = require('discord.js');

const DEFAULT_COFOUNDER_IDS = ['1472295497149579491'];
const DEFAULT_MEMBER_IDS = ['1522386919902937210'];

function envList(name) {
  return String(process.env[name] || '')
    .split(/[,\s]+/)
    .map((s) => s.trim())
    .filter(Boolean);
}

function cofounderRoleIds() {
  const fromEnv = envList('COFOUNDER_ROLE_IDS');
  return fromEnv.length ? fromEnv : DEFAULT_COFOUNDER_IDS;
}

function memberRoleIds() {
  const fromEnv = envList('MEMBER_ROLE_IDS');
  return fromEnv.length ? fromEnv : DEFAULT_MEMBER_IDS;
}

function findMemberRole(guild) {
  for (const id of memberRoleIds()) {
    const byId = guild.roles.cache.get(id);
    if (byId) return byId;
  }
  return (
    guild.roles.cache.find((r) => /^member$/i.test(r.name)) ||
    guild.roles.cache.find((r) => /^members$/i.test(r.name)) ||
    guild.roles.cache.find((r) => /member/i.test(r.name) && !/staff|mod|admin|bot/i.test(r.name))
  );
}

function findCofounderRoles(guild) {
  const roles = [];
  for (const id of cofounderRoleIds()) {
    const r = guild.roles.cache.get(id);
    if (r) roles.push(r);
  }
  if (!roles.length) {
    const byName = guild.roles.cache.find((r) => /^co[- ]?founder$/i.test(r.name));
    if (byName) roles.push(byName);
  }
  return roles;
}

/** Perms needed so Co-Founder can authorize bot OAuth / integrations. */
const BOT_INVITE_PERMS = [
  PermissionFlagsBits.ManageGuild,
  PermissionFlagsBits.CreateInstantInvite,
  PermissionFlagsBits.ManageWebhooks,
];

async function ensureCofounderCanAddBots(guild) {
  const changes = [];
  if (!guild.members.me?.permissions?.has(PermissionFlagsBits.ManageRoles)) {
    return changes;
  }

  for (const role of findCofounderRoles(guild)) {
    if (!role.editable) continue;
    const missing = BOT_INVITE_PERMS.filter((p) => !role.permissions.has(p));
    if (!missing.length) continue;
    try {
      await role.setPermissions(role.permissions.add(...missing), 'Rex: Co-Founder can add bots');
      changes.push(`cofounder:${role.name}: +ManageGuild/invite`);
    } catch (err) {
      console.warn('[ensure-staff-roles] cofounder perms', guild.id, role.id, err.message);
    }
  }
  return changes;
}

async function ensureEveryoneHasMemberRole(guild) {
  const role = findMemberRole(guild);
  if (!role || !role.editable) return { role: role?.name || null, given: 0 };

  let given = 0;
  try {
    await guild.members.fetch();
  } catch (_) {}

  for (const member of guild.members.cache.values()) {
    if (member.user.bot) continue;
    if (member.roles.cache.has(role.id)) continue;
    try {
      await member.roles.add(role, 'Rex: ensure Member role');
      given += 1;
    } catch (_) {}
  }
  return { role: role.name, given };
}

async function syncGuildStaffRoles(guild) {
  const cof = await ensureCofounderCanAddBots(guild);
  const mem = await ensureEveryoneHasMemberRole(guild);
  if (cof.length || mem.given) {
    console.log(
      `[ensure-staff-roles] ${guild.name}: cofounder=${cof.join(',') || 'ok'} member=${mem.role} given=${mem.given}`,
    );
  }
  return { cof, mem };
}

function registerEnsureStaffRoles(client) {
  const run = async () => {
    for (const guild of client.guilds.cache.values()) {
      try {
        await syncGuildStaffRoles(guild);
      } catch (err) {
        console.warn('[ensure-staff-roles]', guild.id, err.message);
      }
    }
  };

  const start = () => {
    run().catch(() => {});
    const ms = Math.max(60_000, Number(process.env.ENSURE_STAFF_ROLES_MS || 300_000) || 300_000);
    setInterval(() => run().catch(() => {}), ms);
    console.log('[ensure-staff-roles] Member + Co-Founder bot-invite sync armed');
  };

  if (client.isReady?.() || client.readyAt) start();
  else client.once(Events.ClientReady, start);
}

module.exports = {
  registerEnsureStaffRoles,
  syncGuildStaffRoles,
  ensureCofounderCanAddBots,
  ensureEveryoneHasMemberRole,
  findMemberRole,
};
