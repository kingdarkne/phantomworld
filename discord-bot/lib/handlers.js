import { EmbedBuilder, PermissionFlagsBits } from 'discord.js';
import { getStatus, getPlayers, buildStatusEmbed } from './fivem.js';
import { setupLiveStatusInChannel } from './liveStatusChannel.js';
import { broadcastServerInviteDms, dmInviteToUserIds } from './serverInvite.js';
import { fetchJoke, fetchGifUrl, eightBallAnswer } from './fun.js';
import {
  playInChannel,
  skipTrack,
  stopMusic,
  getQueue,
  pauseMusic,
  resumeMusic,
  setVolume,
  loopMusic,
  nowPlaying,
} from './music.js';
import { coinFlip, rollDice, pickChoice, buildAvatarEmbed, buildPoll } from './more.js';
import { askAi } from './ai.js';
import { speakInChannel } from './voiceTts.js';
import { commandPrefix, resolveUserFromContext } from './context.js';
import {
  rexJoin,
  rexLeave,
  rexAsk,
  rexSetVoice,
  rexReset,
  rexSetMode,
} from './rex.js';
import { buildHelpMessage, helpEmbed } from './helpMenu.js';
import {
  modBan,
  modUnban,
  modKick,
  modTimeout,
  modClearTimeout,
  modWarn,
  modWarnings,
  modClear,
  modLock,
} from './moderation.js';
import {
  ticketSetup,
  ticketCreate,
  ticketClose,
  ticketAdd,
  ticketRemove,
  ticketPanelPayload,
} from './tickets.js';
import {
  funHug,
  funKiss,
  funPat,
  funSlap,
  funMeme,
  funHowGay,
  funLoveMeter,
  funFact,
  funDog,
  funCat,
  funRoast,
  funAscii,
} from './funExtra.js';

export { helpEmbed };

function reasonFromRest(c, skip = 1) {
  if (c.type === 'slash') return c.getString('reason') || 'No reason provided';
  const parts = c.rest.slice(skip).filter((t) => !/^<@!?\d+>$/.test(t));
  return parts.join(' ').trim() || 'No reason provided';
}

async function replyFunImage(c, result) {
  const embed = new EmbedBuilder().setColor(0x2ee6c5).setImage(result.image);
  const desc = result.content || result.title;
  if (desc) embed.setDescription(desc);
  if (result.url) embed.setURL(result.url);
  if (result.footer) embed.setFooter({ text: result.footer });
  await c.reply({ embeds: [embed] });
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
    case 'speak':
    case 'tts': {
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
    case 'rex': {
      const sub =
        c.getSubcommand?.() ||
        (c.type === 'prefix' ? c.rest[0]?.toLowerCase() : null) ||
        '';
      if (!sub) {
        await c.reply('Usage: `$rex join` · `$rex leave` · `$rex ask <question>` · `$rex voice adam`');
        return;
      }

      if (c.type === 'slash') await c.defer();

      try {
        if (sub === 'join') {
          const result = await rexJoin({
            client: c.client,
            guild: c.guild,
            member: c.member,
            textChannelId: c.channelId,
          });
          await c.reply({ embeds: [result.embed] });
          break;
        }
        if (sub === 'leave') {
          await rexLeave(c.guildId);
          await c.reply('Rex left the voice channel. Later.');
          break;
        }
        if (sub === 'ask') {
          const question =
            c.getString('question') ||
            (c.type === 'prefix' ? c.rest.slice(1).join(' ') : '') ||
            c.rest.join(' ');
          const embed = await rexAsk({
            client: c.client,
            guild: c.guild,
            member: c.member,
            question,
          });
          await c.reply({ embeds: [embed] });
          break;
        }
        if (sub === 'voice') {
          const pick =
            c.getString('pick') ||
            (c.type === 'prefix' ? c.rest[1] : null) ||
            '';
          const map = {
            adam: 'am_adam',
            michael: 'am_michael',
            george: 'bm_george',
            heart: 'af_heart',
            bella: 'af_bella',
            emma: 'bf_emma',
          };
          const voice = map[pick?.toLowerCase()] || pick;
          if (!voice) {
            await c.reply('Pick a voice: adam, michael, george, heart, bella, emma');
            break;
          }
          const label = rexSetVoice(c.guildId, voice);
          await c.reply(`Rex will now speak as **${label}**.`);
          break;
        }
        if (sub === 'reset') {
          await rexReset(c.guildId);
          await c.reply("Rex memory cleared for this server. Fresh start.");
          break;
        }
        if (sub === 'mode') {
          const isAdmin = c.member?.permissions?.has?.(PermissionFlagsBits.Administrator);
          if (!isAdmin && !canManageInvites(c)) {
            await c.reply('Admin only.');
            break;
          }
          const setting =
            c.getString('setting') ||
            (c.type === 'prefix' ? c.rest[1] : null) ||
            '';
          const enable = setting === 'on' || setting === 'enable';
          if (!['on', 'off', 'enable', 'disable'].includes(String(setting).toLowerCase())) {
            await c.reply('Usage: `$rex mode on` or `$rex mode off`');
            break;
          }
          const enabled = await rexSetMode(c.guildId, enable);
          await c.reply(enabled ? '🔓 Rex unrestricted mode **enabled**.' : '🔒 Rex normal mode restored.');
          break;
        }
        await c.reply(`Unknown rex subcommand \`${sub}\`. Try join / leave / ask / voice / reset.`);
      } catch (err) {
        await c.reply(err?.message || 'Rex command failed.');
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
    case 'pause': {
      const ok = pauseMusic(c.guildId);
      await c.reply(ok ? '⏸️ Paused.' : 'Nothing playing.');
      break;
    }
    case 'resume': {
      const ok = resumeMusic(c.guildId);
      await c.reply(ok ? '▶️ Resumed.' : 'Nothing paused.');
      break;
    }
    case 'volume':
    case 'vol': {
      const level = c.getInteger('level') || Number(c.rest[0]);
      if (!Number.isFinite(level)) {
        await c.reply('Usage: `$volume 50` (1-200)');
        return;
      }
      try {
        const vol = setVolume(c.guildId, level);
        if (vol === false || vol == null) {
          await c.reply('Nothing playing.');
          return;
        }
        await c.reply(`🔊 Volume set to **${vol}%**.`);
      } catch (err) {
        await c.reply(err?.message || 'Volume failed.');
      }
      break;
    }
    case 'loop': {
      const mode = (c.getString('mode') || c.rest[0] || 'toggle').toLowerCase();
      try {
        const next = loopMusic(c.guildId, mode);
        if (!next) {
          await c.reply('Nothing playing.');
          return;
        }
        await c.reply(next === 'track' ? '🔁 Track loop **on**.' : '➡️ Loop **off**.');
      } catch (err) {
        await c.reply(err?.message || 'Loop failed.');
      }
      break;
    }
    case 'nowplaying':
    case 'np': {
      const np = nowPlaying(c.guildId);
      if (!np) {
        await c.reply('Nothing playing.');
        return;
      }
      await c.reply({
        embeds: [
          new EmbedBuilder()
            .setColor(0x2ee6c5)
            .setTitle('Now playing')
            .setDescription(
              [
                `**${np.title}**`,
                np.author ? `by ${np.author}` : null,
                np.uri ? np.uri : null,
                `Loop: \`${np.loop}\``,
              ]
                .filter(Boolean)
                .join('\n'),
            ),
        ],
      });
      break;
    }
    case 'mod':
    case 'ban':
    case 'unban':
    case 'kick':
    case 'timeout':
    case 'untimeout':
    case 'warn':
    case 'warnings':
    case 'clear':
    case 'lock':
    case 'unlock': {
      const sub =
        name === 'mod'
          ? c.getSubcommand() || ''
          : name;
      if (!sub) {
        await c.reply(
          'Usage: `$mod ban|kick|timeout|warn|clear|lock|unlock …` or `/mod`',
        );
        return;
      }
      if (c.type === 'slash') await c.defer();
      try {
        if (sub === 'ban') {
          const target = await resolveUserFromContext(c, { restIndex: name === 'mod' ? 1 : 0 });
          if (!target) {
            await c.reply('Mention a user or pass their ID.');
            return;
          }
          const days = c.getInteger('days') || Number(c.rest[name === 'mod' ? 2 : 1]) || 0;
          const embed = await modBan({
            guild: c.guild,
            moderator: c.member,
            targetUser: target,
            reason: reasonFromRest(c, name === 'mod' ? 2 : 1),
            deleteDays: Number.isFinite(days) ? days : 0,
          });
          await c.reply({ embeds: [embed] });
          break;
        }
        if (sub === 'unban') {
          const userId =
            (c.type === 'slash' ? c.getString('userid') : null) ||
            String(c.rest[name === 'mod' ? 1 : 0] || '').replace(/\D/g, '');
          if (!userId) {
            await c.reply('Usage: `$mod unban <userId>`');
            return;
          }
          const embed = await modUnban({
            guild: c.guild,
            moderator: c.member,
            userId,
            reason: reasonFromRest(c, name === 'mod' ? 2 : 1),
          });
          await c.reply({ embeds: [embed] });
          break;
        }
        if (sub === 'kick') {
          const target = await resolveUserFromContext(c, { restIndex: name === 'mod' ? 1 : 0 });
          if (!target) {
            await c.reply('Mention a user or pass their ID.');
            return;
          }
          const embed = await modKick({
            guild: c.guild,
            moderator: c.member,
            targetUser: target,
            reason: reasonFromRest(c, name === 'mod' ? 2 : 1),
          });
          await c.reply({ embeds: [embed] });
          break;
        }
        if (sub === 'timeout') {
          const target = await resolveUserFromContext(c, { restIndex: name === 'mod' ? 1 : 0 });
          const minutes =
            c.getInteger('minutes') ||
            Number(c.rest[name === 'mod' ? 2 : 1]);
          if (!target || !minutes) {
            await c.reply('Usage: `$mod timeout @user <minutes> [reason]`');
            return;
          }
          const embed = await modTimeout({
            guild: c.guild,
            moderator: c.member,
            targetUser: target,
            minutes,
            reason: reasonFromRest(c, name === 'mod' ? 3 : 2),
          });
          await c.reply({ embeds: [embed] });
          break;
        }
        if (sub === 'untimeout') {
          const target = await resolveUserFromContext(c, { restIndex: name === 'mod' ? 1 : 0 });
          if (!target) {
            await c.reply('Mention a user or pass their ID.');
            return;
          }
          const embed = await modClearTimeout({
            guild: c.guild,
            moderator: c.member,
            targetUser: target,
          });
          await c.reply({ embeds: [embed] });
          break;
        }
        if (sub === 'warn') {
          const target = await resolveUserFromContext(c, { restIndex: name === 'mod' ? 1 : 0 });
          if (!target) {
            await c.reply('Mention a user or pass their ID.');
            return;
          }
          const embed = await modWarn({
            guildId: c.guildId,
            moderator: c.member,
            targetUser: target,
            reason: reasonFromRest(c, name === 'mod' ? 2 : 1),
          });
          await c.reply({ embeds: [embed] });
          break;
        }
        if (sub === 'warnings') {
          const target = await resolveUserFromContext(c, { restIndex: name === 'mod' ? 1 : 0 });
          if (!target) {
            await c.reply('Mention a user or pass their ID.');
            return;
          }
          await c.reply({ embeds: [modWarnings({ guildId: c.guildId, targetUser: target })] });
          break;
        }
        if (sub === 'clear') {
          const amount =
            c.getInteger('amount') ||
            Number(c.rest[name === 'mod' ? 1 : 0]);
          const target = await resolveUserFromContext(c, {
            restIndex: name === 'mod' ? 2 : 1,
          });
          const channel =
            c.type === 'slash' ? c.interaction.channel : c.message.channel;
          const embed = await modClear({
            channel,
            moderator: c.member,
            amount,
            targetUser: target,
          });
          await c.reply({ embeds: [embed] });
          break;
        }
        if (sub === 'lock' || sub === 'unlock') {
          const channel =
            c.type === 'slash' ? c.interaction.channel : c.message.channel;
          const embed = await modLock({
            channel,
            moderator: c.member,
            lock: sub === 'lock',
          });
          await c.reply({ embeds: [embed] });
          break;
        }
        await c.reply(`Unknown mod action \`${sub}\`.`);
      } catch (err) {
        await c.reply(err?.message || 'Moderation command failed.');
      }
      break;
    }
    case 'ticket': {
      const sub = c.getSubcommand() || '';
      if (!sub) {
        await c.reply('Usage: `$ticket setup|create|close|add|remove|panel`');
        return;
      }
      if (c.type === 'slash') await c.defer();
      try {
        if (sub === 'setup') {
          if (!c.hasManageGuild()) {
            await c.reply('You need Manage Server permission.');
            return;
          }
          let categoryId;
          let roleId;
          let logId = null;
          if (c.type === 'slash') {
            categoryId = c.getChannel('category')?.id;
            roleId = c.getRole('role')?.id;
            logId = c.getChannel('logs')?.id || null;
          } else {
            categoryId = String(c.rest[1] || '').replace(/\D/g, '');
            roleId = String(c.rest[2] || '').replace(/\D/g, '');
            logId = c.rest[3] ? String(c.rest[3]).replace(/\D/g, '') : null;
          }
          if (!categoryId || !roleId) {
            await c.reply(
              'Usage: `/ticket setup` (pick category + role) or `$ticket setup <categoryId> <roleId> [logChannelId]`',
            );
            return;
          }
          const embed = ticketSetup({ guildId: c.guildId, categoryId, roleId, logId });
          await c.reply({ embeds: [embed] });
          break;
        }
        if (sub === 'panel') {
          if (!c.hasManageGuild()) {
            await c.reply('You need Manage Server permission.');
            return;
          }
          await c.reply(ticketPanelPayload());
          break;
        }
        if (sub === 'create') {
          const reason =
            (c.type === 'slash' ? c.getString('reason') : null) ||
            c.rest.slice(1).join(' ') ||
            'No reason provided';
          const { channel, embed } = await ticketCreate({
            guild: c.guild,
            member: c.member,
            reason,
            client: c.client,
          });
          await c.reply({ embeds: [embed.setDescription(`Ticket created: ${channel}`)] });
          break;
        }
        if (sub === 'close') {
          const channel =
            c.type === 'slash' ? c.interaction.channel : c.message.channel;
          await ticketClose({
            guild: c.guild,
            channel,
            closer: c.member,
            client: c.client,
          });
          await c.reply('Closing ticket…');
          break;
        }
        if (sub === 'add' || sub === 'remove') {
          const target = await resolveUserFromContext(c, { restIndex: 1 });
          if (!target) {
            await c.reply(`Usage: \`$ticket ${sub} @user\``);
            return;
          }
          const channel =
            c.type === 'slash' ? c.interaction.channel : c.message.channel;
          const fn = sub === 'add' ? ticketAdd : ticketRemove;
          const embed = await fn({
            guild: c.guild,
            channel,
            moderator: c.member,
            targetUser: target,
          });
          await c.reply({ embeds: [embed] });
          break;
        }
        await c.reply(`Unknown ticket subcommand \`${sub}\`.`);
      } catch (err) {
        await c.reply(err?.message || 'Ticket command failed.');
      }
      break;
    }
    case 'hug':
    case 'kiss':
    case 'pat':
    case 'slap': {
      if (c.type === 'slash') await c.defer();
      const target = await resolveUserFromContext(c, { restIndex: 0 });
      if (!target) {
        await c.reply(`Usage: \`$${name} @user\``);
        return;
      }
      const fn = { hug: funHug, kiss: funKiss, pat: funPat, slap: funSlap }[name];
      try {
        await replyFunImage(c, await fn(target.toString()));
      } catch (err) {
        await c.reply(err?.message || 'Could not fetch reaction GIF.');
      }
      break;
    }
    case 'meme': {
      if (c.type === 'slash') await c.defer();
      try {
        await replyFunImage(c, await funMeme());
      } catch (err) {
        await c.reply(err?.message || 'Meme API failed.');
      }
      break;
    }
    case 'howgay': {
      const target = (await resolveUserFromContext(c, { restIndex: 0 })) || c.user;
      await c.reply(funHowGay(target.toString()));
      break;
    }
    case 'ship': {
      let a;
      let b;
      if (c.type === 'slash') {
        a = c.getUser('user1');
        b = c.getUser('user2');
      } else {
        const mentions = [...(c.message?.mentions?.users?.values?.() || [])];
        a = mentions[0];
        b = mentions[1];
        if (!a) {
          const id1 = String(c.rest[0] || '').replace(/\D/g, '');
          const id2 = String(c.rest[1] || '').replace(/\D/g, '');
          if (id1) a = await c.client.users.fetch(id1).catch(() => null);
          if (id2) b = await c.client.users.fetch(id2).catch(() => null);
        }
      }
      if (!a || !b) {
        await c.reply('Usage: `$ship @user1 @user2`');
        return;
      }
      await c.reply(funLoveMeter(a.toString(), b.toString()));
      break;
    }
    case 'fact': {
      if (c.type === 'slash') await c.defer();
      try {
        await c.reply(await funFact());
      } catch (err) {
        await c.reply(err?.message || 'Fact API failed.');
      }
      break;
    }
    case 'dog':
    case 'cat': {
      if (c.type === 'slash') await c.defer();
      try {
        const url = name === 'dog' ? await funDog() : await funCat();
        if (!url) {
          await c.reply('No image found.');
          return;
        }
        await c.reply({
          embeds: [new EmbedBuilder().setColor(0x2ee6c5).setImage(url)],
        });
      } catch (err) {
        await c.reply(err?.message || 'Image API failed.');
      }
      break;
    }
    case 'roast': {
      const target = (await resolveUserFromContext(c, { restIndex: 0 })) || c.user;
      await c.reply(funRoast(target.toString()));
      break;
    }
    case 'ascii': {
      const text = (c.type === 'slash' ? c.getString('text') : null) || c.rest.join(' ');
      if (!text) {
        await c.reply('Usage: `$ascii hello`');
        return;
      }
      if (c.type === 'slash') await c.defer();
      try {
        const art = await funAscii(text);
        await c.reply('```\n' + art.slice(0, 1900) + '\n```');
      } catch (err) {
        await c.reply(err?.message || 'ASCII failed (is figlet installed?).');
      }
      break;
    }
    case 'phantomhelp':
    case 'help':
    case 'commands':
    case 'cmds': {
      const payload = buildHelpMessage('overview');
      await c.reply(payload);
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
      const target = (await resolveUserFromContext(c, { restIndex: 0 })) || c.user;
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
      await c.reply(`Unknown command. Try \`${commandPrefix()}help\` or \`/help\`.`);
  }
}
