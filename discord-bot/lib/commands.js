import { SlashCommandBuilder, EmbedBuilder } from 'discord.js';
import { getStatus, getPlayers, buildStatusEmbed } from './fivem.js';
import { fetchJoke, fetchGifUrl, eightBallAnswer } from './fun.js';
import { playInChannel, skipTrack, stopMusic, getQueue } from './music.js';
import { coinFlip, rollDice, pickChoice, buildAvatarEmbed, buildPoll } from './more.js';

export const slashCommands = [
  new SlashCommandBuilder().setName('status').setDescription('Phantom World server status'),
  new SlashCommandBuilder().setName('players').setDescription('List online players'),
  new SlashCommandBuilder()
    .setName('alert')
    .setDescription('Send a host alert (Manage Server)')
    .addStringOption((o) => o.setName('message').setDescription('Alert text').setRequired(true)),
  new SlashCommandBuilder()
    .setName('gif')
    .setDescription('Random meme or GIF')
    .addStringOption((o) => o.setName('search').setDescription('Optional search (needs GIPHY_API_KEY)')),
  new SlashCommandBuilder().setName('joke').setDescription('Random joke'),
  new SlashCommandBuilder()
    .setName('8ball')
    .setDescription('Magic 8-ball')
    .addStringOption((o) => o.setName('question').setDescription('Your question')),
  new SlashCommandBuilder()
    .setName('play')
    .setDescription('Play music in your voice channel (YouTube URL or search)')
    .addStringOption((o) => o.setName('query').setDescription('Song name or URL').setRequired(true)),
  new SlashCommandBuilder().setName('skip').setDescription('Skip current song'),
  new SlashCommandBuilder().setName('stop').setDescription('Stop music and leave voice'),
  new SlashCommandBuilder().setName('queue').setDescription('Show music queue'),
  new SlashCommandBuilder().setName('phantomhelp').setDescription('List Phantom bot commands'),
  new SlashCommandBuilder().setName('coinflip').setDescription('Flip a coin'),
  new SlashCommandBuilder()
    .setName('roll')
    .setDescription('Roll a dice')
    .addIntegerOption((o) => o.setName('max').setDescription('Max number (default 6)').setMinValue(2).setMaxValue(1000)),
  new SlashCommandBuilder()
    .setName('choose')
    .setDescription('Pick between options')
    .addStringOption((o) => o.setName('options').setDescription('Comma-separated options').setRequired(true)),
  new SlashCommandBuilder()
    .setName('avatar')
    .setDescription('Show a user avatar')
    .addUserOption((o) => o.setName('user').setDescription('User (optional)')),
  new SlashCommandBuilder()
    .setName('poll')
    .setDescription('Quick poll embed')
    .addStringOption((o) => o.setName('question').setDescription('Poll question').setRequired(true))
    .addStringOption((o) => o.setName('options').setDescription('Comma-separated options').setRequired(true)),
].map((c) => c.toJSON());

export async function handleCommand(interaction, ctx) {
  const { notifyOwnerEvent, eventEmbed, statusChannelId } = ctx;

  switch (interaction.commandName) {
    case 'status': {
      await interaction.deferReply();
      const status = await getStatus();
      await interaction.editReply({ embeds: [buildStatusEmbed(status)] });
      break;
    }
    case 'players': {
      await interaction.deferReply();
      const [status, players] = await Promise.all([getStatus(), getPlayers()]);
      const lines =
        players.length > 0
          ? players.map((p) => `• **${p.name}** (ID ${p.id})`).join('\n')
          : '_No players online or list unavailable._';
      const embed = buildStatusEmbed(status).setDescription(lines.slice(0, 4000));
      await interaction.editReply({ embeds: [embed] });
      break;
    }
    case 'alert': {
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
      const channel = await interaction.client.channels.fetch(channelId);
      if (channel?.isTextBased()) {
        await channel.send({ embeds: [eventEmbed(entry)] });
      }
      await interaction.reply({ content: 'Alert sent.', ephemeral: true });
      break;
    }
    case 'gif': {
      await interaction.deferReply();
      const search = interaction.options.getString('search') || '';
      const url = await fetchGifUrl(search);
      await interaction.editReply({ content: url });
      break;
    }
    case 'joke': {
      await interaction.deferReply();
      const joke = await fetchJoke();
      await interaction.editReply(joke);
      break;
    }
    case '8ball': {
      const question = interaction.options.getString('question');
      await interaction.reply(eightBallAnswer(question));
      break;
    }
    case 'play': {
      await interaction.deferReply();
      const query = interaction.options.getString('query', true);
      const title = await playInChannel(interaction, query);
      await interaction.editReply(`▶️ Queued: **${title}**`);
      break;
    }
    case 'skip': {
      const ok = skipTrack(interaction.guildId);
      await interaction.reply(ok ? '⏭️ Skipped.' : 'Nothing playing.');
      break;
    }
    case 'stop': {
      const ok = stopMusic(interaction.guildId);
      await interaction.reply(ok ? '⏹️ Stopped and left voice.' : 'Not in voice.');
      break;
    }
    case 'queue': {
      const q = getQueue(interaction.guildId);
      await interaction.reply(
        q.length ? q.map((t, i) => `${i + 1}. ${t}`).join('\n') : '_Queue is empty._',
      );
      break;
    }
    case 'phantomhelp': {
      const embed = new EmbedBuilder()
        .setColor(0x8b5cf6)
        .setTitle('Phantom World Multipurpose Bot')
        .setDescription(
          '**FiveM host:** `/status` `/players` `/alert` + auto DMs on server events\n' +
            '**Fun:** `/gif` `/joke` `/8ball` `/coinflip` `/roll` `/choose` `/poll` `/avatar`\n' +
            '**Music:** `/play` `/skip` `/stop` `/queue` (join voice first)\n\n' +
            'Run this bot **on the game server host** — not your gaming PC.',
        );
      await interaction.reply({ embeds: [embed] });
      break;
    }
    case 'coinflip': {
      await interaction.reply(coinFlip());
      break;
    }
    case 'roll': {
      const max = interaction.options.getInteger('max') || 6;
      await interaction.reply(rollDice(max));
      break;
    }
    case 'choose': {
      const options = interaction.options.getString('options', true);
      await interaction.reply(pickChoice(options));
      break;
    }
    case 'avatar': {
      const target = interaction.options.getUser('user') || interaction.user;
      await interaction.reply({ embeds: [await buildAvatarEmbed(target)] });
      break;
    }
    case 'poll': {
      const question = interaction.options.getString('question', true);
      const options = interaction.options.getString('options', true);
      await interaction.reply({ embeds: [buildPoll(question, options)] });
      break;
    }
    default:
      await interaction.reply({ content: 'Unknown command.', ephemeral: true });
  }
}
