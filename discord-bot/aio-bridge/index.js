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

/** #💬┊general — all Rex bot alerts go here inside a dedicated thread. */
function alertsChannelId() {
  return (
    process.env.DISCORD_ALERTS_CHANNEL_ID ||
    process.env.BILLING_NOTIFY_CHANNEL_ID ||
    '1522386964454703308'
  );
}

function alertsThreadName() {
  return process.env.DISCORD_ALERTS_THREAD_NAME || '🚨 Rex Alerts';
}

let cachedAlertsThreadId = process.env.DISCORD_ALERTS_THREAD_ID || '1538801459087282188';

async function ensureAlertsThread(client) {
  const channelId = alertsChannelId();
  if (!channelId) throw new Error('DISCORD_ALERTS_CHANNEL_ID not set');
  const ready = await waitUntilReady(client);
  if (!ready) throw new Error('Discord client not ready');

  const name = alertsThreadName();
  const channel = await client.channels.fetch(channelId);
  if (!channel?.isTextBased?.()) throw new Error('alerts channel is not text-based');

  if (cachedAlertsThreadId) {
    try {
      const existing = await client.channels.fetch(cachedAlertsThreadId);
      if (existing?.isThread?.()) {
        if (existing.archived) await existing.setArchived(false).catch(() => {});
        return existing;
      }
    } catch (_) {
      cachedAlertsThreadId = '';
    }
  }

  const active = await channel.threads.fetchActive().catch(() => null);
  let thread = active?.threads?.find((t) => t.name === name);
  if (!thread) {
    const archived = await channel.threads.fetchArchived({ type: 'public', fetchAll: true }).catch(() => null);
    thread = archived?.threads?.find((t) => t.name === name);
    if (thread?.archived) await thread.setArchived(false).catch(() => {});
  }
  if (!thread) {
    thread = await channel.threads.create({
      name,
      autoArchiveDuration: 10080,
      reason: 'Phantom World bot alerts thread',
    });
    const owner = ownerId();
    await thread.send({
      content: owner
        ? `Rex alert thread is live. <@${owner}> will be pinged on every bot alert.`
        : 'Rex alert thread is live.',
      allowedMentions: owner ? { users: [owner] } : { parse: [] },
    });
  }
  cachedAlertsThreadId = thread.id;
  return thread;
}

async function postAlertsThread(client, { content, embeds, allowedMentions }) {
  const thread = await ensureAlertsThread(client);
  return thread.send({
    content: content || undefined,
    embeds: embeds || [],
    allowedMentions: allowedMentions || { parse: [] },
  });
}

function botUserId(client) {
  return client?.user?.id || process.env.DISCORD_CLIENT_ID || process.env.DISCORD_ID || '';
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

async function waitUntilReady(client, timeoutMs = 60000) {
  if (client?.isReady?.()) return true;
  if (client?.readyAt) return true;
  return new Promise((resolve) => {
    let done = false;
    const finish = (ok) => {
      if (done) return;
      done = true;
      resolve(ok);
    };
    const timer = setTimeout(() => finish(false), timeoutMs);
    const onReady = () => {
      clearTimeout(timer);
      finish(true);
    };
    // discord.js v14/v15
    client.once('clientReady', onReady);
    client.once('ready', onReady);
  });
}

async function dmOwner(client, payload) {
  const id = ownerId();
  if (!id) {
    console.warn('[phantom-fivem] Owner DM skipped — OWNER_ID / DISCORD_OWNER_USER_ID not set');
    return false;
  }
  try {
    const ready = await waitUntilReady(client);
    if (!ready) {
      console.warn('[phantom-fivem] Owner DM skipped — bot not ready yet');
      return false;
    }
    // Ensure REST has a token (fixes "Expected token to be set…" when bridge loads pre-login).
    const token =
      client.token ||
      process.env.DISCORD_TOKEN ||
      process.env.DISCORD_BOT_TOKEN ||
      '';
    if (token && client.rest && !client.rest.token) {
      client.rest.setToken(token);
    }
    const user = await client.users.fetch(id);
    await user.send(payload);
    return true;
  } catch (err) {
    console.warn('[phantom-fivem] Owner DM failed:', err.message);
    return false;
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
  const m = desc.match(/discord:(\d{16,20})/) || desc.match(/<@!?(\d{16,20})>/);
  return m ? m[1] : '';
}

/** Per-user debounce so stuck false-positives cannot spam DMs. */
const stuckDmCooldownMs = Number(process.env.STUCK_DM_COOLDOWN_MS || 30 * 60 * 1000);
const lastStuckDmAt = new Map();

/** Missing-Discord-guild invite DMs (players in FiveM but not in Discord). */
const missingGuildInviteCooldownMs = Number(
  process.env.MISSING_GUILD_INVITE_COOLDOWN_MS || 7 * 24 * 60 * 60 * 1000,
);
const lastMissingGuildInviteAt = new Map();

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

function missingGuildInviteAllowed(discordId) {
  if (!discordId) return false;
  const now = Date.now();
  const prev = lastMissingGuildInviteAt.get(discordId) || 0;
  if (now - prev < missingGuildInviteCooldownMs) {
    console.log(`[phantom-fivem] Skipping guild-invite DM (cooldown) for ${discordId}`);
    return false;
  }
  lastMissingGuildInviteAt.set(discordId, now);
  return true;
}

async function isInPhantomGuild(client, discordId) {
  const gid = guildId();
  if (!gid || !discordId) return null;
  try {
    const guild = client.guilds.cache.get(gid) || (await client.guilds.fetch(gid));
    await guild.members.fetch(discordId);
    return true;
  } catch (err) {
    // Unknown Member
    if (err?.code === 10007 || err?.status === 404) return false;
    console.warn('[phantom-fivem] guild member lookup failed:', err.message);
    return null;
  }
}

async function dmMissingGuildInvite(client, entry) {
  if (entry.inviteIfMissing !== true) return;
  const discordId = extractDiscordId(entry);
  if (!discordId) return;

  const inGuild = await isInPhantomGuild(client, discordId);
  if (inGuild !== false) return; // already in guild, or lookup failed
  if (!missingGuildInviteAllowed(discordId)) return;

  const invite = discordInviteUrl(client);
  const serverName = process.env.PHANTOM_SERVER_NAME || 'Phantom World';
  const embed = new EmbedBuilder()
    .setColor(0x8b5cf6)
    .setTitle(`Welcome to ${serverName} 🌆`)
    .setDescription(
      [
        `Hey! You’re connected to **${serverName}** on FiveM — nice.`,
        '',
        'We noticed you’re **not in our Discord yet**. Join so you can:',
        '• get help from staff',
        '• see events & announcements',
        '• meet the community',
        '',
        `**Discord:** ${invite}`,
        '',
        '_This is an automatic welcome invite — you won’t get spammed._',
      ].join('\n'),
    )
    .setFooter({ text: `${serverName} · see you in the city` })
    .setTimestamp();

  try {
    const user = await client.users.fetch(discordId);
    await user.send({ embeds: [embed] });
    console.log(`[phantom-fivem] Sent Discord guild invite DM to ${discordId}`);
  } catch (err) {
    console.warn('[phantom-fivem] Guild invite DM failed:', err.message);
  }
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

async function enrichStuckDescription(client, entry) {
  const cat = String(entry.category || '').toLowerCase();
  if (cat !== 'stuck' && entry.pingPlayer !== true) return entry.description || '';

  const lines = [];
  const name = entry.playerName || null;
  const serverId = entry.serverId != null ? entry.serverId : null;
  const discordId = extractDiscordId(entry);
  const ids = entry.identifiers || {};
  const desc = String(entry.description || '');
  const hasIdentity = /\*\*Identity\*\*|CFX \/ FiveM name|Discord:/.test(desc);

  if (!hasIdentity) {
    lines.push('**Identity**');
    lines.push(`• CFX / FiveM name: **${name || 'unknown'}**`);
    if (serverId != null) lines.push(`• Server ID: \`${serverId}\``);
    if (entry.citizenId) lines.push(`• Citizen ID: \`${entry.citizenId}\``);
    if (discordId) {
      lines.push(`• Discord: linked — <@${discordId}> (\`${discordId}\`)`);
    } else {
      lines.push('• Discord: **NOT LINKED** in FiveM (cannot ping / DM)');
    }
    for (const key of ['license', 'license2', 'fivem', 'steam']) {
      if (ids[key]) lines.push(`• ${key}: \`${ids[key]}\``);
    }
    lines.push('');
  }

  if (discordId) {
    const inGuild = await isInPhantomGuild(client, discordId);
    if (inGuild === true) lines.push('• Discord guild: **IN Phantom World**');
    else if (inGuild === false) {
      lines.push('• Discord guild: **NOT IN Phantom World** (linked account, missing invite)');
    } else lines.push('• Discord guild: _could not check membership_');
  }

  if (!lines.length) return desc;
  if (hasIdentity) return `${desc}\n${lines.join('\n')}`.slice(0, 4096);
  return `${lines.join('\n')}\n${desc}`.slice(0, 4096);
}

async function postErrorTargets(client, entry) {
  const cat = String(entry.category || '').toLowerCase();
  // Host restarts / infra are not player stuck reports.
  const isInfra =
    cat === 'scheduled_restart' ||
    cat === 'restart' ||
    cat === 'lifecycle' ||
    /host restarting|scheduled|hourly/i.test(String(entry.title || ''));
  const isPlayerBug =
    !isInfra &&
    (cat === 'stuck' ||
      ((cat === 'error' || cat === 'critical') && entry.pingPlayer === true) ||
      entry.pingPlayer === true);

  const enrichedDesc = await enrichStuckDescription(client, entry);
  const embed = eventEmbed({ ...entry, description: enrichedDesc });
  const discordId = extractDiscordId(entry);
  const owner = ownerId();
  const rexId = botUserId(client);

  const mentionUsers = [];
  const parts = [];
  if (isPlayerBug && discordId) {
    parts.push(`<@${discordId}>`);
    mentionUsers.push(discordId);
  }
  if (isPlayerBug && rexId) {
    parts.push(`<@${rexId}>`);
    mentionUsers.push(rexId);
  }
  if (owner) {
    parts.push(`<@${owner}>`);
    mentionUsers.push(owner);
  }
  if (isPlayerBug) {
    const who = entry.playerName ? `**${entry.playerName}**` : 'player';
    const sid = entry.serverId != null ? ` (serverId \`${entry.serverId}\`)` : '';
    const discordBit = discordId ? 'Discord linked' : 'Discord **not linked**';
    parts.push(`— stuck/bug: ${who}${sid} · ${discordBit}. Rex escalating.`);
  }

  const content = parts.length ? parts.join(' ') : owner ? `<@${owner}>` : null;

  try {
    await postAlertsThread(client, {
      content,
      embeds: [embed],
      allowedMentions: { users: [...new Set(mentionUsers)] },
    });
  } catch (err) {
    console.warn('[phantom-fivem] alerts thread post failed:', err.message);
  }

  for (const key of ['errorLogs', 'consoleLogs']) {
    const hook = webhookFromClient(client, key);
    if (!hook) continue;
    try {
      await hook.send({
        username: 'Phantom FX Errors',
        content: content || undefined,
        embeds: [embed],
        allowedMentions: mentionUsers.length ? { users: [...new Set(mentionUsers)] } : undefined,
      });
    } catch (err) {
      console.warn(`[phantom-fivem] ${key} webhook failed:`, err.message);
    }
  }

  // Owner DM escalation (blocked during Discord quarantine — channel post is primary).
  if (entry.dmOwner !== false && !isInfra) {
    if (cat === 'stuck') {
      if (owner && stuckDmAllowed(`owner:${owner}:${cat}`)) {
        await dmOwner(client, { embeds: [embed] });
      }
    } else if (isPlayerBug || cat === 'error' || cat === 'critical') {
      await dmOwner(client, { embeds: [embed] });
    }
  }

  if (entry.invitePlayer === true) {
    await dmPlayerHelpInvite(client, entry);
  }
}

async function postNormalEvent(client, entry) {
  const cat = String(entry.category || '').toLowerCase();
  const alwaysDmCats = new Set(['staff_join', 'server', 'lifecycle']);
  const neverDmCats = new Set(['resource', 'death', 'kill', 'combat', 'info']);
  const shouldDm =
    entry.dmOwner === true ||
    (entry.dmOwner !== false && alwaysDmCats.has(cat)) ||
    (entry.dmOwner !== false && !neverDmCats.has(cat));

  const owner = ownerId();
  const embed = eventEmbed(entry);
  const content = owner ? `<@${owner}>` : null;

  try {
    await postAlertsThread(client, {
      content,
      embeds: [embed],
      allowedMentions: owner ? { users: [owner] } : { parse: [] },
    });
  } catch (err) {
    console.warn('[phantom-fivem] alerts thread post failed:', err.message);
  }

  if (shouldDm) {
    await dmOwner(client, { embeds: [embed] });
  }

  // Optional quiet mirror to announcements/status (no pings).
  // Skip noisy categories — they already land in the Rex Alerts thread.
  const mirrorId = statusChannelId();
  const skipMirror = new Set(['resource', 'death', 'kill', 'combat', 'info', 'lifecycle', 'server', 'connect', 'join', 'loaded']);
  if (mirrorId && mirrorId !== alertsChannelId() && !skipMirror.has(cat)) {
    try {
      const channel = await client.channels.fetch(mirrorId);
      if (channel?.isTextBased?.()) {
        await channel.send({
          embeds: [embed],
          allowedMentions: { parse: [] },
        });
      }
    } catch (err) {
      console.warn('[phantom-fivem] status mirror failed:', err.message);
    }
  }

  if (cat === 'join' || cat === 'loaded') {
    await dmMissingGuildInvite(client, entry);
  }
}

function mountRelayRoutes(app, client) {
  const secret = relaySecret();
  const recentKeys = new Map();
  const dedupeMs = Number(process.env.FIVEM_EVENT_DEDUPE_MS || 20000);

  const authOk = (req) => {
    const auth = req.headers.authorization?.replace(/^Bearer\s+/i, '') || req.headers['x-phantom-token'];
    return !(secret && auth !== secret);
  };

  const isDuplicate = (entry) => {
    const key = [
      String(entry.category || ''),
      String(entry.title || ''),
      String(entry.description || '').slice(0, 120),
    ].join('|');
    const now = Date.now();
    const prev = recentKeys.get(key) || 0;
    if (now - prev < dedupeMs) return true;
    recentKeys.set(key, now);
    if (recentKeys.size > 200) {
      for (const [k, ts] of recentKeys) {
        if (now - ts > dedupeMs) recentKeys.delete(k);
      }
    }
    return false;
  };

  app.post('/events', async (req, res) => {
    if (!authOk(req)) {
      res.status(401).json({ error: 'unauthorized' });
      return;
    }
    const entry = req.body || {};
    try {
      if (isDuplicate(entry)) {
        res.json({ ok: true, deduped: true });
        return;
      }
      try {
        require('../src/lib/stability-store').recordEvent(entry);
      } catch (storeErr) {
        console.warn('[phantom-fivem] stability store:', storeErr.message);
      }
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
      try {
        require('../src/lib/stability-store').recordEvent(entry);
      } catch (storeErr) {
        console.warn('[phantom-fivem] stability store:', storeErr.message);
      }
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
      const restartEntry = {
        category: 'scheduled_restart',
        title: '🔄 Host restarting FiveM now',
        description: `Bot accepted restart request.\nReason: \`${reason}\`\nPlayers can rejoin once \`info.json\` is up again.`,
        color: 15548997,
        timestamp: Math.floor(Date.now() / 1000),
      };
      try {
        require('../src/lib/stability-store').recordEvent(restartEntry);
      } catch (_) {}
      await postErrorTargets(client, restartEntry);
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

function attachRexMentionEscalation(client) {
  // If a human pings Rex inside the alerts thread, Rex pings the owner + posts an alert.
  client.on('messageCreate', async (message) => {
    try {
      if (!message || message.author?.bot) return;
      const rexId = botUserId(client);
      if (!rexId || !message.mentions?.users?.has(rexId)) return;

      const threadId = cachedAlertsThreadId;
      const inAlertsThread =
        (threadId && message.channelId === threadId) ||
        (message.channel?.isThread?.() && message.channel.name === alertsThreadName());
      if (!inAlertsThread && message.channelId !== alertsChannelId()) return;

      const owner = ownerId();
      if (!owner) return;
      if (message.author.id === owner) return;

      const embed = new EmbedBuilder()
        .setColor(0xf59e0b)
        .setTitle('📣 Rex was pinged about an alert')
        .setDescription(
          `${message.author} pinged Rex in <#${message.channelId}>\n\n${(message.content || '').slice(0, 1500)}`,
        )
        .setTimestamp();

      await postAlertsThread(client, {
        content: `<@${owner}> — Rex escalation from ${message.author}`,
        embeds: [embed],
        allowedMentions: { users: [owner] },
      });
      await dmOwner(client, { embeds: [embed] });
    } catch (err) {
      console.warn('[phantom-fivem] Rex mention escalation failed:', err.message);
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
  attachRexMentionEscalation(client);

  // Defer boot work until Discord login finishes (bridge loads before ready).
  let bootStarted = false;
  const onReady = async () => {
    if (bootStarted) return;
    bootStarted = true;
    try {
      await ensureAlertsThread(client);
    } catch (err) {
      console.warn('[phantom-fivem] alerts thread setup failed:', err.message);
    }
    // Prefer channel alerts under Discord quarantine (owner DMs are often blocked).
    try {
      await postAlertsThread(client, {
        embeds: [
          new EmbedBuilder()
            .setColor(0x8b5cf6)
            .setTitle('Phantom World bot online')
            .setDescription(
              'Alerts post in **#general → 🚨 Rex Alerts**.\nPlayer bugs ping the player + Rex, then escalate here.\nOwner DMs skipped while Discord quarantine is active.',
            )
            .setTimestamp(),
        ],
        allowedMentions: { parse: [] },
      });
    } catch (err) {
      console.warn('[phantom-fivem] boot alert post failed:', err.message);
    }
  };
  if (client?.isReady?.()) {
    onReady();
  } else {
    client.once('clientReady', onReady);
    client.once('ready', onReady);
  }
};
