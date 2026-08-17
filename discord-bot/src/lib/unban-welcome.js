/**
 * Unban everyone on the guild ban list, DM a welcome-back + invite,
 * and report anyone who could not be DMed.
 */
const { EmbedBuilder, ChannelType, PermissionFlagsBits } = require('discord.js');
const fs = require('fs');
const path = require('path');
const { postGuardianAlert } = require('./guardian-alerts');

const PENDING_FILE = path.join(process.cwd(), 'data', 'unban-pending-welcome.json');

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function withRetry(fn, label) {
  let lastErr;
  for (let attempt = 0; attempt < 4; attempt += 1) {
    try {
      return await fn();
    } catch (err) {
      lastErr = err;
      const retryAfter = Number(err?.retryAfter || err?.data?.retry_after || 0);
      const wait = err?.status === 429
        ? Math.max(1000, Math.ceil((retryAfter || 1) * 1000))
        : 500 * (attempt + 1);
      if (err?.status === 429 || /rate limit/i.test(err?.message || '')) {
        console.warn(`[unban-welcome] rate limit on ${label}, wait ${wait}ms`);
        await sleep(wait);
        continue;
      }
      throw err;
    }
  }
  throw lastErr;
}

function envInt(name, fallback) {
  const n = Number(process.env[name]);
  return Number.isFinite(n) ? n : fallback;
}

async function createGuildInvite(guild, me) {
  const preferredId =
    process.env.GUARDIAN_WELCOME_INVITE_CHANNEL_ID ||
    process.env.DISCORD_INVITE_CHANNEL_ID ||
    guild.systemChannelId ||
    null;

  const candidates = [];
  if (preferredId) {
    const ch = guild.channels.cache.get(preferredId);
    if (ch) candidates.push(ch);
  }
  for (const ch of guild.channels.cache.values()) {
    if (ch.type !== ChannelType.GuildText && ch.type !== ChannelType.GuildAnnouncement) continue;
    if (candidates.some((c) => c.id === ch.id)) continue;
    candidates.push(ch);
  }

  for (const ch of candidates) {
    try {
      const perms = ch.permissionsFor?.(me) || ch.permissionsFor?.(guild.members.me);
      if (perms && !perms.has(PermissionFlagsBits.CreateInstantInvite)) continue;
      const invite = await ch.createInvite({
        maxAge: 0,
        maxUses: 0,
        unique: true,
        reason: 'Rex Guardian: welcome-back invite after mass unban',
      });
      return { url: invite.url, channelId: ch.id, code: invite.code };
    } catch (_) {}
  }
  return { url: null, channelId: null, code: null, error: 'Could not create invite' };
}

function welcomeBackPayload(guild, inviteUrl) {
  const fivem =
    process.env.CFX_SERVER_ID
      ? `https://cfx.re/join/${process.env.CFX_SERVER_ID}`
      : null;

  const embed = new EmbedBuilder()
    .setColor(0x22c55e)
    .setTitle(`Welcome back to ${guild.name}`)
    .setDescription(
      [
        `You've been **unbanned** from **${guild.name}**.`,
        '',
        "We'd love to have you back — here's a fresh invite:",
        inviteUrl ? `**Discord:** ${inviteUrl}` : '_Ask staff for a Discord invite if this link is missing._',
        fivem ? `**FiveM:** ${fivem}` : '',
        '',
        'See you in the city.',
      ]
        .filter(Boolean)
        .join('\n'),
    )
    .setFooter({ text: 'Rex Guardian · Welcome back' })
    .setTimestamp();

  return {
    content: `👋 Welcome back to **${guild.name}**!`,
    embeds: [embed],
  };
}

function loadPending() {
  try {
    return JSON.parse(fs.readFileSync(PENDING_FILE, 'utf8'));
  } catch {
    return {};
  }
}

function savePending(state) {
  fs.mkdirSync(path.dirname(PENDING_FILE), { recursive: true });
  fs.writeFileSync(PENDING_FILE, JSON.stringify(state, null, 2));
}

/** Remember unbanned users we could not DM (no mutual guild) so we welcome on rejoin. */
function queuePendingWelcomes(guildId, entries, inviteUrl) {
  const state = loadPending();
  if (!state[guildId]) state[guildId] = {};
  for (const e of entries) {
    if (!e?.id) continue;
    state[guildId][e.id] = {
      tag: e.tag || null,
      inviteUrl: inviteUrl || null,
      queuedAt: Date.now(),
      reason: e.reason || 'dm failed',
    };
  }
  savePending(state);
}

async function deliverPendingWelcomeOnJoin(member) {
  if (!member || member.user.bot) return false;
  const state = loadPending();
  const guildPending = state[member.guild.id];
  if (!guildPending?.[member.id]) return false;

  const entry = guildPending[member.id];
  const payload = welcomeBackPayload(member.guild, entry.inviteUrl);
  // On rejoin they share a guild — DM usually works now
  try {
    await member.send(payload);
  } catch (err) {
    console.warn('[unban-welcome] rejoin DM failed', member.id, err.message);
    return false;
  }

  delete guildPending[member.id];
  if (!Object.keys(guildPending).length) delete state[member.guild.id];
  savePending(state);
  return true;
}

/** Seed pending list from a finished report (e.g. REST resume job). */
function seedPendingFromReport(guildId, report) {
  if (!report?.dmFailed?.length) return 0;
  queuePendingWelcomes(guildId, report.dmFailed, report.inviteUrl || null);
  return report.dmFailed.length;
}

/**
 * @returns {{
 *   total: number,
 *   unbanned: number,
 *   unbanFailed: Array<{id:string,tag?:string,reason:string}>,
 *   dmOk: number,
 *   dmFailed: Array<{id:string,tag?:string,reason:string}>,
 *   inviteUrl: string|null,
 * }}
 */
async function unbanAllAndWelcome(client, guild, { dryRun = false } = {}) {
  const me = guild.members.me || (await guild.members.fetchMe().catch(() => null));
  if (!me?.permissions?.has(PermissionFlagsBits.BanMembers)) {
    throw new Error('Rex needs Ban Members permission');
  }

  const bans = await guild.bans.fetch();
  const total = bans.size;
  const invite = dryRun ? { url: null } : await createGuildInvite(guild, me);
  const inviteUrl = invite.url || null;
  const payload = welcomeBackPayload(guild, inviteUrl);
  const delay = envInt('GUARDIAN_UNBAN_DELAY_MS', 900);

  const result = {
    total,
    unbanned: 0,
    unbanFailed: [],
    dmOk: 0,
    dmFailed: [],
    inviteUrl,
    dryRun,
  };

  if (dryRun) {
    for (const ban of bans.values()) {
      result.dmFailed.push({
        id: ban.user.id,
        tag: ban.user.tag,
        reason: 'dry-run (not contacted)',
      });
    }
    return result;
  }

  for (const ban of bans.values()) {
    const user = ban.user;
    const id = user.id;
    const tag = user.tag;

    try {
      await withRetry(
        () => guild.members.unban(id, 'Rex Guardian: mass unban + welcome back'),
        `unban:${id}`,
      );
      result.unbanned += 1;
    } catch (err) {
      result.unbanFailed.push({ id, tag, reason: err.message || 'unban failed' });
      if (delay) await sleep(delay);
      continue;
    }

    try {
      await withRetry(() => user.send(payload), `dm:${id}`);
      result.dmOk += 1;
    } catch (err) {
      result.dmFailed.push({
        id,
        tag,
        reason: err.code === 50007 ? 'DMs closed / cannot DM' : err.message || 'DM failed',
      });
    }

    if (delay) await sleep(delay);
  }

  if (result.dmFailed.length) {
    queuePendingWelcomes(guild.id, result.dmFailed, inviteUrl);
    result.pendingOnRejoin = result.dmFailed.length;
  }

  return result;
}

function formatUnbanReport(result) {
  const failLines = result.dmFailed.slice(0, 40).map(
    (f) => `• <@${f.id}> (${f.tag || f.id}) — ${f.reason}`,
  );
  const more = result.dmFailed.length > 40 ? `\n_…and ${result.dmFailed.length - 40} more_` : '';

  return [
    result.dryRun ? '**DRY RUN** — no changes made.' : null,
    `**Ban list:** ${result.total}`,
    `**Unbanned:** ${result.unbanned}`,
    `**Unban failed:** ${result.unbanFailed.length}`,
    `**Welcome DMs sent:** ${result.dmOk}`,
    `**Unable to DM now:** ${result.dmFailed.length}`,
    result.pendingOnRejoin
      ? `**Queued for rejoin DM:** ${result.pendingOnRejoin} (Discord blocks DMs with no mutual server)`
      : null,
    result.inviteUrl ? `**Invite:** ${result.inviteUrl}` : '**Invite:** _could not create_',
    '',
    result.dmFailed.length
      ? ['**Could not DM (will retry when they rejoin):**', ...failLines, more].join('\n')
      : '_Everyone who was unbanned received a DM (or list was empty)._',
  ]
    .filter((x) => x !== null)
    .join('\n');
}

async function reportUnbanResults(client, guild, result, runnerId) {
  await postGuardianAlert(client, {
    level: result.dmFailed.length || result.unbanFailed.length ? 'high' : 'info',
    title: result.dryRun ? 'Unban-all preview (dry run)' : 'Mass unban + welcome-back complete',
    description: [
      runnerId ? `Requested by <@${runnerId}>` : null,
      formatUnbanReport(result),
    ]
      .filter(Boolean)
      .join('\n\n'),
    pingOwner: true,
  });
}

module.exports = {
  unbanAllAndWelcome,
  formatUnbanReport,
  reportUnbanResults,
  createGuildInvite,
  welcomeBackPayload,
  queuePendingWelcomes,
  deliverPendingWelcomeOnJoin,
  seedPendingFromReport,
};
