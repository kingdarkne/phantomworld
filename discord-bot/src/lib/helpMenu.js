/**
 * Phantom dropdown help menu (slim-bot) + ALL-IN-ONE category pointers.
 */
const {
  ActionRowBuilder,
  EmbedBuilder,
  StringSelectMenuBuilder,
  StringSelectMenuOptionBuilder,
} = require('discord.js');
const fs = require('fs');
const path = require('path');

function commandPrefix() {
  return process.env.COMMAND_PREFIX || '$';
}

function aioCategories() {
  const root = path.join(process.cwd(), 'src', 'commands');
  if (!fs.existsSync(root)) return [];
  return fs
    .readdirSync(root)
    .filter((d) => {
      try {
        return fs.statSync(path.join(root, d)).isDirectory();
      } catch {
        return false;
      }
    })
    .sort();
}

function helpCategories() {
  const p = commandPrefix();
  const aio = aioCategories();
  return [
    {
      id: 'overview',
      label: 'Overview',
      emoji: '📋',
      blurb: 'Quick start — pick a category below for full command lists.',
      commands: [
        { name: 'help', slash: '/help', prefix: `${p}help`, desc: 'Open this menu (dropdown categories)' },
        { name: 'status', slash: '/phantomstatus', prefix: `${p}status`, desc: 'FiveM server status' },
        { name: 'rex join', slash: '/rex join', prefix: `${p}rex join`, desc: 'Rex joins VC — say "Hey Rex"' },
        { name: 'play', slash: '/music play', prefix: `${p}play`, desc: 'Play music in your voice channel' },
        { name: 'ask', slash: '/ask', prefix: `${p}ask`, desc: 'Text AI support' },
        { name: 'say', slash: '/say', prefix: `${p}say`, desc: 'TTS in your voice channel' },
      ],
    },
    {
      id: 'fivem',
      label: 'FiveM / Server',
      emoji: '🎮',
      blurb: 'Live server status, players, and invites.',
      commands: [
        { name: 'status', slash: '/phantomstatus', prefix: `${p}status`, desc: 'Server name, players, connect link' },
        { name: 'players', slash: '/players', prefix: `${p}players`, desc: 'List online players' },
        {
          name: 'statuslive',
          slash: '/statuslive',
          prefix: `${p}statuslive`,
          desc: 'Post a live-updating status embed',
          staff: true,
        },
        {
          name: 'dminvite',
          slash: '/dminvite',
          prefix: `${p}dminvite <ids>`,
          desc: 'DM FiveM invite by user ID',
          staff: true,
        },
        {
          name: 'serverinvite',
          slash: '/serverinvite',
          prefix: `${p}serverinvite`,
          desc: 'Broadcast FiveM invite DMs',
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
        { name: 'ask', slash: '/ask', prefix: `${p}ask <question>`, desc: 'Text AI (Groq / fallback)' },
        { name: 'say', slash: '/say', prefix: `${p}say <text>`, desc: 'Speak text in your VC' },
      ],
    },
    {
      id: 'music',
      label: 'Music',
      emoji: '🎵',
      blurb: 'Lavalink music — play, skip, queue, volume.',
      commands: [
        { name: 'play', slash: '/music play', prefix: `${p}play <song>`, desc: 'Play a song' },
        { name: 'skip', slash: '/music skip', prefix: `${p}skip`, desc: 'Skip current track' },
        { name: 'queue', slash: '/music queue', prefix: `${p}queue`, desc: 'Show queue' },
        { name: 'stop', slash: '/music stop', prefix: `${p}stop`, desc: 'Stop and leave' },
        { name: 'volume', slash: '/music volume', prefix: `${p}vol <1-100>`, desc: 'Set volume' },
      ],
    },
    {
      id: 'aio',
      label: 'ALL-IN-ONE',
      emoji: '⚡',
      blurb: `Full TRex suite — ${aio.length} category folders (moderation, economy, tickets, …).`,
      commands: aio.slice(0, 20).map((cat) => ({
        name: cat,
        slash: `/${cat}`,
        prefix: `${p}${cat} <subcommand>`,
        desc: `Browse \`/${cat}\` or \`${p}${cat}\` subcommands`,
      })),
    },
  ];
}

const HELP_SELECT_ID = 'phantom-help-category';

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
  const fivemUrl = (process.env.FIVEM_SERVER_URL || 'http://172.245.71.46:30120').replace(/\/$/, '');
  return new EmbedBuilder()
    .setColor(0x2ee6c5)
    .setTitle('Phantom World · Command Menu')
    .setDescription(
      [
        `Browse **slash** (\`/\`) and **prefix** (\`${p}\`) commands with the dropdown below.`,
        '',
        '**Quick start**',
        `• \`${p}rex join\` or \`/rex join\` — voice AI (say **"Hey Rex"**)`,
        `• \`${p}status\` / \`/phantomstatus\` — server status`,
        `• \`${p}play <song>\` / \`/music play\` — music`,
        `• \`${p}ask <question>\` / \`/ask\` — text AI`,
        `• \`${p}say <text>\` / \`/say\` — TTS`,
        `• \`${p}ban\` / \`/moderation ban\` — moderation`,
        '',
        `**FiveM:** ${fivemUrl}`,
        '',
        '**Categories**',
        cats.map((c) => `${c.emoji} **${c.label}** — ${c.blurb}`).join('\n'),
      ].join('\n'),
    )
    .setFooter({ text: `Type / to open Discord's slash dropdown · ${p}help for this menu` });
}

function buildHelpSelect(selectedId = 'overview') {
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

function buildHelpMessage(categoryId = 'overview') {
  const cats = helpCategories();
  const category = cats.find((c) => c.id === categoryId) || cats[0];
  const embed = category.id === 'overview' ? overviewEmbed() : formatCategoryEmbed(category);
  return {
    embeds: [embed],
    components: [buildHelpSelect(category.id)],
  };
}

function handleHelpSelect(interaction) {
  const categoryId = interaction.values?.[0] || 'overview';
  return buildHelpMessage(categoryId);
}

module.exports = {
  HELP_SELECT_ID,
  helpCategories,
  buildHelpMessage,
  handleHelpSelect,
  overviewEmbed,
};
