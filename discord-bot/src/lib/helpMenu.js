/**
 * Rex / Phantom paginated help menu.
 * Lists every registered slash root + subcommand with descriptions.
 * Admin / founder-only categories are labeled with large Discord headings.
 */
const {
  ActionRowBuilder,
  ButtonBuilder,
  ButtonStyle,
  EmbedBuilder,
  StringSelectMenuBuilder,
  StringSelectMenuOptionBuilder,
  ApplicationCommandOptionType,
} = require('discord.js');
const fs = require('fs');
const path = require('path');

const HELP_SELECT_ID = 'phantom-help-category';
const HELP_SELECT_ID_2 = 'phantom-help-category-2';
const HELP_PAGE_PREV = 'phantom-help-prev';
const HELP_PAGE_NEXT = 'phantom-help-next';
const HELP_PAGE_FIRST = 'phantom-help-first';
const HELP_PAGE_LAST = 'phantom-help-last';

/** Commands / categories restricted to founders & server admins */
const ADMIN_CATEGORY_IDS = new Set([
  'developers',
  'moderation',
  'automod',
  'autosetup',
  'setup',
  'config',
  'reactionroles',
  'announcement',
  'stickymessages',
  'custom-commands',
  'serverstats',
  'giveaway',
  'dminvite',
  'serverinvite',
  'statuslive',
  'embed',
]);

const ADMIN_BANNER = [
  '# ADMIN ONLY',
  '## FOUNDERS & ADMINS ONLY',
  '**These commands are for founders and server administrators.**',
].join('\n');

const COMMANDS_PER_PAGE = 8;

function commandPrefix() {
  return process.env.COMMAND_PREFIX || '$';
}

function isAdminCategory(id) {
  return ADMIN_CATEGORY_IDS.has(id);
}

function titleCase(value) {
  return String(value || '')
    .replace(/[-_]/g, ' ')
    .replace(/\b\w/g, (c) => c.toUpperCase());
}

function emojiFor(id) {
  const map = {
    overview: '📋',
    admin: '⛔',
    afk: '💤',
    announcement: '📣',
    automod: '🛡️',
    autosetup: '⚙️',
    birthdays: '🎂',
    bot: '🤖',
    casino: '🎰',
    config: '🔧',
    'custom-commands': '💻',
    developers: '👑',
    dminvite: '✉️',
    economy: '💰',
    embed: '🧱',
    family: '👪',
    fun: '😂',
    games: '🎮',
    giveaway: '🥳',
    guild: '🏠',
    help: '❓',
    images: '🖼️',
    invite: '🔗',
    invites: '📨',
    levels: '🆙',
    messages: '💬',
    moderation: '🔨',
    music: '🎵',
    notepad: '📓',
    phantomstatus: '📡',
    profile: '👤',
    radio: '📻',
    reactionroles: '🎭',
    report: '🚩',
    rex: '🦖',
    search: '🔍',
    serverinvite: '📣',
    serverstats: '📊',
    setup: '🛠️',
    soundboard: '🔊',
    statuslive: '🟢',
    stickymessages: '📌',
    suggestions: '💡',
    thanks: '🤝',
    tickets: '🎫',
    tools: '⚒️',
    tts: '🗣️',
    voice: '🎤',
    ask: '💬',
    say: '📢',
    players: '👥',
    activities: '🕹️',
    activity: '🎯',
  };
  return map[id] || '📁';
}

/**
 * Walk a slash command JSON payload into flat command entries.
 * @param {object} json
 * @returns {{ slash: string, desc: string, admin: boolean }[]}
 */
function flattenCommandJson(json) {
  const entries = [];
  const root = json.name;
  const rootAdmin = isAdminCategory(root);
  const options = json.options || [];

  const push = (slash, desc, admin = rootAdmin) => {
    entries.push({
      slash,
      desc: String(desc || 'No description').slice(0, 200),
      admin: Boolean(admin),
    });
  };

  if (!options.length) {
    push(`/${root}`, json.description, rootAdmin);
    return entries;
  }

  for (const opt of options) {
    if (opt.type === ApplicationCommandOptionType.Subcommand || opt.type === 1) {
      const admin =
        rootAdmin ||
        /\[(ADMIN|OWNER) ONLY\]/i.test(opt.description || '') ||
        /admin only/i.test(opt.description || '');
      push(`/${root} ${opt.name}`, opt.description, admin);
    } else if (opt.type === ApplicationCommandOptionType.SubcommandGroup || opt.type === 2) {
      for (const sub of opt.options || []) {
        if (sub.type === ApplicationCommandOptionType.Subcommand || sub.type === 1) {
          const admin =
            rootAdmin ||
            /\[(ADMIN|OWNER) ONLY\]/i.test(sub.description || '') ||
            /admin only/i.test(sub.description || '');
          push(`/${root} ${opt.name} ${sub.name}`, sub.description, admin);
        }
      }
    }
  }

  if (!entries.length) {
    push(`/${root}`, json.description, rootAdmin);
  }
  return entries;
}

let _catalogCache = null;

function loadCatalog() {
  if (_catalogCache) return _catalogCache;

  const intDir = path.join(process.cwd(), 'src', 'interactions', 'Command');
  const categories = [];

  if (!fs.existsSync(intDir)) {
    _catalogCache = { categories: [], totalCommands: 0 };
    return _catalogCache;
  }

  for (const file of fs.readdirSync(intDir).filter((f) => f.endsWith('.js')).sort()) {
    if (file === 'help.js' || file === 'phantomhelp.js') continue;
    let mod;
    try {
      const full = path.join(intDir, file);
      delete require.cache[require.resolve(full)];
      mod = require(full);
    } catch (err) {
      console.warn(`[helpMenu] skip ${file}:`, err.message);
      continue;
    }
    if (!mod?.data?.toJSON && !mod?.data?.name) continue;

    let json;
    try {
      json = typeof mod.data.toJSON === 'function' ? mod.data.toJSON() : mod.data;
    } catch (err) {
      console.warn(`[helpMenu] toJSON failed ${file}:`, err.message);
      continue;
    }

    const id = json.name;
    const commands = flattenCommandJson(json);
    categories.push({
      id,
      label: titleCase(id).slice(0, 100),
      emoji: emojiFor(id),
      admin: isAdminCategory(id),
      blurb: String(json.description || `Commands under /${id}`).slice(0, 100),
      commands,
    });
  }

  categories.sort((a, b) => {
    if (a.admin !== b.admin) return a.admin ? 1 : -1;
    return a.label.localeCompare(b.label);
  });

  const totalCommands = categories.reduce((n, c) => n + c.commands.length, 0);
  _catalogCache = { categories, totalCommands };
  return _catalogCache;
}

function helpCategories() {
  const { categories, totalCommands } = loadCatalog();
  const p = commandPrefix();
  const adminCats = categories.filter((c) => c.admin);
  const overview = {
    id: 'overview',
    label: 'Overview',
    emoji: '📋',
    admin: false,
    blurb: 'Start here — browse every Rex command.',
    commands: [
      {
        slash: '/help',
        desc: 'Open this menu (dropdown + pages)',
        admin: false,
      },
      {
        slash: '/rex join',
        desc: 'Rex joins your VC — say "Hey Rex"',
        admin: false,
      },
      {
        slash: '/music play',
        desc: 'Play music in your voice channel',
        admin: false,
      },
      {
        slash: '/phantomstatus',
        desc: 'FiveM server status',
        admin: false,
      },
      {
        slash: '/ask',
        desc: 'Text AI support',
        admin: false,
      },
    ],
    meta: { totalCommands, categoryCount: categories.length, prefix: p, adminCount: adminCats.length },
  };

  const adminIndex = {
    id: 'admin',
    label: 'ADMIN (Founders)',
    emoji: '⛔',
    admin: true,
    blurb: 'Founder & admin commands only',
    commands: adminCats.flatMap((c) =>
      c.commands.map((cmd) => ({
        ...cmd,
        slash: cmd.slash,
        desc: `[${c.label}] ${cmd.desc}`,
        admin: true,
      })),
    ),
  };

  return [overview, ...categories, adminIndex];
}

function formatCommandLine(cmd) {
  const p = commandPrefix();
  const slash = cmd.slash || '—';
  // Derive a rough prefix hint: /music play -> $play or $music play
  const parts = slash.replace(/^\//, '').split(/\s+/);
  const prefixHint = parts.length <= 2 ? `${p}${parts.slice(1).join(' ') || parts[0]}` : `${p}${parts.join(' ')}`;

  if (cmd.admin) {
    return [
      '### ⛔ ADMIN',
      `**\`${slash}\`**`,
      `Prefix: \`${prefixHint}\``,
      `**${cmd.desc}**`,
    ].join('\n');
  }

  return [`**\`${slash}\`**`, `Prefix: \`${prefixHint}\``, `_${cmd.desc}_`].join('\n');
}

function categoryPageCount(category) {
  if (category.id === 'overview') return 1;
  const n = category.commands?.length || 0;
  return Math.max(1, Math.ceil(n / COMMANDS_PER_PAGE));
}

function formatCategoryEmbed(category, page = 0) {
  const p = commandPrefix();
  const pages = categoryPageCount(category);
  const safePage = Math.max(0, Math.min(page, pages - 1));

  if (category.id === 'overview') {
    return overviewEmbed(category.meta || loadCatalog());
  }

  const start = safePage * COMMANDS_PER_PAGE;
  const slice = category.commands.slice(start, start + COMMANDS_PER_PAGE);
  const body = slice.map(formatCommandLine).join('\n\n') || '_No commands in this category._';

  const parts = [];
  if (category.admin) {
    parts.push(ADMIN_BANNER);
    parts.push('');
  }
  parts.push(category.blurb);
  parts.push('');
  parts.push(body);

  const color = category.admin ? 0x111111 : 0x2ee6c5;

  return new EmbedBuilder()
    .setColor(color)
    .setTitle(
      category.admin
        ? `⛔ ${category.label} — FOUNDERS & ADMINS ONLY`
        : `${category.emoji} ${category.label}`,
    )
    .setDescription(parts.join('\n').slice(0, 4096))
    .setFooter({
      text: `Page ${safePage + 1}/${pages} · ${category.commands.length} commands · Prefix ${p}${
        category.admin ? ' · ADMIN ONLY' : ''
      }`,
    });
}

function overviewEmbed(meta = {}) {
  const p = commandPrefix();
  const { categories, totalCommands } = loadCatalog();
  const adminCats = categories.filter((c) => c.admin);
  const publicCats = categories.filter((c) => !c.admin);
  const fivemUrl = (process.env.FIVEM_SERVER_URL || 'http://172.245.71.46:30120').replace(/\/$/, '');

  return new EmbedBuilder()
    .setColor(0x2ee6c5)
    .setTitle('Rex · Full Command Menu')
    .setDescription(
      [
        `**${totalCommands || meta.totalCommands || 0}+ slash commands** across **${
          categories.length
        }** categories.`,
        `Discord shows ~${categories.length + 5} top-level \`/\` roots — each expands into subcommands (the full 400+).`,
        '',
        'Use the **dropdowns** to open a category, then **⬅️ ➡️** to page every command with a full description.',
        '',
        '**Quick start**',
        `• \`/help\` — this menu`,
        `• \`/rex join\` — voice AI ("Hey Rex")`,
        `• \`/music play <song>\` — music`,
        `• \`/phantomstatus\` — FiveM status`,
        `• \`/ask <question>\` — text AI`,
        '',
        `**FiveM:** ${fivemUrl}`,
        `**Prefix:** \`${p}\``,
        '',
        `# ADMIN ONLY`,
        `## FOUNDERS & ADMINS ONLY`,
        `**${adminCats.length} admin categories** (moderation, setup, developers, …) are locked to founders/admins and labeled in black.`,
        '',
        '**Public categories**',
        publicCats
          .slice(0, 18)
          .map((c) => `${c.emoji} **${c.label}** (${c.commands.length})`)
          .join('\n'),
        publicCats.length > 18 ? `…and ${publicCats.length - 18} more in the dropdown.` : '',
      ]
        .filter(Boolean)
        .join('\n')
        .slice(0, 4096),
    )
    .setFooter({ text: `Select a category below · ${totalCommands} commands indexed` });
}

function buildHelpSelects(selectedId = 'overview') {
  const cats = helpCategories();
  const chunks = [];
  for (let i = 0; i < cats.length; i += 25) {
    chunks.push(cats.slice(i, i + 25));
  }

  const ids = [HELP_SELECT_ID, HELP_SELECT_ID_2, 'phantom-help-category-3'];

  return chunks.map((list, idx) => {
    const customId = ids[idx] || `phantom-help-category-${idx + 1}`;
    return new ActionRowBuilder().addComponents(
      new StringSelectMenuBuilder()
        .setCustomId(customId)
        .setPlaceholder(`Categories (${idx + 1}/${chunks.length}) — pick one…`)
        .addOptions(
          list.map((c) => {
            const label = ((c.admin ? 'ADMIN · ' : '') + c.label).slice(0, 100);
            const desc = (c.admin ? 'FOUNDERS/ADMINS ONLY' : c.blurb || c.label).slice(0, 100);
            return new StringSelectMenuOptionBuilder()
              .setLabel(label)
              .setDescription(desc)
              .setValue(c.id)
              .setEmoji(c.emoji)
              .setDefault(c.id === selectedId);
          }),
        ),
    );
  });
}

function buildPageButtons(categoryId, page, pageCount) {
  const encode = (btnId) => `${btnId}:${categoryId}:${page}`;
  return new ActionRowBuilder().addComponents(
    new ButtonBuilder()
      .setCustomId(encode(HELP_PAGE_FIRST))
      .setEmoji('⏮️')
      .setStyle(ButtonStyle.Secondary)
      .setDisabled(page <= 0),
    new ButtonBuilder()
      .setCustomId(encode(HELP_PAGE_PREV))
      .setEmoji('⬅️')
      .setStyle(ButtonStyle.Secondary)
      .setDisabled(page <= 0),
    new ButtonBuilder()
      .setCustomId(`phantom-help-pageinfo:${categoryId}:${page}`)
      .setLabel(`${page + 1}/${pageCount}`)
      .setStyle(ButtonStyle.Primary)
      .setDisabled(true),
    new ButtonBuilder()
      .setCustomId(encode(HELP_PAGE_NEXT))
      .setEmoji('➡️')
      .setStyle(ButtonStyle.Secondary)
      .setDisabled(page >= pageCount - 1),
    new ButtonBuilder()
      .setCustomId(encode(HELP_PAGE_LAST))
      .setEmoji('⏭️')
      .setStyle(ButtonStyle.Secondary)
      .setDisabled(page >= pageCount - 1),
  );
}

function buildHelpMessage(categoryId = 'overview', page = 0) {
  const cats = helpCategories();
  const category = cats.find((c) => c.id === categoryId) || cats[0];
  const pageCount = categoryPageCount(category);
  const safePage = Math.max(0, Math.min(page, pageCount - 1));
  const embed = formatCategoryEmbed(category, safePage);
  const components = [...buildHelpSelects(category.id)];
  if (category.id !== 'overview') {
    components.push(buildPageButtons(category.id, safePage, pageCount));
  }
  return { embeds: [embed], components };
}

function handleHelpSelect(interaction) {
  const categoryId = interaction.values?.[0] || 'overview';
  return buildHelpMessage(categoryId, 0);
}

function handleHelpButton(interaction) {
  const [btn, categoryId, pageStr] = String(interaction.customId).split(':');
  const cats = helpCategories();
  const category = cats.find((c) => c.id === categoryId) || cats[0];
  const pageCount = categoryPageCount(category);
  let page = parseInt(pageStr, 10) || 0;

  if (btn === HELP_PAGE_FIRST) page = 0;
  else if (btn === HELP_PAGE_PREV) page = Math.max(0, page - 1);
  else if (btn === HELP_PAGE_NEXT) page = Math.min(pageCount - 1, page + 1);
  else if (btn === HELP_PAGE_LAST) page = pageCount - 1;

  return buildHelpMessage(category.id, page);
}

function isHelpButton(customId) {
  return (
    typeof customId === 'string' &&
    (customId.startsWith(HELP_PAGE_PREV) ||
      customId.startsWith(HELP_PAGE_NEXT) ||
      customId.startsWith(HELP_PAGE_FIRST) ||
      customId.startsWith(HELP_PAGE_LAST))
  );
}

function invalidateHelpCache() {
  _catalogCache = null;
}

module.exports = {
  HELP_SELECT_ID,
  HELP_SELECT_ID_2,
  HELP_PAGE_PREV,
  HELP_PAGE_NEXT,
  HELP_PAGE_FIRST,
  HELP_PAGE_LAST,
  ADMIN_CATEGORY_IDS,
  ADMIN_BANNER,
  helpCategories,
  buildHelpMessage,
  handleHelpSelect,
  handleHelpButton,
  isHelpButton,
  overviewEmbed,
  loadCatalog,
  invalidateHelpCache,
};
