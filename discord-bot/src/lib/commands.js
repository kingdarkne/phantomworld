import {
  SlashCommandBuilder,
  EmbedBuilder,
  ActionRowBuilder,
  ButtonBuilder,
  ButtonStyle,
} from 'discord.js';
import { getStatus, getPlayers, buildStatusEmbed } from './fivem.js';
import { fetchJoke, fetchAioGif, buildGifEmbed, eightBallAnswer } from './fun.js';
import {
  playInChannel,
  skipTrack,
  stopMusic,
  pauseMusic,
  resumeMusic,
  getNowPlaying,
  buildNowPlayingEmbed,
  buildQueueEmbed,
  buildSearchPickRow,
  registerPendingPick,
  getFullQueue,
} from './music.js';
import { coinFlip, rollDice, pickChoice, buildAvatarEmbed, buildPoll } from './more.js';
import { personaChoices } from './personas.js';
import {
  joinVcAssistant,
  leaveVcAssistant,
  askInVc,
  setVcPersona,
  setVcListening,
} from './vc-assistant.js';
import { aiConfigured } from './ai.js';

export const slashCommands = [
  new SlashCommandBuilder().setName('status').setDescription('Phantom World server status'),
  new SlashCommandBuilder().setName('players').setDescription('List online players'),
  new SlashCommandBuilder()
    .setName('alert')
    .setDescription('Send a host alert (Manage Server)')
    .addStringOption((o) => o.setName('message').setDescription('Alert text').setRequired(true)),
  new SlashCommandBuilder()
    .setName('gif')
    .setDescription('Search a GIF (AIO-style Giphy)')
    .addStringOption((o) =>
      o.setName('search').setDescription('Search term (default: funny)'),
    ),
  new SlashCommandBuilder().setName('joke').setDescription('Random joke'),
  new SlashCommandBuilder()
    .setName('8ball')
    .setDescription('Magic 8-ball')
    .addStringOption((o) => o.setName('question').setDescription('Your question')),
  new SlashCommandBuilder()
    .setName('play')
    .setDescription('Play music in your voice channel (YouTube URL or search)')
    .addStringOption((o) => o.setName('query').setDescription('Song name or URL').setRequired(true)),
  new SlashCommandBuilder().setName('pause').setDescription('Pause current song'),
  new SlashCommandBuilder().setName('resume').setDescription('Resume paused song'),
  new SlashCommandBuilder().setName('nowplaying').setDescription('Show now playing (AIO /playing)'),
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
  new SlashCommandBuilder()
    .setName('vcjoin')
    .setDescription('Bot joins your voice channel as a talking assistant')
    .addBooleanOption((o) =>
      o.setName('listen').setDescription('Listen to voice questions (default: on)'),
    ),
  new SlashCommandBuilder()
    .setName('vcleave')
    .setDescription('Stop voice assistant and leave voice'),
  new SlashCommandBuilder()
    .setName('ask')
    .setDescription('Ask the voice assistant (it speaks the answer in VC)')
    .addStringOption((o) =>
      o.setName('question').setDescription('Your question').setRequired(true),
    ),
  new SlashCommandBuilder()
    .setName('vcvoice')
    .setDescription('Change who the bot sounds like in voice')
    .addStringOption((o) => {
      o.setName('persona').setDescription('Voice / character').setRequired(true);
      for (const { name, value } of personaChoices()) {
        o.addChoices({ name, value });
      }
      return o;
    }),
  new SlashCommandBuilder()
    .setName('vcpersona')
    .setDescription('Extra personality instructions (speak like someone specific)')
    .addStringOption((o) =>
      o.setName('style').setDescription('e.g. "southern cowboy" or "wise old wizard"').setRequired(true),
    ),
  new SlashCommandBuilder()
    .setName('vclisten')
    .setDescription('Turn voice listening on/off (speak questions without /ask)')
    .addBooleanOption((o) =>
      o.setName('enabled').setDescription('Listen to VC speech').setRequired(true),
    ),
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
      const embed = eventEmbed(entry);

      await notifyOwnerEvent(entry);

      const targetIds = new Set();
      if (interaction.channelId) targetIds.add(interaction.channelId);
      if (statusChannelId) targetIds.add(statusChannelId);

      const postedTo = [];
      const failures = [];

      for (const channelId of targetIds) {
        try {
          const channel = await interaction.client.channels.fetch(channelId);
          if (!channel?.isTextBased()) continue;

          const perms = channel.permissionsFor(interaction.client.user);
          if (!perms?.has('ViewChannel') || !perms.has('SendMessages')) {
            failures.push(`#${'name' in channel ? channel.name : channelId}: missing Send Messages`);
            continue;
          }

          await channel.send({ embeds: [embed] });
          postedTo.push('name' in channel ? `#${channel.name}` : channelId);
        } catch (err) {
          failures.push(`${channelId}: ${err?.message || 'send failed'}`);
        }
      }

      if (postedTo.length === 0) {
        await interaction.reply({
          content:
            'Could not post the alert. Add the bot to this channel with **View Channel**, **Send Messages**, and **Embed Links**, or run `/alert` in a channel the bot can post in.\n' +
            (failures.length ? `\nDetails: ${failures.join('; ')}` : ''),
          ephemeral: true,
        });
        return;
      }

      const note =
        failures.length > 0 ? `\n(Some targets failed: ${failures.join('; ')})` : '';
      await interaction.reply({
        content: `Alert posted to ${postedTo.join(', ')}.${note}`,
        ephemeral: true,
      });
      break;
    }
    case 'gif': {
      await interaction.deferReply();
      const search = interaction.options.getString('search') || 'funny';
      const gif = await fetchAioGif(search);
      await interaction.editReply({ embeds: [buildGifEmbed(gif)] });
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
      const result = await playInChannel(interaction, query);

      if (result.mode === 'pick' && result.results) {
        const results = result.results;
        const lines = results
          .map((t, i) => `**[#${i + 1}]**┆${t.title.length >= 45 ? `${t.title.slice(0, 45)}…` : t.title}`)
          .join('\n');

        const pickRow = buildSearchPickRow(results.length);
        const cancelRow = new ActionRowBuilder().addComponents(
          new ButtonBuilder()
            .setEmoji('🛑')
            .setLabel('Cancel')
            .setCustomId('phantom-music-pick-cancel')
            .setStyle(ButtonStyle.Danger),
        );

        const reply = await interaction.editReply({
          embeds: [
            new EmbedBuilder()
              .setColor(0x8b5cf6)
              .setTitle('🔍・Search Results')
              .setDescription(lines)
              .addFields({
                name: '❓┆Cancel search?',
                value: 'Press **Cancel** to stop',
                inline: true,
              }),
          ],
          components: [pickRow, cancelRow],
        });

        const msg = await interaction.fetchReply();
        registerPendingPick(msg.id, {
          guildId: interaction.guildId,
          channelId: interaction.channelId,
          userId: interaction.user.id,
          tracks: results,
        });
        break;
      }

      if (result.mode === 'queued') {
        const embed = buildNowPlayingEmbed(
          result.track,
          interaction.member.voice.channel.id,
        );
        embed.setDescription('The song has been added to the queue!');
        await interaction.editReply({ embeds: [embed] });
      } else {
        await interaction.editReply(`▶️ Now playing: **${result.track.title}**`);
      }
      break;
    }
    case 'pause': {
      const ok = pauseMusic(interaction.guildId);
      await interaction.reply(ok ? '⏸️ Paused the music!' : 'Nothing playing.');
      break;
    }
    case 'resume': {
      const ok = resumeMusic(interaction.guildId);
      await interaction.reply(ok ? '▶️ Resumed the music!' : 'Music is not paused.');
      break;
    }
    case 'nowplaying': {
      const np = getNowPlaying(interaction.guildId);
      if (!np) {
        await interaction.reply({ content: 'There are no songs playing in this server.', ephemeral: true });
        break;
      }
      await interaction.reply({
        embeds: [buildNowPlayingEmbed(np.track, np.voiceChannelId, { paused: np.paused })],
      });
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
      const session = getFullQueue(interaction.guildId);
      if (!session?.current && !session?.queue?.length) {
        await interaction.reply('_Queue is empty._');
        break;
      }
      await interaction.reply({
        embeds: [buildQueueEmbed(interaction.guild.name, session)],
      });
      break;
    }
    case 'vcjoin': {
      await interaction.deferReply();
      const listen = interaction.options.getBoolean('listen') ?? true;
      const result = await joinVcAssistant(interaction, { listen });
      await interaction.editReply(
        `🎙️ Joined **${result.channelName}** as **${result.persona.label}**.\n` +
          (result.listening
            ? 'Speak your question in VC **or** use `/ask`.\nChange voice: `/vcvoice` · Style: `/vcpersona`'
            : 'Voice listen off — use `/ask` for questions.'),
      );
      break;
    }
    case 'vcleave': {
      const ok = await leaveVcAssistant(interaction.guildId);
      await interaction.reply(ok ? '👋 Left voice channel.' : 'Not in a voice channel.');
      break;
    }
    case 'ask': {
      await interaction.deferReply();
      const question = interaction.options.getString('question', true);
      const { answer, persona } = await askInVc(interaction, question);
      await interaction.editReply({
        embeds: [
          new EmbedBuilder()
            .setColor(0x8b5cf6)
            .setTitle(`🎙️ ${persona.label}`)
            .addFields(
              { name: 'You asked', value: question.slice(0, 500) },
              { name: 'Speaking in VC', value: answer.slice(0, 1000) },
            ),
        ],
      });
      break;
    }
    case 'vcvoice': {
      const personaKey = interaction.options.getString('persona', true);
      const persona = setVcPersona(interaction.guildId, personaKey);
      if (!persona) {
        await interaction.reply({ content: 'Use `/vcjoin` first.', ephemeral: true });
        break;
      }
      await interaction.reply(
        `🔊 Voice set to **${persona.label}** (OpenAI voice: ${persona.openaiVoice}).`,
      );
      break;
    }
    case 'vcpersona': {
      const style = interaction.options.getString('style', true);
      const persona = setVcPersona(interaction.guildId, undefined, style);
      if (!persona) {
        await interaction.reply({ content: 'Use `/vcjoin` first.', ephemeral: true });
        break;
      }
      await interaction.reply(`🎭 Personality updated. Still using **${persona.label}** voice.`);
      break;
    }
    case 'vclisten': {
      const enabled = interaction.options.getBoolean('enabled', true);
      if (!aiConfigured()) {
        await interaction.reply({
          content: 'Voice listen needs `OPENAI_API_KEY` (Whisper).',
          ephemeral: true,
        });
        break;
      }
      const ok = setVcListening(interaction.guildId, enabled);
      if (!ok) {
        await interaction.reply({ content: 'Use `/vcjoin` first.', ephemeral: true });
        break;
      }
      await interaction.reply(
        enabled
          ? '🎤 Listening — speak your question in VC.'
          : '🎤 Voice listen off — use `/ask` only.',
      );
      break;
    }
    case 'phantomhelp': {
      const embed = new EmbedBuilder()
        .setColor(0x8b5cf6)
        .setTitle('Phantom World Multipurpose Bot')
        .setDescription(
          '**Voice AI:** `/vcjoin` then `/ask` or speak in VC · `/vcvoice` `/vcpersona` `/vcleave`\n' +
            '**Server:** `/status` — FiveM + CFX listing\n' +
            '**GIFs:** `/gif` — Giphy (`GIPHY_API_KEY`)\n' +
            '**Music:** `/play` `/skip` `/stop` `/queue` (Lavalink)\n\n' +
            'Voice AI needs `OPENAI_API_KEY` in bot `.env`.',
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
