import dotenv from 'dotenv';
dotenv.config();
dotenv.config({ path: 'env.host' });

import express from 'express';
import {
  Client,
  GatewayIntentBits,
  REST,
  Routes,
  EmbedBuilder,
} from 'discord.js';
import { slashCommands, handleCommand } from './lib/commands.js';
import { getStatus } from './lib/fivem.js';
import { startLivePresence } from './lib/presence.js';

const token = process.env.DISCORD_BOT_TOKEN;
const guildId = process.env.DISCORD_GUILD_ID;
const statusChannelId = process.env.DISCORD_STATUS_CHANNEL_ID;
const ownerUserId = process.env.DISCORD_OWNER_USER_ID;
const fivemUrl = (process.env.FIVEM_SERVER_URL || 'http://127.0.0.1:30120').replace(/\/$/, '');
const pollMinutes = Number(process.env.STATUS_POLL_MINUTES || 0);
const relayPort = Number(process.env.BOT_HTTP_PORT || 3099);
const relaySecret = process.env.BOT_RELAY_SECRET || process.env.FIVEM_API_TOKEN || '';

if (!token) {
  console.error('Missing DISCORD_BOT_TOKEN in .env');
  process.exit(1);
}

async function registerCommands(clientId) {
  if (!guildId) {
    console.warn('DISCORD_GUILD_ID not set — skip slash command registration');
    return;
  }
  const rest = new REST({ version: '10' }).setToken(token);
  await rest.put(Routes.applicationGuildCommands(clientId, guildId), { body: slashCommands });
  console.log('Slash commands registered for guild', guildId);
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

const client = new Client({
  intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildVoiceStates],
});

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
  return `https://discord.com/api/oauth2/authorize?client_id=${clientId}&permissions=2147567616&scope=bot%20applications.commands`;
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

const commandCtx = {
  notifyOwnerEvent,
  eventEmbed,
  statusChannelId,
};

client.once('ready', async () => {
  console.log(`Logged in as ${client.user.tag}`);
  console.log(`Invite: ${botInviteUrl(client.user.id)}`);
  startRelayServer();

  try {
    await registerCommands(client.user.id);
  } catch (err) {
    console.warn('Slash registration failed (invite bot first):', err?.message || err);
  }

  startLivePresence(client);

  await dmOwner({
    embeds: [
      new EmbedBuilder()
        .setColor(0x8b5cf6)
        .setTitle('Phantom World Bot Online')
        .setDescription(
          '**Host alerts** → your DMs when FXServer posts events.\n' +
            '**Commands:** `/phantomhelp` for music, GIFs, jokes, status.\n\n' +
            `FiveM: ${fivemUrl}`,
        )
        .setTimestamp(),
    ],
  });

  if (pollMinutes > 0 && statusChannelId) {
    setInterval(async () => {
      try {
        const status = await getStatus();
        const { buildStatusEmbed } = await import('./lib/fivem.js');
        const channel = await client.channels.fetch(statusChannelId);
        if (channel?.isTextBased()) {
          await channel.send({ embeds: [buildStatusEmbed(status)] });
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
    await handleCommand(interaction, commandCtx);
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
      console.log('Commands registered after joining', guild.name);
    } catch (err) {
      console.warn('guildCreate registration failed:', err?.message || err);
    }
    await dmOwner({
      embeds: [
        new EmbedBuilder()
          .setColor(0x8b5cf6)
          .setTitle('Bot joined your server')
          .setDescription('Alerts + `/phantomhelp` for commands.')
          .setTimestamp(),
      ],
    });
  }
});

client.login(token);
