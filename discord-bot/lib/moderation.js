import fs from 'fs';
import path from 'path';
import { EmbedBuilder, PermissionFlagsBits, ChannelType } from 'discord.js';

const warnFile = path.join(process.cwd(), 'data', 'warnings.json');

function loadWarnings() {
  try {
    return JSON.parse(fs.readFileSync(warnFile, 'utf8'));
  } catch {
    return {};
  }
}

function saveWarnings(data) {
  fs.mkdirSync(path.dirname(warnFile), { recursive: true });
  fs.writeFileSync(warnFile, JSON.stringify(data, null, 2));
}

function guildWarns(guildId) {
  const data = loadWarnings();
  if (!data[guildId]) data[guildId] = {};
  return { data, guild: data[guildId] };
}

function modEmbed(title, description, color = 0xef4444) {
  return new EmbedBuilder().setColor(color).setTitle(title).setDescription(description).setTimestamp();
}

export function memberHas(member, flag) {
  return member?.permissions?.has?.(flag) ?? false;
}

export async function modBan({ guild, moderator, targetUser, reason = 'No reason provided', deleteDays = 0 }) {
  if (!memberHas(moderator, PermissionFlagsBits.BanMembers)) {
    throw new Error('You need **Ban Members** permission.');
  }
  const me = guild.members.me;
  if (!me?.permissions?.has(PermissionFlagsBits.BanMembers)) {
    throw new Error('I need **Ban Members** permission.');
  }

  let member = null;
  try {
    member = await guild.members.fetch(targetUser.id);
  } catch {
    // user may not be in guild — ban by id still works
  }
  if (member) {
    if (!member.bannable) throw new Error('I cannot ban that member (role hierarchy).');
    if (member.id === moderator.id) throw new Error("You can't ban yourself.");
    if (member.permissions.has(PermissionFlagsBits.BanMembers)) {
      throw new Error("You can't ban another moderator.");
    }
  }

  try {
    await targetUser.send({
      embeds: [
        modEmbed(
          `Banned from ${guild.name}`,
          `**By:** ${moderator.user.tag}\n**Reason:** ${reason}`,
        ),
      ],
    });
  } catch {
    // DMs closed
  }

  await guild.members.ban(targetUser.id, {
    reason: `${reason} · by ${moderator.user.tag}`,
    deleteMessageSeconds: Math.min(Math.max(Number(deleteDays) || 0, 0), 7) * 86400,
  });

  return modEmbed('Member banned', `**User:** ${targetUser.tag} (\`${targetUser.id}\`)\n**Reason:** ${reason}`);
}

export async function modUnban({ guild, moderator, userId, reason = 'No reason provided' }) {
  if (!memberHas(moderator, PermissionFlagsBits.BanMembers)) {
    throw new Error('You need **Ban Members** permission.');
  }
  await guild.members.unban(userId, `${reason} · by ${moderator.user.tag}`);
  return modEmbed('Member unbanned', `**User ID:** \`${userId}\`\n**Reason:** ${reason}`, 0x10b981);
}

export async function modKick({ guild, moderator, targetUser, reason = 'No reason provided' }) {
  if (!memberHas(moderator, PermissionFlagsBits.KickMembers)) {
    throw new Error('You need **Kick Members** permission.');
  }
  const member = await guild.members.fetch(targetUser.id);
  if (!member.kickable) throw new Error('I cannot kick that member (role hierarchy).');
  if (member.id === moderator.id) throw new Error("You can't kick yourself.");

  try {
    await targetUser.send({
      embeds: [modEmbed(`Kicked from ${guild.name}`, `**By:** ${moderator.user.tag}\n**Reason:** ${reason}`)],
    });
  } catch {
    // ignore
  }
  await member.kick(`${reason} · by ${moderator.user.tag}`);
  return modEmbed('Member kicked', `**User:** ${targetUser.tag}\n**Reason:** ${reason}`);
}

export async function modTimeout({ guild, moderator, targetUser, minutes, reason = 'No reason provided' }) {
  if (!memberHas(moderator, PermissionFlagsBits.ModerateMembers)) {
    throw new Error('You need **Timeout Members** permission.');
  }
  const mins = Number(minutes);
  if (!Number.isFinite(mins) || mins < 1 || mins > 40320) {
    throw new Error('Timeout must be between 1 and 40320 minutes (28 days).');
  }
  const member = await guild.members.fetch(targetUser.id);
  if (!member.moderatable) throw new Error('I cannot timeout that member.');
  await member.timeout(mins * 60_000, `${reason} · by ${moderator.user.tag}`);
  return modEmbed(
    'Member timed out',
    `**User:** ${targetUser.tag}\n**Duration:** ${mins} minute(s)\n**Reason:** ${reason}`,
    0xf59e0b,
  );
}

export async function modClearTimeout({ guild, moderator, targetUser }) {
  if (!memberHas(moderator, PermissionFlagsBits.ModerateMembers)) {
    throw new Error('You need **Timeout Members** permission.');
  }
  const member = await guild.members.fetch(targetUser.id);
  await member.timeout(null);
  return modEmbed('Timeout removed', `**User:** ${targetUser.tag}`, 0x10b981);
}

export async function modWarn({ guildId, moderator, targetUser, reason = 'No reason provided' }) {
  if (
    !memberHas(moderator, PermissionFlagsBits.ModerateMembers) &&
    !memberHas(moderator, PermissionFlagsBits.KickMembers)
  ) {
    throw new Error('You need **Timeout** or **Kick Members** permission.');
  }
  const { data, guild } = guildWarns(guildId);
  if (!guild[targetUser.id]) guild[targetUser.id] = [];
  const entry = {
    id: `${Date.now()}`,
    reason,
    modId: moderator.id,
    modTag: moderator.user.tag,
    at: new Date().toISOString(),
  };
  guild[targetUser.id].push(entry);
  saveWarnings(data);

  try {
    await targetUser.send({
      embeds: [
        modEmbed('You received a warning', `**Server:** warning recorded\n**By:** ${moderator.user.tag}\n**Reason:** ${reason}`, 0xf59e0b),
      ],
    });
  } catch {
    // ignore
  }

  return modEmbed(
    'Warning issued',
    `**User:** ${targetUser.tag}\n**Reason:** ${reason}\n**Total warnings:** ${guild[targetUser.id].length}`,
    0xf59e0b,
  );
}

export function modWarnings({ guildId, targetUser }) {
  const { guild } = guildWarns(guildId);
  const list = guild[targetUser.id] || [];
  if (!list.length) {
    return modEmbed('Warnings', `${targetUser.tag} has **0** warnings.`, 0x94a3b8);
  }
  const lines = list
    .slice(-15)
    .map((w, i) => `**${i + 1}.** ${w.reason} — _${w.modTag}_ (<t:${Math.floor(new Date(w.at).getTime() / 1000)}:R>)`)
    .join('\n');
  return modEmbed(`Warnings · ${targetUser.tag}`, lines, 0xf59e0b);
}

export async function modClear({ channel, moderator, amount, targetUser = null }) {
  if (!memberHas(moderator, PermissionFlagsBits.ManageMessages)) {
    throw new Error('You need **Manage Messages** permission.');
  }
  const n = Math.min(Math.max(Number(amount) || 0, 1), 100);
  const fetched = await channel.messages.fetch({ limit: 100 });
  let toDelete = [...fetched.values()];
  if (targetUser) toDelete = toDelete.filter((m) => m.author.id === targetUser.id);
  toDelete = toDelete.slice(0, n);
  const deleted = await channel.bulkDelete(toDelete, true);
  return modEmbed('Messages cleared', `Deleted **${deleted.size}** message(s).`, 0x10b981);
}

export async function modLock({ channel, moderator, lock = true }) {
  if (!memberHas(moderator, PermissionFlagsBits.ManageChannels)) {
    throw new Error('You need **Manage Channels** permission.');
  }
  if (channel.type !== ChannelType.GuildText && channel.type !== ChannelType.GuildAnnouncement) {
    throw new Error('Only text channels can be locked.');
  }
  await channel.permissionOverwrites.edit(channel.guild.roles.everyone, {
    SendMessages: lock ? false : null,
  });
  return modEmbed(
    lock ? 'Channel locked' : 'Channel unlocked',
    `${channel} is now **${lock ? 'locked' : 'unlocked'}**.`,
    lock ? 0xef4444 : 0x10b981,
  );
}
