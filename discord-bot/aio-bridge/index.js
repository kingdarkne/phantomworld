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

function discordInviteUrl(client) {
  return (
    process.env.DISCORD_SERVER_INVITE ||
    process.env.DISCORD_INVITE_URL ||
    client?.config?.discord?.serverInvite ||
    'https://discord.gg/phantomworld'
  );
}

function extractDiscordId(entry) {
  if (entry?.discordId) return String(entry.discordId).replace(/^discord:/, '');
  const desc = String(entry?.description || '');
  const m = desc.match(/<@!?(\d{16,20})>/);
  return m ? m[1] : '';
}

async function dmPlayerHelpInvite(client, entry) {
  const discordId = extractDiscordId(entry);
  if (!discordId) return;
  if (entry.invitePlayer === false) return;

  const invite = discordInviteUrl(client);
  const embed = new EmbedBuilder()
    .setColor(0xf59e0b)
    .setTitle('Need help on Phantom World?')
    .setDescription(
      [
        'Hey — we detected a **stuck / possible bug** on the FiveM server.',
        '',
        'Join our Discord so staff can help you fix it:',
        invite,
        '',
        'In-game you can also try: `/unstuck`',
        '',
        '_If you already used /reportstuck, staff can see your report._',
      ].join('\n'),
    )
    .setFooter({ text: 'Phantom World Support' })
    .setTimestamp();

  try {
    const user = await client.users.fetch(discordId);
    await user.send({ embeds: [embed] });
    console.log(`[phantom-fivem] Sent Discord invite DM to ${discordId}`);
  } catch (err) {
    console.warn('[phantom-fivem] Player invite DM failed:', err.message);
  }
}

async function postErrorTargets(client, entry) {
  const embed = eventEmbed(entry);
  const discordId = extractDiscordId(entry);
  const pingContent =
    entry.pingPlayer && discordId
      ? `<@${discordId}> having an in-game issue — check DMs / join Discord for help`
      : null;

  const payload = {
    username: 'Phantom FX Errors',
    embeds: [embed],
  };
  if (pingContent) {
    payload.content = pingContent;
    payload.allowedMentions = { users: [discordId] };
  }

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
        await channel.send({
          content: pingContent || undefined,
          embeds: [embed],
          allowedMentions: discordId ? { users: [discordId] } : undefined,
        });
      }
    } catch (err) {
      console.warn('[phantom-fivem] error channel post failed:', err.message);
    }
  }

  await dmOwner(client, { embeds: [embed] });

  // Stuck / bug reports: DM the player a Discord invite for help
  if (String(entry.category || '').toLowerCase() === 'stuck' || entry.invitePlayer) {
    await dmPlayerHelpInvite(client, entry);
  }
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
      if (String(entry.category || '').toLowerCase() === 'error' || String(entry.category || '').toLowerCase() === 'stuck') {
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
