import { PermissionFlagsBits } from 'discord.js';

export function commandPrefix() {
  return process.env.COMMAND_PREFIX || '$';
}

export function createSlashContext(interaction, ctx) {
  const state = { deferred: false, replied: false };

  return {
    type: 'slash',
    client: interaction.client,
    guildId: interaction.guildId,
    channelId: interaction.channelId,
    member: interaction.member,
    user: interaction.user,
    guild: interaction.guild,
    shardId: interaction.guild?.shardId ?? 0,
    interaction,
    ctx,
    getString(name, required = false) {
      return interaction.options.getString(name, required);
    },
    getInteger(name) {
      return interaction.options.getInteger(name);
    },
    getBoolean(name) {
      return interaction.options.getBoolean(name);
    },
    getUser(name) {
      return interaction.options.getUser(name);
    },
    getSubcommand() {
      return interaction.options.getSubcommand(false);
    },
    hasManageGuild() {
      return interaction.memberPermissions?.has(PermissionFlagsBits.ManageGuild) ?? false;
    },
    async defer(ephemeral = false) {
      if (!state.deferred && !state.replied) {
        await interaction.deferReply({ ephemeral });
        state.deferred = true;
      }
    },
    async reply(payload) {
      const body = typeof payload === 'string' ? { content: payload } : payload;
      if (state.replied) {
        return interaction.followUp(body);
      }
      if (state.deferred || interaction.deferred) {
        state.replied = true;
        return interaction.editReply(body);
      }
      state.replied = true;
      return interaction.reply(body);
    },
    async followUp(payload) {
      return interaction.followUp(typeof payload === 'string' ? { content: payload } : payload);
    },
    isDeferred() {
      return state.deferred;
    },
    isReplied() {
      return state.replied;
    },
  };
}

export function createPrefixContext(message, args, ctx) {
  return {
    type: 'prefix',
    client: message.client,
    guildId: message.guildId,
    channelId: message.channelId,
    member: message.member,
    user: message.author,
    guild: message.guild,
    shardId: message.guild?.shardId ?? 0,
    message,
    ctx,
    args,
    command: args[0]?.toLowerCase(),
    rest: args.slice(1),
    getString() {
      return args.slice(1).join(' ');
    },
    getInteger(name) {
      if (name === 'max') {
        const n = Number(args[1]);
        return Number.isFinite(n) ? n : null;
      }
      return null;
    },
    getBoolean() {
      return false;
    },
    getUser() {
      return null;
    },
    getSubcommand() {
      return args[1]?.toLowerCase();
    },
    hasManageGuild() {
      return message.member?.permissions?.has(PermissionFlagsBits.ManageGuild) ?? false;
    },
    async defer() {},
    async reply(payload) {
      return message.reply(typeof payload === 'string' ? { content: payload } : payload);
    },
    async followUp(payload) {
      return message.channel.send(typeof payload === 'string' ? { content: payload } : payload);
    },
    isDeferred() {
      return false;
    },
    isReplied() {
      return false;
    },
  };
}
