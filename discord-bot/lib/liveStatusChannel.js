import fs from 'fs';
import path from 'path';
import { ActionRowBuilder, ButtonBuilder, ButtonStyle } from 'discord.js';
import { getStatus, buildStatusEmbed } from './fivem.js';

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
  const online = (status.playerCount ?? 0) > 0;
  const embed = buildStatusEmbed(status)
    .setTitle('Phantom World — Live Server Status')
    .setDescription(
      `${online ? 'Server online' : 'Server online — waiting for players'}\n` +
        (joinId ? `[Connect on FiveM](https://cfx.re/join/${joinId})` : ''),
    );

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
  if (!channel?.isTextBased()) {
    throw new Error('Channel is not a text channel');
  }

  const perms = channel.permissionsFor(client.user);
  if (!perms?.has(['ViewChannel', 'SendMessages', 'EmbedLinks'])) {
    throw new Error('Bot needs View Channel, Send Messages, and Embed Links');
  }

  const status = await getStatus();
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

export function startLiveStatusChannel(client) {
  const channelId =
    process.env.DISCORD_STATUS_CHANNEL_ID || process.env.FIVEM_STATUS_CHANNEL_ID || '';
  if (!channelId) {
    console.warn('DISCORD_STATUS_CHANNEL_ID not set — live status channel disabled');
    return;
  }

  const tick = async () => {
    try {
      await upsertStatusMessage(client, channelId, { pin: false });
    } catch (err) {
      console.warn('Live status channel update failed:', err.message);
    }
  };

  console.log(`Live status channel: #${channelId} (every ${pollSeconds}s)`);
  tick();
  setInterval(tick, pollSeconds * 1000);
}

export async function setupLiveStatusInChannel(client, channelId, { pin = true } = {}) {
  return upsertStatusMessage(client, channelId, { pin });
}
