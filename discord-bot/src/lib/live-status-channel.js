const fs = require('fs');
const path = require('path');
const { ActionRowBuilder, ButtonBuilder, ButtonStyle, EmbedBuilder } = require('discord.js');
const { getPhantomStatus } = require('../../aio-bridge/fivem-status');

const pollSeconds = Number(process.env.STATUS_LIVE_POLL_SECONDS || 60);
const stateFile = path.join(process.cwd(), 'data', 'live-status.json');

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

function cfxJoinId() {
  return process.env.CFX_SERVER_ID || '';
}

function buildPayload(status) {
  const joinId = cfxJoinId();
  const name =
    process.env.PHANTOM_SERVER_NAME || status.serverName || 'Phantom World';
  const online = (status.playerCount ?? 0) > 0;
  const embed = new EmbedBuilder()
    .setColor(0x8b5cf6)
    .setTitle(`${name} — Live Server Status`)
    .setDescription(
      `${online ? '🟢 Server online' : '🟡 Server online — waiting for players'}\n` +
        `**Players:** ${status.playerCount ?? 0}/${status.maxPlayers ?? 48}\n` +
        (joinId ? `[Connect on FiveM](https://cfx.re/join/${joinId})` : ''),
    )
    .setTimestamp();

  const components = [];
  if (joinId) {
    components.push(
      new ActionRowBuilder().addComponents(
        new ButtonBuilder()
          .setLabel('Join Server')
          .setStyle(ButtonStyle.Link)
          .setURL(`https://cfx.re/join/${joinId}`),
      ),
    );
  }

  return { embeds: [embed], components };
}

async function upsertStatusMessage(client, channelId, { pin = true } = {}) {
  const channel = await client.channels.fetch(channelId);
  if (!channel?.isTextBased()) throw new Error('Channel is not a text channel');

  const perms = channel.permissionsFor(client.user);
  if (!perms?.has(['ViewChannel', 'SendMessages', 'EmbedLinks'])) {
    throw new Error('Bot needs View Channel, Send Messages, and Embed Links');
  }

  const status = await getPhantomStatus();
  const payload = buildPayload(status);
  const state = loadState();
  const key = String(channelId);

  if (state[key]?.messageId) {
    try {
      const msg = await channel.messages.fetch(state[key].messageId);
      await msg.edit(payload);
      return msg;
    } catch {
      delete state[key];
    }
  }

  const msg = await channel.send(payload);
  if (pin && perms.has('ManageMessages')) {
    try {
      await msg.pin();
    } catch {
      // non-fatal
    }
  }

  state[key] = { messageId: msg.id };
  saveState(state);
  return msg;
}

function startLiveStatusChannel(client) {
  const channelId =
    process.env.DISCORD_STATUS_CHANNEL_ID || process.env.FIVEM_STATUS_CHANNEL_ID || '';
  if (!channelId) {
    console.warn('[live-status] DISCORD_STATUS_CHANNEL_ID not set — disabled');
    return;
  }

  const tick = async () => {
    try {
      await upsertStatusMessage(client, channelId, { pin: false });
    } catch (err) {
      console.warn('[live-status] refresh failed:', err.message);
    }
  };

  tick();
  setInterval(tick, Math.max(pollSeconds, 30) * 1000);
  console.log(`[live-status] channel ${channelId} every ${pollSeconds}s`);
}

module.exports = { startLiveStatusChannel, upsertStatusMessage };
