const { SlashCommandBuilder } = require('discord.js');
const { buildHelpMessage } = require('../../lib/helpMenu');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('help')
    .setDescription('Browse all Rex commands — dropdown categories, pages, and details'),

  /**
   * @param {import('discord.js').Client} client
   * @param {import('discord.js').ChatInputCommandInteraction} interaction
   */
  run: async (client, interaction) => {
    const payload = buildHelpMessage('overview');

    if (interaction.deferred || interaction.replied) {
      await interaction.editReply(payload);
    } else {
      await interaction.reply(payload);
    }
  },
};
