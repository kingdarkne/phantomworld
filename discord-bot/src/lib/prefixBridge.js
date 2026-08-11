const fs = require('fs');
const path = require('path');

/**
 * Build a message-backed fake ChatInputCommandInteraction so prefix
 * commands can reuse the same handlers as slash commands.
 */
function createMessageInteraction(message, { commandName, subcommand = null, group = null, values = {} }) {
  const state = { deferred: false, replied: false };

  const resolveUser = (name) => {
    if (values.users?.[name]) return values.users[name];
    return message.mentions.users.first() || null;
  };

  const interaction = {
    guild: message.guild,
    guildId: message.guildId,
    channel: message.channel,
    channelId: message.channelId,
    member: message.member,
    user: message.author,
    client: message.client,
    commandName,
    createdTimestamp: message.createdTimestamp,
    id: message.id,
    token: `prefix-${message.id}`,
    deferred: false,
    replied: false,
    isChatInputCommand: () => true,
    isRepliable: () => true,
    isButton: () => false,
    isStringSelectMenu: () => false,
    inGuild: () => Boolean(message.guild),
    memberPermissions: message.member?.permissions,
    options: {
      getSubcommand: () => subcommand,
      getSubcommandGroup: () => group,
      getUser: (name) => resolveUser(name),
      getMember: (name) => {
        const u = resolveUser(name);
        return u ? message.guild.members.cache.get(u.id) || null : null;
      },
      getString: (name, required = false) => {
        const v = values.strings?.[name];
        if ((v === undefined || v === null || v === '') && required) {
          throw new Error(`Missing required string option: ${name}`);
        }
        return v ?? null;
      },
      getInteger: (name) => {
        const v = values.integers?.[name];
        return Number.isFinite(v) ? v : null;
      },
      getNumber: (name) => {
        const v = values.numbers?.[name];
        return Number.isFinite(v) ? v : null;
      },
      getBoolean: (name) => values.booleans?.[name] ?? null,
      getChannel: (name) => values.channels?.[name] || message.mentions.channels.first() || message.channel,
      getRole: (name) => values.roles?.[name] || message.mentions.roles.first() || null,
      getAttachment: () => message.attachments.first() || null,
      getMentionable: (name) => resolveUser(name) || message.mentions.roles.first() || null,
    },
    async deferReply() {
      state.deferred = true;
      interaction.deferred = true;
    },
    async reply(payload) {
      state.replied = true;
      interaction.replied = true;
      const msg = await message.reply(typeof payload === 'string' ? { content: payload } : payload);
      interaction._reply = msg;
      return msg;
    },
    async editReply(payload) {
      if (interaction._reply) {
        return interaction._reply.edit(typeof payload === 'string' ? { content: payload } : payload);
      }
      return interaction.reply(payload);
    },
    async followUp(payload) {
      return message.channel.send(typeof payload === 'string' ? { content: payload } : payload);
    },
    async deleteReply() {
      if (interaction._reply) await interaction._reply.delete().catch(() => {});
    },
    async fetchReply() {
      return interaction._reply || message;
    },
  };

  return interaction;
}

function listCommandFiles() {
  const root = path.join(process.cwd(), 'src', 'commands');
  /** @type {Map<string, { category: string, sub: string, group: string|null }[]>} */
  const byLeaf = new Map();
  /** @type {Set<string>} */
  const categories = new Set();

  if (!fs.existsSync(root)) return { byLeaf, categories };

  for (const category of fs.readdirSync(root)) {
    const catPath = path.join(root, category);
    if (!fs.statSync(catPath).isDirectory()) continue;
    categories.add(category);
    for (const file of fs.readdirSync(catPath)) {
      if (!file.endsWith('.js') || file.includes('-beta')) continue;
      const sub = file.replace(/\.js$/, '');
      // fun/extra nesting is flat files named normally in this tree
      const entry = { category, sub, group: null };
      if (!byLeaf.has(sub)) byLeaf.set(sub, []);
      byLeaf.get(sub).push(entry);
    }
  }
  return { byLeaf, categories };
}

function parseValuesFromArgs(args, message) {
  const values = {
    users: {},
    strings: {},
    integers: {},
    numbers: {},
    booleans: {},
    channels: {},
    roles: {},
  };

  const mentionUser = message.mentions.users.first();
  if (mentionUser) values.users.user = mentionUser;

  // Common positional patterns
  const tokens = [...args];
  // Strip mention tokens from text args
  const textTokens = tokens.filter((t) => !/^<@!?\d+>$/.test(t) && !/^<#\d+>$/.test(t) && !/^<@&\d+>$/.test(t));

  if (textTokens.length) {
    // Prefer first numeric as amount/time
    const numIdx = textTokens.findIndex((t) => /^\d+$/.test(t));
    if (numIdx >= 0) {
      const n = Number(textTokens[numIdx]);
      values.integers.amount = n;
      values.integers.time = n;
      values.integers.minutes = n;
      values.numbers.amount = n;
      values.numbers.time = n;
      values.numbers.level = n;
    }
    const joined = textTokens.join(' ');
    values.strings.reason = joined;
    values.strings.text = joined;
    values.strings.song = joined;
    values.strings.query = joined;
    values.strings.message = joined;
    values.strings.name = textTokens[0];
    // If first token is not the only one and we have a user mention, reason is text without leading numbers sometimes
    if (mentionUser) {
      values.strings.reason = textTokens.join(' ') || 'Not given';
      values.strings.song = textTokens.join(' ');
    }
  }

  // Second user for ship-like commands
  const users = [...message.mentions.users.values()];
  if (users[0]) values.users.user = users[0];
  if (users[1]) {
    values.users.user1 = users[0];
    values.users.user2 = users[1];
  }

  return values;
}

/**
 * Prefer unique leaf names; otherwise require `$category sub`.
 * Hard aliases for common short names.
 */
const HARD_ALIASES = {
  help: { category: 'help', sub: null, topLevel: true },
  h: { category: 'help', sub: null, topLevel: true },
  commands: { category: 'help', sub: null, topLevel: true },
  cmds: { category: 'help', sub: null, topLevel: true },
  play: { category: 'music', sub: 'play' },
  p: { category: 'music', sub: 'play' },
  skip: { category: 'music', sub: 'skip' },
  s: { category: 'music', sub: 'skip' },
  stop: { category: 'music', sub: 'stop' },
  queue: { category: 'music', sub: 'queue' },
  q: { category: 'music', sub: 'queue' },
  pause: { category: 'music', sub: 'pause' },
  resume: { category: 'music', sub: 'resume' },
  volume: { category: 'music', sub: 'volume' },
  vol: { category: 'music', sub: 'volume' },
  loop: { category: 'music', sub: 'loop' },
  np: { category: 'music', sub: 'playing' },
  nowplaying: { category: 'music', sub: 'playing' },
  ban: { category: 'moderation', sub: 'ban' },
  kick: { category: 'moderation', sub: 'kick' },
  warn: { category: 'moderation', sub: 'warn' },
  warnings: { category: 'moderation', sub: 'warnings' },
  timeout: { category: 'moderation', sub: 'timeout' },
  clear: { category: 'moderation', sub: 'clear' },
  purge: { category: 'moderation', sub: 'clear' },
  lock: { category: 'moderation', sub: 'lock' },
  unlock: { category: 'moderation', sub: 'unlock' },
  hug: { category: 'fun', sub: 'hug' },
  kiss: { category: 'fun', sub: 'kiss' },
  slap: { category: 'fun', sub: 'slap' },
  meme: { category: 'images', sub: 'meme' },
  status: { category: 'phantomstatus', sub: null, topLevel: true },
  phantomstatus: { category: 'phantomstatus', sub: null, topLevel: true },
  dminvite: { category: 'dminvite', sub: null, topLevel: true },
  'dm-invite': { category: 'dminvite', sub: null, topLevel: true },
  serverinvite: { category: 'serverinvite', sub: null, topLevel: true },
  statuslive: { category: 'statuslive', sub: null, topLevel: true },
  rex: { category: 'rex', sub: null, needsSub: true },
  ticket: { category: 'tickets', sub: null, needsSub: true },
  tickets: { category: 'tickets', sub: null, needsSub: true },
};

module.exports = {
  createMessageInteraction,
  listCommandFiles,
  parseValuesFromArgs,
  HARD_ALIASES,
};
