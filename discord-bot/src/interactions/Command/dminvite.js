const { SlashCommandBuilder, PermissionFlagsBits } = require('discord.js');
const { dmInviteToUserIds } = require('../../lib/server-invite-dm');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('dminvite')
    .setDescription('DM the FiveM invite to friends by Discord user ID (Manage Server)')
    .setDefaultMemberPermissions(PermissionFlagsBits.ManageGuild)
    .addStringOption((o) =>
      o
        .setName('ids')
        .setDescription('One or more Discord user IDs (space or comma separated)')
        .setRequired(false),
    )
    .addUserOption((o) =>
      o.setName('user').setDescription('Or pick a user from the server').setRequired(false),
    ),

  run: async (client, interaction) => {
    const ids = [];
    const picked = interaction.options.getUser('user');
    if (picked?.id) ids.push(picked.id);
    const raw = interaction.options.getString('ids');
    if (raw) ids.push(raw);

    if (!ids.length) {
      await interaction.editReply(
        'Usage: `/dminvite ids:702712064778436668` or pick a user.',
      );
      return;
    }

    const result = await dmInviteToUserIds(client, ids);
    const lines = result.details.map((d) =>
      d.ok
        ? `✅ ${d.tag || d.id}`
        : `❌ ${d.tag || d.id} — ${d.reason || 'could not DM'}`,
    );
    await interaction.editReply(
      [
        `Invite DMs: **${result.sent}** sent, **${result.failed}** failed.`,
        result.link ? `Link: ${result.link}` : null,
        '',
        ...lines.slice(0, 20),
      ]
        .filter(Boolean)
        .join('\n'),
    );
  },
};
