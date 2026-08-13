/**
 * Phantom FiveM bridge for ALL-IN-ONE-Discord-Bot (CommonJS).
 * Relays FXServer events (including SCRIPT ERROR reports) to Discord.
 * @param {import('discord.js').Client} client
 */
const { EmbedBuilder, REST, Routes, SlashCommandBuilder, WebhookClient } = require('discord.js');
const { getPhantomStatus } = require('./fivem-status');

function relaySecret() {
  return process.env.BOT_RELAY_SECRET || process.env.FIVEM_API_TOKEN || '';
}

function ownerId() {
  return process.env.OWNER_ID || process.env.DISCORD_OWNER_USER_ID || '';
}

function guildId() {
  return process.env.DISCORD_GUILD_ID || process.env.DISCORD_ID || '';
}

function statusChannelId() {
  return process.env.DISCORD_STATUS_CHANNEL_ID || '';
}

function errorChannelId() {
  return process.env.DISCORD_ERROR_CHANNEL_ID || process.env.DISCORD_STATUS_CHANNEL_ID || '';
}

function eventEmbed(entry) {
  const color = Number(entry.color) || 0x8b5cf6;
  const desc = entry.description || '';
  const players =
    entry.players != null && entry.maxPlayers != null
      ? `\n\nPlayers: ${entry.players}/${entry.maxPlayers}`
      : '';
  return new EmbedBuilder()
    .setColor(color)
    .setTitle(entry.title || 'Server Event')
    .setDescription((desc + players).slice(0, 4096))
    .setFooter({ text: `${entry.category || 'event'} • ${entry.time || ''}` })
    .setTimestamp(entry.timestamp ? new Date(entry.timestamp * 1000) : undefined);
}

async function dmOwner(client, payload) {
  const id = ownerId();
  if (!id) return;
  try {
    const user = await client.users.fetch(id);
    await user.send(payload);
  } catch (err) {
    console.warn('[phantom-fivem] Owner DM failed:', err.message);
  }
}

function webhookFromClient(client, key) {
  const wh = client?.webhooks?.[key];
  if (!wh?.id || !wh?.token || wh.token === 'REPLACE_ME') return null;
  try {
    return new WebhookClient({ id: wh.id, token: wh.token });
  } catch {
    return null;
  }
}

async function postErrorTargets(client, entry) {
  const embed = eventEmbed(entry);
  const payload = { username: 'Phantom FX Errors', embeds: [embed] };

  // Prefer dedicated errorLogs / consoleLogs webhooks from webhooks.json
  for (const key of ['errorLogs', 'consoleLogs']) {
    const hook = webhookFromClient(client, key);
    if (!hook) continue;
    try {
      await hook.send(payload);
    } catch (err) {
      console.warn(`[phantom-fivem] ${key} webhook failed:`, err.message);
    }
  }

  const channelId = errorChannelId();
  if (channelId) {
    try {
      const channel = await client.channels.fetch(channelId);
      if (channel?.isTextBased?.()) {
        await channel.send({ embeds: [embed] });
      }
    } catch (err) {
      console.warn('[phantom-fivem] error channel post failed:', err.message);
    }
  }

  await dmOwner(client, { embeds: [embed] });
}

async function postNormalEvent(client, entry) {
  await dmOwner(client, { embeds: [eventEmbed(entry)] });
  const mirrorId = statusChannelId();
  if (!mirrorId) return;
  try {
    const channel = await client.channels.fetch(mirrorId);
    if (channel?.isTextBased?.()) {
      await channel.send({ embeds: [eventEmbed(entry)] });
    }
  } catch (err) {
    console.warn('[phantom-fivem] status mirror failed:', err.message);
  }
}

function mountRelayRoutes(app, client) {
  const secret = relaySecret();

  app.post('/events', async (req, res) => {
    const auth = req.headers.authorization?.replace(/^Bearer\s+/i, '') || req.headers['x-phantom-token'];
    if (secret && auth !== secret) {
      res.status(401).json({ error: 'unauthorized' });
      return;
    }
    const entry = req.body || {};
    try {
      if (String(entry.category || '').toLowerCase() === 'error') {
        await postErrorTargets(client, entry);
      } else {
        await postNormalEvent(client, entry);
      }
      res.json({ ok: true });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  app.post('/errors', async (req, res) => {
    const auth = req.headers.authorization?.replace(/^Bearer\s+/i, '') || req.headers['x-phantom-token'];
    if (secret && auth !== secret) {
      res.status(401).json({ error: 'unauthorized' });
      return;
    }
    try {
      const entry = { category: 'error', ...(req.body || {}) };
      await postErrorTargets(client, entry);
      res.json({ ok: true });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  console.log('[phantom-fivem] Event relay mounted at POST /events and POST /errors');
}

function attachInteractionHandler(client) {
  client.on('interactionCreate', async (interaction) => {
    if (!interaction.isChatInputCommand()) return;
    if (interaction.commandName !== 'phantomstatus') return;

    try {
      await interaction.deferReply();
      const status = await getPhantomStatus();
      const embed = new EmbedBuilder()
        .setColor(0x8b5cf6)
        .setTitle('Phantom World — Server Status')
        .addFields(
          { name: 'Server', value: status.serverName || 'Unknown', inline: true },
          { name: 'Players', value: `${status.playerCount}/${status.maxPlayers}`, inline: true },
          { name: 'Source', value: status.source || 'fivem', inline: true },
        )
        .setTimestamp();
      await interaction.editReply({ embeds: [embed] });
    } catch (err) {
      const msg = err?.message || 'Status failed';
      if (interaction.deferred) await interaction.editReply({ content: msg });
      else await interaction.reply({ content: msg, ephemeral: true });
    }
  });
}

module.exports = function setupPhantomFivem(client) {
  console.log('[phantom-fivem] Initializing bridge…');

  const app = global.phantomHttpApp;
  if (app) {
    mountRelayRoutes(app, client);
  } else {
    console.warn('[phantom-fivem] No shared HTTP app — relay not mounted');
  }

  attachInteractionHandler(client);

  dmOwner(client, {
    embeds: [
      new EmbedBuilder()
        .setColor(0x8b5cf6)
        .setTitle('Phantom World bot online')
        .setDescription(
          'FiveM event relay on `/events` · error reports on `/errors` · `/phantomstatus`',
        )
        .setTimestamp(),
    ],
  }).catch(() => {});
};
