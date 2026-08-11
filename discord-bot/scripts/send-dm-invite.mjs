#!/usr/bin/env node
/**
 * One-shot: DM FiveM invite embed to Discord user IDs.
 * Usage (on VPS):
 *   node scripts/send-dm-invite.mjs 702712064778436668
 *   DM_INVITE_USER_IDS=id1,id2 node scripts/send-dm-invite.mjs
 */
import '../load-env.js';
import { Client, GatewayIntentBits, Partials } from 'discord.js';
import { dmInviteToUserIds } from '../lib/serverInvite.js';

const ids = [
  ...process.argv.slice(2),
  ...(process.env.DM_INVITE_USER_IDS || '').split(/[\s,]+/),
].filter(Boolean);

if (!ids.length) {
  console.error('Usage: node scripts/send-dm-invite.mjs <userId> [userId...]');
  process.exit(1);
}

const token = process.env.DISCORD_BOT_TOKEN;
if (!token) {
  console.error('DISCORD_BOT_TOKEN missing');
  process.exit(1);
}

const client = new Client({
  intents: [GatewayIntentBits.Guilds],
  partials: [Partials.Channel],
});

client.once('ready', async () => {
  console.log(`Logged in as ${client.user.tag}`);
  try {
    const result = await dmInviteToUserIds(client, ids);
    console.log(JSON.stringify(result, null, 2));
    process.exit(result.failed && !result.sent ? 2 : 0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
});

client.login(token);
