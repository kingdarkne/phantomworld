import { EmbedBuilder } from 'discord.js';
import { getStatus, getPlayers, buildStatusEmbed } from './fivem.js';
import { setupLiveStatusInChannel } from './liveStatusChannel.js';
import { broadcastServerInviteDms, dmInviteToUserIds } from './serverInvite.js';
import { fetchJoke, fetchGifUrl, eightBallAnswer } from './fun.js';
import { playInChannel, skipTrack, stopMusic, getQueue } from './music.js';
import { coinFlip, rollDice, pickChoice, buildAvatarEmbed, buildPoll } from './more.js';
import { askAi } from './ai.js';
import { speakInChannel } from './voiceTts.js';
import { commandPrefix } from './context.js';

export function helpEmbed() {
  const p = commandPrefix();
  return new EmbedBuilder()
    .setColor(0x8b5cf6)
    .setTitle('Phantom World Multipurpose Bot')
    .setDescription(
      [
        '**FiveM:** `/status` `$status` · `/players` `$players` · `/alert` `$alert`',
        '**Invites:** `/dm-invite` `$dm-invite <userId>` · `/server-invite` (all members)',
        '**AI support:** `/ask` `$ask` · `/say` `$say` (voice TTS — join VC first)',
        '**Music:** `/play` `$play` · Lavalink on VPS · `$skip` `$stop` `$queue`',
        '**Fun:** `$gif` `$joke` `$8ball` `$coinflip` `$roll` `$choose` `$poll`',
        '',
        `Prefix commands use **${p}** (e.g. \`${p}dm-invite 702712064778436668\`).`,
        'Music uses **Lavalink** on the VPS. AI uses Ollama locally.',
      ].join('\n'),
    );
}

function canManageInvites(c) {
  if (c.hasManageGuild()) return true;
  const ownerId = process.env.DISCORD_OWNER_USER_ID || '';
  return Boolean(ownerId && c.user?.id === ownerId);
}

export async function runCommand(name, c) {
  const { notifyOwnerEvent, eventEmbed, statusChannelId } = c.ctx;

  switch (name) {
    case 'status': {
      if (c.type === 'slash') await c.defer();
      const status = await getStatus();
      await c.reply({ embeds: [buildStatusEmbed(status)] });
      break;
    }
    case 'players': {
      if (c.type === 'slash') await c.defer();
      const [status, players] = await Promise.all([getStatus(), getPlayers()]);
      const lines =
        players.length > 0
          ? players.map((p) => `• **${p.name}** (ID ${p.id})`).join('\n')
          : '_No players online or list unavailable._';
      const embed = buildStatusEmbed(status).setDescription(lines.slice(0, 4000));
      await c.reply({ embeds: [embed] });
      break;
    }
    case 'status-live': {
      if (c.getSubcommand() !== 'setup') {
        await c.reply('Unknown subcommand. Use `$status-live setup` or `/status-live setup`.');
        return;
      }
      if (!c.hasManageGuild()) {
        await c.reply('You need Manage Server permission.');
        return;
      }
      if (c.type === 'slash') await c.defer(true);
      await setupLiveStatusInChannel(c.client, c.channelId, { pin: true });
      await c.reply('Live server status is active in this channel (refreshes every minute).');
      break;
    }
    case 'server-invite': {
      if (!canManageInvites(c)) {
        await c.reply('You need Manage Server permission (or be the bot owner).');
        return;
      }
      if (c.getBoolean('force') || c.rest?.[0] === 'force') {
        process.env.FORCE_SERVER_INVITE_DM = '1';
      }
      if (c.type === 'slash') await c.defer(true);
      const result = await broadcastServerInviteDms(c.client, c.guildId);
      delete process.env.FORCE_SERVER_INVITE_DM;
      if (result.skippedCooldown) {
        await c.reply('Invite DMs were sent recently. Use `force` to send again.');
        return;
      }
      await c.reply(
        `Done! **${result.sent}** DMs sent, **${result.failed}** blocked, **${result.bots}** bots skipped.` +
          (result.link ? `\nLink: ${result.link}` : ''),
      );
      break;
    }
    case 'dm-invite':
    case 'dminvite':
    case 'invite-dm': {
      if (!canManageInvites(c)) {
        await c.reply('You need Manage Server permission (or be the bot owner).');
        return;
      }

      const ids = [];
      const picked = c.getUser?.('user');
      if (picked?.id) ids.push(picked.id);

      const fromOption = c.type === 'slash' ? c.getString('ids') : null;
      const fromRest = c.type === 'prefix' ? c.rest : [];
      if (fromOption) ids.push(fromOption);
      if (fromRest?.length) ids.push(...fromRest);

      if (!ids.length) {
        await c.reply(
          'Usage: `/dm-invite ids:702712064778436668` or `$dm-invite 702712064778436668`\n' +
            'You can pass several IDs separated by spaces or commas.',
        );
        return;
      }

      if (c.type === 'slash') await c.defer(true);
      const result = await dmInviteToUserIds(c.client, ids);
      if (!result.sent && !result.failed) {
        await c.reply('No valid Discord user IDs found. Use numeric IDs (Developer Mode → Copy User ID).');
        return;
      }

      const lines = result.details.map((d) =>
        d.ok
          ? `✅ ${d.tag || d.id}`
          : `❌ ${d.tag || d.id} — ${d.reason || 'could not DM (privacy / not shared server)'}`,
      );
      await c.reply(
        [
          `Invite DMs: **${result.sent}** sent, **${result.failed}** failed.`,
          result.link ? `Link: ${result.link}` : null,
          '',
          ...lines.slice(0, 20),
        ]
          .filter((x) => x !== null)
          .join('\n'),
      );
      break;
    }
    case 'alert': {
      if (!c.hasManageGuild()) {
        await c.reply('You need Manage Server permission.');
        return;
      }
      const message = c.getString('message', true) || c.rest.join(' ');
      if (!message) {
        await c.reply('Usage: `$alert your message here`');
        return;
      }
      const entry = {
        category: c.type,
        title: 'Dashboard Alert',
        description: message,
        color: 0xf59e0b,
        time: new Date().toISOString(),
      };
      const embed = eventEmbed(entry);
      await notifyOwnerEvent(entry);

      const targetIds = new Set([c.channelId]);
      if (statusChannelId) targetIds.add(statusChannelId);

      const postedTo = [];
      for (const channelId of targetIds) {
        try {
          const channel = await c.client.channels.fetch(channelId);
          if (!channel?.isTextBased()) continue;
          const perms = channel.permissionsFor(c.client.user);
          if (!perms?.has('ViewChannel') || !perms?.has('SendMessages')) continue;
          await channel.send({ embeds: [embed] });
          postedTo.push('name' in channel ? `#${channel.name}` : channelId);
        } catch {
          // skip
        }
      }

      if (!postedTo.length) {
        await c.reply('Could not post alert — bot needs Send Messages in this channel.');
        return;
      }
      await c.reply(`Alert posted to ${postedTo.join(', ')}.`);
      break;
    }
    case 'ask': {
      const question = c.getString('question') || c.rest.join(' ');
      if (!question) {
        await c.reply('Usage: `$ask how do I get a job?`');
        return;
      }
      if (c.type === 'slash') await c.defer();
      const answer = await askAi(question);
      const chunks = answer.match(/[\s\S]{1,1900}/g) || [answer];
      if (c.type === 'slash' && c.isDeferred()) {
        await c.reply(chunks[0]);
        for (let i = 1; i < chunks.length; i += 1) {
          await c.followUp(chunks[i]);
        }
      } else {
        await c.reply(chunks[0]);
        for (let i = 1; i < chunks.length; i += 1) {
          await c.followUp(chunks[i]);
        }
      }
      break;
    }
    case 'say':
    case 'speak': {
      const text = c.getString('text') || c.rest.join(' ');
      if (!text) {
        await c.reply('Usage: `$say hello everyone` (join a voice channel first)');
        return;
      }
      if (c.type === 'slash') await c.defer();
      try {
        await speakInChannel({
          guild: c.guild,
          guildId: c.guildId,
          member: c.member,
          text,
        });
        await c.reply(`🔊 Speaking in **${c.member.voice.channel.name}**`);
      } catch (err) {
        const msg = err?.message || 'TTS failed';
        await c.reply(`${msg}\n\n_Text reply:_ ${await askAi(text)}`);
      }
      break;
    }
    case 'gif': {
      if (c.type === 'slash') await c.defer();
      const search = c.getString('search') || c.rest.join(' ');
      const url = await fetchGifUrl(search);
      await c.reply(url);
      break;
    }
    case 'joke': {
      if (c.type === 'slash') await c.defer();
      const joke = await fetchJoke();
      await c.reply(joke);
      break;
    }
    case '8ball': {
      const question = c.getString('question') || c.rest.join(' ');
      await c.reply(eightBallAnswer(question));
      break;
    }
    case 'play': {
      const query = c.getString('query', true) || c.rest.join(' ');
      if (!query) {
        await c.reply('Usage: `$play never gonna give you up`');
        return;
      }
      if (c.type === 'slash') await c.defer();
      const title = await playInChannel(
        {
          guildId: c.guildId,
          member: c.member,
          guild: c.guild,
          shardId: c.shardId,
        },
        query,
      );
      await c.reply(`▶️ Queued: **${title}**`);
      break;
    }
    case 'skip': {
      const ok = skipTrack(c.guildId);
      await c.reply(ok ? '⏭️ Skipped.' : 'Nothing playing.');
      break;
    }
    case 'stop': {
      const ok = stopMusic(c.guildId);
      await c.reply(ok ? '⏹️ Stopped and left voice.' : 'Not in voice.');
      break;
    }
    case 'queue': {
      const q = getQueue(c.guildId);
      await c.reply(q.length ? q.map((t, i) => `${i + 1}. ${t}`).join('\n') : '_Queue is empty._');
      break;
    }
    case 'phantomhelp':
    case 'help': {
      await c.reply({ embeds: [helpEmbed()] });
      break;
    }
    case 'coinflip': {
      await c.reply(coinFlip());
      break;
    }
    case 'roll': {
      const max = c.getInteger('max') || Number(c.rest[0]) || 6;
      await c.reply(rollDice(max));
      break;
    }
    case 'choose': {
      const options = c.getString('options', true) || c.rest.join(' ');
      await c.reply(pickChoice(options));
      break;
    }
    case 'avatar': {
      const target = c.getUser('user') || c.user;
      await c.reply({ embeds: [await buildAvatarEmbed(target)] });
      break;
    }
    case 'poll': {
      const question = c.getString('question', true) || c.rest[0];
      const options = c.getString('options', true) || c.rest.slice(1).join(',');
      if (!question || !options) {
        await c.reply('Usage: `$poll Should we host an event? | Yes, No, Maybe`');
        return;
      }
      await c.reply({ embeds: [buildPoll(question, options)] });
      break;
    }
    default:
      await c.reply(`Unknown command. Try \`${commandPrefix()}help\` or \`/phantomhelp\`.`);
  }
}
