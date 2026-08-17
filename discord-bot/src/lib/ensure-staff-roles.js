/**
 * Keep Member auto-assigned and Co-Founder / Co-Owner able to invite/add apps (Manage Server).
 */
const { Events, PermissionFlagsBits } = require('discord.js');

const DEFAULT_COFOUNDER_IDS = ['1472295497149579491'];
/** Legacy Member role — stripped in favor of Phantom | Civilian */
const DEFAULT_MEMBER_IDS = ['1522386919902937210'];
const DEFAULT_CIVILIAN_IDS = ['1472295618935259372'];

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

function civilianRoleIds() {
  const fromEnv = envList('CIVILIAN_ROLE_IDS');
  return fromEnv.length ? fromEnv : DEFAULT_CIVILIAN_IDS;
}

/** Co-Founder / Co-Owner style role names. */
function isCoOwnerRoleName(name) {
  return /^co[- ]?(founder|owner)$/i.test(String(name || '').trim());
}

function findCivilianRole(guild) {
  for (const id of civilianRoleIds()) {
    const byId = guild.roles.cache.get(id);
    if (byId) return byId;
  }
  return (
    guild.roles.cache.find((r) => /phantom\s*\|\s*civilian/i.test(r.name)) ||
    guild.roles.cache.find((r) => /^civilian$/i.test(r.name))
  );
}

function findMemberRole(guild) {
  // Prefer Phantom Civilian as the default join role
  const civ = findCivilianRole(guild);
  if (civ) return civ;
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
  const seen = new Set();
  for (const id of cofounderRoleIds()) {
    const r = guild.roles.cache.get(id);
    if (r && !seen.has(r.id)) {
      roles.push(r);
      seen.add(r.id);
    }
  }
  for (const r of guild.roles.cache.values()) {
    if (seen.has(r.id)) continue;
    if (isCoOwnerRoleName(r.name)) {
      roles.push(r);
      seen.add(r.id);
    }
  }
  return roles;
}

function memberHasCoOwnerRole(member) {
  if (!member?.roles?.cache) return false;
  const ids = new Set(cofounderRoleIds());
  return member.roles.cache.some((r) => ids.has(r.id) || isCoOwnerRoleName(r.name));
}

/** Perms needed so Co-Founder/Co-Owner can authorize app/bot OAuth. */
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
      await role.setPermissions(role.permissions.add(...missing), 'Rex: Co-Owner/Co-Founder can add apps');
      changes.push(`coowner:${role.name}: +ManageGuild/invite`);
    } catch (err) {
      console.warn('[ensure-staff-roles] cofounder perms', guild.id, role.id, err.message);
    }
  }
  return changes;
}

async function ensureEveryoneHasMemberRole(guild) {
  const civilian = findCivilianRole(guild) || findMemberRole(guild);
  const legacyMember = guild.roles.cache.get(memberRoleIds()[0])
    || guild.roles.cache.find((r) => /^member$/i.test(r.name));
  if (!civilian || !civilian.editable) return { role: civilian?.name || null, given: 0, stripped: 0 };

  let given = 0;
  let stripped = 0;
  try {
    await guild.members.fetch();
  } catch (_) {}

  for (const member of guild.members.cache.values()) {
    if (member.user.bot) continue;
    // Remove legacy Member if present
    if (legacyMember && member.roles.cache.has(legacyMember.id) && legacyMember.id !== civilian.id) {
      try {
        await member.roles.remove(legacyMember, 'Rex: replace Member with Phantom Civilian');
        stripped += 1;
      } catch (_) {}
    }
    if (member.roles.cache.has(civilian.id)) continue;
    // Skip jailed
    if (member.roles.cache.some((r) => /^jail$/i.test(r.name))) continue;
    try {
      await member.roles.add(civilian, 'Rex: ensure Phantom Civilian role');
      given += 1;
    } catch (_) {}
  }
  return { role: civilian.name, given, stripped };
}

async function syncGuildStaffRoles(guild) {
  const cof = await ensureCofounderCanAddBots(guild);
  const mem = await ensureEveryoneHasMemberRole(guild);
  if (cof.length || mem.given || mem.stripped) {
    console.log(
      `[ensure-staff-roles] ${guild.name}: cofounder=${cof.join(',') || 'ok'} civilian=${mem.role} given=${mem.given} memberStripped=${mem.stripped || 0}`,
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
    console.log('[ensure-staff-roles] Member + Co-Owner app-invite sync armed');
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
  findCivilianRole,
  findCofounderRoles,
  memberHasCoOwnerRole,
  isCoOwnerRoleName,
  cofounderRoleIds,
};
