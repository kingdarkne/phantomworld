/**
 * Rebuild Rex logging after nuke + quarantine:
 * - Recreate webhooks into mod-log
 * - Point status channel to new announcements
 * - Point Mongo server logs + ticket logs to mod-log
 * - Smoke-test join/server log webhook
 */
const fs = require('fs');
const path = require('path');

const ENV_CANDIDATES = [
  path.join(process.cwd(), '.env'),
  '/home/container/.env',
];
for (const p of ENV_CANDIDATES) {
  if (fs.existsSync(p)) {
    require('dotenv').config({ path: p });
    break;
  }
}

const {
  Client,
  GatewayIntentBits,
  EmbedBuilder,
} = require('discord.js');

const GID = '1472275444257783984';
const MOD_LOG = '1538986072405704835';
const ALERTS = '1522387012726816920';
const ANNOUNCEMENTS = '1538985933318393971';
const GENERAL = '1522386964454703308';
const OPEN_TICKET = '1522386952090030130';
const CLIENT_SERVICES = '1522386949510402131';
const SUPPORT_ROLE_CANDIDATES = [
  '1472295515218640921', // Tickets Support
  '1472295505127149659', // Tickets Admin
  '1472295497149579491', // Co-Founder
];

const WH_PATH = path.join(process.cwd(), 'src/config/webhooks.json');

const client = new Client({
  intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMembers],
});

async function ensureBotCanSend(channel) {
  const me = channel.guild.members.me || (await channel.guild.members.fetchMe());
  await channel.permissionOverwrites.edit(me.id, {
    ViewChannel: true,
    SendMessages: true,
    EmbedLinks: true,
    AttachFiles: true,
    ManageWebhooks: true,
    ManageMessages: true,
    ReadMessageHistory: true,
  }).catch(() => {});
}

function patchEnv(envPath) {
  let envText = fs.readFileSync(envPath, 'utf8');
  const setEnv = (key, val) => {
    const re = new RegExp(`^${key}=.*$`, 'm');
    if (re.test(envText)) envText = envText.replace(re, `${key}=${val}`);
    else envText += `\n${key}=${val}\n`;
  };
  setEnv('DISCORD_STATUS_CHANNEL_ID', ANNOUNCEMENTS);
  setEnv('FIVEM_STATUS_CHANNEL_ID', ANNOUNCEMENTS);
  setEnv('BILLING_NOTIFY_CHANNEL_ID', GENERAL);
  setEnv('DISCORD_LOGS_CHANNEL_ID', MOD_LOG);
  setEnv('FIVEM_EVENTS_CHANNEL_ID', ALERTS);
  setEnv('DISCORD_ERROR_CHANNEL_ID', MOD_LOG);
  fs.writeFileSync(envPath, envText);
  console.log('ENV_PATCHED', envPath);
}

async function run() {
  console.log('rebuild-logging: ready as', client.user?.tag);
  const guild = await client.guilds.fetch(GID);
  await guild.channels.fetch().catch(() => {});
  const modLog = await client.channels.fetch(MOD_LOG);
  const alerts = await client.channels.fetch(ALERTS).catch(() => null);
  const announce = await client.channels.fetch(ANNOUNCEMENTS);

  await ensureBotCanSend(modLog);
  if (alerts) await ensureBotCanSend(alerts);
  await ensureBotCanSend(announce);

  // Drop stale Rex webhooks in mod-log so we do not accumulate duplicates
  const existing = await modLog.fetchWebhooks().catch(() => null);
  if (existing) {
    for (const wh of existing.values()) {
      if (/^Rex /i.test(wh.name)) {
        await wh.delete('Rebuild logging').catch(() => {});
      }
    }
  }

  const primary = await modLog.createWebhook({
    name: 'Rex Server Logs',
    reason: 'Restore logging after nuke',
  });
  const secondary = await modLog.createWebhook({
    name: 'Rex Bug / Extra Logs',
    reason: 'Restore logging after nuke',
  });
  console.log('WH_PRIMARY', primary.id);
  console.log('WH_SECONDARY', secondary.id);

  const webhooks = {
    startLogs: { id: primary.id, token: primary.token },
    shardLogs: { id: secondary.id, token: secondary.token },
    errorLogs: { id: primary.id, token: primary.token },
    dmLogs: { id: primary.id, token: primary.token },
    voiceLogs: { id: secondary.id, token: secondary.token },
    serverLogs: { id: primary.id, token: primary.token },
    serverLogs2: { id: secondary.id, token: secondary.token },
    commandLogs: { id: secondary.id, token: secondary.token },
    consoleLogs: { id: secondary.id, token: secondary.token },
    warnLogs: { id: secondary.id, token: secondary.token },
    voiceErrorLogs: { id: secondary.id, token: secondary.token },
    creditLogs: { id: secondary.id, token: secondary.token },
    evalLogs: { id: secondary.id, token: secondary.token },
    interactionLogs: { id: primary.id, token: primary.token },
    bugReportLogs: { id: secondary.id, token: secondary.token },
  };

  fs.writeFileSync(WH_PATH, JSON.stringify(webhooks, null, 4));
  console.log('WROTE', WH_PATH);

  for (const envPath of ENV_CANDIDATES) {
    if (fs.existsSync(envPath)) patchEnv(envPath);
  }

  // Print webhook URL for FiveM secrets (host must update phantom_dashboard.secrets.cfg)
  console.log('FIVEM_WEBHOOK_URL', `https://discord.com/api/webhooks/${primary.id}/${primary.token}`);

  const mongo = process.env.MONGO_TOKEN || process.env.MONGO_URI || process.env.MONGO;
  if (mongo) {
    const mongoose = require('mongoose');
    await mongoose.connect(mongo);
    const LogChannels = require('../src/database/models/logChannels');
    await LogChannels.findOneAndUpdate(
      { Guild: GID },
      { Guild: GID, Channel: MOD_LOG },
      { upsert: true },
    );
    console.log('MONGO logChannels ->', MOD_LOG);

    try {
      const tickets = require('../src/database/models/tickets');
      let supportRole = SUPPORT_ROLE_CANDIDATES.find((id) => guild.roles.cache.has(id));
      if (!supportRole) {
        const found = guild.roles.cache.find((r) => /co-?founder|staff|support|mod/i.test(r.name));
        supportRole = found?.id;
      }
      const openTicket = await client.channels.fetch(OPEN_TICKET).catch(() => null);
      const category = await client.channels.fetch(CLIENT_SERVICES).catch(() => null);

      await tickets.findOneAndUpdate(
        { Guild: GID },
        {
          Guild: GID,
          Category: category?.id || CLIENT_SERVICES,
          Role: supportRole || SUPPORT_ROLE_CANDIDATES[0],
          Channel: openTicket?.id || OPEN_TICKET,
          Logs: MOD_LOG,
        },
        { upsert: true },
      );
      console.log('MONGO tickets Logs ->', MOD_LOG, 'Channel', openTicket?.id || OPEN_TICKET);
    } catch (e) {
      console.log('TICKETS_UPDATE', e.message);
    }
    await mongoose.disconnect();
  } else {
    console.log('NO_MONGO');
  }

  await primary.send({
    username: 'Rex Server Logs',
    embeds: [
      new EmbedBuilder()
        .setColor(0x22c55e)
        .setTitle('✅ Logging restored')
        .setDescription(
          [
            'Server / join / bug / ticket / audit logs → **mod-log**.',
            `Live status → <#${ANNOUNCEMENTS}>`,
            `FiveM events → <#${ALERTS}> + Rex Alerts thread (channel, not DM).`,
            'Discord quarantine still blocks owner DMs — appeal: https://dis.gd/app-quarantine',
          ].join('\n'),
        )
        .setTimestamp(),
    ],
  });
  console.log('SMOKE_OK');

  await client.destroy();
  process.exit(0);
}

const started = Date.now();
let running = false;
const onReady = () => {
  if (running) return;
  running = true;
  run().catch((err) => {
    console.error('rebuild-logging FAILED', err);
    process.exit(1);
  });
};
client.once('clientReady', onReady);
client.once('ready', onReady);

setTimeout(() => {
  if (Date.now() - started > 45000 && !client.isReady?.()) {
    console.error('rebuild-logging TIMEOUT waiting for Discord ready');
    process.exit(1);
  }
}, 50000);

if (!process.env.DISCORD_TOKEN) {
  console.error('DISCORD_TOKEN missing');
  process.exit(1);
}
client.login(process.env.DISCORD_TOKEN);
