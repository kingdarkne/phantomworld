const { SlashCommandBuilder, PermissionFlagsBits } = require('discord.js');
const {
  lockdownGuild,
  unlockGuild,
  isLocked,
  guardianEnabled,
  THRESHOLDS,
  infraState,
} = require('../../lib/guardian-engine');
const { postGuardianAlert, ownerIds } = require('../../lib/guardian-alerts');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('guardian')
    .setDescription('[ADMIN — FOUNDERS/ADMINS ONLY] Rex anti-raid / anti-nuke control')
    .setDefaultMemberPermissions(PermissionFlagsBits.Administrator)
    .addSubcommand((s) => s.setName('status').setDescription('Show Guardian status + thresholds'))
    .addSubcommand((s) => s.setName('lockdown').setDescription('Force full server lockdown now'))
    .addSubcommand((s) => s.setName('unlock').setDescription('Lift Guardian lockdown'))
    .addSubcommand((s) => s.setName('infra').setDescription('Run infra health checks now'))
    .addSubcommand((s) =>
      s
        .setName('testalert')
        .setDescription('Post a test alert to the security channel'),
    ),

  /**
   * @param {import('discord.js').Client} client
   * @param {import('discord.js').ChatInputCommandInteraction} interaction
   */
  run: async (client, interaction) => {
    const owners = ownerIds();
    const isOwner = owners.includes(interaction.user.id);
    const isAdmin = interaction.memberPermissions?.has(PermissionFlagsBits.Administrator);

    if (!isOwner && !isAdmin) {
      const payload = { content: 'Founders / admins only.', ephemeral: true };
      if (interaction.deferred || interaction.replied) return interaction.editReply(payload);
      return interaction.reply(payload);
    }

    if (!interaction.deferred && !interaction.replied) {
      await interaction.deferReply({ ephemeral: true });
    }

    const sub = interaction.options.getSubcommand();

    if (sub === 'status') {
      const lines = Object.entries(THRESHOLDS).map(
        ([k, v]) => `• **${k}**: ${v.threshold} / ${Math.round(v.windowMs / 1000)}s`,
      );
      const infra = [...infraState.values()]
        .map((c) => `${c.ok ? '✅' : '❌'} **${c.label}** — ${c.detail}`)
        .join('\n') || '_No infra samples yet_';

      await interaction.editReply({
        embeds: [
          {
            title: '🛡 Rex Guardian',
            color: guardianEnabled() ? 0x22c55e : 0xef4444,
            description: [
              `**Enabled:** ${guardianEnabled() ? 'YES' : 'NO'}`,
              `**Lockdown:** ${isLocked(interaction.guildId) ? 'ACTIVE' : 'off'}`,
              `**Owners:** ${owners.map((id) => `<@${id}>`).join(' ') || 'none'}`,
              '',
              '**Thresholds**',
              ...lines,
              '',
              '**Infra (last sample)**',
              infra,
            ].join('\n'),
          },
        ],
      });
      return;
    }

    if (sub === 'lockdown') {
      const n = await lockdownGuild(client, interaction.guild, `Manual lockdown by ${interaction.user.tag}`);
      await interaction.editReply(`Lockdown engaged — touched **${n}** channels.`);
      return;
    }

    if (sub === 'unlock') {
      const n = await unlockGuild(client, interaction.guild);
      await interaction.editReply(`Lockdown lifted — restored **${n}** channels.`);
      return;
    }

    if (sub === 'infra') {
      const guardianMod = require('../../handlers/security/guardian');
      const checks = await guardianMod.checkInfra(client);
      await interaction.editReply({
        content: checks.map((c) => `${c.ok ? '✅' : '❌'} **${c.label}** — ${c.detail}`).join('\n'),
      });
      return;
    }

    if (sub === 'testalert') {
      await postGuardianAlert(client, {
        level: 'high',
        title: 'Test alert',
        description: `Manual test from <@${interaction.user.id}>. If you see this, the unified alerts channel is working.`,
        pingOwner: true,
      });
      await interaction.editReply('Test alert posted to the security alerts channel/thread.');
    }
  },
};
