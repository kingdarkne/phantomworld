/**
 * Phantom FiveM bridge for ALL-IN-ONE-Discord-Bot (CommonJS).
 * @param {import('discord.js').Client} client
 */
const express = require('express');
const { EmbedBuilder, REST, Routes, SlashCommandBuilder } = require('discord.js');
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
    .setFooter({ text: `${entry.category || 'event'} • ${entry.time || ''}` });
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

function mountRelayRoutes(app, client) {
  const secret = relaySecret();

  app.post('/events', async (req, res) => {
    const auth = req.headers.authorization?.replace(/^Bearer\s+/i, '') || req.headers['x-phantom-token'];
    if (secret && auth !== secret) {
      res.status(401).json({ error: 'unauthorized' });
      return;
    }
    try {
      await dmOwner(client, { embeds: [eventEmbed(req.body || {})] });
      res.json({ ok: true });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  console.log('[phantom-fivem] Event relay mounted at POST /events');
}

async function registerPhantomSlash(client) {
  const gid = guildId();
  if (!gid || !client.user) return;
  const token = process.env.DISCORD_TOKEN || process.env.DISCORD_BOT_TOKEN;
  if (!token) return;

  const commands = [
    new SlashCommandBuilder()
      .setName('phantomstatus')
      .setDescription('Phantom World FiveM server status'),
  ].map((c) => c.toJSON());

  const rest = new REST({ version: '10' }).setToken(token);
  await rest.put(Routes.applicationGuildCommands(client.user.id, gid), { body: commands });
  console.log('[phantom-fivem] Registered /phantomstatus');
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

  // /phantomstatus is registered via src/interactions/Command/phantomstatus.js

  dmOwner(client, {
    embeds: [
      new EmbedBuilder()
        .setColor(0x8b5cf6)
        .setTitle('Phantom World bot online')
        .setDescription(
          'Full ALL-IN-ONE bot restored · FiveM event relay on `/events` · `/phantomstatus` · `/help`',
        )
        .setTimestamp(),
    ],
  }).catch(() => {});
};
