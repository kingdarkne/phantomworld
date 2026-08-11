const { SlashCommandBuilder, PermissionFlagsBits } = require('discord.js');
const { upsertStatusMessage } = require('../../lib/live-status-channel');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('statuslive')
    .setDescription('Post or refresh the live-updating FiveM status embed in this channel')
    .setDefaultMemberPermissions(PermissionFlagsBits.ManageGuild),

  run: async (client, interaction) => {
    try {
      await upsertStatusMessage(client, interaction.channelId, { pin: true });
      await interaction.editReply(
        'Live server status is active in this channel (refreshes every minute).',
      );
    } catch (err) {
      await interaction.editReply(err?.message || 'Failed to set up live status');
    }
  },
};
