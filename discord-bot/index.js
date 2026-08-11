import './load-env.js';

import express from 'express';
import {
  Client,
  GatewayIntentBits,
  Partials,
  REST,
  Routes,
  EmbedBuilder,
} from 'discord.js';
import { slashCommands, handleCommand } from './lib/commands.js';
import { getStatus } from './lib/fivem.js';
import { startLivePresence } from './lib/presence.js';
import { startLiveStatusChannel } from './lib/liveStatusChannel.js';
import { maybeAutoInviteBroadcast } from './lib/serverInvite.js';
import { initLavalink } from './lib/lavalink.js';
import { startPrefixCommands } from './lib/prefix.js';
import { probeAiServices } from './lib/ai.js';
import { generateDependencyReport } from '@discordjs/voice';
import { createRequire } from 'module';
import { assertFfmpegAvailable } from './lib/ffmpeg.js';

const require = createRequire(import.meta.url);

async function bootstrapVoice() {
  try {
    const sodium = require('libsodium-wrappers');
    await sodium.ready;
  } catch (err) {
    console.warn('[voice] libsodium-wrappers:', err.message);
  }
  try {
    assertFfmpegAvailable();
  } catch (err) {
    console.error('[voice]', err.message);
  }
  try {
    console.log('[voice] deps:\n' + generateDependencyReport());
  } catch {
    // ignore
  }
}

const token = process.env.DISCORD_BOT_TOKEN;
const guildId = process.env.DISCORD_GUILD_ID;
function statusChannelId() {
  return process.env.DISCORD_STATUS_CHANNEL_ID || '';
}
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
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMembers,
    GatewayIntentBits.GuildVoiceStates,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent,
  ],
  partials: [Partials.Channel],
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
      const mirrorChannelId = statusChannelId();
      if (mirrorChannelId) {
        const channel = await client.channels.fetch(mirrorChannelId);
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
  statusChannelId: statusChannelId(),
};

client.once('ready', async () => {
  console.log(`Logged in as ${client.user.tag}`);
  console.log(`Invite: ${botInviteUrl(client.user.id)}`);
  await bootstrapVoice();
  startRelayServer();
  initLavalink(client);
  startPrefixCommands(client, commandCtx);

  probeAiServices().then((status) => {
    console.log('[ai] Provider:', status.provider, status.ollama ? `(Ollama OK: ${status.ollamaModels?.join(', ') || 'models'})` : '(Ollama not reachable)');
  });

  try {
    await registerCommands(client.user.id);
  } catch (err) {
    console.warn('Slash registration failed (invite bot first):', err?.message || err);
  }

  if (process.env.FIVEM_LIVE_PRESENCE !== '0') {
    startLivePresence(client);
  }

  startLiveStatusChannel(client);

  maybeAutoInviteBroadcast(client).catch((err) =>
    console.warn('Auto invite broadcast failed:', err.message),
  );

  await dmOwner({
    embeds: [
      new EmbedBuilder()
        .setColor(0x8b5cf6)
        .setTitle('Phantom World Bot Online')
        .setDescription(
          '**Prefix:** `$help` · **Slash:** `/help` — dropdown command menu\n' +
            '**Rex:** `$rex join` / `/rex join` — say **"Hey Rex"** in VC\n' +
            '**AI/TTS:** `$ask` · `$say` · **Music:** `$play`\n\n' +
            `FiveM: ${fivemUrl}`,
        )
        .setTimestamp(),
    ],
  });

  const pollChannelId = statusChannelId();
  if (pollMinutes > 0 && pollChannelId) {
    setInterval(async () => {
      try {
        const status = await getStatus();
        const { buildStatusEmbed } = await import('./lib/fivem.js');
        const channel = await client.channels.fetch(pollChannelId);
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
  try {
    if (interaction.isStringSelectMenu() && interaction.customId === 'phantom-help-category') {
      const { handleHelpSelect } = await import('./lib/helpMenu.js');
      const payload = handleHelpSelect(interaction);
      await interaction.update(payload);
      return;
    }

    if (interaction.isButton() && interaction.customId?.startsWith('ticket:')) {
      const { handleTicketButton } = await import('./lib/tickets.js');
      const handled = await handleTicketButton(interaction);
      if (handled) return;
    }

    if (!interaction.isChatInputCommand()) return;
    await handleCommand(interaction, commandCtx);
  } catch (err) {
    const msg = err?.message || 'Unknown error';
    console.warn('[interaction]', msg);
    try {
      if (interaction.deferred || interaction.replied) {
        await interaction.editReply({ content: `Failed: ${msg}` });
      } else if (interaction.isRepliable?.()) {
        await interaction.reply({ content: `Failed: ${msg}`, ephemeral: true });
      }
    } catch {
      // ignore
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
          .setDescription('Use `$help` or `/help` — dropdown command menu.')
          .setTimestamp(),
      ],
    });
  }
});

client.login(token);
