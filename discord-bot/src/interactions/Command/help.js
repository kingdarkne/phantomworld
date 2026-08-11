const { SlashCommandBuilder } = require('discord.js');
const { buildHelpMessage, HELP_SELECT_ID } = require('../../lib/helpMenu');

module.exports = {
  data: new SlashCommandBuilder().setName('help').setDescription('Phantom command menu (dropdown)'),
  HELP_SELECT_ID,
  buildHelpMessage,

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
