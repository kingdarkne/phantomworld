const { SlashCommandBuilder } = require('discord.js');
const { askAi } = require('../../lib/phantom-ai');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('ask')
    .setDescription('Ask Phantom AI about the server')
    .addStringOption((o) =>
      o.setName('question').setDescription('Your question').setRequired(true),
    ),

  /**
   * @param {import('discord.js').Client} client
   * @param {import('discord.js').ChatInputCommandInteraction} interaction
   * @param {string[]} args
   */
  run: async (client, interaction, args = []) => {
    const question =
      interaction.options?.getString?.('question') ||
      (Array.isArray(args) ? args.join(' ') : '') ||
      '';

    if (!question.trim()) {
      const msg = 'Usage: `$ask how do I get a job?` or `/ask question:...`';
      if (interaction.deferred || interaction.replied) return interaction.editReply(msg);
      return interaction.reply(msg);
    }

    if (!interaction.deferred && !interaction.replied) {
      await interaction.deferReply().catch(() => {});
    }

    const answer = await askAi(question);
    const chunks = answer.match(/[\s\S]{1,1900}/g) || [answer];
    await interaction.editReply({ content: chunks[0] }).catch(() =>
      interaction.reply({ content: chunks[0] }).catch(() => {}),
    );
    for (let i = 1; i < chunks.length; i += 1) {
      await interaction.followUp({ content: chunks[i] }).catch(() => {});
    }
  },
};
