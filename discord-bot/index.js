import dotenv from 'dotenv';
dotenv.config();
dotenv.config({ path: 'env.host' });
import express from 'express';
import {
  Client,
  GatewayIntentBits,
  REST,
  Routes,
  SlashCommandBuilder,
  EmbedBuilder,
  ActivityType,
} from 'discord.js';

const token = process.env.DISCORD_BOT_TOKEN;
const guildId = process.env.DISCORD_GUILD_ID;
const statusChannelId = process.env.DISCORD_STATUS_CHANNEL_ID;
const ownerUserId = process.env.DISCORD_OWNER_USER_ID;
const fivemUrl = (process.env.FIVEM_SERVER_URL || 'http://127.0.0.1:30120').replace(/\/$/, '');
const apiToken = process.env.FIVEM_API_TOKEN || '';
const cfxServerId = process.env.CFX_SERVER_ID || '';
const pollMinutes = Number(process.env.STATUS_POLL_MINUTES || 0);
const relayPort = Number(process.env.BOT_HTTP_PORT || 3099);
const relaySecret = process.env.BOT_RELAY_SECRET || apiToken;

if (!token) {
  console.error('Missing DISCORD_BOT_TOKEN in .env');
  process.exit(1);
}

const commands = [
  new SlashCommandBuilder()
    .setName('status')
    .setDescription('Show Phantom World server status'),
  new SlashCommandBuilder()
    .setName('players')
    .setDescription('List online players'),
  new SlashCommandBuilder()
    .setName('alert')
    .setDescription('Send a dashboard alert (admin)')
    .addStringOption((o) => o.setName('message').setDescription('Alert text').setRequired(true)),
].map((c) => c.toJSON());

async function registerCommands(clientId) {
  if (!guildId) {
    console.warn('DISCORD_GUILD_ID not set — skip slash command registration');
    return;
  }
  const rest = new REST({ version: '10' }).setToken(token);
  await rest.put(Routes.applicationGuildCommands(clientId, guildId), { body: commands });
  console.log('Slash commands registered for guild', guildId);
}

async function fetchFivem(path) {
  const headers = {};
  if (apiToken) headers.Authorization = `Bearer ${apiToken}`;
  const res = await fetch(`${fivemUrl}${path}`, { headers, signal: AbortSignal.timeout(8000) });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}

async function fetchCfxFallback() {
  if (!cfxServerId) return null;
  const res = await fetch(`https://servers-frontend.fivem.net/api/servers/single/${cfxServerId}`, {
    signal: AbortSignal.timeout(8000),
  });
  if (!res.ok) return null;
  const data = await res.json();
  const d = data?.Data;
  if (!d) return null;
  return {
    serverName: d.hostname || 'Phantom World',
    playerCount: d.clients ?? 0,
    maxPlayers: d.sv_maxclients ?? 48,
    serverTime: new Date().toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' }),
    source: 'cfx',
  };
}

async function getStatus() {
  try {
    const status = await fetchFivem('/phantom-dashboard/status');
    return { ...status, source: 'fivem' };
  } catch (err) {
    console.warn('FiveM HTTP failed:', err.message);
    const fallback = await fetchCfxFallback();
    if (fallback) return fallback;
    throw err;
  }
}

async function getPlayers() {
  try {
    const data = await fetchFivem('/phantom-dashboard/players');
    return data.players || [];
  } catch {
    return [];
  }
}

function statusEmbed(status) {
  return new EmbedBuilder()
    .setColor(0x8b5cf6)
    .setTitle('Phantom World — Server Status')
    .addFields(
      { name: 'Server', value: status.serverName || 'Unknown', inline: true },
      { name: 'Players', value: `${status.playerCount ?? '?'}/${status.maxPlayers ?? '?'}`, inline: true },
      { name: 'Time', value: status.serverTime || '—', inline: true },
    )
    .setFooter({ text: `Source: ${status.source || 'fivem'}` })
    .setTimestamp();
}

function eventEmbed(entry) {
  const color = Number(entry.color) || 0x8b5cf6;
  const desc = entry.description || '';
  const footer = entry.time || new Date().toISOString();
  const players =
    entry.players != null && entry.maxPlayers != null
      ? `\n\nPlayers: ${entry.players}/${entry.maxPlayers}`
      : '';
  return new EmbedBuilder()
    .setColor(color)
    .setTitle(entry.title || 'Server Event')
    .setDescription((desc + players).slice(0, 4096))
    .setFooter({ text: `${entry.category || 'event'} • ${footer}` })
    .setTimestamp(entry.timestamp ? new Date(entry.timestamp * 1000) : undefined);
}

const client = new Client({ intents: [GatewayIntentBits.Guilds] });

async function dmOwner(contentOrPayload) {
  if (!ownerUserId) return;
  try {
    const user = await client.users.fetch(ownerUserId);
    await user.send(contentOrPayload);
  } catch (err) {
    console.warn('Owner DM failed:', err.message);
  }
}

async function notifyOwnerEvent(entry) {
  await dmOwner({ embeds: [eventEmbed(entry)] });
}

function botInviteUrl(clientId) {
  const perms = '2147567616';
  return `https://discord.com/api/oauth2/authorize?client_id=${clientId}&permissions=${perms}&scope=bot%20applications.commands`;
}

function startRelayServer() {
  const app = express();
  app.use(express.json({ limit: '64kb' }));

  app.post('/events', async (req, res) => {
    const auth = req.headers.authorization?.replace(/^Bearer\s+/i, '') || req.headers['x-phantom-token'];
    if (relaySecret && auth !== relaySecret) {
      res.status(401).json({ error: 'unauthorized' });
      return;
    }
    const entry = req.body || {};
    try {
      await notifyOwnerEvent(entry);
      if (statusChannelId) {
        const channel = await client.channels.fetch(statusChannelId);
        if (channel?.isTextBased()) {
          await channel.send({ embeds: [eventEmbed(entry)] });
        }
      }
      res.json({ ok: true });
    } catch (err) {
      console.warn('Relay notify failed:', err.message);
      res.status(500).json({ error: err.message });
    }
  });

  app.get('/health', (_req, res) => {
    res.json({ ok: true, bot: client.user?.tag || 'starting' });
  });

  app.listen(relayPort, '127.0.0.1', () => {
    console.log(`Event relay listening on http://127.0.0.1:${relayPort}/events`);
  });
}

client.once('ready', async () => {
  console.log(`Logged in as ${client.user.tag}`);
  console.log(`Invite bot to your server: ${botInviteUrl(client.user.id)}`);
  startRelayServer();

  try {
    await registerCommands(client.user.id);
  } catch (err) {
    console.warn(
      'Slash command registration failed (invite the bot to your guild first):',
      err?.message || err,
    );
  }

  try {
    const status = await getStatus();
    client.user.setActivity(`${status.playerCount}/${status.maxPlayers} online`, {
      type: ActivityType.Watching,
    });
  } catch {
    client.user.setActivity('Phantom World', { type: ActivityType.Watching });
  }

  await dmOwner({
    embeds: [
      new EmbedBuilder()
        .setColor(0x8b5cf6)
        .setTitle('Phantom World Alert Bot Online')
        .setDescription(
          'You will receive **DM alerts** for server events (join/leave, resources, deaths, txAdmin, etc.).\n\n' +
            `Guild: ${guildId || 'not set'}\n` +
            `FiveM API: ${fivemUrl}`,
        )
        .setTimestamp(),
    ],
  });

  if (pollMinutes > 0 && statusChannelId) {
    setInterval(async () => {
      try {
        const status = await getStatus();
        const channel = await client.channels.fetch(statusChannelId);
        if (channel?.isTextBased()) {
          await channel.send({ embeds: [statusEmbed(status)] });
        }
      } catch (err) {
        console.warn('Status poll failed:', err.message);
      }
    }, pollMinutes * 60 * 1000);
  }
});

client.on('interactionCreate', async (interaction) => {
  if (!interaction.isChatInputCommand()) return;

  try {
    if (interaction.commandName === 'status') {
      await interaction.deferReply();
      const status = await getStatus();
      await interaction.editReply({ embeds: [statusEmbed(status)] });
      return;
    }

    if (interaction.commandName === 'players') {
      await interaction.deferReply();
      const [status, players] = await Promise.all([getStatus(), getPlayers()]);
      const lines =
        players.length > 0
          ? players.map((p) => `• **${p.name}** (ID ${p.id})`).join('\n')
          : '_No players online or player list unavailable._';
      const embed = statusEmbed(status).setDescription(lines.slice(0, 4000));
      await interaction.editReply({ embeds: [embed] });
      return;
    }

    if (interaction.commandName === 'alert') {
      if (!interaction.memberPermissions?.has('ManageGuild')) {
        await interaction.reply({ content: 'You need Manage Server permission.', ephemeral: true });
        return;
      }
      const message = interaction.options.getString('message', true);
      const entry = {
        category: 'slash',
        title: 'Dashboard Alert',
        description: message,
        color: 0xf59e0b,
        time: new Date().toISOString(),
      };
      await notifyOwnerEvent(entry);
      const channelId = statusChannelId || interaction.channelId;
      const channel = await client.channels.fetch(channelId);
      if (channel?.isTextBased()) {
        await channel.send({ embeds: [eventEmbed(entry)] });
      }
      await interaction.reply({ content: 'Alert sent to owner DM and status channel.', ephemeral: true });
    }
  } catch (err) {
    const msg = err?.message || 'Unknown error';
    if (interaction.deferred || interaction.replied) {
      await interaction.editReply({ content: `Failed: ${msg}` });
    } else {
      await interaction.reply({ content: `Failed: ${msg}`, ephemeral: true });
    }
  }
});

client.on('guildCreate', async (guild) => {
  if (guild.id === guildId) {
    try {
      await registerCommands(client.user.id);
      console.log('Slash commands registered after joining guild', guild.name);
    } catch (err) {
      console.warn('guildCreate command registration failed:', err?.message || err);
    }
    if (ownerUserId) {
      await dmOwner({
        embeds: [
          new EmbedBuilder()
            .setColor(0x8b5cf6)
            .setTitle('Bot joined your server')
            .setDescription('Phantom World alerts are active. You should receive server event DMs here.')
            .setTimestamp(),
        ],
      });
    }
  }
});

client.login(token);
