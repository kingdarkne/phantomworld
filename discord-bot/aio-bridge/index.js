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

/** Per-user debounce so stuck false-positives cannot spam DMs. */
const stuckDmCooldownMs = Number(process.env.STUCK_DM_COOLDOWN_MS || 30 * 60 * 1000);
const lastStuckDmAt = new Map();

function stuckDmAllowed(discordId) {
  if (!discordId) return false;
  const now = Date.now();
  const prev = lastStuckDmAt.get(discordId) || 0;
  if (now - prev < stuckDmCooldownMs) {
    console.log(`[phantom-fivem] Skipping stuck DM (cooldown) for ${discordId}`);
    return false;
  }
  lastStuckDmAt.set(discordId, now);
  return true;
}

async function dmPlayerHelpInvite(client, entry) {
  const discordId = extractDiscordId(entry);
  if (!discordId) return;
  // Only when explicitly requested (manual /reportstuck). Never for auto heuristics.
  if (entry.invitePlayer !== true) return;
  if (!stuckDmAllowed(discordId)) return;

  const invite = discordInviteUrl(client);
  const embed = new EmbedBuilder()
    .setColor(0xf59e0b)
    .setTitle('Need help on Phantom World?')
    .setDescription(
      [
        'Hey — you asked for help with a **stuck / possible bug** on the FiveM server.',
        '',
        'Join our Discord so staff can help you fix it:',
        invite,
        '',
        'In-game you can also try: `/unstuck`',
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

  // Skip owner spam for quiet stuck auto-reports (dmOwner:false from FXServer).
  if (entry.dmOwner !== false) {
    const cat = String(entry.category || '').toLowerCase();
    if (cat === 'stuck') {
      const owner = ownerId();
      if (owner && stuckDmAllowed(`owner:${owner}:${cat}`)) {
        await dmOwner(client, { embeds: [embed] });
      }
    } else {
      await dmOwner(client, { embeds: [embed] });
    }
  }

  // Stuck help DMs only when invitePlayer is explicitly true (manual report).
  if (entry.invitePlayer === true) {
    await dmPlayerHelpInvite(client, entry);
  }
}

async function postNormalEvent(client, entry) {
  const cat = String(entry.category || '').toLowerCase();
  // Routine FX join/leave noise: channel mirror only — no owner DMs, no player pings.
  const quietCats = new Set([
    'join',
    'connect',
    'loaded',
    'leave',
    'resource',
    'death',
    'kill',
    'combat',
    'info',
  ]);
  const quiet = quietCats.has(cat) || entry.dmOwner === false;

  if (!quiet && entry.dmOwner !== false) {
    await dmOwner(client, { embeds: [eventEmbed(entry)] });
  }

  const mirrorId = statusChannelId();
  if (!mirrorId) return;
  try {
    const channel = await client.channels.fetch(mirrorId);
    if (channel?.isTextBased?.()) {
      await channel.send({
        embeds: [eventEmbed(entry)],
        allowedMentions: { parse: [] },
      });
    }
  } catch (err) {
    console.warn('[phantom-fivem] status mirror failed:', err.message);
  }
}

function mountRelayRoutes(app, client) {
  const secret = relaySecret();

  const authOk = (req) => {
    const auth = req.headers.authorization?.replace(/^Bearer\s+/i, '') || req.headers['x-phantom-token'];
    return !(secret && auth !== secret);
  };

  app.post('/events', async (req, res) => {
    if (!authOk(req)) {
      res.status(401).json({ error: 'unauthorized' });
      return;
    }
    const entry = req.body || {};
    try {
      const cat = String(entry.category || '').toLowerCase();
      if (cat === 'error' || cat === 'stuck' || cat === 'critical' || cat === 'scheduled_restart') {
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
    if (!authOk(req)) {
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

  /**
   * Called by phantom_dashboard before FXServer quits after a critical error.
   * Recycles the Pterodactyl game container so players can rejoin.
   */
  app.post('/server/restart', async (req, res) => {
    if (!authOk(req)) {
      res.status(401).json({ error: 'unauthorized' });
      return;
    }
    res.json({ ok: true, accepted: true });

    const { exec } = require('child_process');
    const uuid = process.env.FIVEM_SERVER_UUID || '5e6a18d6-d453-4130-b80c-f5f1d7dc82ef';
    const reason = req.body?.reason || 'critical_script_error';
    console.warn(`[phantom-fivem] Host restart requested (${reason})`);

    // Notify Discord immediately
    try {
      await postErrorTargets(client, {
        category: 'critical',
        title: '🔄 Host restarting FiveM now',
        description: `Bot accepted restart request.\nReason: \`${reason}\`\nPlayers can rejoin once \`info.json\` is up again.`,
        color: 15548997,
        timestamp: Math.floor(Date.now() / 1000),
      });
    } catch (_) {}

    // Delay so FXServer can quit first, then force-cycle container via Wings token if present
    setTimeout(() => {
      const script = [
        'set -e',
        `UUID='${uuid}'`,
        'TOKEN=$(grep -E "^token:" /etc/pterodactyl/config.yml 2>/dev/null | awk "{print \\$2}")',
        'CID=$(docker ps -aq --filter name=$UUID | head -1)',
        'if [ -n "$CID" ]; then docker kill "$CID" 2>/dev/null || true; docker rm -f "$CID" 2>/dev/null || true; fi',
        'sleep 2',
        'if [ -n "$TOKEN" ]; then',
        '  curl -sS -m 20 -X POST "http://127.0.0.1:8080/api/servers/${UUID}/power" \\',
        '    -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \\',
        '    -d \'{"action":"start"}\' || true',
        'fi',
      ].join('\n');

      exec(script, { shell: '/bin/bash' }, (err, stdout, stderr) => {
        if (err) console.warn('[phantom-fivem] restart script error:', err.message);
        if (stdout) console.log('[phantom-fivem] restart stdout:', String(stdout).slice(0, 400));
        if (stderr) console.warn('[phantom-fivem] restart stderr:', String(stderr).slice(0, 400));
      });
    }, 4000);
  });

  console.log('[phantom-fivem] Event relay mounted at POST /events, /errors, /server/restart');
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
