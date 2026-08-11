const fs = require('fs');
const path = require('path');
const { ActionRowBuilder, ButtonBuilder, ButtonStyle, EmbedBuilder } = require('discord.js');
const { getPhantomStatus } = require('../../aio-bridge/fivem-status');

const COOLDOWN_HOURS = Number(process.env.SERVER_INVITE_DM_COOLDOWN_HOURS || 168);
const stateFile = path.join(process.cwd(), 'data', 'invite-broadcast.json');

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function joinUrl() {
  const id = process.env.CFX_SERVER_ID || '';
  return id ? `https://cfx.re/join/${id}` : null;
}

function displayName(status) {
  return (
    process.env.PHANTOM_SERVER_NAME ||
    process.env.FIVEM_DISPLAY_NAME ||
    status?.serverName ||
    'Phantom World'
  );
}

function buildInvitePayload(status) {
  const name = displayName(status);
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

  return { embeds: [embed], components, link };
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
  const last = loadState()[guildId];
  if (!last) return false;
  return (Date.now() - last) / 3_600_000 < COOLDOWN_HOURS;
}

function markSent(guildId) {
  const state = loadState();
  state[guildId] = Date.now();
  saveState(state);
}

async function broadcastServerInviteDms(client, guildId) {
  if (onCooldown(guildId)) {
    return { skippedCooldown: true, sent: 0, failed: 0, bots: 0, link: joinUrl() };
  }

  const guild = await client.guilds.fetch(guildId);
  await guild.members.fetch();
  const status = await getPhantomStatus().catch(() => ({}));
  const payload = buildInvitePayload(status);
  const delay = Number(process.env.SERVER_INVITE_DM_DELAY_MS || 750);

  let sent = 0;
  let failed = 0;
  let bots = 0;

  for (const member of guild.members.cache.values()) {
    if (member.user.bot) {
      bots += 1;
      continue;
    }
    try {
      await member.send(payload);
      sent += 1;
    } catch {
      failed += 1;
    }
    if (delay > 0) await sleep(delay);
  }

  markSent(guildId);
  return { skippedCooldown: false, sent, failed, bots, link: payload.link };
}

async function dmInviteToUserIds(client, rawIds) {
  const ids = [
    ...new Set(
      String(Array.isArray(rawIds) ? rawIds.join(' ') : rawIds)
        .split(/[\s,]+/)
        .map((s) => s.replace(/\D/g, ''))
        .filter((s) => /^\d{15,22}$/.test(s)),
    ),
  ];

  const status = await getPhantomStatus().catch(() => ({}));
  const payload = buildInvitePayload(status);
  const details = [];
  let sent = 0;
  let failed = 0;

  for (const id of ids) {
    try {
      const user = await client.users.fetch(id);
      await user.send(payload);
      sent += 1;
      details.push({ id, tag: user.tag, ok: true });
    } catch (err) {
      failed += 1;
      details.push({ id, ok: false, reason: err.message });
    }
  }

  return { sent, failed, details, link: payload.link };
}

module.exports = {
  broadcastServerInviteDms,
  dmInviteToUserIds,
  buildInvitePayload,
  joinUrl,
};
