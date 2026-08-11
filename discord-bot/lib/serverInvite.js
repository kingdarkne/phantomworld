import fs from 'fs';
import path from 'path';
import { ActionRowBuilder, ButtonBuilder, ButtonStyle, EmbedBuilder } from 'discord.js';
import { getStatus } from './fivem.js';
import { displayServerName, joinUrl } from './branding.js';

const COOLDOWN_HOURS = Number(process.env.SERVER_INVITE_DM_COOLDOWN_HOURS || 168);
const stateFile = path.join(process.cwd(), 'data', 'invite-broadcast.json');

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export function buildInviteEmbed(status) {
  const name = displayServerName(status);
  const link = joinUrl();
  const players = status?.playerCount ?? 0;
  const max = status?.maxPlayers ?? 48;

  const embed = new EmbedBuilder()
    .setColor(0x8b5cf6)
    .setTitle(`Join ${name}`)
    .setDescription(
      [
        `Our **FiveM roleplay server** is live — come hang out in Los Santos!`,
        '',
        link ? `**Connect:** ${link}` : '',
        `**Players online:** ${players}/${max}`,
        '',
        'Open FiveM → **Play** → paste the link above, or use **Connect** in the server browser.',
        '',
        '_Hope to see you in-city soon!_',
      ]
        .filter(Boolean)
        .join('\n'),
    )
    .setFooter({ text: name })
    .setTimestamp();

  const components = [];
  if (link) {
    components.push(
      new ActionRowBuilder().addComponents(
        new ButtonBuilder().setLabel(`Join ${name}`).setStyle(ButtonStyle.Link).setURL(link),
      ),
    );
  }

  return { embeds: [embed], components };
}

function loadState() {
  try {
    return JSON.parse(fs.readFileSync(stateFile, 'utf8'));
  } catch {
    return {};
  }
}

function saveState(state) {
  fs.mkdirSync(path.dirname(stateFile), { recursive: true });
  fs.writeFileSync(stateFile, JSON.stringify(state, null, 2));
}

function onCooldown(guildId) {
  if (process.env.FORCE_SERVER_INVITE_DM === '1') return false;
  const state = loadState();
  const last = state[guildId];
  if (!last) return false;
  const hours = (Date.now() - last) / 3_600_000;
  return hours < COOLDOWN_HOURS;
}

function markSent(guildId) {
  const state = loadState();
  state[guildId] = Date.now();
  saveState(state);
}

/**
 * DM every non-bot member in a guild (skips users with DMs closed).
 */
export async function broadcastServerInviteDms(client, guildId, { onProgress } = {}) {
  if (onCooldown(guildId)) {
    return { skippedCooldown: true, sent: 0, failed: 0, bots: 0 };
  }

  const guild = await client.guilds.fetch(guildId);
  const members = await guild.members.fetch();
  console.log(
    `[invite] Member list: ${members.size} fetched (${guild.memberCount} in guild, ${members.filter((m) => m.user.bot).size} bots)`,
  );

  const status = await getStatus();
  const payload = buildInviteEmbed(status);

  let sent = 0;
  let failed = 0;
  let bots = 0;

  for (const [, member] of members) {
    if (member.user.bot) {
      bots += 1;
      continue;
    }

    try {
      await member.send(payload);
      sent += 1;
      if (onProgress) onProgress({ sent, failed, member: member.user.tag });
      await sleep(Number(process.env.SERVER_INVITE_DM_DELAY_MS || 1500));
    } catch {
      failed += 1;
    }
  }

  markSent(guildId);
  return { sent, failed, bots, serverName: displayServerName(status), link: joinUrl() };
}

export async function maybeAutoInviteBroadcast(client) {
  if (process.env.SERVER_INVITE_DM_ON_START !== '1') return null;

  const guildId = process.env.DISCORD_GUILD_ID || process.env.GUILD_ID;
  if (!guildId) {
    console.warn('[invite] DISCORD_GUILD_ID not set — skip auto DM broadcast');
    return null;
  }

  if (onCooldown(guildId)) {
    console.log('[invite] Auto DM broadcast on cooldown');
    return null;
  }

  console.log('[invite] Starting auto DM broadcast to guild members...');
  const result = await broadcastServerInviteDms(client, guildId, {
    onProgress: ({ sent }) => {
      if (sent % 25 === 0) console.log(`[invite] DMs sent: ${sent}`);
    },
  });
  console.log('[invite] Broadcast done:', result);
  return result;
}
