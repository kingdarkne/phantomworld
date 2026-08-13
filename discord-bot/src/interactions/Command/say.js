const { SlashCommandBuilder } = require('discord.js');
const { speakInChannel } = require('../../lib/phantom-say');
const { askAi } = require('../../lib/phantom-ai');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('say')
    .setDescription('Speak text in your voice channel (TTS)')
    .addStringOption((o) =>
      o.setName('text').setDescription('What to say').setRequired(true),
    ),

  /**
   * @param {import('discord.js').Client} client
   * @param {import('discord.js').ChatInputCommandInteraction} interaction
   * @param {string[]} args
   */
  run: async (client, interaction, args = []) => {
    const text =
      interaction.options?.getString?.('text') ||
      (Array.isArray(args) ? args.join(' ') : '') ||
      '';

    if (!text.trim()) {
      const msg = 'Usage: `$say hello everyone` (join a voice channel first)';
      if (interaction.deferred || interaction.replied) return interaction.editReply(msg);
      return interaction.reply(msg);
    }

    if (!interaction.deferred && !interaction.replied) {
      if (!interaction.deferred && !interaction.replied) await interaction.deferReply().catch(() => {}).catch(() => {});
    }

    try {
      await speakInChannel({
        guild: interaction.guild,
        guildId: interaction.guildId,
        member: interaction.member,
        text,
      });
      const channelName = interaction.member?.voice?.channel?.name || 'VC';
      await interaction.editReply(`🔊 Speaking in **${channelName}**`);
    } catch (err) {
      const msg = err?.message || 'TTS failed';
      let fallback = '';
      try {
        fallback = await askAi(text);
      } catch {
        // ignore
      }
      await interaction
        .editReply(`${msg}${fallback ? `\n\n_Text reply:_ ${fallback}` : ''}`)
        .catch(() => {});
    }
  },
};
