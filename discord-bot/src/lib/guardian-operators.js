/**
 * Track who invited bots + who recently ran .clear / purge / nuke-style commands,
 * so when a bot deletes channels Rex can jail the human operator (not just the bot).
 */
const { Events, AuditLogEvent, PermissionFlagsBits } = require('discord.js');
const { memberHasCoOwnerRole } = require('./ensure-staff-roles');
const { jailMember, isOwnerProtected } = require('./guardian-jail');
const { postGuardianAlert } = require('./guardian-alerts');

function envInt(name, fallback) {
  const n = Number(process.env[name]);
  return Number.isFinite(n) ? n : fallback;
}

/** guildId -> Map(botId -> { invitedBy, taggedAt, tag }) */
const botInviters = new Map();

/** guildId -> [{ userId, tag, content, at, channelId }] */
const dangerCommands = new Map();

const DANGER_CMD_RE = new RegExp(
  String.raw`(?:^|\s)[.!$/]*(?:clear|purge|nuke|wipe|massdelete|mass-delete|deleteall|delete-all|destroy|raid)\b`,
  'i',
);

function guildInviterMap(guildId) {
  if (!botInviters.has(guildId)) botInviters.set(guildId, new Map());
  return botInviters.get(guildId);
}

function guildDangerList(guildId) {
  if (!dangerCommands.has(guildId)) dangerCommands.set(guildId, []);
  return dangerCommands.get(guildId);
}

function rememberBotInviter(guildId, botId, invitedBy, tag) {
  if (!guildId || !botId) return;
  guildInviterMap(guildId).set(botId, {
    invitedBy: invitedBy || null,
    taggedAt: Date.now(),
    tag: tag || null,
  });
}

function forgetBot(guildId, botId) {
  guildInviterMap(guildId).delete(botId);
}

function recordDangerCommand(message) {
  if (!message?.guild || !message.author || message.author.bot) return false;
  const content = String(message.content || '').trim();
  if (!content || !DANGER_CMD_RE.test(content)) return false;

  const list = guildDangerList(message.guild.id);
  list.push({
    userId: message.author.id,
    tag: message.author.tag,
    content: content.slice(0, 120),
    at: Date.now(),
    channelId: message.channelId,
  });
  // keep last ~40
  while (list.length > 40) list.shift();
  console.log(
    `[guardian-operators] danger cmd by ${message.author.tag}: ${content.slice(0, 80)}`,
  );
  return true;
}

function recentDangerOperators(guildId, windowMs = 120_000) {
  const now = Date.now();
  const list = guildDangerList(guildId).filter((e) => now - e.at <= windowMs);
  // unique, newest first
  const seen = new Set();
  const out = [];
  for (let i = list.length - 1; i >= 0; i -= 1) {
    const e = list[i];
    if (seen.has(e.userId)) continue;
    seen.add(e.userId);
    out.push(e);
  }
  return out;
}

async function resolveBotInviter(guild, botId) {
  const cached = guildInviterMap(guild.id).get(botId);
  if (cached?.invitedBy) return cached.invitedBy;
  try {
    if (!guild.members.me?.permissions?.has(PermissionFlagsBits.ViewAuditLog)) {
      return null;
    }
    const logs = await guild.fetchAuditLogs({ type: AuditLogEvent.BotAdd, limit: 6 });
    const now = Date.now();
    for (const entry of logs.entries.values()) {
      if (entry.target?.id && entry.target.id !== botId) continue;
      // BotAdd may be older than 15s — accept up to 30 days for inviter lookup
      if (now - entry.createdTimestamp > 30 * 24 * 60 * 60 * 1000) continue;
      if (entry.executor?.id) {
        rememberBotInviter(guild.id, botId, entry.executor.id, null);
        return entry.executor.id;
      }
    }
  } catch (_) {}
  return null;
}

/**
 * After a bot is banned for nuke: jail humans who ran .clear/.purge and/or
 * Co-Owner/Co-Founder who invited or operated the bot.
 */
async function jailOperatorsForBotNuke(client, guild, botId, reason) {
  const windowMs = envInt('GUARDIAN_CLEAR_CMD_WINDOW_MS', 180_000);
  const operators = new Map(); // userId -> why

  for (const op of recentDangerOperators(guild.id, windowMs)) {
    operators.set(op.userId, `ran danger command: ${op.content}`);
  }

  const inviterId = await resolveBotInviter(guild, botId);
  if (inviterId) {
    let inviter = guild.members.cache.get(inviterId);
    if (!inviter) {
      try {
        inviter = await guild.members.fetch(inviterId);
      } catch (_) {}
    }
    if (inviter && memberHasCoOwnerRole(inviter)) {
      operators.set(
        inviterId,
        operators.get(inviterId)
          ? `${operators.get(inviterId)}; invited nuking bot`
          : 'Co-Owner/Co-Founder invited nuking bot',
      );
    } else if (inviterId && !isOwnerProtected(inviterId)) {
      // Non-owner inviter also accountable when their bot nukes
      if (!operators.has(inviterId)) {
        operators.set(inviterId, 'invited nuking bot');
      }
    }
  }

  // Any Co-Owner who used a danger command in-window is always included (already from list)
  const jailed = [];
  const skipped = [];

  for (const [userId, why] of operators.entries()) {
    if (isOwnerProtected(userId)) {
      skipped.push({ userId, reason: 'owner' });
      continue;
    }
    if (userId === botId) continue;

    const jailReason = `${reason} — operator: ${why}`;
    const result = await jailMember(client, guild, userId, jailReason, {
      force: true,
      kickBots: false,
    });
    if (result.ok) {
      jailed.push({ userId, action: result.action, why, stripped: result.stripped });
    } else {
      skipped.push({ userId, reason: result.reason || 'jail_failed', why });
    }
  }

  if (jailed.length || operators.size) {
    await postGuardianAlert(client, {
      level: 'critical',
      title: 'Operators jailed for bot nuke / .clear',
      description: [
        `Bot <@${botId}> nuked. Rex jails the **human** who ran \`.clear\` / purge / nuke commands — not only the bot.`,
        '',
        jailed.length
          ? jailed.map((j) => `• <@${j.userId}> → **${j.action}** (${j.why})`).join('\n')
          : '_No humans jailed (none matched / owner-protected)._',
        skipped.length
          ? `\nSkipped: ${skipped.map((s) => `<@${s.userId}> (${s.reason})`).join(', ')}`
          : '',
      ].join('\n'),
      pingOwner: true,
    });
  }

  forgetBot(guild.id, botId);
  return { jailed, skipped, operators: [...operators.keys()] };
}

function registerOperatorWatch(client) {
  client.on(Events.MessageCreate, (message) => {
    try {
      recordDangerCommand(message);
    } catch (_) {}
  });
  console.log('[guardian-operators] .clear / purge operator watch armed');
}

module.exports = {
  rememberBotInviter,
  forgetBot,
  recordDangerCommand,
  recentDangerOperators,
  jailOperatorsForBotNuke,
  registerOperatorWatch,
  botInviters,
  DANGER_CMD_RE,
};
