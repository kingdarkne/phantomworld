const { SlashCommandBuilder, PermissionFlagsBits } = require('discord.js');
const { broadcastServerInviteDms } = require('../../lib/server-invite-dm');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('serverinvite')
    .setDescription('DM all members with the FiveM server link (Manage Server)')
    .setDefaultMemberPermissions(PermissionFlagsBits.ManageGuild)
    .addBooleanOption((o) =>
      o.setName('force').setDescription('Ignore cooldown and send again'),
    ),

  run: async (client, interaction) => {
    if (interaction.options.getBoolean('force')) {
      process.env.FORCE_SERVER_INVITE_DM = '1';
    }
    try {
      const result = await broadcastServerInviteDms(client, interaction.guildId);
      delete process.env.FORCE_SERVER_INVITE_DM;
      if (result.skippedCooldown) {
        await interaction.editReply(
          'Invite DMs were sent recently. Use `force: True` to send again.',
        );
        return;
      }
      await interaction.editReply(
        `Done! **${result.sent}** DMs sent, **${result.failed}** blocked, **${result.bots}** bots skipped.` +
          (result.link ? `\nLink: ${result.link}` : ''),
      );
    } catch (err) {
      delete process.env.FORCE_SERVER_INVITE_DM;
      await interaction.editReply(err?.message || 'Broadcast failed');
    }
  },
};
