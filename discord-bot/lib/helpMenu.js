import {
  ActionRowBuilder,
  EmbedBuilder,
  StringSelectMenuBuilder,
  StringSelectMenuOptionBuilder,
} from 'discord.js';
import { commandPrefix } from './context.js';

/** @typedef {{ name: string, slash?: string, prefix?: string, desc: string, staff?: boolean }} HelpCommand */
/** @typedef {{ id: string, label: string, emoji: string, blurb: string, commands: HelpCommand[] }} HelpCategory */

/** Single source of truth for help dropdown + slash/prefix listings. */
export function helpCategories() {
  const p = commandPrefix();
  return [
    {
      id: 'overview',
      label: 'Overview',
      emoji: '📋',
      blurb: 'Quick start — pick a category below for full command lists.',
      commands: [
        { name: 'help', slash: '/help', prefix: `${p}help`, desc: 'Open this menu (dropdown categories)' },
        { name: 'commands', slash: '/commands', prefix: `${p}commands`, desc: 'Same as help — command browser' },
        { name: 'status', slash: '/status', prefix: `${p}status`, desc: 'FiveM server status' },
        { name: 'rex join', slash: '/rex join', prefix: `${p}rex join`, desc: 'Rex joins VC — say "Hey Rex"' },
        { name: 'play', slash: '/play', prefix: `${p}play`, desc: 'Play music in your voice channel' },
      ],
    },
    {
      id: 'fivem',
      label: 'FiveM / Server',
      emoji: '🎮',
      blurb: 'Live server status, players, and staff alerts.',
      commands: [
        { name: 'status', slash: '/status', prefix: `${p}status`, desc: 'Server name, players, connect link' },
        { name: 'players', slash: '/players', prefix: `${p}players`, desc: 'List online players' },
        {
          name: 'status-live',
          slash: '/status-live setup',
          prefix: `${p}status-live setup`,
          desc: 'Post a live-updating status embed in this channel',
          staff: true,
        },
        {
          name: 'alert',
          slash: '/alert',
          prefix: `${p}alert <message>`,
          desc: 'Post a host alert embed',
          staff: true,
        },
      ],
    },
    {
      id: 'rex',
      label: 'Rex AI Voice',
      emoji: '🤖',
      blurb: 'Voice assistant — join VC, then say **"Hey Rex"** + your question.',
      commands: [
        { name: 'rex join', slash: '/rex join', prefix: `${p}rex join`, desc: 'Join your voice channel & listen' },
        { name: 'rex leave', slash: '/rex leave', prefix: `${p}rex leave`, desc: 'Leave voice and stop listening' },
        {
          name: 'rex ask',
          slash: '/rex ask',
          prefix: `${p}rex ask <question>`,
          desc: 'Ask Rex in text (speaks if you are in VC)',
        },
        {
          name: 'rex voice',
          slash: '/rex voice',
          prefix: `${p}rex voice adam`,
          desc: 'Change Rex voice (adam, michael, george, heart, bella, emma)',
        },
        { name: 'rex reset', slash: '/rex reset', prefix: `${p}rex reset`, desc: 'Clear Rex memory for this server' },
        {
          name: 'rex mode',
          slash: '/rex mode',
          prefix: `${p}rex mode on|off`,
          desc: 'Admin: unrestricted mode (needs Rex AI server)',
          staff: true,
        },
      ],
    },
    {
      id: 'ai',
      label: 'AI & TTS',
      emoji: '💬',
      blurb: 'Text AI answers and text-to-speech in voice.',
      commands: [
        { name: 'ask', slash: '/ask', prefix: `${p}ask <question>`, desc: 'Ask about Phantom World / FiveM' },
        { name: 'say', slash: '/say', prefix: `${p}say <text>`, desc: 'Speak text in your voice channel' },
        { name: 'tts', prefix: `${p}tts <text>`, desc: 'Alias for say' },
      ],
    },
    {
      id: 'music',
      label: 'Music',
      emoji: '🎵',
      blurb: 'Lavalink music — join a voice channel first.',
      commands: [
        { name: 'play', slash: '/play', prefix: `${p}play <song|url>`, desc: 'Queue a track (alias: p)' },
        { name: 'skip', slash: '/skip', prefix: `${p}skip`, desc: 'Skip current track (alias: s)' },
        { name: 'stop', slash: '/stop', prefix: `${p}stop`, desc: 'Stop and leave voice' },
        { name: 'queue', slash: '/queue', prefix: `${p}queue`, desc: 'Show queue (alias: q)' },
        { name: 'pause', slash: '/pause', prefix: `${p}pause`, desc: 'Pause playback' },
        { name: 'resume', slash: '/resume', prefix: `${p}resume`, desc: 'Resume playback' },
        { name: 'volume', slash: '/volume', prefix: `${p}volume <1-200>`, desc: 'Set volume (alias: vol)' },
        { name: 'loop', slash: '/loop', prefix: `${p}loop [toggle|track|none]`, desc: 'Toggle track loop' },
        { name: 'nowplaying', slash: '/nowplaying', prefix: `${p}np`, desc: 'Show current track' },
      ],
    },
    {
      id: 'moderation',
      label: 'Moderation',
      emoji: '🛡️',
      blurb: 'Ban, kick, timeout, warn, clear, and lock tools.',
      commands: [
        { name: 'mod ban', slash: '/mod ban', prefix: `${p}ban @user [reason]`, desc: 'Ban a member', staff: true },
        { name: 'mod kick', slash: '/mod kick', prefix: `${p}kick @user [reason]`, desc: 'Kick a member', staff: true },
        {
          name: 'mod timeout',
          slash: '/mod timeout',
          prefix: `${p}timeout @user <minutes> [reason]`,
          desc: 'Timeout a member',
          staff: true,
        },
        { name: 'mod warn', slash: '/mod warn', prefix: `${p}warn @user [reason]`, desc: 'Warn (stored locally)', staff: true },
        { name: 'mod warnings', slash: '/mod warnings', prefix: `${p}warnings @user`, desc: 'List warnings', staff: true },
        { name: 'mod clear', slash: '/mod clear', prefix: `${p}clear <1-100>`, desc: 'Bulk delete messages', staff: true },
        { name: 'mod lock', slash: '/mod lock', prefix: `${p}lock`, desc: 'Lock this channel', staff: true },
        { name: 'mod unlock', slash: '/mod unlock', prefix: `${p}unlock`, desc: 'Unlock this channel', staff: true },
      ],
    },
    {
      id: 'tickets',
      label: 'Tickets',
      emoji: '🎫',
      blurb: 'Support tickets with Close / Claim buttons.',
      commands: [
        {
          name: 'ticket setup',
          slash: '/ticket setup',
          prefix: `${p}ticket setup <categoryId> <roleId>`,
          desc: 'Configure ticket category + support role',
          staff: true,
        },
        {
          name: 'ticket panel',
          slash: '/ticket panel',
          prefix: `${p}ticket panel`,
          desc: 'Post Open Ticket button',
          staff: true,
        },
        { name: 'ticket create', slash: '/ticket create', prefix: `${p}ticket create [reason]`, desc: 'Open a ticket' },
        { name: 'ticket close', slash: '/ticket close', prefix: `${p}ticket close`, desc: 'Close this ticket' },
        { name: 'ticket add', slash: '/ticket add', prefix: `${p}ticket add @user`, desc: 'Add someone to the ticket' },
      ],
    },
    {
      id: 'invites',
      label: 'Invites',
      emoji: '📨',
      blurb: 'DM the FiveM connect link to members.',
      commands: [
        {
          name: 'dm-invite',
          slash: '/dm-invite',
          prefix: `${p}dm-invite <userId>`,
          desc: 'DM invite to specific Discord user IDs',
          staff: true,
        },
        {
          name: 'server-invite',
          slash: '/server-invite',
          prefix: `${p}server-invite [force]`,
          desc: 'DM invite to all server members',
          staff: true,
        },
      ],
    },
    {
      id: 'fun',
      label: 'Fun',
      emoji: '🎲',
      blurb: 'Games, GIFs, reactions, and quick utilities.',
      commands: [
        { name: 'gif', slash: '/gif', prefix: `${p}gif [search]`, desc: 'Random meme/GIF' },
        { name: 'joke', slash: '/joke', prefix: `${p}joke`, desc: 'Random joke' },
        { name: '8ball', slash: '/8ball', prefix: `${p}8ball [question]`, desc: 'Magic 8-ball (alias: ?)' },
        { name: 'hug', slash: '/hug', prefix: `${p}hug @user`, desc: 'Hug reaction GIF' },
        { name: 'kiss', slash: '/kiss', prefix: `${p}kiss @user`, desc: 'Kiss reaction GIF' },
        { name: 'pat', slash: '/pat', prefix: `${p}pat @user`, desc: 'Pat reaction GIF' },
        { name: 'slap', slash: '/slap', prefix: `${p}slap @user`, desc: 'Slap reaction GIF' },
        { name: 'meme', slash: '/meme', prefix: `${p}meme`, desc: 'Random Reddit meme' },
        { name: 'howgay', slash: '/howgay', prefix: `${p}howgay [@user]`, desc: 'Gay rate meter' },
        { name: 'ship', slash: '/ship', prefix: `${p}ship @a @b`, desc: 'Love meter' },
        { name: 'fact', slash: '/fact', prefix: `${p}fact`, desc: 'Random useless fact' },
        { name: 'dog', slash: '/dog', prefix: `${p}dog`, desc: 'Random dog photo' },
        { name: 'cat', slash: '/cat', prefix: `${p}cat`, desc: 'Random cat photo' },
        { name: 'roast', slash: '/roast', prefix: `${p}roast [@user]`, desc: 'Friendly roast' },
        { name: 'ascii', slash: '/ascii', prefix: `${p}ascii <text>`, desc: 'ASCII art text' },
        { name: 'coinflip', slash: '/coinflip', prefix: `${p}coinflip`, desc: 'Heads or tails' },
        { name: 'roll', slash: '/roll', prefix: `${p}roll [max]`, desc: 'Roll a dice' },
        { name: 'choose', slash: '/choose', prefix: `${p}choose a, b, c`, desc: 'Pick an option' },
        { name: 'avatar', slash: '/avatar', prefix: `${p}avatar [@user]`, desc: 'Show avatar' },
        { name: 'poll', slash: '/poll', prefix: `${p}poll Q | A, B`, desc: 'Quick poll embed' },
      ],
    },
  ];
}

export const HELP_SELECT_ID = 'phantom-help-category';

function formatCategoryEmbed(category) {
  const p = commandPrefix();
  const lines = category.commands.map((cmd) => {
    const slash = cmd.slash ? `\`${cmd.slash}\`` : '—';
    const prefix = cmd.prefix ? `\`${cmd.prefix}\`` : '—';
    const staff = cmd.staff ? ' 🔒' : '';
    return `**${cmd.name}**${staff}\nSlash: ${slash}\nPrefix: ${prefix}\n_${cmd.desc}_`;
  });

  return new EmbedBuilder()
    .setColor(0x2ee6c5)
    .setTitle(`${category.emoji} ${category.label}`)
    .setDescription(`${category.blurb}\n\n${lines.join('\n\n')}`.slice(0, 4096))
    .setFooter({
      text: `Prefix is ${p} · 🔒 = staff/admin · Use the dropdown to switch categories`,
    });
}

function overviewEmbed() {
  const p = commandPrefix();
  const cats = helpCategories().filter((c) => c.id !== 'overview');
  return new EmbedBuilder()
    .setColor(0x2ee6c5)
    .setTitle('Phantom Hosting · Command Menu')
    .setDescription(
      [
        `Browse **slash** (\`/\`) and **prefix** (\`${p}\`) commands with the dropdown below.`,
        '',
        '**Quick start**',
        `• \`${p}rex join\` or \`/rex join\` — voice AI (say **"Hey Rex"**)`,
        `• \`${p}status\` / \`/status\` — server status`,
        `• \`${p}play <song>\` / \`/play\` — music`,
        `• \`${p}mod ban\` / \`/mod\` — moderation`,
        `• \`${p}ticket create\` / \`/ticket\` — support tickets`,
        `• \`${p}ask <question>\` / \`/ask\` — text AI`,
        '',
        '**Categories**',
        cats.map((c) => `${c.emoji} **${c.label}** — ${c.blurb}`).join('\n'),
      ].join('\n'),
    )
    .setFooter({ text: `Type / to open Discord's slash dropdown · ${p}help for this menu` });
}

export function buildHelpSelect(selectedId = 'overview') {
  const menu = new StringSelectMenuBuilder()
    .setCustomId(HELP_SELECT_ID)
    .setPlaceholder('Select a command category…')
    .addOptions(
      helpCategories().map((c) =>
        new StringSelectMenuOptionBuilder()
          .setLabel(c.label)
          .setDescription(c.blurb.slice(0, 100))
          .setValue(c.id)
          .setEmoji(c.emoji)
          .setDefault(c.id === selectedId),
      ),
    );

  return new ActionRowBuilder().addComponents(menu);
}

/** Payload for $help / /help / /commands */
export function buildHelpMessage(categoryId = 'overview') {
  const cats = helpCategories();
  const category = cats.find((c) => c.id === categoryId) || cats[0];
  const embed = category.id === 'overview' ? overviewEmbed() : formatCategoryEmbed(category);
  return {
    embeds: [embed],
    components: [buildHelpSelect(category.id)],
  };
}

export function handleHelpSelect(interaction) {
  const categoryId = interaction.values?.[0] || 'overview';
  return buildHelpMessage(categoryId);
}

/** Flat text fallback (no components) — used in short tips */
export function helpEmbed() {
  return overviewEmbed();
}
