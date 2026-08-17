require('dotenv').config({ path: '/home/container/.env' });
const { Client, GatewayIntentBits } = require('discord.js');
const wh = require('./src/config/webhooks.json');

const client = new Client({ intents: [GatewayIntentBits.Guilds] });

client.once('clientReady', async () => {
  const seen = new Set();
  for (const [name, cfg] of Object.entries(wh)) {
    const key = `${cfg.id}:${cfg.token.slice(0, 8)}`;
    if (seen.has(cfg.id)) {
      console.log(name, 'SAME_AS_OTHER', cfg.id);
      continue;
    }
    seen.add(cfg.id);
    try {
      const info = await fetch(`https://discord.com/api/v10/webhooks/${cfg.id}/${cfg.token}`).then((r) => r.json());
      console.log(name, 'channel', info.channel_id, 'hook', info.name, 'err', info.message || 'ok');
    } catch (e) {
      console.log(name, 'FAIL', e.message);
    }
  }

  for (const id of [
    process.env.DISCORD_STATUS_CHANNEL_ID,
    process.env.BILLING_NOTIFY_CHANNEL_ID,
    '1538985933318393971',
    '1538986072405704835',
    '1522387012726816920',
  ]) {
    try {
      const ch = await client.channels.fetch(id);
      console.log('CH_OK', id, ch.name, ch.type);
    } catch (e) {
      console.log('CH_BAD', id, e.message);
    }
  }

  // Mongo log channel
  try {
    const mongoose = require('mongoose');
    const uri = process.env.MONGO_URI || process.env.MONGO || process.env.DATABASE;
    if (uri) {
      await mongoose.connect(uri);
      const Schema = require('./src/database/models/logChannels');
      const data = await Schema.findOne({ Guild: '1472275444257783984' });
      console.log('MONGO_LOGS', data);
      const tickets = require('./src/database/models/tickets');
      const td = await tickets.findOne({ Guild: '1472275444257783984' });
      console.log('MONGO_TICKETS', td);
      await mongoose.disconnect();
    } else {
      console.log('NO_MONGO_URI');
    }
  } catch (e) {
    console.log('MONGO_ERR', e.message);
  }

  await client.destroy();
});

client.login(process.env.DISCORD_TOKEN);
