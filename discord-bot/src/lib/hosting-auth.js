/**
 * Owner-only gate for Phantom Hosting / panel admin commands.
 */
function hostingAdminIds() {
  const extras = String(process.env.HOSTING_ADMIN_IDS || '')
    .split(/[,\s]+/)
    .map((s) => s.trim())
    .filter(Boolean);
  return [
    process.env.OWNER_ID,
    process.env.DISCORD_OWNER_USER_ID,
    ...extras,
  ].filter(Boolean);
}

function isHostingAdmin(userId) {
  return hostingAdminIds().includes(String(userId));
}

async function requireHostingAdmin(client, interaction) {
  if (isHostingAdmin(interaction.user.id)) return true;
  await client.errNormal(
    {
      error: 'Only the bot owner (hosting admin) can use panel commands.',
      type: interaction.deferred || interaction.replied ? 'editreply' : 'ephemeral',
    },
    interaction,
  );
  return false;
}

module.exports = { hostingAdminIds, isHostingAdmin, requireHostingAdmin };
