import { SlashCommandBuilder } from 'discord.js';
import { createSlashContext } from './context.js';
import { runCommand } from './handlers.js';

export const slashCommands = [
  new SlashCommandBuilder().setName('status').setDescription('Phantom World server status'),
  new SlashCommandBuilder().setName('players').setDescription('List online FiveM players'),
  new SlashCommandBuilder()
    .setName('status-live')
    .setDescription('Manage the live-updating server status embed')
    .addSubcommand((s) =>
      s.setName('setup').setDescription('Post or refresh the live status message in this channel'),
    ),
  new SlashCommandBuilder()
    .setName('server-invite')
    .setDescription('DM all members with the FiveM server link (Manage Server)')
    .addBooleanOption((o) =>
      o.setName('force').setDescription('Ignore cooldown and send again'),
    ),
  new SlashCommandBuilder()
    .setName('dm-invite')
    .setDescription('DM the FiveM invite to friends by Discord user ID (Manage Server)')
    .addStringOption((o) =>
      o
        .setName('ids')
        .setDescription('One or more Discord user IDs (space or comma separated)')
        .setRequired(false),
    )
    .addUserOption((o) =>
      o.setName('user').setDescription('Or pick a user from the server').setRequired(false),
    ),
  new SlashCommandBuilder()
    .setName('ask')
    .setDescription('AI support — ask about the server')
    .addStringOption((o) => o.setName('question').setDescription('Your question').setRequired(true)),
  new SlashCommandBuilder()
    .setName('say')
    .setDescription('Speak text in your voice channel (TTS)')
    .addStringOption((o) => o.setName('text').setDescription('What to say').setRequired(true)),
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
  const c = createSlashContext(interaction, ctx);
  await runCommand(interaction.commandName, c);
}
