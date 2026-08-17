const { SlashCommandBuilder, PermissionFlagsBits } = require('discord.js');
const {
  lockdownGuild,
  unlockGuild,
  runLockdownDrill,
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
    .addSubcommand((s) =>
      s
        .setName('drill')
        .setDescription('Run a professional lockdown DRILL (warn everyone, lock, auto-unlock)')
        .addIntegerOption((o) =>
          o
            .setName('seconds')
            .setDescription('How long to hold the lockdown (15–180, default 45)')
            .setMinValue(15)
            .setMaxValue(180),
        ),
    )
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
      const result = await lockdownGuild(client, interaction.guild, `Manual lockdown by ${interaction.user.tag}`);
      const hidden = result?.hidden ?? result?.locked ?? result;
      const sz = result?.safeZoneId ? `<#${result.safeZoneId}>` : 'safe-zone';
      await interaction.editReply(
        `Full lockdown engaged — **${hidden}** channels hidden. Only ${sz} is visible (warning posted there).`,
      );
      return;
    }

    if (sub === 'unlock') {
      const n = await unlockGuild(client, interaction.guild);
      await interaction.editReply(`Lockdown lifted — restored **${n}** channels.`);
      return;
    }

    if (sub === 'drill') {
      const seconds = interaction.options.getInteger('seconds') || 45;
      await interaction.editReply(
        `Starting **security lockdown drill** for **${seconds}s** — warning @everyone, locking the server, then auto-unlocking.`,
      );
      const result = await runLockdownDrill(client, interaction.guild, { holdSeconds: seconds });
      await interaction.followUp({
        ephemeral: true,
        content: `Drill finished. Locked **${result.locked}** → unlocked **${result.unlocked}** after ${result.holdSeconds}s.`,
      });
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
